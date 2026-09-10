extends Node

class_name RoomBuilder


static func construir(
	room: Node2D,
	data: RoomData,
	laboratorio: LaboratoryData
) -> void:

	# Guardar los datos en el nodo de la sala para que
	# otros sistemas (p.ej. inventario al soltar objetos)
	# puedan registrar contenido nuevo en la sala.
	room.set_meta("room_data", data)

	# SUELO

	FloorGenerator.generar(
		room.get_node("Floor"),
		data
	)


	# PAREDES

	WallGenerator.generar(
		room.get_node("Walls"),
		data
	)


	# PUERTAS

	DoorGenerator.generar(
		room.get_node("Doors"),
		data
	)
	# TERMINALES

	TerminalGenerator.generar(
		room.get_node("Terminals"),
		data
	)

	# OBJETOS

	ObjectGenerator.generar(
		room.get_node("Objects"),
		data
	)


	# OBJETOS DE ENERGÍA (BATERÍAS)

	PowerGenerator.generar(
		room.get_node("Objects"),
		data,
		laboratorio
	)


	# VIBRACIÓN PENDIENTE (GOLPE DE SUELO VECINO)
	# Si una sala vecina sacudió el laboratorio, esta sala
	# se construye con sus puzzles ya desordenados.
	_aplicar_vibracion_pendiente(room, data)


	# DECORACIÓN

	# Más adelante:
	# DecorationGenerator.generar(
	#     room.get_node("Decoration"),
	#     data
	# )


	# PERSONAJES

	# Más adelante


	# EFECTOS

	# Más adelante


# VIBRACIÓN PENDIENTE (GOLPE DE SUELO)
# Aplica el desorden guardado en los datos de la sala y
# limpia la marca para que solo afecte a la primera
# visita tras el golpe.

static func _aplicar_vibracion_pendiente(
	room: Node2D,
	data: RoomData
) -> void:

	if not data.vibracion_pendiente:
		return

	data.vibracion_pendiente = false

	var objects := room.get_node_or_null("Objects")
	if objects == null:
		return

	for hijo in objects.get_children():
		if hijo.has_method("desordenar_piezas"):
			if hijo is PanelElectrico:
				hijo.desordenar_piezas(false)
			else:
				hijo.desordenar_piezas()
