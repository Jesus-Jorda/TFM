extends CharacterBody2D

class_name Character

@export var velocidad := 200.0
@export var es_forzudo: bool = false

# Factores de escala por animación (nombre -> factor).
# Compensa spritesheets con frames más pequeños en
# alguna dirección (p. ej. el teleportador camina más
# pequeño de espaldas: {"arriba": 1.12}).
@export var escala_por_animacion: Dictionary = {}

# Radio (en píxeles) al que debe estar el robot de una
# puerta cerrada o de un terminal apagado para que la
# Descarga eléctrica pueda activarlos.
const RADIO_DESCARGA := 90.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# Dirección recibida desde la cruceta táctil
var direccion_tactil := Vector2.ZERO

# Permite bloquear movimiento mientras una UI está abierta.
var movimiento_bloqueado: bool = false
var sala_actual_idx: int = -1
var _tiempo_animacion_golpe: float = 0.0
var _tiempo_animacion_empujar: float = 0.0
var _restaurar_flip_h_habilidad: bool = false
var _flip_h_antes_habilidad: bool = false
var _restaurar_speed_scale_habilidad: bool = false
# Última dirección de movimiento: la usan las
# animaciones de habilidad direccionales (el agacharse
# del niño para pasar por huecos).
var _ultima_direccion: Vector2 = Vector2.DOWN

# Escala original del sprite (para aplicar los
# factores de escala_por_animacion sin acumular).
var _escala_sprite_base: Vector2 = Vector2.ONE

# Apagado del cortocircuito: el robot se queda sin
# energía y no puede moverse durante un tiempo.
var _tiempo_apagado: float = 0.0
var _movimiento_impredecible_restante: float = 0.0
var _direccion_impredecible := Vector2.ZERO
const DURACION_MOVIMIENTO_IMPREDECIBLE := 5.0

# Luz alrededor del robot mientras su sala está en
# apagón (todo negro salvo un círculo cerca de él).
var _luz_apagon: PointLight2D = null

var _empujando_caja: bool = false
var _direccion_empuje: Vector2 = Vector2.UP
var _eje_empuje_horizontal: bool = false

# Tween del temblor de cámara (para poder cancelarlo
# si llega otro temblor mientras dura el anterior).
var _tween_camara: Tween = null

# Habilidades del personaje (datos HabilidadData que
# llegan del catálogo a través de Main/GameSession).
var habilidades: Array = []

# Recargas activas: id de habilidad -> segundos restantes
var _recargas: Dictionary = {}


func _ready() -> void:
	# El personaje debe dibujarse por encima de decoraciones tipo mesas
	# y espejos del puzzle para no quedar tapado.
	z_index = 2
	add_to_group("player")

	# Escala base del sprite para las compensaciones
	# por animación (ver escala_por_animacion).
	if anim != null:

		_escala_sprite_base = anim.scale

	# Cámara de respaldo: los personajes sin Camera2D
	# propia (Cientifica, etc.) siguen siendo visibles.
	if get_node_or_null("Camera2D") == null:

		var camara := Camera2D.new()

		camara.name = "Camera2D"

		add_child(camara)

		camara.make_current()

	# Luz del apagón (cortocircuito del robot): se
	# enciende alrededor del jugador cuando su sala
	# está a oscuras.
	_luz_apagon = PointLight2D.new()

	_luz_apagon.name = "LuzApagon"

	_luz_apagon.enabled = false

	_luz_apagon.energy = 1.0

	_luz_apagon.texture = _crear_textura_luz()

	_luz_apagon.texture_scale = 0.6

	var colision_personaje := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D
	if colision_personaje != null:
		_luz_apagon.position = colision_personaje.position

	add_child(_luz_apagon)


func _physics_process(delta: float):

	_tick_recargas(delta)

	# Robot apagado (riesgo del cortocircuito): no se
	# mueve y muestra su animación de apagado.
	if _tiempo_apagado > 0.0:

		_tiempo_apagado = max(0.0, _tiempo_apagado - delta)

		velocity = Vector2.ZERO

		move_and_slide()

		if anim != null and anim.sprite_frames != null \
				and anim.sprite_frames.has_animation("apagarse") \
				and anim.animation != "apagarse":

			anim.play("apagarse")

		if _tiempo_apagado == 0.0 and anim != null:

			# Al reactivarse corta la animación de apagado
			# y vuelve al flujo normal de movimiento.
			anim.stop()

		return

	if _tiempo_animacion_golpe > 0.0:
		_tiempo_animacion_golpe = max(0.0, _tiempo_animacion_golpe - delta)
		velocity = Vector2.ZERO
		move_and_slide()
		if _tiempo_animacion_golpe == 0.0 and _restaurar_flip_h_habilidad:
			anim.flip_h = _flip_h_antes_habilidad
			_restaurar_flip_h_habilidad = false
		if _tiempo_animacion_golpe == 0.0 and _restaurar_speed_scale_habilidad:
			anim.speed_scale = 1.0
			_restaurar_speed_scale_habilidad = false
		return
	if _tiempo_animacion_empujar > 0.0:
		_tiempo_animacion_empujar = max(0.0, _tiempo_animacion_empujar - delta)
	if _empujando_caja:
		velocity = Vector2.ZERO
		return
	if _movimiento_impredecible_restante > 0.0:
		_movimiento_impredecible_restante = maxf(0.0, _movimiento_impredecible_restante - delta)
		velocity = _direccion_impredecible * velocidad
		move_and_slide()
		actualizar_animacion(_direccion_impredecible)
		return

	if movimiento_bloqueado:
		velocity = Vector2.ZERO
		move_and_slide()
		actualizar_animacion(Vector2.ZERO)
		return

	var direccion := Vector2.ZERO


	# TECLADO - PC

	if Input.is_key_pressed(KEY_W):
		direccion.y -= 1

	if Input.is_key_pressed(KEY_S):
		direccion.y += 1

	if Input.is_key_pressed(KEY_A):
		direccion.x -= 1

	if Input.is_key_pressed(KEY_D):
		direccion.x += 1


	# CONTROL TÁCTIL - MÓVIL

	if direccion == Vector2.ZERO:
		direccion = direccion_tactil


	# NORMALIZAR

	direccion = direccion.normalized()
	if _empujando_caja:
		if _eje_empuje_horizontal:
			direccion.y = 0.0
		else:
			direccion.x = 0.0


	# MOVIMIENTO

	velocity = direccion * velocidad

	move_and_slide()


	# ANIMACIÓN

	actualizar_animacion(direccion)


# RECIBIR DIRECCIÓN DE LA CRUCETA

func establecer_direccion(direccion: Vector2):

	direccion_tactil = direccion


# DETENER MOVIMIENTO TÁCTIL

func detener_movimiento():

	direccion_tactil = Vector2.ZERO
	velocity = Vector2.ZERO


func establecer_sala_actual(indice: int) -> void:
	sala_actual_idx = indice


# ANIMACIÓN

func actualizar_animacion(dir: Vector2):
	if _empujando_caja:
		if dir == Vector2.ZERO:
			anim.pause()
			return
		activar_animacion_empujar(_direccion_empuje)
		return

	if dir == Vector2.ZERO:
		anim.pause()
		return

	_recordar_direccion(dir)

	var nombre := ""

	if abs(dir.x) > abs(dir.y):

		if dir.x > 0:
			nombre = "derecha"
		else:
			nombre = "izquierda"

	else:

		if dir.y > 0:
			nombre = "abajo"
		else:
			nombre = "arriba"

	if anim.sprite_frames.has_animation(nombre):

		anim.play(nombre)

	else:

		# Algunos personajes usan otros nombres para
		# arriba/abajo (up/down).
		var alias := _alias_animacion(nombre)

		if alias != "":

			nombre = alias

			anim.play(nombre)

	_aplicar_escala_animacion(nombre)


# Recuerda hacia dónde miraba el personaje por última
# vez (lo llama actualizar_animacion).
func _recordar_direccion(dir: Vector2) -> void:

	if dir != Vector2.ZERO:

		_ultima_direccion = dir


# Sufijo de animación según la última dirección:
# derecha / izquierda / arriba / abajo (por defecto).
func _sufijo_direccion() -> String:

	if _ultima_direccion.x > 0.5:

		return "derecha"

	if _ultima_direccion.x < -0.5:

		return "izquierda"

	if _ultima_direccion.y < -0.5:

		return "arriba"

	return "abajo"


# Aplica el factor de escala de la animación actual
# (por defecto 1.0: no cambia nada).
func _aplicar_escala_animacion(nombre: String) -> void:

	if anim == null:

		return

	var factor: float = float(
		escala_por_animacion.get(nombre, 1.0)
	)

	anim.scale = _escala_sprite_base * factor


func activar_animacion_golpe() -> void:
	_tiempo_animacion_golpe = 1.4

	# El golpe de suelo sacude la cámara del personaje.
	sacudir_camara(14.0, 0.8)

	if anim == null:
		return

	if anim.sprite_frames != null \
			and anim.sprite_frames.has_animation("golpe"):

		anim.play("golpe")

		_aplicar_escala_animacion("golpe")


# SACUDIR LA CÁMARA
# Tiembla la Camera2D del personaje (nodo hijo
# "Camera2D"). Lo usa el golpe de suelo y la vibración
# que llega de las salas vecinas.
func sacudir_camara(
	intensidad: float = 14.0,
	duracion: float = 0.8
) -> void:

	var camara := get_node_or_null("Camera2D") as Camera2D

	if camara == null:
		return

	# Si ya había un temblor en marcha, se cancela.
	if _tween_camara != null and _tween_camara.is_valid():
		_tween_camara.kill()

	var pasos := 10

	_tween_camara = create_tween()

	for i in range(pasos):

		var fuerza := intensidad * (1.0 - float(i) / float(pasos))

		var desvio := Vector2(
			randf_range(-fuerza, fuerza),
			randf_range(-fuerza, fuerza)
		)

		_tween_camara.tween_property(
			camara,
			"offset",
			desvio,
			duracion / pasos
		)

	_tween_camara.tween_property(
		camara,
		"offset",
		Vector2.ZERO,
		duracion / pasos
	)


func activar_animacion_empujar(direccion: Vector2) -> void:
	if anim == null:
		return
	_empujando_caja = true
	_direccion_empuje = direccion
	_tiempo_animacion_empujar = 0.25
	var animacion := "empujarabajo"
	if abs(direccion.x) > abs(direccion.y):
		animacion = "empujarderecha" if direccion.x > 0.0 else "empujarizquierda"
	else:
		animacion = "empujarabajo" if direccion.y > 0.0 else "empujararriba"
	if anim.sprite_frames.has_animation(animacion):
		if anim.animation != animacion:
			anim.play(animacion)


func dejar_de_empujar() -> void:
	_empujando_caja = false
	_tiempo_animacion_empujar = 0.0
	velocity = Vector2.ZERO


func pausar_animacion_empujar() -> void:
	if anim != null:
		anim.pause()


func configurar_eje_empuje(horizontal: bool) -> void:
	_eje_empuje_horizontal = horizontal


func tiene_habilidad_forzudo() -> bool:
	return es_forzudo


# SISTEMA DE HABILIDADES
# Las habilidades llegan como datos (HabilidadData)
# desde el catálogo. La interfaz se genera sola y cada
# botón ejecuta usar_habilidad(id). Añadir un personaje
# nuevo = añadirlo al catálogo con sus habilidades;
# no hay que tocar la interfaz.

func configurar_habilidades(lista: Array) -> void:

	habilidades = lista

	_recargas.clear()

	for hab in lista:

		if hab != null and not hab.es_pasiva:

			_recargas[hab.id] = 0.0


func _tick_recargas(delta: float) -> void:

	for id in _recargas.keys():

		if _recargas[id] > 0.0:

			_recargas[id] = max(
				0.0,
				_recargas[id] - delta
			)


func en_recarga(id: String) -> bool:

	return float(_recargas.get(id, 0.0)) > 0.0


func tiempo_recarga_restante(id: String) -> float:

	return float(_recargas.get(id, 0.0))


func _hab_por_id(id: String) -> HabilidadData:

	for hab in habilidades:

		if hab != null and hab.id == id:

			return hab

	return null


func usar_habilidad(id: String) -> bool:

	if movimiento_bloqueado:

		return false

	if _tiempo_apagado > 0.0:

		# El robot está apagado: sin habilidades.
		return false

	var hab := _hab_por_id(id)

	if hab == null or hab.es_pasiva or en_recarga(id):

		return false

	var ejecutada := false

	match id:

		"golpe_llave":

			var caja := _caja_met_alica_delante()

			var hay_puzzle := (
				caja == null and _hay_puzzle_descolocable()
			)

			if caja != null or hay_puzzle:
				if caja != null:
					ejecutada = _desplazar_caja(caja)
					if not ejecutada:
						_avisar_tooltip(
							"Golpe con llave inglesa",
							"La caja no puede moverse en esa dirección."
						)
				else:
					_activar_animacion_habilidad(
						"golpellave", 0.8, 6.0
					)
					_desordenar_puzzle_cercano()
					_reproducir_sonido_habilidad("golpellave")
					ejecutada = true

			else:

				_aviso_golpe_llave_sin_objetivo()

		"reparacion_chapucera":

			var objetivo := _reparacion_objetivo()

			if objetivo.is_empty():

				_aviso_reparacion_sin_objetivo()

			else:

				if randf() < 0.3:

					# FALLO: chispa + puerta bloqueada
					_activar_animacion_habilidad(
						"reparacionmal", 1.0, 0.0
					)

					_fallo_reparacion()

				else:

					# Exito: repara el objetivo
					_activar_animacion_habilidad(
						"reparacion", 1.2, 0.0
					)

					_ejecutar_reparacion(objetivo)

				_reproducir_sonido_habilidad("reparacionchapucera")
				ejecutada = true

		# ROBOT DEFECTUOSO
		"descarga_electrica":

			# Solo funciona con mecanismos cerca; si no
			# hay nada al alcance, no se gasta la recarga.
			if _descarga_electrica_efecto():

				_activar_animacion_habilidad(
					"descarga", 0.8, 4.0
				)
				_reproducir_sonido_habilidad("descargaelectrica")

				ejecutada = true

			else:

				_aviso_descarga_sin_objetivo()

		"cortocircuito":

			_activar_animacion_habilidad(
				"cortocircuito", 1.0, 6.0
			)
			_reproducir_sonido_habilidad("cortocircuito", 3.0)

			# Apaga la sala 100s (todo negro salvo la luz
			# alrededor del robot) con riesgo de apagarse.
			_cortocircuito_efecto()

			ejecutada = true

		# NIÑO CIENTÍFICO
		"pasar_huecos":
			var conducto := _conducto_cercano()
			if conducto == null:
				_avisar_tooltip("Pasar por huecos", "Acércate a un conducto de ventilación.")
			else:
				var main := get_tree().get_first_node_in_group("main")
				var conexion_id: int = conducto.objeto_datos.conducto_conexion_id
				var puede_pasar: bool = (
					main != null
					and main.has_method("puede_teletransportar_por_conducto")
					and main.puede_teletransportar_por_conducto(conexion_id)
				)
				if not puede_pasar:
					_avisar_tooltip(
						"Pasar por huecos",
						"El conducto conectado no esta disponible."
					)
				elif main.has_method("teletransportar_por_conducto"):
					var superficie: ObjectBase.Superficie = conducto.objeto_datos.superficie
					_activar_animacion_conducto(superficie)
					_reproducir_sonido_habilidad("conductoventilacion")
					ejecutada = main.teletransportar_por_conducto(
						conexion_id
					)

		"accion_impredecible":

			_activar_animacion_habilidad(
				"accionimpredecible", 0.9, 2.0
			)
			_reproducir_sonido_habilidad("accionimpredecible")

			var gestor := get_tree().get_first_node_in_group("gestor_turnos") as GestorTurnos
			var exito_impredecible: bool = (
				gestor != null and gestor.resultado_accion_impredecible()
			)
			if exito_impredecible:
				_avisar_tooltip("Acción impredecible", "La acción ha salido bien: +10 segundos de turno.")
			else:
				_direccion_impredecible = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT].pick_random()
				_movimiento_impredecible_restante = DURACION_MOVIMIENTO_IMPREDECIBLE
				_avisar_tooltip("Acción impredecible", "La acción ha fallado: el niño se moverá solo durante 5 segundos.")
			ejecutada = true

		# CIENTÍFICO TELEPORTADOR
		"mini_teletransporte":

			_activar_animacion_habilidad(
				"teleport", 0.6, 3.0
			)
			_reproducir_sonido_habilidad("teletransporte")

			ejecutada = true

		"teletransporte_objeto":

			_activar_animacion_habilidad(
				"teleobject", 0.8, 0.0
			)
			_reproducir_sonido_habilidad("teletransporte")

			ejecutada = true

		# ELECTRICISTA LOCO
		"mezcla_cables":

			# Abre una puerta cercana; puede cerrar otra
			# abierta al azar (50%).
			if _mezcla_cables_efecto():

				_activar_animacion_habilidad(
					"mezclacables", 0.9, 2.0
				)
				_reproducir_sonido_habilidad("mezclacables")

				ejecutada = true

			else:

				_aviso_mezcla_sin_puerta()

		"sobrecarga":

			# Acelera un puzzle eléctrico cercano.
			if _sobrecarga_efecto():

				_activar_animacion_habilidad(
					"sobrecarga", 0.9, 3.0
				)
				_reproducir_sonido_habilidad("sobrecarga")

				ejecutada = true

			else:

				_aviso_sobrecarga_sin_objetivo()

		_:
			# Habilidades como golpe_suelo las gestiona
			# InventoryManager (confirmación y vibración
			# de salas), así que no deberían llegar aquí.
			push_warning(
				"[HABILIDAD] Sin lógica directa: " + id
			)

	if ejecutada and float(hab.cooldown) > 0.0:

		_recargas[id] = float(hab.cooldown)

	return ejecutada


func _activar_animacion_habilidad(
	nombre: String,
	duracion: float,
	temblor: float
) -> void:

	_tiempo_animacion_golpe = duracion

	if temblor > 0.0:

		sacudir_camara(temblor, duracion * 0.5)

	if anim != null and anim.sprite_frames != null:

		if anim.sprite_frames.has_animation(nombre):

			anim.play(nombre)

			_aplicar_escala_animacion(nombre)


func _reproducir_sonido_habilidad(
	nombre_archivo: String,
	duracion: float = 0.0
) -> void:
	var ga := get_tree().get_first_node_in_group(
		"gestor_audio"
	) as AudioManager
	if ga:
		ga.reproducir_habilidad(nombre_archivo, duracion)


func _activar_animacion_conducto(superficie: ObjectBase.Superficie) -> void:
	_configurar_animacion_conducto(superficie, false)


func _activar_animacion_salida_conducto(superficie: ObjectBase.Superficie) -> void:
	_configurar_animacion_conducto(superficie, true)


func _configurar_animacion_conducto(
	superficie: ObjectBase.Superficie,
	salida: bool
) -> void:
	var sufijo := "abajo"
	match superficie:
		ObjectBase.Superficie.PARED_ARRIBA:
			sufijo = "abajo" if salida else "arriba"
		ObjectBase.Superficie.PARED_ABAJO:
			sufijo = "arriba" if salida else "abajo"
		ObjectBase.Superficie.PARED_IZQUIERDA:
			sufijo = "derecha" if salida else "izquierda"
		ObjectBase.Superficie.PARED_DERECHA:
			sufijo = "izquierda" if salida else "derecha"

	var nombre := "agachar" + sufijo
	var espejar := false
	if anim == null or not anim.sprite_frames.has_animation(nombre):
		if sufijo == "derecha":
			nombre = "agacharizquierda"
			espejar = true

	if anim == null or not anim.sprite_frames.has_animation(nombre):
		return

	_flip_h_antes_habilidad = anim.flip_h
	anim.flip_h = espejar
	_restaurar_flip_h_habilidad = espejar
	_activar_animacion_habilidad(nombre, 0.8, 0.0)
	if salida:
		anim.frame = anim.sprite_frames.get_frame_count(nombre) - 1
		anim.speed_scale = -1.0
		_restaurar_speed_scale_habilidad = true


func _conducto_cercano() -> ConductoVentilacion:
	var mejor: ConductoVentilacion = null
	var distancia_minima: float = 72.0
	for nodo in get_tree().get_nodes_in_group("conductos_ventilacion"):
		var conducto := nodo as ConductoVentilacion
		if conducto == null or conducto.objeto_datos == null:
			continue
		var distancia: float = global_position.distance_to(conducto.global_position)
		if distancia <= distancia_minima:
			distancia_minima = distancia
			mejor = conducto
	return mejor


# GOLPE CON LLAVE INGLESA (EFECTO)
# Golpea la caja metálica que tenga delante y la
# desplaza varias casillas en la dirección del golpe
# (alejándose del jugador). Si no hay caja, descoloca
# las piezas del puzzle más cercano (las reinicia).

func _caja_met_alica_delante() -> MetalBox:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return null

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return null

	var objetos := sala_nodo.get_node_or_null("Objects")

	if objetos == null:

		return null

	var dir := _ultima_direccion.normalized()

	var mejor: MetalBox = null

	var mejor_dist: float = 120.0

	for hijo in objetos.get_children():

		var caja := hijo as MetalBox

		if caja == null:

			continue

		var hacia := caja.global_position - global_position

		var d: float = hacia.length()

		if d > mejor_dist:

			continue

		if d > 8.0 and dir.dot(hacia.normalized()) < -0.15:
			continue

		mejor_dist = d

		mejor = caja

	return mejor


func _desplazar_caja(caja: MetalBox) -> bool:

	var dir := _ultima_direccion.normalized()
	if dir == Vector2.ZERO:
		return false

	var desplazamiento := dir * 96.0

	# Si no cabe a 2 casillas, prueba con 1
	if not caja._puede_moverse(desplazamiento):

		desplazamiento = dir * 48.0

		if not caja._puede_moverse(desplazamiento):
			print("🔧 La caja no tiene sitio para moverse")
			return false

	var destino: Vector2 = (
		caja.global_position + desplazamiento
	)

	var tween := create_tween()

	_activar_animacion_habilidad("golpellave", 0.8, 6.0)
	_reproducir_sonido_habilidad("golpellave")
	tween.tween_property(
		caja,
		"global_position",
		destino,
		0.3
	).set_trans(Tween.TRANS_SINE)

	# Persistir la nueva posición en los datos de la sala
	if caja.objeto_datos != null:

		var datos := caja.objeto_datos

		tween.tween_callback(func():

			if is_instance_valid(caja):

				datos.posicion = caja.position
		)

	print("🔧 Golpe de llave: caja metálica desplazada")
	return true


func _hay_puzzle_descolocable() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return false

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return false

	var objetos := sala_nodo.get_node_or_null("Objects")

	if objetos != null:

		for hijo in objetos.get_children():

			var laser := hijo as LaserPuzzle

			if laser != null and global_position.distance_to(laser.global_position) <= 150.0:

				return true

			var panel := hijo as PanelElectrico
			if panel != null and global_position.distance_to(panel.global_position) <= 150.0:
				return true

	for n in get_tree().root.find_children(
		"*", "PuzzleCables", true, false
	):

		var cables := n as PuzzleCables

		if cables != null and cables.abierto:

			return true

	return false


func _desordenar_puzzle_cercano() -> void:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return

	var objetos := sala_nodo.get_node_or_null("Objects")

	if objetos != null:

		var mejor: Node = null

		var mejor_dist: float = 150.0

		for hijo in objetos.get_children():

			var laser := hijo as LaserPuzzle

			if laser == null:

				continue

			var d: float = global_position.distance_to(
				(laser as Node2D).global_position
			)

			if d < mejor_dist:

				mejor_dist = d

				mejor = laser

		for hijo in objetos.get_children():
			var panel := hijo as PanelElectrico
			if panel == null:
				continue
			var distancia_panel: float = global_position.distance_to(panel.global_position)
			if distancia_panel < mejor_dist:
				mejor_dist = distancia_panel
				mejor = panel

		if mejor != null:
			mejor.desordenar_piezas()
			print("🔧 Golpe de llave: puzzle cercano reiniciado")

			return

	for n in get_tree().root.find_children(
		"*", "PuzzleCables", true, false
	):

		var cables := n as PuzzleCables

		if cables != null and cables.abierto \
				and not cables._resuelto:

			cables.desordenar_piezas()

			print("🔧 Golpe de llave: cables del puzle descolocados")

			return


# REPARACIÓN CHAPUCERA (EFECTO)
# Repara lo "roto" más cercano: terminales sin energía
# y puertas cerradas por mecanismo. RIESGO 30%: chispa,
# la reparación falla y la puerta abierta más cercana
# queda bloqueada 10 segundos.

func _reparacion_objetivo() -> Dictionary:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return {}

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return {}

	var mejor := {}

	var mejor_dist: float = RADIO_DESCARGA

	# Terminales sin energía
	var terminales := sala_nodo.get_node_or_null(
		"Terminals"
	)

	if terminales != null:

		for hijo in terminales.get_children():

			var terminal := hijo as Terminal

			if terminal == null:

				continue

			if terminal.energia_disponible():

				continue

			var d: float = global_position.distance_to(
				terminal.global_position
			)

			if d < mejor_dist:

				mejor_dist = d

				mejor = {
					"tipo": "terminal",
					"nodo": terminal
				}

	# Puertas cerradas o bloqueadas
	var doors := sala_nodo.get_node_or_null("Doors")

	if doors != null:

		for hijo in doors.get_children():

			var puerta := hijo as Door

			if puerta == null:

				continue

			if not (puerta.cerrada or puerta.bloqueada):

				continue

			var d: float = global_position.distance_to(
				puerta.global_position
			)

			if d < mejor_dist:

				mejor_dist = d

				mejor = {
					"tipo": "puerta",
					"nodo": puerta
				}

	return mejor


func _ejecutar_reparacion(objetivo: Dictionary) -> void:

	if objetivo["tipo"] == "terminal":

		var terminal := objetivo["nodo"] as Terminal

		terminal.instalar_bateria()

		print("🔧 Reparación chapucera: terminal energizado")

		_avisar_tooltip(
			"Reparación chapucera",
			"Terminal reparado y con energía."
		)

		return

	var puerta := objetivo["nodo"] as Door

	puerta.bloqueada = false

	puerta.abrir()

	# Persistir el mecanismo con los datos de la sala
	var data_sala: RoomData = null

	var main_datos := (
		get_tree().get_first_node_in_group("main")
	)

	if main_datos != null and "room_actual" in main_datos:

		var sala_nodo_datos: Node2D = main_datos.room_actual

		if sala_nodo_datos != null \
				and sala_nodo_datos.has_meta("room_data"):

			data_sala = (
				sala_nodo_datos.get_meta("room_data") as RoomData
			)

	_persistir_mecanismo_puerta(data_sala, puerta)

	print(
		"🔧 Reparación chapucera: ",
		puerta.name, " abierta"
	)

	_avisar_tooltip(
		"Reparación chapucera",
		"Mecanismo reparado: puerta abierta."
	)


# Si la puerta es la de un mecanismo (panel de cables
# o láser), el estado persiste como resuelto.
func _persistir_mecanismo_puerta(
	data: RoomData,
	puerta: Door
) -> void:

	if data == null:

		return

	var direccion := _direccion_puerta(puerta.name)

	if data.panel_puerta == direccion:

		data.panel_resuelto = true

	if data.panel_puerta_vecina == direccion:

		data.panel_resuelto_vecina = true

	if data.laser_puerta == direccion:

		data.laser_resuelto = true

	if data.laser_puerta_vecina == direccion:

		data.laser_resuelto_vecina = true


func _fallo_reparacion() -> void:

	# CHISPA: sacudida + chispazo sonoro
	sacudir_camara(9.0, 0.5)

	var ga := (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga != null:

		ga.reproducir_efecto("apagar")

	print("⚠️ ¡Chispazo! La reparación ha fallado")

	# BLOQUEO DE PUERTA: la puerta abierta más cercana
	# se cierra 10 segundos (fallo temporal)
	var puerta := _puerta_abierta_cercana()

	if puerta == null:

		_avisar_tooltip(
			"Reparación chapucera",
			"¡Chispazo! La reparación ha fallado."
		)

		return

	puerta.cerrar()

	print("⚠️ ", puerta.name, " bloqueada 10 segundos")

	_avisar_tooltip(
		"Reparación chapucera",
		"¡Chispazo! No entiendo esos cables. " + puerta.name + " queda bloqueada 10 segundos."
	)

	var timer := get_tree().create_timer(10.0)

	timer.timeout.connect(func():

		if is_instance_valid(puerta):

			puerta.abrir()
	)


func _puerta_abierta_cercana() -> Door:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return null

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return null

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors == null:

		return null

	var mejor: Door = null

	var mejor_dist: float = 400.0

	for hijo in doors.get_children():

		var puerta := hijo as Door

		if puerta == null:

			continue

		if puerta.cerrada or puerta.bloqueada:

			continue

		if puerta.sala_destino == -1:

			continue

		var d: float = global_position.distance_to(
			puerta.global_position
		)

		if d < mejor_dist:

			mejor_dist = d

			mejor = puerta

	return mejor


func _aviso_golpe_llave_sin_objetivo() -> void:

	print("🔧 Golpe de llave: no hay cajas ni puzzles cerca.")

	_avisar_tooltip(
		"Golpe con llave inglesa",
		"No hay cajas metálicas ni puzzles cerca. Acércate a uno e inténtalo otra vez."
	)


func _aviso_reparacion_sin_objetivo() -> void:

	print("🔧 Reparación: no hay nada roto cerca.")

	_avisar_tooltip(
		"Reparación chapucera",
		"No hay terminales apagados ni puertas cerradas cerca. Acércate a lo que quieras reparar."
	)


# AVISO EN EL PANEL DEL INVENTARIO
# Muestra un mensaje en el panel de descripción de
# habilidades del inventario (delegando en su método
# _mostrar_info_habilidad, que vive en el
# InventoryManager y no en el personaje).

func _avisar_tooltip(titulo: String, texto: String) -> void:

	var inventario := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as Node
	)

	if inventario != null and inventario.has_method(
		"_mostrar_info_habilidad"
	):

		if inventario.has_method("_mostrar_info_habilidad_temporal"):
			inventario._mostrar_info_habilidad_temporal(titulo, texto)


# Alias para personajes cuyos spritesheets usan otros
# nombres para arriba/abajo (up/down).
func _alias_animacion(nombre: String) -> String:

	if anim == null or anim.sprite_frames == null:

		return ""

	if nombre == "arriba" \
			and anim.sprite_frames.has_animation("up"):

		return "up"

	if nombre == "abajo" \
			and anim.sprite_frames.has_animation("down"):

		return "down"

	return ""


# DESCARGA ELÉCTRICA (EFECTO)
# Activa los mecanismos de la sala actual: abre las
# puertas cerradas o bloqueadas (paneles, láseres,
# terminales...) y da energía a los terminales
# apagados, igual que si les instalara una batería.

func _descarga_electrica_efecto() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return false

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return false

	var data: RoomData = null

	if sala_nodo.has_meta("room_data"):

		data = sala_nodo.get_meta("room_data") as RoomData

	# PUERTAS CERRADAS POR MECANISMOS

	var abiertas := 0

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors != null:

		for hijo in doors.get_children():

			var puerta := hijo as Door

			if puerta == null:

				continue

			if not (puerta.cerrada or puerta.bloqueada):

				continue

			# Solo las puertas cercanas al robot.
			if global_position.distance_to(
					puerta.global_position
			) > RADIO_DESCARGA:

				continue

			puerta.bloqueada = false

			puerta.abrir()

			abiertas += 1

			# Si la puerta era la de un mecanismo
			# (panel de cables o láser), el estado
			# persiste como resuelto en la sala.
			_persistir_mecanismo_puerta(data, puerta)

	# TERMINALES SIN ENERGÍA

	var energizados := 0

	var terminales := sala_nodo.get_node_or_null(
		"Terminals"
	)

	if terminales != null:

		for hijo in terminales.get_children():

			var terminal := hijo as Terminal

			if terminal == null:

				continue

			if terminal.tiene_energia or terminal.resuelto:

				continue

			# Solo los terminales cercanos al robot.
			if global_position.distance_to(
					terminal.global_position
			) > RADIO_DESCARGA:

				continue

			terminal.instalar_bateria()

			energizados += 1

	if abiertas == 0 and energizados == 0:

		# Nada al alcance: la habilidad no se ejecuta
		# (no consume recarga ni animación).
		return false

	print(
		"⚡ Descarga eléctrica: ",
		abiertas, " puerta(s) abierta(s), ",
		energizados, " terminal(es) energizado(s)"
	)

	return true


# Aviso al jugador cuando no hay mecanismos cerca
# (la habilidad no se ejecuta ni consume recarga).
func _aviso_descarga_sin_objetivo() -> void:

	print(
		"⚡ Descarga eléctrica: no hay puertas cerradas",
		" ni terminales apagados cerca."
	)

	var inventario := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as Node
	)

	if inventario != null and inventario.has_method(
		"_mostrar_info_habilidad"
	):

		inventario._mostrar_info_habilidad_temporal(
			"Descarga eléctrica",
			"No hay puertas cerradas ni terminales apagados cerca. Acércate a un mecanismo e inténtalo otra vez."
		)


# MEZCLA DE CABLES (EFECTO)
# Abre la puerta cerrada más cercana al electricista.
# RIESGO 50%: otra puerta abierta de la sala se cierra
# al azar. Es un apaño eléctrico: no marca el mecanismo
# como resuelto (al reconstruir la sala, una puerta
# abierta así vuelve a su estado original).

func _mezcla_cables_efecto() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return false

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return false

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors == null:

		return false

	var cerradas: Array = []

	for hijo in doors.get_children():

		var puerta := hijo as Door

		if puerta == null:

			continue

		if global_position.distance_to(
				puerta.global_position
		) > RADIO_DESCARGA:

			continue

		if puerta.cerrada or puerta.bloqueada:

			cerradas.append(puerta)

		elif puerta.sala_destino != -1:
			continue

	if cerradas.is_empty():

		return false

	# Abre la puerta cerrada más cercana.
	var objetivo: Door = null

	var mejor_dist: float = INF

	for puerta in cerradas:

		var d: float = global_position.distance_to(
			puerta.global_position
		)

		if d < mejor_dist:

			mejor_dist = d

			objetivo = puerta

	if objetivo == null:

		return false

	objetivo.bloqueada = false

	objetivo.abrir()

	print(
		"🔌 Mezcla de cables: ", objetivo.name, " abierta"
	)

	return true


func _aviso_mezcla_sin_puerta() -> void:

	print(
		"🔌 Mezcla de cables: no hay puertas cerradas cerca."
	)

	var inventario := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as Node
	)

	if inventario != null and inventario.has_method(
		"_mostrar_info_habilidad"
	):

		inventario._mostrar_info_habilidad_temporal(
			"Mezcla de cables",
			"No hay puertas cerradas cerca. Acércate a una puerta bloqueada e inténtalo otra vez."
		)


# SOBRECARGA (EFECTO)
# Acelera un puzzle eléctrico cercano: el panel de
# cables se abre con la mitad de los cables ya
# conectados, y el terminal numérico se abre con parte
# de la respuesta escrita. (Ralentizar a otros
# jugadores llegará con el multijugador.)

func _sobrecarga_efecto() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "room_actual" in main:

		return false

	var sala_nodo: Node2D = main.room_actual

	if sala_nodo == null:

		return false

	var mejor: Node = null

	var mejor_dist: float = RADIO_DESCARGA

	# Terminales encendidos y sin resolver.
	var terminales := sala_nodo.get_node_or_null(
		"Terminals"
	)

	if terminales != null:

		for hijo in terminales.get_children():

			var terminal := hijo as Terminal

			if terminal == null:

				continue

			if terminal.resuelto or terminal.sobrecargado:

				continue

			if not terminal.energia_disponible():

				continue

			var d: float = global_position.distance_to(
				terminal.global_position
			)

			if d < mejor_dist:

				mejor_dist = d

				mejor = terminal

	# Paneles de cables sin resolver.
	var objetos := sala_nodo.get_node_or_null("Objects")

	if objetos != null:

		for hijo in objetos.get_children():

			var panel := hijo as PanelElectrico

			if panel == null:

				continue

			if panel.resuelto or panel.sobrecargado:

				continue

			var d: float = global_position.distance_to(
				panel.global_position
			)

			if d < mejor_dist:

				mejor_dist = d

				mejor = panel

	if mejor == null:

		return false

	if mejor is Terminal:

		(mejor as Terminal).sobrecargar()

	elif mejor is PanelElectrico:
		var panel := mejor as PanelElectrico
		if panel.resuelto or panel.sobrecargado:
			return false
		panel.sobrecargar()
		var gestor_interaccion := get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
		if gestor_interaccion != null:
			gestor_interaccion.establecer_activo(true)
			gestor_interaccion.refrescar_para_jugador(self)
			panel._jugador_entra(self)
			gestor_interaccion.registrar_objeto(panel)

	print("⚡ Sobrecarga aplicada a ", mejor.name)

	return true


func _aviso_sobrecarga_sin_objetivo() -> void:

	print(
		"⚡ Sobrecarga: no hay puzzles eléctricos ni",
		" terminales encendidos cerca."
	)

	var inventario := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as Node
	)

	if inventario != null and inventario.has_method(
		"_mostrar_info_habilidad"
	):

		inventario._mostrar_info_habilidad_temporal(
			"Sobrecarga",
			"No hay paneles de cables ni terminales encendidos cerca. Acércate a uno e inténtalo otra vez."
		)


# "PuertaDerecha" → "derecha" ("" si no encaja).
func _direccion_puerta(nombre: String) -> String:

	var texto := nombre.to_lower().trim_prefix("puerta")

	if texto in ["arriba", "abajo", "izquierda", "derecha"]:

		return texto

	return ""


# CORTOCIRCUITO (EFECTO)
# Apaga la sala actual 100 segundos: todo se ve negro
# salvo un círculo de luz alrededor del robot. Además
# tiene un 25% de riesgo de apagarse él mismo y no
# poder moverse durante 30 segundos.

func _cortocircuito_efecto() -> void:

	var main := get_tree().get_first_node_in_group("main")

	if main != null and main.has_method(
		"activar_apagon_sala_actual"
	):

		main.activar_apagon_sala_actual(100.0)

	var sala_nodo := main.room_actual as Node2D
	if sala_nodo != null:
		var puertas := sala_nodo.get_node_or_null("Doors")
		if puertas != null:
			for hijo in puertas.get_children():
				var puerta := hijo as Door
				if puerta != null and not puerta.cerrada:
					puerta.cerrar()

	# RIESGO: 25% de que el robot se apague él mismo.
	if randf() < 0.25:

		_apagarse(30.0)


# El robot se queda apagado y sin moverse.
func _apagarse(duracion: float) -> void:

	_tiempo_apagado = duracion

	if anim != null and anim.sprite_frames != null \
			and anim.sprite_frames.has_animation("apagarse"):

		anim.play("apagarse")

		_aplicar_escala_animacion("apagarse")

	# Sonido de apagado (apagar.mp3 del AudioManager).
	var ga := (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga != null and ga.has_method("reproducir_efecto"):

		ga.reproducir_efecto("apagar")

	print(
		"🤖 ¡El robot se ha apagado! Sin moverse durante ",
		duracion, " segundos."
	)

	_avisar_tooltip(
		"Cortocircuito",
		"¡Te has apagado! El robot no puede moverse durante %.0f segundos." % duracion
	)


# RECARGA INSTANTÁNEA CON BATERÍA
# La llama Bateria.gd al recoger una batería: la
# descarga eléctrica se recarga al instante. Devuelve
# false si la habilidad ya está lista (no hay nada que
# recargar).

func recargar_descarga_bateria() -> bool:

	if _hab_por_id("descarga_electrica") == null:

		return false

	if not en_recarga("descarga_electrica"):

		return false

	_recargas["descarga_electrica"] = 0.0

	return true


# Enciende / apaga la luz del apagón (lo gestiona Main).
func establecer_apagon(activo: bool) -> void:

	if _luz_apagon != null:

		_luz_apagon.enabled = activo


func reactivar_control_si_corresponde() -> void:
	if _tiempo_apagado <= 0.0:
		velocity = Vector2.ZERO
		direccion_tactil = Vector2.ZERO
		movimiento_bloqueado = false


# Textura radial para la luz del apagón (círculo suave
# y cálido alrededor del robot).
func _crear_textura_luz() -> GradientTexture2D:

	var gradiente := Gradient.new()

	gradiente.colors = PackedColorArray([
		Color(1.0, 0.97, 0.85, 1.0),
		Color(1.0, 0.95, 0.8, 0.35),
		Color(1.0, 0.95, 0.8, 0.0)
	])

	# Caída rápida: núcleo corto y oscuro pronto, para
	# que no se illumine media sala.
	gradiente.offsets = PackedFloat32Array([
		0.0, 0.35, 0.85
	])

	var textura := GradientTexture2D.new()

	textura.gradient = gradiente

	textura.fill = GradientTexture2D.FILL_RADIAL

	textura.fill_from = Vector2(0.5, 0.5)

	textura.fill_to = Vector2(0.5, 0.0)

	textura.width = 256

	textura.height = 256

	return textura


# TELETRANSPORTE (CIENTÍFICO TELEPORTADOR)
# Las dos habilidades necesitan elegir sala destino
# desde un selector del inventario. El selector llama
# a puede_usar_habilidad antes de abrirse y a estos
# métodos cuando el jugador confirma.

func puede_usar_habilidad(id: String) -> bool:

	if movimiento_bloqueado or _tiempo_apagado > 0.0:

		return false

	var hab := _hab_por_id(id)

	if hab == null or hab.es_pasiva or en_recarga(id):

		return false

	return true


func consumir_recarga_habilidad(id: String) -> bool:

	if not puede_usar_habilidad(id):

		return false

	var hab := _hab_por_id(id)

	if float(hab.cooldown) > 0.0:

		_recargas[id] = float(hab.cooldown)

	return true


func recuperar_habilidades() -> void:
	_recargas.clear()
	print("[Habilidades] Todas las habilidades están disponibles de nuevo")


func habilidades_en_recarga() -> Array[String]:
	var resultado: Array[String] = []
	for id in _recargas:
		if float(_recargas[id]) > 0.0:
			resultado.append(String(id))
	return resultado


func reactivar_habilidad(id: String, segundos: float, completa: bool = false) -> bool:
	if not _recargas.has(id) or float(_recargas[id]) <= 0.0:
		return false
	if completa:
		_recargas[id] = 0.0
	else:
		_recargas[id] = maxf(0.0, float(_recargas[id]) - segundos)
	return true


# Mini-teletransporte: se teletransporta a la sala
# adyacente elegida, apareciendo junto a la puerta de
# entrada (misma posición que al cruzar la puerta).
func teleportar_a_sala(
	indice: int,
	direccion: String
) -> bool:

	if not consumir_recarga_habilidad("mini_teletransporte"):

		return false

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not main.has_method(
		"teletransportar_jugador"
	):

		return false

	_activar_animacion_habilidad("teleport", 0.6, 0.0)
	_reproducir_sonido_habilidad("teletransporte")

	main.teletransportar_jugador(indice, direccion)

	return true


# Teletransporte de objeto: envía un objeto del
# inventario a la sala adyacente elegida.
func teletransportar_objeto_a_sala(
	nombre_datos: String,
	descripcion: String,
	indice: int,
	direccion: String,
	textura: Texture2D
) -> bool:

	if not consumir_recarga_habilidad("teletransporte_objeto"):

		return false

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not main.has_method(
		"teletransportar_objeto"
	):

		return false

	_activar_animacion_habilidad("teleobject", 0.8, 0.0)
	_reproducir_sonido_habilidad("teletransporte")

	main.teletransportar_objeto(
		nombre_datos, descripcion, indice, direccion, textura
	)

	return true
