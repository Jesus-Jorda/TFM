extends Node

class_name TerminalGenerator


# ESCENA DEL TERMINAL

static var terminal_scene = preload(
	"res://Scenes/Objects/Interactable/Terminal.tscn"
)


# CONFIGURACIÓN

# Separación del terminal respecto a la pared.
const DISTANCIA_PARED := 0.55

# Separación vertical de los terminales laterales
# respecto a la altura de la puerta.
const DESPLAZAMIENTO_LATERAL := 1.45


# GENERAR TERMINALES

static func generar(
	parent: Node2D,
	data: RoomData
) -> void:

	# BORRAR TERMINALES ANTERIORES

	for hijo in parent.get_children():
		hijo.queue_free()


	# TERMINAL ARRIBA

	if data.terminal_arriba:

		var centro_x := (
			(data.ancho / 2 + 1)
			* data.tam_celda
		)

		crear_terminal(
			parent,
			"TerminalArriba",
			Vector2(
				centro_x + data.tam_celda,
				DISTANCIA_PARED * data.tam_celda
			),
			Terminal.Direccion.ARRIBA,
			data
		)


	# TERMINAL ABAJO

	if data.terminal_abajo:

		var centro_x := (
			(data.ancho / 2 + 1)
			* data.tam_celda
		)

		crear_terminal(
			parent,
			"TerminalAbajo",
			Vector2(
				centro_x + data.tam_celda,
				(data.alto + 1.0 - DISTANCIA_PARED)
				* data.tam_celda
			),
			Terminal.Direccion.ABAJO,
			data
		)


	# TERMINAL IZQUIERDA

	if data.terminal_izquierda:

		var centro_y := (
			(data.alto / 2 + 0.5)
			* data.tam_celda
		)

		crear_terminal(
			parent,
			"TerminalIzquierda",
			Vector2(
				DISTANCIA_PARED * data.tam_celda,
				centro_y + DESPLAZAMIENTO_LATERAL
				* data.tam_celda
			),
			Terminal.Direccion.IZQUIERDA,
			data
		)


	# TERMINAL DERECHA

	if data.terminal_derecha:

		var centro_y := (
			(data.alto / 2 + 0.5)
			* data.tam_celda
		)

		crear_terminal(
			parent,
			"TerminalDerecha",
			Vector2(
				(data.ancho + 1.0 - DISTANCIA_PARED)
				* data.tam_celda,
				centro_y + DESPLAZAMIENTO_LATERAL
				* data.tam_celda
			),
			Terminal.Direccion.DERECHA,
			data
		)


# NUMERAR TERMINALES DE LA PARTIDA
# Recorre todas las salas del laboratorio y asigna a
# cada terminal un número único global, guardándolo en
# los datos de su sala por dirección (arriba, abajo,
# izquierda, derecha) con RoomData.registrar_terminal.

static func asignar_numeros(
	salas: Array[RoomData]
) -> void:

	var numero: int = 1

	for data in salas:

		if data.terminal_arriba:
			data.registrar_terminal("arriba", numero)
			numero += 1

		if data.terminal_abajo:
			data.registrar_terminal("abajo", numero)
			numero += 1

		if data.terminal_izquierda:
			data.registrar_terminal("izquierda", numero)
			numero += 1

		if data.terminal_derecha:
			data.registrar_terminal("derecha", numero)
			numero += 1


# CREAR TERMINAL

static func crear_terminal(
	parent: Node2D,
	nombre: String,
	posicion: Vector2,
	direccion: Terminal.Direccion,
	data: RoomData
) -> void:

	var terminal := (
		terminal_scene.instantiate()
		as Terminal
	)

	if terminal == null:
		return


	terminal.name = nombre

	terminal.position = posicion

	# Elegir directamente el sprite correcto.
	terminal.direccion = direccion

	# PREGUNTA FIJA y ENERGÍA PERSISTENTE
	# El terminal recibe su índice de pregunta (fijo para
	# esta sala+dirección) y su estado de batería guardado
	# en RoomData, para que no cambie de pregunta ni se
	# apague al reconstruir la sala.

	var direccion_texto: String = Terminal.direccion_a_texto(direccion)

	if data.terminal_pregunta_indice.has(direccion_texto):
		terminal.pregunta_índice = data.terminal_pregunta_indice[direccion_texto]
	else:
		# Primera vez: se le asigna un índice fijo según su
		# número de terminal (siempre el mismo mientras el
		# laboratorio no se regenere).
		var numero: int = 0
		match direccion_texto:
			"arriba":
				numero = data.terminal_arriba_numero
			"abajo":
				numero = data.terminal_abajo_numero
			"izquierda":
				numero = data.terminal_izquierda_numero
			"derecha":
				numero = data.terminal_derecha_numero

		var indice: int = max(0, numero) % TerminalBanco.bateria_terminal.size()
		terminal.pregunta_índice = indice
		data.terminal_pregunta_indice[direccion_texto] = indice

	# Energía guardada (batería instalada antes de salir
	# de la sala).
	terminal.tiene_energia = data.terminal_energia.get(direccion_texto, false)

	parent.add_child(terminal)
