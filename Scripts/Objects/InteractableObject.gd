extends ObjectBase

class_name InteractableObject


# ESTADO

var jugador_cerca: bool = false

var jugador: Character = null


# MANAGER

var interaction_manager: InteractionManager = null

func puede_interactuar_con_jugador(_jugador: Character) -> bool:
	return true


# AREA

@onready var interaction_area: Area2D = get_node_or_null("InteractionArea") as Area2D


# READY

func _ready() -> void:

	# Buscar el InteractionManager de la partida.

	interaction_manager = (
		get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
	)


	# Conectar área.

	if interaction_area:

		interaction_area.body_entered.connect(
			_jugador_entra
		)

		interaction_area.body_exited.connect(
			_jugador_sale
		)


# JUGADOR ENTRA

func _jugador_entra(
	body: Node2D
) -> void:

	if not body is Character:
		return

	if not puede_interactuar_con_jugador(body as Character):
		return

	# Solo el personaje cuyo turno está activo puede activar el
	# prompt. Los demás jugadores siguen presentes en la sala.
	if interaction_manager != null \
			and interaction_manager.jugador != null \
			and body != interaction_manager.jugador:
		return


	jugador = body as Character

	jugador_cerca = true


	print(
		"Objeto interactuable cerca: ",
		object_id
	)


	if interaction_manager:

		interaction_manager.registrar_objeto(
			self
		)


# JUGADOR SALE

func _jugador_sale(
	body: Node2D
) -> void:

	if body != jugador:
		return


	jugador = null

	jugador_cerca = false


	if interaction_manager:

		interaction_manager.quitar_objeto(
			self
		)


# INTERACTUAR

func interactuar() -> void:

	if not jugador_cerca:
		return

	print(
		"Interacción con objeto: ",
		object_id
	)


# TEXTO DEL PROMPT
# Cada objeto puede personalizar el texto del botón
# de interacción. Vacío = texto genérico del manager.

func obtener_texto_prompt() -> String:

	return ""
