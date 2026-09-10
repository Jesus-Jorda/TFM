extends Node

class_name FloorGenerator

const ESCALA := 0.17

# Colores distintivos por tipo de sala para diferenciarlas
# visualmente sin cambiar la textura base del suelo.
static var colores_sala: Dictionary = {
	RoomData.TipoSala.INICIO: Color(1.0, 1.0, 1.0),
	RoomData.TipoSala.LABORATORIO: Color(0.82, 0.86, 0.92),
	RoomData.TipoSala.MAQUINAS: Color(0.98, 0.96, 0.72),
	RoomData.TipoSala.DESCANSO: Color(0.78, 0.94, 0.82),
	RoomData.TipoSala.ALMACEN: Color(0.98, 0.86, 0.70),
	RoomData.TipoSala.CONTROL: Color(0.72, 0.82, 0.96),
	RoomData.TipoSala.SALIDA: Color(1.0, 0.52, 0.52),
}

static func generar(
	parent: Node2D,
	data: RoomData
) -> void:

	# Mantener siempre el mismo suelo para esta sala
	seed(data.seed)

	# Eliminar suelo anterior
	for hijo in parent.get_children():
		hijo.queue_free()

	# Cargar texturas
	var texturas := {
		"bg": preload("res://Sprites/bg.png"),
		"bg2": preload("res://Sprites/bg2.png"),
		"bg3": preload("res://Sprites/bg3.png"),
		"brota": preload("res://Sprites/brota.png"),
		"ba": preload("res://Sprites/ba.png"),
		"br": preload("res://Sprites/br.png"),
		"bl": preload("res://Sprites/bl.png"),
		"bv": preload("res://Sprites/bv.png")
	}

	# Color distintivo según el tipo de sala
	var color_sala: Color = colores_sala.get(data.tipo, Color.WHITE)

	# El suelo empieza una casilla hacia dentro
	for y in range(data.alto):
		for x in range(data.ancho):
			var sprite := Sprite2D.new()
			sprite.texture = elegir_losa(texturas, data.tipo)
			sprite.scale = Vector2.ONE * ESCALA
			sprite.modulate = color_sala
			sprite.position = Vector2(
				(x + 1) * data.tam_celda,
				(y + 1) * data.tam_celda
			)
			parent.add_child(sprite)


static func elegir_losa(texturas: Dictionary, tipo_sala: RoomData.TipoSala) -> Texture2D:
	var paleta: Array[String]

	match tipo_sala:
		RoomData.TipoSala.INICIO:
			paleta = ["bg", "bl", "bv"]
		RoomData.TipoSala.LABORATORIO:
			paleta = ["bl", "bg", "bv"]
		RoomData.TipoSala.MAQUINAS:
			paleta = ["bv", "bg", "ba"]
		RoomData.TipoSala.DESCANSO:
			paleta = ["bg", "ba", "bl"]
		RoomData.TipoSala.ALMACEN:
			paleta = ["ba", "bg", "bv"]
		RoomData.TipoSala.CONTROL:
			paleta = ["bl", "bv", "bg"]
		RoomData.TipoSala.SALIDA:
			paleta = ["br"]
		_:
			paleta = ["bg"]

	var clave := paleta[randi() % paleta.size()]
	return texturas.get(clave, texturas["bg"])