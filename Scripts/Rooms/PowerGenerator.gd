extends Node

class_name PowerGenerator


# OBJETOS DE ENERGÍA
# Crea los objetos interactuables de energía (baterías)
# que el jugador puede recoger para alimentar los
# terminales apagados.
# Los datos viven en RoomData.objetos (registrados por
# ObjectGenerator la primera vez que se genera la sala),
# así que la sala sabe qué baterías tenía y cuáles han
# sido recogidas.

static var bateria_script = preload(
	"res://Scripts/Objects/Bateria.gd"
)


# GENERAR OBJETOS DE ENERGÍA

static func generar(
	parent: Node2D,
	data: RoomData,
	laboratorio: LaboratoryData
) -> void:

	for objeto in data.objetos:

		# Las baterías recogidas no reaparecen
		if objeto.recogido:
			continue

		if objeto.nombre == "bateria" and objeto.interactuable:
			crear_bateria(parent, objeto)

		elif objeto.nombre == "panelcables" and objeto.interactuable:
			crear_panel_cables(parent, objeto, data)

		elif objeto.nombre == "laserpuzzle" and objeto.interactuable:
			crear_laser_puzzle(parent, objeto, data, laboratorio)

		elif objeto.interactuable and objeto.textura != null:
			# Resto de recogibles de Power (van al inventario)
			crear_recogible(parent, objeto)


# CREAR PANEL ELÉCTRICO (PUZLE DE CABLES)

static func crear_panel_cables(
	parent: Node2D,
	objeto: ObjectData,
	data: RoomData
) -> void:

	var panel := Node2D.new()

	panel.name = "PanelElectrico"

	panel.position = objeto.posicion

	panel.set_script(preload(
		"res://Scripts/Objects/PanelElectrico.gd"
	))

	panel.objeto_datos = objeto

	panel.datos_sala = data

	panel.sala_nodo = parent.get_parent()

	panel.direccion_puerta = data.panel_puerta

	# Estado persistente: si el mecanismo ya fue resuelto,
	# el panel recreado lo sabe (la puerta ya está abierta).
	panel.resuelto = data.panel_resuelto

	parent.add_child(panel)


# CREAR PUZLE DE LÁSERES (DENTRO DE LA SALA)
# Crea el objeto "laserpuzzle": una mesa con emisor,
# receptores y espejos azules. NO abre ninguna pantalla.

static func crear_laser_puzzle(
	parent: Node2D,
	objeto: ObjectData,
	data: RoomData,
	laboratorio: LaboratoryData
) -> void:

	var puzzle := Node2D.new()

	puzzle.name = "LaserPuzzle"

	puzzle.position = objeto.posicion

	puzzle.set_script(preload(
		"res://Scripts/Objects/LaserPuzzle.gd"
	))

	puzzle.objeto_datos = objeto

	puzzle.datos_sala = data

	puzzle.sala_nodo = parent.get_parent()

	puzzle.direccion_puerta = data.laser_puerta

	puzzle.resuelto = data.laser_resuelto

	puzzle.laboratorio_datos = laboratorio

	parent.add_child(puzzle)

# CREAR BATERÍA INTERACTUABLE


static func crear_bateria(
	parent: Node2D,
	objeto: ObjectData
) -> void:

	var bateria := Node2D.new()

	bateria.name = "Bateria"

	bateria.position = objeto.posicion

	bateria.set_script(bateria_script)

	# Conectar la batería con sus datos de sala para
	# que al recogerla quede marcada como recogida y
	# no vuelva a aparecer.
	bateria.objeto_datos = objeto

	parent.add_child(bateria)


# CREAR OBJETO RECOGIBLE DE POWER (VA AL INVENTARIO)
# Usa el mismo script que la batería (ahora genérico):
# coge textura/nombre de sus ObjectData y al recogerlo
# entra en el inventario ocupando su propia ranura.

static func crear_recogible(
	parent: Node2D,
	objeto: ObjectData
) -> void:

	var recogible := Node2D.new()

	recogible.name = "RecogiblePower"

	recogible.position = objeto.posicion

	recogible.set_script(bateria_script)

	recogible.objeto_datos = objeto

	parent.add_child(recogible)
