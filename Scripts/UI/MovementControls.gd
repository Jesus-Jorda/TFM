extends CanvasLayer

class_name MovementControls


# REFERENCIA AL JUGADOR

var jugador: Character
var controles_activos: bool = true


# CRUCETA DE DIRECCIÓN

const TEXTURA_CRUZETA: Texture2D = preload(
	"res://Sprites/cruzetaizq.png"
)

const TAM_BOTON_DIR := Vector2(56, 56)

# El sprite base apunta a la IZQUIERDA; giramos cada
# botón para que apunte a su dirección. Si alguna
# flecha queda al revés, ajusta solo estos grados.
const ROT_ARRIBA := 90.0
const ROT_ABAJO := 270.0
const ROT_IZQUIERDA := 0.0
const ROT_DERECHA := 180.0


# NODOS

@onready var up_button := $Control/DPad/Up
@onready var down_button := $Control/DPad/Down
@onready var left_button := $Control/DPad/Left
@onready var right_button := $Control/DPad/Right


# READY

func _ready():

	# CONECTAR BOTONES

	up_button.button_down.connect(_arriba_pulsado)
	up_button.button_up.connect(_arriba_soltado)

	down_button.button_down.connect(_abajo_pulsado)
	down_button.button_up.connect(_abajo_soltado)

	left_button.button_down.connect(_izquierda_pulsado)
	left_button.button_up.connect(_izquierda_soltado)

	right_button.button_down.connect(_derecha_pulsado)
	right_button.button_up.connect(_derecha_soltado)


	_configurar_botones_direccion()


# CONFIGURAR LA CRUCETA
# Aplica el sprite de la cruzeta a los 4 botones de
# dirección, girado para que cada flecha apunte a su
# lado, y los coloca formando una cruz.

func _configurar_botones_direccion() -> void:

	_aplicar_cruzeta(up_button, ROT_ARRIBA, Vector2(85, 5))

	_aplicar_cruzeta(left_button, ROT_IZQUIERDA, Vector2(13, 63))

	_aplicar_cruzeta(right_button, ROT_DERECHA, Vector2(157, 63))

	_aplicar_cruzeta(down_button, ROT_ABAJO, Vector2(85, 121))


func _aplicar_cruzeta(
	boton: TextureButton,
	rotacion: float,
	posicion: Vector2
) -> void:

	# Anclas a cero: posición y tamaño los controlamos
	# nosotros (si no, el layout del editor sobrescribe
	# el tamaño después de _ready).
	boton.anchor_left = 0.0

	boton.anchor_top = 0.0

	boton.anchor_right = 0.0

	boton.anchor_bottom = 0.0


	boton.texture_normal = TEXTURA_CRUZETA

	boton.ignore_texture_size = true

	boton.stretch_mode = TextureButton.STRETCH_SCALE

	boton.size = TAM_BOTON_DIR

	# Girar alrededor del centro del botón
	boton.pivot_offset = TAM_BOTON_DIR / 2.0

	boton.rotation_degrees = rotacion

	boton.position = posicion


# CONFIGURAR JUGADOR

func asignar_jugador(nuevo_jugador: Character):

	jugador = nuevo_jugador


# ACTIVAR / DESACTIVAR CONTROLES

func establecer_activo(activo: bool) -> void:
	controles_activos = activo

	up_button.disabled = not activo
	down_button.disabled = not activo
	left_button.disabled = not activo
	right_button.disabled = not activo

	if not activo and jugador:
		jugador.establecer_direccion(Vector2.ZERO)


# ARRIBA

func _arriba_pulsado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.UP)


func _arriba_soltado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.ZERO)


# ABAJO

func _abajo_pulsado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.DOWN)


func _abajo_soltado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.ZERO)


# IZQUIERDA

func _izquierda_pulsado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.LEFT)


func _izquierda_soltado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.ZERO)


# DERECHA

func _derecha_pulsado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.RIGHT)


func _derecha_soltado():

	if not controles_activos:
		return

	if jugador:
		jugador.establecer_direccion(Vector2.ZERO)

