extends Node

class_name LaboratoryConnector


const MAX_PUERTAS := 3
const PROBABILIDAD_TERMINAL := 0.40


# CONECTAR LABORATORIO

static func conectar(salas: Array[RoomData]) -> void:

	# LIMPIAR

	for sala in salas:

		sala.vecinos.clear()

		sala.arriba = -1
		sala.abajo = -1
		sala.izquierda = -1
		sala.derecha = -1

		sala.puerta_arriba = false
		sala.puerta_abajo = false
		sala.puerta_izquierda = false
		sala.puerta_derecha = false

		sala.terminal_arriba = false
		sala.terminal_abajo = false
		sala.terminal_izquierda = false
		sala.terminal_derecha = false


	# CONECTAR PADRES

	for i in range(salas.size()):

		var padre: int = salas[i].padre


		if padre == -1:
			continue


		# Seguridad
		if padre < 0 or padre >= salas.size():
			continue


		# COMPROBAR LÍMITES

		if salas[padre].vecinos.size() >= MAX_PUERTAS:
			print(
				"⚠️ La sala ",
				padre,
				" ya tiene 3 conexiones."
			)

			continue


		if salas[i].vecinos.size() >= MAX_PUERTAS:
			continue


		# CONECTAR

		_conectar_dos_salas(
			salas,
			padre,
			i
		)


	# COMPROBAR SALIDA

	verificar_salida(salas)


# VERIFICAR SALIDA

static func verificar_salida(
	salas: Array[RoomData]
) -> void:

	var salida: int = -1


	for i in range(salas.size()):

		if salas[i].tipo == RoomData.TipoSala.SALIDA:

			salida = i
			break


	if salida == -1:
		return


	var conexiones: int = salas[salida].vecinos.size()


	if conexiones == 2:

		print(
			"✅ SALIDA correctamente conectada. Vecinos: ",
			salas[salida].vecinos
		)

	else:

		print(
			"⚠️ ERROR: La SALIDA tiene ",
			conexiones,
			" conexiones."
		)


# CONECTAR DOS SALAS

static func _conectar_dos_salas(
	salas: Array[RoomData],
	a: int,
	b: int
) -> void:

	# YA CONECTADAS

	if salas[a].vecinos.has(b):
		return


	# LÍMITES

	if salas[a].vecinos.size() >= MAX_PUERTAS:
		return


	if salas[b].vecinos.size() >= MAX_PUERTAS:
		return


	# COMPROBAR QUE SON ADYACENTES

	var diferencia: Vector2i = (
		salas[b].posicion -
		salas[a].posicion
	)


	if abs(diferencia.x) + abs(diferencia.y) != 1:

		print(
			"⚠️ Intento de conectar salas no adyacentes: ",
			a,
			" -> ",
			b
		)

		return


	# AÑADIR VECINOS

	salas[a].vecinos.append(b)
	salas[b].vecinos.append(a)


	# DIRECCIÓN

	var tiene_terminal: bool = randf() < PROBABILIDAD_TERMINAL

	match diferencia:


		# ARRIBA

		Vector2i.UP:

			salas[a].arriba = b
			salas[b].abajo = a

			salas[a].puerta_arriba = true
			salas[b].puerta_abajo = true

			salas[a].terminal_arriba = tiene_terminal
			salas[b].terminal_abajo = tiene_terminal


		# ABAJO

		Vector2i.DOWN:

			salas[a].abajo = b
			salas[b].arriba = a

			salas[a].puerta_abajo = true
			salas[b].puerta_arriba = true

			salas[a].terminal_abajo = tiene_terminal
			salas[b].terminal_arriba = tiene_terminal


		# IZQUIERDA

		Vector2i.LEFT:

			salas[a].izquierda = b
			salas[b].derecha = a

			salas[a].puerta_izquierda = true
			salas[b].puerta_derecha = true

			salas[a].terminal_izquierda = tiene_terminal
			salas[b].terminal_derecha = tiene_terminal


		# DERECHA

		Vector2i.RIGHT:

			salas[a].derecha = b
			salas[b].izquierda = a

			salas[a].puerta_derecha = true
			salas[b].puerta_izquierda = true

			salas[a].terminal_derecha = tiene_terminal
			salas[b].terminal_izquierda = tiene_terminal
