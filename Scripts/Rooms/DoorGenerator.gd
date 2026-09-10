extends Node

class_name DoorGenerator


# CONFIGURACIÓN

const ESCALA := 0.33


# SPRITES DE PUERTAS ABIERTAS

static var puerta_arriba = preload(
	"res://Sprites/puertaa.png"
)

static var puerta_izquierda = preload(
	"res://Sprites/puertaizqa.png"
)

static var puerta_derecha = preload(
	"res://Sprites/puertadera.png"
)


# SPRITES DE PUERTAS CERRADAS

static var puerta_arriba_cerrada = preload(
	"res://Sprites/puertac.png"
)

static var puerta_izquierda_cerrada = preload(
	"res://Sprites/puertaizqc.png"
)

static var puerta_derecha_cerrada = preload(
	"res://Sprites/puertaderc.png"
)


# GENERAR PUERTAS

static func generar(
	parent: Node2D,
	data: RoomData
) -> void:
	_normalizar_puertas_compartidas(data)

	# BORRAR PUERTAS ANTERIORES

	for hijo in parent.get_children():
		hijo.queue_free()

	# PUERTA ARRIBA

	if data.puerta_arriba:

		crear_puerta(
			parent,
			"PuertaArriba",
			Vector2(
				(data.ancho / 2 + 1) * data.tam_celda,
				0
			),
			puerta_arriba,
			puerta_arriba_cerrada,
			false,
			"arriba",
			data.arriba,
			data.terminal_arriba and not data.puertas_abiertas.get("arriba", false),
			_puerta_cerrada_mecanismo(data, "arriba") \
				and not data.puertas_abiertas.get("arriba", false)
		)


	# PUERTA ABAJO

	if data.puerta_abajo:

		crear_puerta(
			parent,
			"PuertaAbajo",
			Vector2(
				(data.ancho / 2 + 1) * data.tam_celda,
				(data.alto + 1) * data.tam_celda
			),
			puerta_arriba,
			puerta_arriba_cerrada,
			true,
			"abajo",
			data.abajo,
			data.terminal_abajo and not data.puertas_abiertas.get("abajo", false),
			_puerta_cerrada_mecanismo(data, "abajo") \
				and not data.puertas_abiertas.get("abajo", false)
		)


	# PUERTA IZQUIERDA

	if data.puerta_izquierda:

		crear_puerta(
			parent,
			"PuertaIzquierda",
			Vector2(
				10,
				(data.alto / 2 + 0.5) * data.tam_celda
			),
			puerta_izquierda,
			puerta_izquierda_cerrada,
			false,
			"izquierda",
			data.izquierda,
			data.terminal_izquierda and not data.puertas_abiertas.get("izquierda", false),
			_puerta_cerrada_mecanismo(data, "izquierda") \
				and not data.puertas_abiertas.get("izquierda", false)
		)


	# PUERTA DERECHA

	if data.puerta_derecha:

		crear_puerta(
			parent,
			"PuertaDerecha",
			Vector2(
				(data.ancho + 1) * data.tam_celda - 10,
				(data.alto / 2 + 0.5) * data.tam_celda
			),
			puerta_derecha,
			puerta_derecha_cerrada,
			false,
			"derecha",
			data.derecha,
			data.terminal_derecha and not data.puertas_abiertas.get("derecha", false),
			_puerta_cerrada_mecanismo(data, "derecha") \
				and not data.puertas_abiertas.get("derecha", false)
		)


static func _normalizar_puertas_compartidas(data: RoomData) -> void:
	var conexiones := [
		["arriba", data.arriba, "abajo"],
		["abajo", data.abajo, "arriba"],
		["izquierda", data.izquierda, "derecha"],
		["derecha", data.derecha, "izquierda"]
	]
	var arbol := Engine.get_main_loop() as SceneTree
	if arbol == null:
		return
	var main := arbol.get_first_node_in_group("main")
	if main == null or not "laboratorio" in main:
		return

	for conexion in conexiones:
		var direccion: String = conexion[0]
		var destino: int = conexion[1]
		var opuesta: String = conexion[2]
		if destino < 0 or destino >= main.laboratorio.salas.size():
			continue
		var vecina: RoomData = main.laboratorio.salas[destino]
		var abierta: bool = bool(
			data.puertas_abiertas.get(direccion, false)
		) or bool(vecina.puertas_abiertas.get(opuesta, false))
		data.puertas_abiertas[direccion] = abierta
		vecina.puertas_abiertas[opuesta] = abierta


# PUERTA CERRADA POR MECANISMO (PANEL ELÉCTRICO O LÁSER)
# Devuelve true si la puerta de esta dirección está
# bloqueada por un mecanismo (panel eléctrico o puzzle
# láser) de esta sala o de la sala vecina y aún no se
# ha resuelto. Las puertas así bloqueadas nacen cerradas
# hasta que se resuelva el puzzle correspondiente.

static func _puerta_cerrada_mecanismo(
	data: RoomData,
	direccion: String
) -> bool:

	# Puerta bloqueada por el panel de esta sala
	if data.panel_puerta == direccion:
		return not data.panel_resuelto

	# Puerta bloqueada por el panel de la sala vecina
	if data.panel_puerta_vecina == direccion:
		return not data.panel_resuelto_vecina

	# Puerta bloqueada por el láser de esta sala
	if data.laser_puerta == direccion:
		return not data.laser_resuelto

	# Puerta bloqueada por el láser de la sala vecina
	if data.laser_puerta_vecina == direccion:
		return not data.laser_resuelto_vecina

	return false


# CREAR PUERTA

static func crear_puerta(
	parent: Node2D,
	nombre_puerta: String,
	posicion: Vector2,
	textura_abierta: Texture2D,
	textura_cerrada: Texture2D,
	invertir_vertical: bool,
	direccion: String,
	sala_destino: int,
	tiene_terminal: bool = false,
	cerrada: bool = false
) -> void:

	# AREA DE INTERACCIÓN

	var puerta := Area2D.new()

	puerta.name = nombre_puerta
	puerta.position = posicion

	parent.add_child(puerta)


	# DATOS

	puerta.set_script(
		preload("res://Scripts/Laboratory/Door.gd")
	)

	puerta.direccion = direccion
	puerta.sala_destino = sala_destino
	puerta.textura_abierta = textura_abierta
	puerta.textura_cerrada = textura_cerrada

	# Las puertas con terminal empiezan cerradas.
	puerta.cerrada = tiene_terminal or cerrada


	# SPRITE

	var sprite := Sprite2D.new()

	sprite.name = "Sprite"

	if puerta.cerrada:

		sprite.texture = textura_cerrada

	else:

		sprite.texture = textura_abierta

	sprite.scale = Vector2.ONE * ESCALA

	sprite.flip_v = invertir_vertical

	puerta.add_child(sprite)


	# BLOQUEADOR FÍSICO

	var blocker_body := StaticBody2D.new()
	blocker_body.name = "Blocker"
	blocker_body.collision_layer = 1
	blocker_body.collision_mask = 0
	blocker_body.position = Vector2.ZERO
	puerta.add_child(blocker_body)

	var blocker_collision := CollisionShape2D.new()
	var blocker_shape := RectangleShape2D.new()
	blocker_shape.size = Vector2(42, 54)
	blocker_collision.shape = blocker_shape
	blocker_collision.position = Vector2.ZERO
	blocker_body.add_child(blocker_collision)

	if puerta.cerrada:
		blocker_collision.disabled = false
	else:
		blocker_collision.disabled = true

	puerta.blocker_body = blocker_body
	puerta.blocker_shape = blocker_collision


	# ÁREA DE DETECCIÓN

	var collision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	forma.size = Vector2(
		20,
		40
	)

	collision.shape = forma

	puerta.add_child(collision)
