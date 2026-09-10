extends Control


@onready var terminal_interface: TerminalInterface = $TerminalInterface


# BATERÍA DE PREGUNTAS (TODO EN TerminalBanco)
# El banco vive ahora en TerminalBanco.gd (compartido).
# Esta escena de prueba usa ese mismo banco.


func _ready() -> void:

	if TerminalBanco.bateria_terminal.is_empty():
		return

	abrir_pregunta(0)


func abrir_pregunta(indice: int) -> void:

	if indice < 0 or indice >= TerminalBanco.bateria_terminal.size():
		return

	var item: Dictionary = TerminalBanco.bateria_terminal[indice]
	terminal_interface.abrir_terminal(
		item["pregunta"],
		item["respuesta"]
	)
