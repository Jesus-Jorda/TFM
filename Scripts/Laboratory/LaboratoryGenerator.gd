extends Node

class_name LaboratoryGenerator

const PROBABILIDAD_PANEL := 0.85
const PROBABILIDAD_LASER := 0.75

static func generar(numero_salas: int) -> LaboratoryData:

	randomize()

	var laboratorio := LaboratoryData.new()

	laboratorio.numero_salas = numero_salas


	# SALA INICIAL

	laboratorio.salas.append(
		crear_sala(RoomData.TipoSala.INICIO)
	)


	# SALAS INTERMEDIAS

	var cantidades := generar_reparto(numero_salas)

	for tipo in cantidades:

		laboratorio.salas.append(
			crear_sala(tipo)
		)


	# CONTROL

	laboratorio.salas.append(
		crear_sala(RoomData.TipoSala.CONTROL)
	)


	# SALIDA

	laboratorio.salas.append(
		crear_sala(RoomData.TipoSala.SALIDA)
	)


	# COLOCAR LAS SALAS

	LaboratoryPlacer.colocar(
		laboratorio.salas
	)


	# CONECTAR LAS SALAS

	LaboratoryConnector.conectar(
		laboratorio.salas
	)

	# CALCULAR DISTANCIAS

	LaboratoryTypeGenerator.calcular_distancias(
		laboratorio.salas
	)

	# Los conductos se asignan por parejas en salas distintas:
	# nunca puede existir un punto de teletransporte sin otro conectado.
	ObjectGenerator.asignar_parejas_conductos(
		laboratorio.salas
	)


	# NUMERAR TERMINALES DE LA PARTIDA

	TerminalGenerator.asignar_numeros(
		laboratorio.salas
	)


	# PUERTAS DE MECANISMO (PANEL ELÉCTRICO)
	# Algunas puertas sin terminal pasan a bloquearse
	# con un mecanismo: se abren resolviendo el puzle
	# de cables del panel eléctrico de su sala.

	_asignar_paneles(
		laboratorio.salas
	)

	# PUERTAS DE MECANISMO (PUZZLE LÁSER)
	# Algunas puertas sin terminal que no tengan ya mecanismo
	# de panel pasan a bloquearse con un puzzle láser: se abren
	# alineando el haz con el receptor.

	_assignar_lasers(
		laboratorio.salas
	)

	_asegurar_tamano_salas_laser(laboratorio.salas)

	# Seguridad final: cualquier puerta sin terminal que
	# quede cerrada sin mecanismo debe forzarse a un mecanismo
	# resoluble para que no haya bloqueos imposibles.
	_garantizar_puertas_abiertas_o_mecanismo(laboratorio.salas)

	return laboratorio


# ASIGNAR PUERTAS DE PANEL ELÉCTRICO

static func _asignar_paneles(
	salas: Array[RoomData]
) -> void:

	var direcciones := [
		"arriba", "abajo", "izquierda", "derecha"
	]

	for sala_indice in range(salas.size()):

		var sala: RoomData = salas[sala_indice]
		if sala.tipo == RoomData.TipoSala.SALIDA:
			continue

		# Solo de vez en cuando hay mecanismo
		if randf() > PROBABILIDAD_PANEL:
			continue

		var candidatas: Array[String] = []

		for direccion in direcciones:

			var hay_puerta: bool = false
			var con_terminal: bool = false
			var vecina_indice: int = -1
			var direccion_vecina: String = ""

			match direccion:
				"arriba":
					hay_puerta = sala.puerta_arriba
					con_terminal = sala.terminal_arriba
					vecina_indice = sala.arriba
					direccion_vecina = "abajo"

				"abajo":
					hay_puerta = sala.puerta_abajo
					con_terminal = sala.terminal_abajo
					vecina_indice = sala.abajo
					direccion_vecina = "arriba"

				"izquierda":
					hay_puerta = sala.puerta_izquierda
					con_terminal = sala.terminal_izquierda
					vecina_indice = sala.izquierda
					direccion_vecina = "derecha"

				"derecha":
					hay_puerta = sala.puerta_derecha
					con_terminal = sala.terminal_derecha
					vecina_indice = sala.derecha
					direccion_vecina = "izquierda"

			# Puerta sin terminal = candidata a mecanismo
			if not hay_puerta or con_terminal:
				continue

			# La sala vecina debe existir
			if vecina_indice < 0 or vecina_indice >= salas.size():
				continue

			var vecina: RoomData = salas[vecina_indice]
			if vecina.tipo == RoomData.TipoSala.SALIDA:
				continue

			# El mecanismo se coloca en el lado más cercano al inicio.
			# Así el jugador puede resolverlo antes de avanzar hacia la salida.
			if sala.distancia_inicio >= vecina.distancia_inicio:
				continue

			# La puerta no puede estar ya bloqueada por
			# otro mecanismo (el de la vecina o el de
			# otra sala conectada a ella).
			# La sala inicial y la de tránsito siempre deben
			# seguir siendo accesibles.
			if vecina.tipo == RoomData.TipoSala.INICIO:
				continue
			if vecina.panel_puerta == direccion_vecina:
				continue
			if vecina.panel_puerta_vecina == direccion_vecina:
				continue
			if sala.panel_puerta_vecina == direccion:
				continue

			candidatas.append(direccion)

		if candidatas.is_empty():
			continue

		sala.panel_puerta = candidatas.pick_random()

		# MARCAR LA PUERTA EN LA SALA VECINA
		# Es la misma puerta física vista desde el otro
		# lado: también nace cerrada hasta que se resuelva
		# el panel eléctrico.
		var direccion_elegida: String = sala.panel_puerta
		var vecina_indice: int = -1
		var direccion_vecina: String = ""

		match direccion_elegida:
			"arriba":
				vecina_indice = sala.arriba
				direccion_vecina = "abajo"
			"abajo":
				vecina_indice = sala.abajo
				direccion_vecina = "arriba"
			"izquierda":
				vecina_indice = sala.izquierda
				direccion_vecina = "derecha"
			"derecha":
				vecina_indice = sala.derecha
				direccion_vecina = "izquierda"

		if vecina_indice >= 0 and vecina_indice < salas.size():
			if salas[vecina_indice].tipo != RoomData.TipoSala.INICIO:
				salas[vecina_indice].panel_puerta_vecina = direccion_vecina

		print(
			"⚙️ Mecanismo en sala (puerta ",
			sala.panel_puerta,
			"): se abre con el panel eléctrico"
		)


# ASIGNAR PUERTAS DE PUZZLE LÁSER
# Algunas puertas sin terminal que no tengan ya mecanismo
# de panel pasan a bloquearse con un puzzle láser: se abren
# alineando el haz con el receptor.

static func _assignar_lasers(
	salas: Array[RoomData]
) -> void:

	var direcciones := [
		"arriba", "abajo", "izquierda", "derecha"
	]

	for sala_indice in range(salas.size()):

		var sala: RoomData = salas[sala_indice]

		# Solo de vez en cuando hay mecanismo láser
		if randf() > PROBABILIDAD_LASER:
			continue

		var candidatas: Array[String] = []

		for direccion in direcciones:

			var hay_puerta: bool = false
			var con_terminal: bool = false
			var vecina_indice: int = -1
			var direccion_vecina: String = ""

			match direccion:
				"arriba":
					hay_puerta = sala.puerta_arriba
					con_terminal = sala.terminal_arriba
					vecina_indice = sala.arriba
					direccion_vecina = "abajo"
				"abajo":
					hay_puerta = sala.puerta_abajo
					con_terminal = sala.terminal_abajo
					vecina_indice = sala.abajo
					direccion_vecina = "arriba"
				"izquierda":
					hay_puerta = sala.puerta_izquierda
					con_terminal = sala.terminal_izquierda
					vecina_indice = sala.izquierda
					direccion_vecina = "derecha"
				"derecha":
					hay_puerta = sala.puerta_derecha
					con_terminal = sala.terminal_derecha
					vecina_indice = sala.derecha
					direccion_vecina = "izquierda"

			# Puerta sin terminal = candidata
			if not hay_puerta or con_terminal:
				continue

			# La sala vecina debe existir
			if vecina_indice < 0 or vecina_indice >= salas.size():
				continue

			var vecina: RoomData = salas[vecina_indice]

			# El mecanismo se coloca en el lado más cercano al inicio.
			# Así el jugador puede resolverlo antes de avanzar hacia la salida.
			if sala.distancia_inicio >= vecina.distancia_inicio:
				continue

			# No puede estar ya bloqueada por panel o láser
			# y la sala inicial nunca debe recibir un bloqueo
			# de mecanismo sin solución.
			if vecina.tipo == RoomData.TipoSala.INICIO:
				continue
			if vecina.panel_puerta == direccion_vecina:
				continue
			if vecina.panel_puerta_vecina == direccion_vecina:
				continue
			if sala.panel_puerta_vecina == direccion:
				continue
			if sala.laser_puerta == direccion:
				continue
			if vecina.laser_puerta == direccion_vecina:
				continue
			if vecina.laser_puerta_vecina == direccion_vecina:
				continue
			if sala.laser_puerta_vecina == direccion:
				continue

			candidatas.append(direccion)

		if candidatas.is_empty():
			continue

		sala.laser_puerta = candidatas.pick_random()

		# Marcar la puerta en la sala vecina
		var direccion_elegida: String = sala.laser_puerta
		var vecina_indice: int = -1
		var direccion_vecina: String = ""

		match direccion_elegida:
			"arriba":
				vecina_indice = sala.arriba
				direccion_vecina = "abajo"
			"abajo":
				vecina_indice = sala.abajo
				direccion_vecina = "arriba"
			"izquierda":
				vecina_indice = sala.izquierda
				direccion_vecina = "derecha"
			"derecha":
				vecina_indice = sala.derecha
				direccion_vecina = "izquierda"

		if vecina_indice >= 0 and vecina_indice < salas.size():
			if salas[vecina_indice].tipo != RoomData.TipoSala.INICIO:
				salas[vecina_indice].laser_puerta_vecina = direccion_vecina

		print(
			"🔦 Mecanismo láser en sala (puerta ",
			sala.laser_puerta,
			"): se abre alineando el haz"
		)


static func _asegurar_tamano_salas_laser(salas: Array[RoomData]) -> void:
	for sala in salas:
		if sala.tipo == RoomData.TipoSala.SALIDA:
			sala.laser_puerta = ""
			sala.laser_puerta_vecina = ""
			sala.laser_resuelto = false
			sala.laser_resuelto_vecina = false
			continue
		if sala.laser_puerta == "":
			continue
		sala.ancho = maxi(sala.ancho, 12)
		sala.alto = maxi(sala.alto, 10)


static func _direccion_segura_inicio(salas: Array[RoomData]) -> String:
	if salas.is_empty():
		return ""

	var inicio: RoomData = salas[0]
	if inicio.puerta_arriba:
		return "arriba"
	if inicio.puerta_abajo:
		return "abajo"
	if inicio.puerta_izquierda:
		return "izquierda"
	if inicio.puerta_derecha:
		return "derecha"
	return ""


static func _garantizar_puerta_libre_inicio(salas: Array[RoomData]) -> void:
	if salas.is_empty():
		return

	var inicio: RoomData = salas[0]
	var direccion := _direccion_segura_inicio(salas)
	if direccion == "":
		return

	match direccion:
		"arriba":
			inicio.terminal_arriba = false
			if inicio.arriba >= 0:
				salas[inicio.arriba].terminal_abajo = false
		"abajo":
			inicio.terminal_abajo = false
			if inicio.abajo >= 0:
				salas[inicio.abajo].terminal_arriba = false
		"izquierda":
			inicio.terminal_izquierda = false
			if inicio.izquierda >= 0:
				salas[inicio.izquierda].terminal_derecha = false
		"derecha":
			inicio.terminal_derecha = false
			if inicio.derecha >= 0:
				salas[inicio.derecha].terminal_izquierda = false


static func _garantizar_puertas_abiertas_o_mecanismo(salas: Array[RoomData]) -> void:
	var direcciones := ["arriba", "abajo", "izquierda", "derecha"]

	for sala in salas:
		for direccion in direcciones:
			var hay_puerta: bool = false
			var con_terminal: bool = false
			var vecina_indice: int = -1
			var es_puerta_cerrada: bool = false

			match direccion:
				"arriba":
					hay_puerta = sala.puerta_arriba
					con_terminal = sala.terminal_arriba
					vecina_indice = sala.arriba
					es_puerta_cerrada = sala.panel_puerta == "arriba" or sala.laser_puerta == "arriba"
				"abajo":
					hay_puerta = sala.puerta_abajo
					con_terminal = sala.terminal_abajo
					vecina_indice = sala.abajo
					es_puerta_cerrada = sala.panel_puerta == "abajo" or sala.laser_puerta == "abajo"
				"izquierda":
					hay_puerta = sala.puerta_izquierda
					con_terminal = sala.terminal_izquierda
					vecina_indice = sala.izquierda
					es_puerta_cerrada = sala.panel_puerta == "izquierda" or sala.laser_puerta == "izquierda"
				"derecha":
					hay_puerta = sala.puerta_derecha
					con_terminal = sala.terminal_derecha
					vecina_indice = sala.derecha
					es_puerta_cerrada = sala.panel_puerta == "derecha" or sala.laser_puerta == "derecha"

			if not hay_puerta:
				continue
			if con_terminal:
				continue
			if es_puerta_cerrada:
				continue

			# Si la puerta es cerrada sin mecanismo, forzamos una solución resoluble.
			if vecina_indice < 0 or vecina_indice >= salas.size():
				continue

			if sala.tipo == RoomData.TipoSala.INICIO:
				continue

			if randf() < 0.5:
				sala.panel_puerta = direccion
				if vecina_indice >= 0 and vecina_indice < salas.size():
					salas[vecina_indice].panel_puerta_vecina = _direccion_opuesta(direccion)
			else:
				sala.laser_puerta = direccion
				if vecina_indice >= 0 and vecina_indice < salas.size():
					salas[vecina_indice].laser_puerta_vecina = _direccion_opuesta(direccion)


static func _direccion_opuesta(direccion: String) -> String:
	match direccion:
		"arriba": return "abajo"
		"abajo": return "arriba"
		"izquierda": return "derecha"
		"derecha": return "izquierda"
	return ""


# GENERAR REPARTO ALEATORIO

static func generar_reparto(numero_salas: int) -> Array:

	var tipos: Array = []

	# Necesitamos:
	# numero_salas
	# - INICIO
	# - CONTROL
	# - SALIDA
	# salas intermedias

	var cantidad_intermedias := numero_salas - 3


	# TIPOS DISPONIBLES

	var tipos_disponibles := [

		RoomData.TipoSala.LABORATORIO,

		RoomData.TipoSala.MAQUINAS,

		RoomData.TipoSala.DESCANSO,

		RoomData.TipoSala.ALMACEN
	]


	# CONTADOR DE CADA TIPO

	var cantidades := {

		RoomData.TipoSala.LABORATORIO: 0,
		RoomData.TipoSala.MAQUINAS: 0,
		RoomData.TipoSala.DESCANSO: 0,
		RoomData.TipoSala.ALMACEN: 0
	}


	# CREAR LAS SALAS

	while tipos.size() < cantidad_intermedias:

		var tipo = tipos_disponibles.pick_random()

		# Máximo 3 de cada tipo
		if cantidades[tipo] >= 3:
			continue

		tipos.append(tipo)

		cantidades[tipo] += 1


	# MEZCLAR EL ORDEN

	tipos.shuffle()


	return tipos


# CREAR SALA

static func crear_sala(
	tipo: RoomData.TipoSala
) -> RoomData:

	var sala := RoomData.new()

	sala.tipo = tipo


	match tipo:

		RoomData.TipoSala.INICIO:

			sala.ancho = 14
			sala.alto = 10


		RoomData.TipoSala.LABORATORIO:

			sala.ancho = randi_range(10, 16)
			sala.alto = randi_range(8, 12)


		RoomData.TipoSala.MAQUINAS:

			sala.ancho = randi_range(12, 18)
			sala.alto = randi_range(10, 14)


		RoomData.TipoSala.ALMACEN:

			sala.ancho = randi_range(8, 12)
			sala.alto = randi_range(8, 10)


		RoomData.TipoSala.DESCANSO:

			sala.ancho = randi_range(8, 12)
			sala.alto = randi_range(6, 8)


		RoomData.TipoSala.CONTROL:

			sala.ancho = 12
			sala.alto = 10


		RoomData.TipoSala.SALIDA:

			sala.ancho = 10
			sala.alto = 8


	# Cada sala tendrá su propia semilla
	sala.seed = randi()


	return sala
