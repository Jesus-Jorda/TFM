extends InteractableObject

class_name LaserPuzzle


# PUZLE DE LÁSERES — SISTEMA REUTILIZABLE
# Genera un emisor, un receptor y N espejos (LaserMirror)
# en las posiciones configuradas. Cada espejo es un objeto
# interactuable independiente con su propio InteractionArea.
# El haz sale del emisor, recorre los espejos en orden y
# calcula cada rebote mediante reflexión vectorial real
# (ángulo de incidencia = ángulo de reflexión). Al llegar
# al receptor el mecanismo se activa.
# Para añadir más espejos: agrégalos a POSICIONES_ESPEJOS.

# Sprites del puesto de láser
const TEXTURA_EMISOR: Texture2D = preload(
	"res://Assets/Objects/Computers/laseremisor.png"
)
const TEXTURA_RECEPTOR: Texture2D = preload(
	"res://Assets/Objects/Computers/laserreceptor.png"
)

const ESCALA_EMISOR := 0.20
const ESCALA_RECEPTOR := 0.20

const COLOR_HAZ := Color(0.95, 0.15, 0.15)

# Escala del circuito para dejar hueco entre espejos y obstáculos.
const ESCALA_CIRCUITO := 1.20

# Posiciones LOCALES de cada espejo (en orden de rebote).
# El primer espejo de la lista es el primero que golpea el
# haz al salir del emisor.
const FORMAS_PUZZLE := [
	{
		"emisor": Vector2(110, -80),
		"espejos": [Vector2(40, -80), Vector2(40, 70)],
		"receptor": Vector2(-110, 70),
		"orientaciones": [1, 2]
	},
	{
		"emisor": Vector2(110, -70),
		"espejos": [Vector2(50, -70), Vector2(50, 20), Vector2(-50, 20)],
		"receptor": Vector2(-50, 125),
		"orientaciones": [2, 1, 3]
	},
	{
		"emisor": Vector2(110, -80),
		"espejos": [Vector2(40, -80), Vector2(40, 10), Vector2(-35, 10), Vector2(-35, 85)],
		"receptor": Vector2(-110, 70),
		"orientaciones": [1, 2, 1, 3]
	},
	{
		"emisor": Vector2(110, 75),
		"espejos": [Vector2(20, 75), Vector2(20, -50), Vector2(-70, -50)],
		"receptor": Vector2(-70, 75),
		"orientaciones": [1, 3, 2]
	},
	{
		"emisor": Vector2(110, 70),
		"espejos": [Vector2(30, 70), Vector2(30, -65), Vector2(-50, -65), Vector2(-50, 15)],
		"receptor": Vector2(-110, 15),
		"orientaciones": [1, 0, 2, 1]
	}
]

var emisor_pos := Vector2.ZERO
var receptor_pos := Vector2.ZERO
var posiciones_espejos: Array[Vector2] = []
var orientaciones_espejos: Array[int] = []
var _rng := RandomNumberGenerator.new()

# Posición del emisor (dispara hacia la +x) y del receptor
const RADIO_RECEPTOR := 24.0

# Longitud (media barra) de cada espejo para la física
const LONGITUD_ESPEJO := 18.0

# Zona por la que puede viajar el haz
var _zona := Rect2(Vector2(-150, -120), Vector2(280, 300))

var _max_pasos := 1200


# DATOS Y ESTADO

var objeto_datos: ObjectData = null

var datos_sala: RoomData = null

var sala_nodo: Node2D = null

# Puerta cerrada por mecanismo que este puzzle abre
var direccion_puerta: String = ""

var resuelto: bool = false
var emisor_encendido: bool = false
var laboratorio_datos: LaboratoryData = null

# Espejos creados (cada uno es un LaserMirror)
var _nodos_espejos: Array[LaserMirror] = []

var _receptor_sprite: Sprite2D = null
var _emisor_sprite: Sprite2D = null

var _beam: Line2D = null

# Cajas de metal de la sala: si el haz choca con una, se corta.
var _cajas_corte: Array[MetalBox] = []

# Refresco del haz mientras el emisor está encendido (para
# seguir los movimientos de la caja de metal).
var _timer_retrazado: float = 0.0
# READY

func _ready() -> void:
	# El puzzle queda sobre el suelo, pero por debajo del personaje.
	z_index = 0
	if datos_sala != null:
		resuelto = datos_sala.laser_resuelto
		emisor_encendido = datos_sala.laser_emisor_encendido

	_rng.randomize()
	var indice_forma: int = -1
	if datos_sala != null:
		indice_forma = datos_sala.laser_forma_indice
	if indice_forma < 0 or indice_forma >= FORMAS_PUZZLE.size():
		indice_forma = _rng.randi_range(0, FORMAS_PUZZLE.size() - 1)
		if datos_sala != null:
			datos_sala.laser_forma_indice = indice_forma

	var forma: Dictionary = FORMAS_PUZZLE[indice_forma]
	emisor_pos = forma["emisor"] * ESCALA_CIRCUITO
	receptor_pos = forma["receptor"] * ESCALA_CIRCUITO
	posiciones_espejos.clear()
	for posicion in forma["espejos"]:
		posiciones_espejos.append(Vector2(posicion) * ESCALA_CIRCUITO)
	orientaciones_espejos.clear()
	if datos_sala != null and datos_sala.laser_orientaciones.size() == forma["orientaciones"].size():
		for orientacion in datos_sala.laser_orientaciones:
			orientaciones_espejos.append(int(orientacion))
	else:
		for orientacion in forma["orientaciones"]:
			orientaciones_espejos.append(int(orientacion))
		if datos_sala != null:
			datos_sala.laser_orientaciones = orientaciones_espejos.duplicate()

	# EMISOR (a la derecha del primer espejo, dispara hacia la -x)

	var emisor := Sprite2D.new()
	_emisor_sprite = emisor

	emisor.texture = TEXTURA_EMISOR

	emisor.scale = Vector2.ONE * ESCALA_EMISOR

	emisor.position = emisor_pos
	emisor.z_index = 1

	add_child(emisor)

	var area := Area2D.new()
	area.name = "InteractionArea"
	var area_collision := CollisionShape2D.new()
	var area_shape := CircleShape2D.new()
	area_shape.radius = 34.0
	area_collision.shape = area_shape
	area.position = emisor_pos
	area.add_child(area_collision)
	add_child(area)
	interaction_area = area
	object_id = "emisor_laser"
	_actualizar_emisor()

	_anadir_cuerpo(Vector2(52, 60), emisor_pos)


	# RECEPTOR (objetivo, abajo a la derecha)

	_receptor_sprite = Sprite2D.new()

	_receptor_sprite.texture = TEXTURA_RECEPTOR

	_receptor_sprite.scale = Vector2.ONE * ESCALA_RECEPTOR

	_receptor_sprite.position = receptor_pos
	_receptor_sprite.z_index = 1

	add_child(_receptor_sprite)

	_anadir_cuerpo(Vector2(50, 60), receptor_pos)


	# HAZ (se dibuja en el suelo de la sala)

	_beam = Line2D.new()

	_beam.width = 4.0

	_beam.default_color = COLOR_HAZ

	_beam.joint_mode = Line2D.LINE_JOINT_ROUND

	_beam.begin_cap_mode = Line2D.LINE_CAP_ROUND

	_beam.end_cap_mode = Line2D.LINE_CAP_ROUND

	_beam.z_index = 0

	add_child(_beam)


	# ESPEJOS (cada uno un LaserMirror independiente)

	_nodos_espejos.clear()

	for indice in posiciones_espejos.size():

		_crear_espejo(
			posiciones_espejos[indice],
			orientaciones_espejos[indice]
		)
		# Los espejos siguen siendo interactuables después de resolver
		# el puzzle: otro jugador puede girarlos y cerrar la puerta.
		_nodos_espejos[indice].activo = true

	super._ready()
	_localizar_cajas_corte()
	_retrazar()


# CAJAS DE METAL QUE CORTAN EL HAZ
# Busca las cajas de metal de la sala (hermanas en Objects).
# Si el haz llega a tocar una, se corta ahí (no la atraviesa).

func _localizar_cajas_corte() -> void:

	_cajas_corte.clear()

	var contenedor := get_parent()

	if contenedor == null:
		return

	for hijo in contenedor.get_children():

		if hijo is MetalBox:

			_cajas_corte.append(hijo as MetalBox)


# REFRESCO DEL HAZ (SIGUE A LA CAJA DE METAL)
# Mientras el emisor está encendido, el haz debe recalcularse
# de vez en cuando para que, si el forzudo mueve la caja de
# metal, el corte aparezca o desaparezca en vivo.

func _physics_process(delta: float) -> void:

	if not emisor_encendido:
		return

	_timer_retrazado -= delta

	if _timer_retrazado > 0.0:
		return

	_timer_retrazado = 0.1

	_localizar_cajas_corte()

	_retrazar()


# CREAR UN ESPEJO (LaserMirror reutilizable)
# Crea un LaserMirror en la posición local dada, con su
# propia InteractionArea y colisión, y lo conecta para
# que al girar recalcule el haz.

func _crear_espejo(pos: Vector2, orientacion_inicial: int) -> void:

	var espejo := LaserMirror.new()

	espejo.name = "LaserMirror"

	espejo.position = pos
	espejo.orient = orientacion_inicial

	espejo.rotado.connect(_espejo_rotado)

	add_child(espejo)

	_nodos_espejos.append(espejo)


func _espejo_rotado() -> void:
	_guardar_orientaciones()
	_retrazar()


# AÑADIR CUERPO FÍSICO A LOS OBJETOS DEL PUZLE
# La mesa, el emisor y el receptor bloquean al jugador.
# El haz (Line2D) NO tiene colisión.

func _anadir_cuerpo(tamano: Vector2, pos: Vector2) -> void:

	var cuerpo := StaticBody2D.new()

	cuerpo.name = "ColisionPuzzle"

	var colision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	forma.size = tamano

	colision.shape = forma

	cuerpo.add_child(colision)

	cuerpo.position = pos

	add_child(cuerpo)


# REFLEXIÓN VECTORIAL EN UN ESPEJO
# d' = d - 2*(d·n)*n  siendo n la normal de la superficie
# del espejo. Así el rayo rebota respetando la ley
# ángulo de incidencia = ángulo de reflexión, teniendo
# en cuenta por dónde llega el rayo al espejo.

func _dir_tras_espejo(dir: Vector2, espejo: LaserMirror) -> Vector2:

	var n := _normal_de_espejo(dir, espejo)

	return (dir - 2.0 * dir.dot(n) * n).normalized()


# NORMAL ORIENTADA SEGÚN EL LADO DE INCIDENCIA
# Toma la normal base del espejo y la orienta para que
# apunte al lado del que viene el rayo. Así la reflexión
# es correcta venga el rayo de donde venga.

func _normal_de_espejo(dir: Vector2, espejo: LaserMirror) -> Vector2:

	var base := espejo.obtener_normal()

	# Si la normal apunta en contra del rayo, girarla
	if base.dot(dir) < 0.0:
		base = -base

	return base.normalized()


# SEGMENTO (A, B) DE UN ESPEJO EN COORDENADAS LOCALES

func _segmento_espejo(indice: int) -> Array:

	var espejo: LaserMirror = _nodos_espejos[indice]

	var centro: Vector2 = espejo.position

	var media: Vector2 = espejo.obtener_direccion_segmento() * LONGITUD_ESPEJO

	return [centro - media, centro + media]


# INTERSECCIÓN RAYO ↔ SEGMENTO
# Devuelve t>=0 del rayo (o + t*d) o INF si no corta.

func _interseccion_segmento(
	o: Vector2,
	d: Vector2,
	a: Vector2,
	b: Vector2
) -> float:

	var e := b - a

	var denom := d.cross(e)

	if absf(denom) < 0.00001:
		return INF

	var ao := a - o

	var t := ao.cross(e) / denom

	var s := ao.cross(d) / denom

	if t >= 0.0 and s >= -0.0001 and s <= 1.0001:
		return t

	return INF


# INTERSECCIÓN RAYO ↔ CÍRCULO (receptor)

func _interseccion_circulo(
	o: Vector2,
	d: Vector2,
	centro: Vector2,
	radio: float
) -> float:

	var v := centro - o

	var proy := v.dot(d)

	if proy < 0.0:
		return INF

	var perp2 := v.length_squared() - proy * proy

	if perp2 > radio * radio:
		return INF

	var t := proy - sqrt(radio * radio - perp2)

	if t < 0.0:
		t = 0.0

	return t


# INTERSECCIÓN RAYO ↔ SALIDA DE LA ZONA

func _interseccion_zona(o: Vector2, d: Vector2) -> float:

	var t_mejor := INF

	if d.x > 0.0:
		t_mejor = minf(t_mejor, (_zona.end.x - o.x) / d.x)
	elif d.x < 0.0:
		t_mejor = minf(t_mejor, (_zona.position.x - o.x) / d.x)

	if d.y > 0.0:
		t_mejor = minf(t_mejor, (_zona.end.y - o.y) / d.y)
	elif d.y < 0.0:
		t_mejor = minf(t_mejor, (_zona.position.y - o.y) / d.y)

	return t_mejor


# INTERSECCIÓN RAYO ↔ CAJAS DE METAL (corte del haz)
# Devuelve la distancia al corte más cercano entre el rayo y
# cualquiera de las cajas de metal de la sala (INF si ninguna).

func _interseccion_cajas(
	o: Vector2,
	d: Vector2
) -> float:

	var t_mejor := INF

	for caja_c in _cajas_corte:

		if caja_c == null or not is_instance_valid(caja_c):
			continue

		var forma_c: Shape2D = caja_c.get("_forma_caja")

		if forma_c == null or not (forma_c is RectangleShape2D):
			continue

		var t_caja := _interseccion_rect(
			o,
			d,
			to_local(caja_c.global_position),
			(forma_c as RectangleShape2D).size
		)

		if t_caja < t_mejor:
			t_mejor = t_caja

	return t_mejor


# INTERSECCIÓN RAYO ↔ RECTÁNGULO (slab)
# Devuelve t>=0 del rayo (o + t*d) que entra al rectángulo
# axis-aligned centrado en `centro` con tamaño `tamano`,
# o INF si no lo corta.

func _interseccion_rect(
	o: Vector2,
	d: Vector2,
	centro: Vector2,
	tamano: Vector2
) -> float:

	var mitad := tamano * 0.5

	var minimo := centro - mitad

	var maximo := centro + mitad

	var t_near := -INF

	var t_far := INF

	for eje in 2:

		var o_eje: float = o[eje]

		var d_eje: float = d[eje]

		var min_eje: float = minimo[eje]

		var max_eje: float = maximo[eje]

		if absf(d_eje) < 0.00001:

			if o_eje < min_eje or o_eje > max_eje:
				return INF

		else:

			var t1 := (min_eje - o_eje) / d_eje

			var t2 := (max_eje - o_eje) / d_eje

			if t1 > t2:

				var tmp := t1

				t1 = t2

				t2 = tmp

			t_near = maxf(t_near, t1)

			t_far = minf(t_far, t2)

			if t_near > t_far:
				return INF

	if t_far < 0.0:
		return INF

	return maxf(t_near, 0.0)


# TRAZAR EL HAZ (recorre los espejos dinámicamente)
# El rayo sale del emisor. En cada tramo busca el espejo
# más cercano en su trayectoria, calcula la reflexión con
# la normal de ese espejo y continúa. Soporta cualquier
# número de espejos en cadena.

func _retrazar() -> void:

	if _beam == null:
		return

	_beam.clear_points()

	_receptor_sprite.modulate = Color.WHITE

	if not emisor_encendido:
		_invalidar_solucion()
		return

	var alcanzado := false

	var pos: Vector2 = emisor_pos

	var dir: Vector2 = Vector2(-1, 0)

	var puntos := PackedVector2Array([pos])

	for paso in _max_pasos:

		var t_min := INF

		var tipo := ""

		var indice := -1

		# Buscar el espejo más cercano en el trayecto
		for i in range(_nodos_espejos.size()):

			var seg: Array = _segmento_espejo(i)

			var t := _interseccion_segmento(pos, dir, seg[0], seg[1])

			if t < t_min:

				t_min = t

				tipo = "espejo"

				indice = i

		# Receptor
		var t_rec := _interseccion_circulo(
			pos, dir, receptor_pos, RADIO_RECEPTOR
		)

		if t_rec < t_min:

			t_min = t_rec

			tipo = "receptor"

		# Salida de la zona
		var t_z := _interseccion_zona(pos, dir)

		if t_z < t_min:

			t_min = t_z

			tipo = "fin"

		# Cajas de metal: cortan el haz si están en el camino
		var t_caja := _interseccion_cajas(pos, dir)

		if t_caja < t_min:

			t_min = t_caja

			tipo = "caja"

		if t_min == INF or t_min > 2000.0:
			break

		var nuevo := pos + dir * t_min

		puntos.append(nuevo)

		if tipo == "fin":
			break

		if tipo == "caja":

			# El haz se corta contra la caja de metal.
			break

		pos = nuevo

		if tipo == "receptor":

			alcanzado = true

			break

		# Rebote en el espejo: nueva dirección tras cada rebote
		dir = _dir_tras_espejo(dir, _nodos_espejos[indice])

		# Avanzar un poco para no volver a detectar el mismo espejo
		pos += dir * 1.0

	_beam.points = puntos

	if alcanzado:

		_receptor_sprite.modulate = Color(0.4, 1.0, 0.4)

		_resolver()
	else:
		_invalidar_solucion()


func _invalidar_solucion() -> void:

	if not resuelto:
		return

	resuelto = false
	if datos_sala != null:
		datos_sala.laser_componentes_activos = true

	# Persistir estado en RoomData
	if datos_sala:
		datos_sala.laser_resuelto = false
		var direccion: String = direccion_puerta
		var vecina_indice: int = -1
		match direccion:
			"arriba": vecina_indice = datos_sala.arriba
			"abajo": vecina_indice = datos_sala.abajo
			"izquierda": vecina_indice = datos_sala.izquierda
			"derecha": vecina_indice = datos_sala.derecha
		if laboratorio_datos and vecina_indice >= 0 and vecina_indice < laboratorio_datos.salas.size():
			laboratorio_datos.salas[vecina_indice].laser_resuelto_vecina = false

	for espejo in _nodos_espejos:
		espejo.activo = true

	if sala_nodo == null or not is_instance_valid(sala_nodo):
		return

	var doors := sala_nodo.get_node_or_null("Doors")
	if doors == null or direccion_puerta.is_empty():
		return

	var nombre_puerta := "Puerta" + direccion_puerta.capitalize()
	var puerta := doors.get_node_or_null(nombre_puerta) as Door
	if puerta:
		puerta.cerrar()


# ENCENDER EMISOR

func desordenar_piezas() -> void:

	if _nodos_espejos.is_empty():
		return

	if resuelto:
		_invalidar_solucion()
	else:
		_reiniciar_puerta_por_vibracion()

	emisor_encendido = false
	if datos_sala != null:
		datos_sala.laser_emisor_encendido = false
	_actualizar_emisor()

	for espejo in _nodos_espejos:
		if espejo == null or not is_instance_valid(espejo):
			continue
		for _i in range(randi_range(1, 3)):
			espejo.rotar()
	_guardar_orientaciones()

	_retrazar()

	print("🔊 Vibración: piezas del láser desordenadas")


func _guardar_orientaciones() -> void:
	if datos_sala == null:
		return
	datos_sala.laser_orientaciones.clear()
	for espejo in _nodos_espejos:
		if espejo != null and is_instance_valid(espejo):
			datos_sala.laser_orientaciones.append(espejo.orient)


func interactuar() -> void:
	var jugador_activo := jugador
	if jugador_activo == null:
		var gestor := get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
		if gestor != null:
			jugador_activo = gestor.jugador
	if jugador_activo == null:
		return

	if not jugador_cerca:
		if global_position.distance_to(jugador_activo.global_position) > 50.0:
			return
		jugador = jugador_activo
		jugador_cerca = true

	if interaction_manager != null:
		interaction_manager.establecer_activo(true)

	# APAGÓN (CORTOCIRCUITO DEL ROBOT)
	# Sin energía el emisor no se puede tocar.
	if _sala_en_apagon():

		print("⚡ Apagón: el puzzle láser está sin energía")

		return

	emisor_encendido = not emisor_encendido
	if datos_sala != null:
		datos_sala.laser_emisor_encendido = emisor_encendido
	_actualizar_emisor()
	_retrazar()
	if interaction_manager:
		interaction_manager.refrescar_prompt()


# ¿La sala mostrada está en apagón (cortocircuito)?
func _sala_en_apagon() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not main.has_method(
		"sala_actual_en_apagon"
	):

		return false

	return main.sala_actual_en_apagon()


func obtener_texto_prompt() -> String:

	if emisor_encendido:
		return "Apagar emisor"

	return "Encender emisor"


func _actualizar_emisor() -> void:

	if _emisor_sprite == null:
		return

	if emisor_encendido:
		_emisor_sprite.modulate = Color.WHITE
	else:
		_emisor_sprite.modulate = Color(0.25, 0.25, 0.25, 1.0)


# RESOLVER (EL HAZ LLEGA AL RECEPTOR)

func _resolver() -> void:

	if resuelto:
		return

	resuelto = true
	_persistir_estado_resuelto()

	if objeto_datos:
		datos_sala.registrar_puzzle(objeto_datos)

	_abrir_puerta_mecanica()

	var ga := get_tree().get_first_node_in_group("gestor_audio") as AudioManager
	if ga:
		ga.reproducir_efecto_corto("laserresuelto", 0.9, -2.0)

	print("🔦 Alineador láser resuelto")


func _persistir_estado_resuelto() -> void:
	if datos_sala == null:
		return

	datos_sala.laser_resuelto = true
	datos_sala.laser_componentes_activos = false
	# El emisor permanece encendido al completar el circuito y
	# se restaura así al reconstruir la sala.
	datos_sala.laser_emisor_encendido = emisor_encendido
	_guardar_orientaciones()

	var vecina_indice: int = -1
	match direccion_puerta:
		"arriba": vecina_indice = datos_sala.arriba
		"abajo": vecina_indice = datos_sala.abajo
		"izquierda": vecina_indice = datos_sala.izquierda
		"derecha": vecina_indice = datos_sala.derecha
	if laboratorio_datos != null and vecina_indice >= 0 \
			and vecina_indice < laboratorio_datos.salas.size():
		laboratorio_datos.salas[vecina_indice].laser_resuelto_vecina = true


func _reiniciar_puerta_por_vibracion() -> void:
	if datos_sala != null:
		datos_sala.laser_resuelto = false
		datos_sala.laser_componentes_activos = true
		datos_sala.laser_emisor_encendido = false
		var vecina_indice: int = -1
		match direccion_puerta:
			"arriba": vecina_indice = datos_sala.arriba
			"abajo": vecina_indice = datos_sala.abajo
			"izquierda": vecina_indice = datos_sala.izquierda
			"derecha": vecina_indice = datos_sala.derecha
		if laboratorio_datos != null and vecina_indice >= 0 \
				and vecina_indice < laboratorio_datos.salas.size():
			laboratorio_datos.salas[vecina_indice].laser_resuelto_vecina = false

	_cerrar_puerta_mecanica()


func _cerrar_puerta_mecanica() -> void:
	if sala_nodo == null or not is_instance_valid(sala_nodo):
		return
	if direccion_puerta.is_empty():
		return
	var doors := sala_nodo.get_node_or_null("Doors")
	if doors == null:
		return
	var nombre_puerta := "Puerta" + direccion_puerta.capitalize()
	var puerta := doors.get_node_or_null(nombre_puerta) as Door
	if puerta != null:
		puerta.bloqueada = false
		puerta.cerrar()


# ABRIR LA PUERTA DEL MECANISMO (si la hay)

func _abrir_puerta_mecanica() -> void:

	if direccion_puerta.is_empty():
		return

	if sala_nodo == null or not is_instance_valid(sala_nodo):

		var padre := get_parent()

		if padre != null:
			sala_nodo = padre.get_parent()

	if sala_nodo == null:
		push_warning("LaserPuzzle: no se encontró la sala.")
		return

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors == null:
		return

	var nombre_puerta := "Puerta" + direccion_puerta.capitalize()

	var puerta := doors.get_node_or_null(nombre_puerta) as Door

	if puerta:

		puerta.abrir()

		print("🔦 Mecanismo activado: ", puerta.name)
