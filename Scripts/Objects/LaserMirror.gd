extends InteractableObject

class_name LaserMirror


# ESPEJO DEL PUZLE DE LÁSERES (reutilizable)
# Cada espejo es un objeto interactuable INDEPENDIENTE
# con su propia InteractionArea, su colisión y su mesa.
# Al interactuar rota 90° y emite la señal "rotado"
# para que el sistema del láser recalcule el haz.

signal rotado

# Radio del área de interacción. Debe ser pequeño para
# que las áreas de espejos cercanos NO se solapen y cada
# uno se gire de forma independiente.
const RADIO_INTERACCION := 22.0

const COLOR_ESPEJO := Color(0.20, 0.50, 1.0, 0.95)

const TAM_MESA := Vector2(46, 14)

const ESCALA_MESA := 0.08

const TEXTURA_MESA: Texture2D = preload(
	"res://Assets/Objects/Computers/mesareceptora.png"
)

# Orientaciones del espejo en orden de giro
const ORIENTACIONES := ["/", "|", "\\", "-"]


# ESTADO

# Índice de orientación actual (0..3)
var orient := 2

# Si el puzzle está resuelto, el espejo deja de girar
var activo := true

var _cuerpo: StaticBody2D = null


# READY

func _ready() -> void:

	# ÁREA DE INTERACCIÓN PROPIA (la que detecta al
	# jugador, igual que el resto de interactuables)

	if interaction_area == null:

		var area := Area2D.new()

		area.name = "InteractionArea"

		area.monitoring = true

		var collision := CollisionShape2D.new()

		var forma := CircleShape2D.new()

		forma.radius = RADIO_INTERACCION

		collision.shape = forma

		area.add_child(collision)

		add_child(area)

		interaction_area = area


	# MESITA INDIVIDUAL (una por cada espejo)

	var mesa := StaticBody2D.new()

	mesa.name = "MesaEspejo"
	mesa.z_index = 0
	mesa.position = Vector2(0, 26)

	var col_mesa := CollisionShape2D.new()

	var forma_mesa := RectangleShape2D.new()

	forma_mesa.size = TAM_MESA

	col_mesa.shape = forma_mesa
	col_mesa.disabled = true

	mesa.add_child(col_mesa)

	# Visual de la mesa (usa la textura de la mesa receptora)
	var visual_mesa := Sprite2D.new()

	visual_mesa.texture = TEXTURA_MESA

	visual_mesa.scale = Vector2.ONE * ESCALA_MESA

	visual_mesa.z_index = 1

	mesa.add_child(visual_mesa)

	mesa.z_index = 0
	add_child(mesa)
	self.z_index = 0

	# CUERPO DEL ESPEJO (colisión + visual azul)

	_cuerpo = StaticBody2D.new()

	_cuerpo.name = "Espejo"
	_cuerpo.z_index = 1

	var colision := CollisionShape2D.new()

	var forma_esp := RectangleShape2D.new()

	forma_esp.size = Vector2(10, 34)

	colision.shape = forma_esp

	_cuerpo.add_child(colision)

	var rect := Polygon2D.new()

	rect.polygon = PackedVector2Array([
		Vector2(-6, -18),
		Vector2(6, -18),
		Vector2(6, 18),
		Vector2(-6, 18)
	])

	rect.color = COLOR_ESPEJO

	rect.z_index = 0

	_cuerpo.add_child(rect)

	add_child(_cuerpo)

	_aplicar_rotacion()


	super._ready()

	object_id = "espejo_laser"


# INTERACTUAR (GIRAR EL ESPEJO 90°)

func interactuar() -> void:

	# El InteractionManager ya garantiza que este espejo es el
	# objeto_actual (el más cercano al jugador), así que siempre
	# que se pulse Interactuar sobre él, gira. Esto evita que
	# falle cuando el jugador se teletransporta o la señal
	# body_entered no se dispara por solapamiento de áreas.
	if not activo:
		return

	rotar()


func rotar() -> void:

	orient = (orient + 1) % ORIENTACIONES.size()

	_aplicar_rotacion()

	rotado.emit()


func _aplicar_rotacion() -> void:

	if _cuerpo == null:
		return

	match ORIENTACIONES[orient]:

		"/":
			_cuerpo.rotation = deg_to_rad(45.0)   # antes: -45.0

		"\\":
			_cuerpo.rotation = deg_to_rad(-45.0)  # antes: 45.0

		"|":
			_cuerpo.rotation = 0.0

		"-":
			_cuerpo.rotation = deg_to_rad(90.0)

# NORMAL DE LA SUPERFICIE (para la física del láser)

func obtener_normal() -> Vector2:

	match ORIENTACIONES[orient]:

		"/":
			return Vector2(1, 1).normalized()

		"\\":
			return Vector2(1, -1).normalized()

		"|":
			return Vector2(1, 0)

		"-":
			return Vector2(0, 1)

	return Vector2(1, 0)


# DIRECCIÓN DE LA SUPERFICIE (para el segmento)

func obtener_direccion_segmento() -> Vector2:

	match ORIENTACIONES[orient]:

		"/":
			return Vector2(1, -1).normalized()

		"\\":
			return Vector2(1, 1).normalized()

		"|":
			return Vector2(0, 1)

		"-":
			return Vector2(1, 0)

	return Vector2(1, 0)


# TEXTO DEL PROMPT

func obtener_texto_prompt() -> String:

	return "Girar espejo"
