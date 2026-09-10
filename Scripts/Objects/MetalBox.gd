extends InteractableObject

class_name MetalBox

const RADIO_INTERACCION := 54.0
const DISTANCIA_EMPUJE := 3.0
const INTERVALO_EMPUJE := 0.08
const DISTANCIA_JUGADOR_CAJA := 30.0
const MARGEN_SUPERFICIE := 14.0
const DISTANCIA_JUGADOR_CAJA_DESDE_ARRIBA := 24.0

var _jugador: Character = null
var _tiempo_para_empujar: float = 0.0
var _empujando: bool = false
var _direccion_animacion: Vector2 = Vector2.LEFT
var _desplazamiento_jugador: Vector2 = Vector2.ZERO
var _empuje_horizontal: bool = false
var _forma_caja: Shape2D = null
var _cuerpo_caja: CollisionObject2D = null
var _offset_caja: Vector2 = Vector2.ZERO
var objeto_datos: ObjectData = null


func _ready() -> void:
	var area := Area2D.new()
	area.name = "InteractionArea"
	var collision := CollisionShape2D.new()
	var forma := CircleShape2D.new()
	forma.radius = RADIO_INTERACCION
	collision.shape = forma
	area.add_child(collision)
	add_child(area)
	interaction_area = area
	area.body_entered.connect(_al_entrar_jugador)
	area.body_exited.connect(_al_salir_jugador)
	object_id = "cajametal"
	super._ready()
	_inicializar_fisica_caja()


func puede_interactuar_con_jugador(personaje: Character) -> bool:
	return personaje != null and personaje.es_forzudo


# FÍSICA DE LA CAJA
# Carga la colisión de la caja (MetalBoxCollision) para
# poder saber si puede moverse. Sin esto la caja no se
# entera de las paredes y las atraviesa al empujarla.

func _inicializar_fisica_caja() -> void:
	# La colisión se monta desde ObjectGenerator como hijo de
	# MetalBoxCollision. Como ese CollisionShape2D se crea con
	# nombre autogenerado (@CollisionShape2D@xxx), no podemos
	# localizarlo por ruta: lo buscamos como primer hijo.
	var fisica := get_node_or_null(
		"MetalBoxCollision"
	) as CollisionObject2D
	if fisica == null or fisica.get_child_count() == 0:
		# Sin colisión cargada la caja no se mueve (no atraviesa muros).
		return
	var colision: CollisionShape2D = null
	for hijo in fisica.get_children():
		if hijo is CollisionShape2D:
			colision = hijo as CollisionShape2D
			break
	if colision == null:
		return
	_forma_caja = colision.shape
	_cuerpo_caja = fisica
	_offset_caja = Vector2.ZERO
	if _cuerpo_caja != null:
		_cuerpo_caja.collision_layer = 1
		_cuerpo_caja.collision_mask = 1


func _physics_process(delta: float) -> void:
	_tiempo_para_empujar = max(0.0, _tiempo_para_empujar - delta)
	if not _empujando:
		return
	if _jugador == null or not is_instance_valid(_jugador):
		_jugador = null
		_empujando = false
		return
	if not _jugador.tiene_habilidad_forzudo():
		_empujando = false
		return
	if _tiempo_para_empujar > 0.0:
		return

	var direccion: Vector2 = _obtener_direccion_empuje()
	if direccion.length_squared() < 0.01:
		if _jugador.has_method("pausar_animacion_empujar"):
			_jugador.pausar_animacion_empujar()
		return
	var desplazamiento := direccion * DISTANCIA_EMPUJE
	if not _puede_moverse(desplazamiento):
		return
	global_position += desplazamiento
	_jugador.global_position = global_position + _desplazamiento_jugador
	_tiempo_para_empujar = INTERVALO_EMPUJE
	var gestor_audio := get_tree().get_first_node_in_group("gestor_audio")
	if gestor_audio != null:
		gestor_audio.reproducir_efecto_corto(
			"arrastrarcaja",
			0.22,
			-4.0
		)
	if _jugador.has_method("activar_animacion_empujar"):
		_jugador.activar_animacion_empujar(_direccion_animacion)
	if objeto_datos != null:
		objeto_datos.posicion = position


func _al_entrar_jugador(body: Node2D) -> void:
	if body is Character \
			and interaction_manager != null \
			and interaction_manager.jugador == body:
		_jugador = body as Character


func interactuar() -> void:
	if interaction_manager != null:
		var jugador_activo := interaction_manager.jugador
		if jugador_activo != null \
				and jugador_activo.es_forzudo \
				and global_position.distance_to(
					jugador_activo.global_position
				) <= RADIO_INTERACCION:
			_jugador = jugador_activo
	if _jugador == null or not _jugador.tiene_habilidad_forzudo():
		return
	_empujando = not _empujando
	_tiempo_para_empujar = 0.0
	if _empujando:
		var diferencia: Vector2 = _jugador.global_position - global_position
		_empuje_horizontal = abs(diferencia.x) > abs(diferencia.y)
		if _empuje_horizontal:
			_direccion_animacion = Vector2.RIGHT if diferencia.x < 0.0 else Vector2.LEFT
			var distancia_x: float = _distancia_superficie(Vector2.RIGHT)
			var offset_jugador_x: float = _obtener_offset_collider_jugador().x
			var mitad_jugador_x: float = _obtener_mitad_collider_jugador(true)
			_desplazamiento_jugador = Vector2(
				-distancia_x - offset_jugador_x - mitad_jugador_x if diferencia.x < 0.0 else distancia_x + mitad_jugador_x - offset_jugador_x,
				diferencia.y
			)
		else:
			_direccion_animacion = Vector2.DOWN if diferencia.y < 0.0 else Vector2.UP
			var distancia_y: float = _distancia_superficie(Vector2.DOWN)
			var offset_jugador_y: float = _obtener_offset_collider_jugador().y
			var mitad_jugador_y: float = _obtener_mitad_collider_jugador(false)
			var distancia_arriba: float = DISTANCIA_JUGADOR_CAJA_DESDE_ARRIBA
			if diferencia.y < 0.0:
				distancia_y = distancia_arriba
			_desplazamiento_jugador = Vector2(
				diferencia.x,
				-distancia_y if diferencia.y < 0.0 else distancia_y + mitad_jugador_y - offset_jugador_y
			)
		_jugador.global_position = global_position + _desplazamiento_jugador
		if _jugador.has_method("configurar_eje_empuje"):
			_jugador.configurar_eje_empuje(_empuje_horizontal)
		if _jugador.has_method("activar_animacion_empujar"):
			_jugador.activar_animacion_empujar(_direccion_animacion)
		if _jugador.has_method("pausar_animacion_empujar"):
			_jugador.pausar_animacion_empujar()
	else:
		if _jugador.has_method("dejar_de_empujar"):
			_jugador.dejar_de_empujar()
		if _jugador.has_method("configurar_eje_empuje"):
			_jugador.configurar_eje_empuje(false)
	if interaction_manager != null:
		interaction_manager.refrescar_prompt()


func _distancia_superficie(direccion: Vector2) -> float:
	var distancia: float = DISTANCIA_JUGADOR_CAJA
	if _forma_caja is RectangleShape2D:
		var tamano: Vector2 = (_forma_caja as RectangleShape2D).size
		var mitad: float = tamano.x / 2.0 if abs(direccion.x) > 0.0 else tamano.y / 2.0
		distancia = mitad + MARGEN_SUPERFICIE
	return distancia


func _obtener_offset_collider_jugador() -> Vector2:
	if _jugador == null:
		return Vector2.ZERO
	var colision := _jugador.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision == null:
		return Vector2.ZERO
	return colision.position


func _obtener_mitad_collider_jugador(horizontal: bool) -> float:
	if _jugador == null:
		return 0.0
	var colision := _jugador.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision == null or colision.shape == null:
		return 0.0
	if colision.shape is RectangleShape2D:
		var tamano: Vector2 = (colision.shape as RectangleShape2D).size
		return tamano.x / 2.0 if horizontal else tamano.y / 2.0
	return 0.0


func _obtener_direccion_empuje() -> Vector2:
	var direccion: Vector2 = Vector2.ZERO
	if _empuje_horizontal:
		if Input.is_key_pressed(KEY_A):
			direccion.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			direccion.x += 1.0
	else:
		if Input.is_key_pressed(KEY_W):
			direccion.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			direccion.y += 1.0
	if direccion == Vector2.ZERO and _jugador.direccion_tactil != Vector2.ZERO:
		direccion = _jugador.direccion_tactil
		if _empuje_horizontal:
			direccion.y = 0.0
		else:
			direccion.x = 0.0
	if direccion == Vector2.ZERO:
		return Vector2.ZERO
	if abs(direccion.x) > abs(direccion.y):
		return Vector2.LEFT if direccion.x < 0.0 else Vector2.RIGHT
	return Vector2.UP if direccion.y < 0.0 else Vector2.DOWN


func _puede_moverse(desplazamiento: Vector2) -> bool:
	# Seguridad: sin colisión cargada la caja NO se mueve.
	# Devolver true aquí permite atravesar las paredes.
	if _forma_caja == null:
		return false
	if not _dentro_de_la_sala(desplazamiento):
		return false
	# Comprobamos la ruta por pasos con intersect_shape excluyendo al
	# propio cuerpo y al jugador (que al empujar va pegado a la caja
	# y no debe ser tratado como obstáculo).
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = _forma_caja
	consulta.collision_mask = 0xFFFFFFFF
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = true
	var exclusiones: Array[RID] = []
	if _cuerpo_caja != null:
		exclusiones.append(_cuerpo_caja.get_rid())
	var fisica_caja := get_node_or_null(
		"MetalBoxCollision"
	) as CollisionObject2D
	if fisica_caja != null:
		exclusiones.append(fisica_caja.get_rid())
	if _jugador != null:
		exclusiones.append(_jugador.get_rid())
	if interaction_area != null:
		exclusiones.append(interaction_area.get_rid())
	consulta.exclude = exclusiones
	for paso in range(1, 5):
		consulta.transform = Transform2D(
			0.0,
			global_position + _offset_caja + desplazamiento * (float(paso) / 4.0)
		)
		if not get_world_2d().direct_space_state.intersect_shape(
			consulta,
			1
		).is_empty():
			return false
	return true


func _dentro_de_la_sala(desplazamiento: Vector2) -> bool:
	var contenedor := get_parent()
	if contenedor == null:
		return true
	var sala := contenedor.get_parent()
	if sala == null or not sala.has_meta("room_data"):
		return true
	var datos := sala.get_meta("room_data") as RoomData
	if datos == null or not (_forma_caja is RectangleShape2D):
		return true
	var tamano: Vector2 = (_forma_caja as RectangleShape2D).size
	var posicion_local: Vector2 = contenedor.to_local(global_position + desplazamiento)
	var margen_x: float = tamano.x / 2.0 + 4.0
	var margen_y: float = tamano.y / 2.0 + 4.0
	return (
		posicion_local.x >= datos.tam_celda + margen_x
		and posicion_local.x <= (datos.ancho + 1.0) * datos.tam_celda - margen_x
		and posicion_local.y >= datos.tam_celda + margen_y
		and posicion_local.y <= (datos.alto + 1.0) * datos.tam_celda - margen_y
	)


func _al_salir_jugador(body: Node2D) -> void:
	if body == _jugador:
		if _empujando:
			return
		_jugador = null
		_desplazamiento_jugador = Vector2.ZERO


func obtener_texto_prompt() -> String:
	return "Dejar de empujar" if _empujando else "Empujar caja"
