extends InteractableObject

class_name Tele


# CONFIGURACIÓN

const RADIO_INTERACCION := 42.0

# Desplazamiento vertical del área hacia abajo. La tele

const DESPLAZAMIENTO_INTERACCION := 45.0


# READY

func _ready() -> void:

	# CREAR EL ÁREA DE INTERACCIÓN SI NO EXISTE
	

	if interaction_area == null:

		var area := Area2D.new()

		area.name = "InteractionArea"

		var collision := CollisionShape2D.new()

		var forma := CircleShape2D.new()

		forma.radius = RADIO_INTERACCION

		collision.shape = forma

		# Centrar el área más abajo, cerca del suelo
		# por donde camina el jugador.
		collision.position = Vector2(0, DESPLAZAMIENTO_INTERACCION)

		area.add_child(collision)

		add_child(area)

		interaction_area = area


	super._ready()

	object_id = "tele"


# INTERACTUAR

func interactuar() -> void:

	if not jugador_cerca:
		return

	print("📺 Has interactuado con la tele")
