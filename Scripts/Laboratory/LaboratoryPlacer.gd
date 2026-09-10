extends Node

class_name LaboratoryPlacer


const MAX_CONEXIONES := 3


# COLOCAR LABORATORIO

static func colocar(salas: Array[RoomData]) -> void:

	if salas.is_empty():
		return


	# ÍNDICES

	var indice_inicio: int = 0
	var indice_salida: int = salas.size() - 1


	# LIMPIAR

	for sala in salas:

		sala.posicion = Vector2i.ZERO
		sala.padre = -1


	# SALIDA

	salas[indice_salida].posicion = Vector2i.ZERO
	salas[indice_salida].padre = -1


	var ocupadas: Dictionary = {}

	ocupadas[Vector2i.ZERO] = indice_salida


	# CONEXIONES

	var conexiones: Array[int] = []

	for i in range(salas.size()):
		conexiones.append(0)


	# SALAS COLOCADAS

	var colocadas: Array[int] = []

	colocadas.append(indice_salida)


	# RESERVAR POSICIONES ALREDEDOR DE LA SALIDA

	var posiciones_salida: Array[Vector2i] = []

	var direcciones_salida: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	direcciones_salida.shuffle()


	# CREAR LAS 2 RAMAS DE LA SALIDA

	var siguiente_indice: int = 1


	for direccion in direcciones_salida:

		if posiciones_salida.size() >= 2:
			break


		if siguiente_indice >= indice_salida:
			break


		var posicion_nueva: Vector2i = (
			salas[indice_salida].posicion
			+ direccion
		)


		if ocupadas.has(posicion_nueva):
			continue


		# No utilizar INICIO todavía
		if siguiente_indice == indice_inicio:

			siguiente_indice += 1

			if siguiente_indice >= indice_salida:
				break


		var sala_nueva: int = siguiente_indice


		# COLOCAR

		salas[sala_nueva].posicion = posicion_nueva
		salas[sala_nueva].padre = indice_salida


		ocupadas[posicion_nueva] = sala_nueva


		conexiones[indice_salida] += 1
		conexiones[sala_nueva] += 1


		colocadas.append(sala_nueva)

		posiciones_salida.append(posicion_nueva)


		siguiente_indice += 1


	# COMPROBAR SALIDA

	if conexiones[indice_salida] != 2:

		print(
			"⚠️ ERROR: No se pudieron crear las 2 conexiones iniciales de la SALIDA."
		)

		return


	# COLOCAR RESTO

	for i in range(1, indice_salida):

		# Ya colocada
		if colocadas.has(i):
			continue


		# INICIO al final
		if i == indice_inicio:
			continue


		var colocada: bool = false
		var intentos: int = 0


		while !colocada and intentos < 500:

			intentos += 1


			# Elegir una sala colocada
			var origen: int = colocadas.pick_random()


			# La salida queda cerrada
			if origen == indice_salida:
				continue


			# Máximo de conexiones
			if conexiones[origen] >= MAX_CONEXIONES:
				continue


			var direcciones: Array[Vector2i] = [
				Vector2i.UP,
				Vector2i.DOWN,
				Vector2i.LEFT,
				Vector2i.RIGHT
			]

			direcciones.shuffle()


			for direccion in direcciones:

				var destino: Vector2i = (
					salas[origen].posicion
					+ direccion
				)


				# NO PISAR OTRA SALA

				if ocupadas.has(destino):
					continue


				# NO COLOCAR JUNTO A LA SALIDA

				if destino == salas[indice_salida].posicion:
					continue


				# COLOCAR

				salas[i].posicion = destino
				salas[i].padre = origen


				ocupadas[destino] = i


				conexiones[origen] += 1
				conexiones[i] += 1


				colocadas.append(i)


				colocada = true

				break


		# SEGURIDAD

		if !colocada:

			print(
				"⚠️ No se pudo colocar la sala ",
				i
			)


	# COLOCAR INICIO AL FINAL

	var inicio_colocado: bool = false
	var intentos_inicio: int = 0


	while !inicio_colocado and intentos_inicio < 500:

		intentos_inicio += 1


		var origen_inicio: int = colocadas.pick_random()


		# No usar salida
		if origen_inicio == indice_salida:
			continue


		if conexiones[origen_inicio] >= MAX_CONEXIONES:
			continue


		var direcciones_inicio: Array[Vector2i] = [
			Vector2i.UP,
			Vector2i.DOWN,
			Vector2i.LEFT,
			Vector2i.RIGHT
		]

		direcciones_inicio.shuffle()


		for direccion in direcciones_inicio:

			var destino_inicio: Vector2i = (
				salas[origen_inicio].posicion
				+ direccion
			)


			if ocupadas.has(destino_inicio):
				continue


			# COLOCAR INICIO

			salas[indice_inicio].posicion = destino_inicio
			salas[indice_inicio].padre = origen_inicio


			ocupadas[destino_inicio] = indice_inicio


			conexiones[origen_inicio] += 1
			conexiones[indice_inicio] += 1


			inicio_colocado = true

			break


	# COMPROBAR INICIO

	if !inicio_colocado:

		print(
			"⚠️ No se pudo colocar correctamente el INICIO"
		)


	# INFORMACIÓN FINAL

	print(
		"✅ SALIDA creada con ",
		conexiones[indice_salida],
		" conexiones."
	)
