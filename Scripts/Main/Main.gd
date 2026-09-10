extends Node2D


# NODOS

@onready var displayed_room := $DisplayedRoom
@onready var movement_controls: MovementControls = $MovementControls
@onready var room_name: Label = $MovementControls/Control/RoomName
@onready var interaction_manager: InteractionManager = $InteractionManager
@onready var terminal_interface: TerminalInterface = $TerminalLayer/TerminalInterface

@onready var interaction_prompt: Button = (
	$MovementControls/Control/InteractionPrompt
)

# SONIDOS DE PUERTA

const SONIDOS_PUERTA := [
	preload("res://Audio/Doors/puerta1.mp3"),
	preload("res://Audio/Doors/puerta2.mp3"),
	preload("res://Audio/Doors/puerta3.mp3")
]

# LABORATORIO

var laboratorio: LaboratoryData

# JUGADOR

var jugador_data: CharacterData
var jugador: Character

# Personaje elegido en la pantalla de selección
var personaje_actual: CharacterData


# AUDIO

var audio_puertas: AudioStreamPlayer


# SALA ACTUAL

var sala_actual: int = 0


# CONTROL DE TRANSICIÓN

var cambiando_sala := false

var transition_panel: ColorRect
var transition_label: Label


# ROOM ACTUAL

var room_actual: Node2D


# APAGONES (CORTOCIRCUITO DEL ROBOT)
# sala -> segundos que le quedan a oscuras. El estado
# sobrevive a la reconstrucción de las salas: al volver
# a entrar en una sala apagada, sigue a oscuras.
var _apagones: Dictionary = {}


# READY

func _ready():

	randomize()
	add_to_group("main")
	if GameSession.tiempo_inicio_partida_msec <= 0:
		GameSession.tiempo_inicio_partida_msec = Time.get_ticks_msec()

	# GENERAR LABORATORIO

	laboratorio = LaboratoryGenerator.generar(10)


	# INFORMACIÓN

	imprimir_laboratorio()


	# MOSTRAR SALA INICIAL

	_crear_overlay_transicion()
	mostrar_sala(0)


	# CREAR JUGADOR

	crear_jugador()


	# ASIGNAR JUGADOR AL CONTROL TÁCTIL

	movement_controls.asignar_jugador(jugador)

	# ICONOS DE HABILIDAD DEL INVENTARIO (DINÁMICOS)
	# El inventario reconstruye sus iconos a partir de
	# las habilidades del personaje elegido.

	var inventario := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as InventoryManager
	)

	if inventario != null:

		inventario.configurar_habilidades(
			personaje_actual
		)

	# ASIGNAR JUGADOR AL SISTEMA DE INTERACCIÓN

	interaction_manager.asignar_jugador(
		jugador
	)
	interaction_manager.call_deferred(
		"refrescar_para_jugador", jugador
	)

	interaction_manager.asignar_prompt(
		interaction_prompt
	)
	terminal_interface.estado_cambiado.connect(
		_on_terminal_estado_cambiado
	)
	_crear_audio_puertas()


# MOSTRAR SALA

func mostrar_sala(indice: int, ocultar_nombre: bool = true):
	_cerrar_puzzles_antes_de_reconstruir()

	# Al abandonar una sala se materializan las reposiciones pendientes.
	# La sala conserva sus datos aunque deje de estar visible.
	if laboratorio != null and sala_actual >= 0 \
			and sala_actual < laboratorio.salas.size() \
			and sala_actual != indice:
		ObjectGenerator.reponer_objetos_marcados(
			laboratorio.salas[sala_actual]
		)

	# DATOS DE LA SALA

	sala_actual = indice

	var sala = laboratorio.salas[indice]

	# NOMBRE DE LA SALA

	room_name.text = RoomData.TipoSala.keys()[sala.tipo]
	room_name.visible = true

	if ocultar_nombre:
		room_name.modulate = Color(1, 1, 1, 0)

	# PRESERVAR TODOS LOS PERSONAJES
	# Solo se muestra la sala activa, pero los personajes de
	# otras salas siguen vivos y conservan su posición lógica.
	for jugador_partida in jugadores_partida:
		if jugador_partida != null and is_instance_valid(jugador_partida) \
				and jugador_partida.get_parent() == displayed_room:
			displayed_room.remove_child(jugador_partida)


	# BORRAR ROOM ANTERIOR

	for hijo in displayed_room.get_children():
		if hijo not in jugadores_partida:
			hijo.queue_free()


	# CREAR NUEVO ROOM

	var escena = preload(
		"res://Scenes/Rooms/Room.tscn"
	)

	room_actual = escena.instantiate()

	displayed_room.add_child(room_actual)


	# ¿Vino una vibración de un golpe de suelo en una sala
	# vecina? (RoomBuilder limpia la marca al desordenar
	# los puzzles de esta sala.)
	var vibracion_pendiente: bool = sala.vibracion_pendiente


	# CONSTRUIR SALA

	RoomBuilder.construir(
		room_actual,
		sala,
		laboratorio
	)

	if vibracion_pendiente:
		_tiemblar_camara_vibracion()


	# SALA ACTUAL PARA INTERACCIONES E INVENTARIO

	interaction_manager.sala_actual = room_actual

	var inv := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as InventoryManager
	)

	if inv:
		inv.sala_actual = room_actual


	# VOLVER A AÑADIR PERSONAJES PRESENTES EN ESTA SALA
	for jugador_partida in jugadores_partida:
		if jugador_partida == null or not is_instance_valid(jugador_partida):
			continue
		if jugador_partida.sala_actual_idx != sala_actual:
			continue
		displayed_room.add_child(jugador_partida)

	if interaction_manager != null and jugador != null:
		interaction_manager.call_deferred(
			"refrescar_para_jugador", jugador
		)


	# CONECTAR PUERTAS

	conectar_puertas()


	# APAGÓN (CORTOCIRCUITO DEL ROBOT)
	# Si esta sala está en apagón, aplicarlo también al
	# reconstruirla (y encender la luz del jugador).

	_aplicar_apagon_sala(sala_actual)


func _cerrar_puzzles_antes_de_reconstruir() -> void:
	for nodo in get_tree().get_nodes_in_group("puzzle_cables"):
		if nodo is PuzzleCables:
			var puzzle := nodo as PuzzleCables
			if puzzle.abierto:
				puzzle.cerrar()
			else:
				puzzle.visible = false
			puzzle.queue_free()

	for nodo in get_tree().get_nodes_in_group("paneles_electricos"):
		if nodo is PanelElectrico:
			var panel := nodo as PanelElectrico
			panel.cerrar_puzzle_por_turno()


func reponer_objetos_al_cambiar_turno() -> void:
	if laboratorio == null:
		return

	var sala_actual_reconstruida: bool = false
	for indice in range(laboratorio.salas.size()):
		var sala: RoomData = laboratorio.salas[indice]
		if ObjectGenerator.reponer_objetos_marcados(sala):
			if indice == sala_actual:
				sala_actual_reconstruida = true

	if sala_actual_reconstruida and room_actual != null:
		mostrar_sala(sala_actual, true)


func obtener_salas_adyacentes_a_actual() -> Array[int]:

	var salas_afectadas: Array[int] = []

	if laboratorio == null:
		return salas_afectadas

	if sala_actual < 0 or sala_actual >= laboratorio.salas.size():
		return salas_afectadas

	salas_afectadas.append(sala_actual)

	var sala_actual_data: RoomData = laboratorio.salas[sala_actual]

	for vecino in sala_actual_data.vecinos:
		if not salas_afectadas.has(vecino):
			salas_afectadas.append(vecino)

	return salas_afectadas


# APAGÓN POR SALA (CORTOCIRCUITO DEL ROBOT)

func _process(delta: float) -> void:

	if _apagones.is_empty():

		return

	var expirados: Array = []

	for clave in _apagones.keys():

		_apagones[clave] = max(
			0.0, float(_apagones[clave]) - delta
		)

		if float(_apagones[clave]) <= 0.0:

			expirados.append(clave)

	for clave in expirados:

		_apagones.erase(clave)

		if clave == sala_actual:

			_aplicar_apagon_sala(clave)


# Enciende un apagón en la sala actual (lo llama el
# robot con su cortocircuito).
func activar_apagon_sala_actual(duracion: float) -> void:

	_apagones[sala_actual] = duracion

	_aplicar_apagon_sala(sala_actual)


# ¿Está la sala mostrada ahora mismo en apagón?
# La consultan los objetos eléctricos (terminales,
# paneles de cables, láseres) para desactivarse.
func sala_actual_en_apagon() -> bool:

	return (
		_apagones.has(sala_actual)
		and float(_apagones[sala_actual]) > 0.0
	)


# Aplica o retira la oscuridad de la sala mostrada.
func _aplicar_apagon_sala(indice: int) -> void:

	if room_actual == null or indice != sala_actual:

		return

	var activo: bool = (
		_apagones.has(indice)
		and float(_apagones[indice]) > 0.0
	)

	var modulacion := (
		room_actual.get_node_or_null("ApagonModulate")
		as CanvasModulate
	)

	if activo and modulacion == null:

		modulacion = CanvasModulate.new()

		modulacion.name = "ApagonModulate"

		# Casi negro total: sin luz no se ve nada de la
		# sala (antes quedaba demasiado translúcido).
		modulacion.color = Color(0.01, 0.01, 0.02)

		room_actual.add_child(modulacion)

	elif not activo and modulacion != null:

		modulacion.queue_free()

	# La luz alrededor del jugador se enciende o apaga.
	for jugador_partida in jugadores_partida:
		if jugador_partida == null or not is_instance_valid(jugador_partida):
			continue
		if jugador_partida.sala_actual_idx != indice:
			continue
		if jugador_partida.has_method("establecer_apagon"):
			jugador_partida.establecer_apagon(
				activo and jugador_partida == jugador
			)

	# TERMINALES: SIN ENERGÍA DURANTE EL APAGÓN
	# Con el apagón activo, los terminales con batería
	# se comportan como apagados (y se ven apagados).
	# Al terminar, recuperan su energía guardada.

	var terminales := room_actual.get_node_or_null(
		"Terminals"
	)

	if terminales != null:

		for hijo in terminales.get_children():

			if activo and hijo.has_method("apagar_por_apagon"):

				hijo.apagar_por_apagon()

			elif not activo and hijo.has_method(
				"reactivar_tras_apagon"
			):

				hijo.reactivar_tras_apagon()


# MARCAR VIBRACIÓN EN UNA SALA (GOLPE DE SUELO)
# Guarda en los datos de la sala que una vibración la
# sacudió: al construirla sus puzzles aparecen
# desordenados (RoomBuilder) y la cámara tiembla al
# entrar (mostrar_sala).

func marcar_vibracion_sala(indice: int) -> void:

	if laboratorio == null:
		return

	if indice < 0 or indice >= laboratorio.salas.size():
		return

	laboratorio.salas[indice].vibracion_pendiente = true


# TEMBLOR DE CÁMARA POR VIBRACIÓN

func _tiemblar_camara_vibracion() -> void:

	# Pequeña espera para que el temblor se aprecie
	# cuando termina el fundido de la transición.
	await get_tree().create_timer(0.8).timeout

	if jugador == null or not is_instance_valid(jugador):
		return

	if jugador.has_method("sacudir_camara"):
		jugador.sacudir_camara(8.0, 0.7)


# PREPARAR OVERLAY DE TRANSICIÓN

# CREAR TRANSICIÓN

func _crear_overlay_transicion() -> void:

	if transition_panel and is_instance_valid(transition_panel):
		return


	# PANEL NEGRO

	transition_panel = ColorRect.new()

	transition_panel.name = "TransitionPanel"

	transition_panel.color = Color(0, 0, 0, 0)

	transition_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	transition_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	transition_panel.z_index = 200


	movement_controls.add_child(transition_panel)


	# NOMBRE DE LA SALA

	transition_label = Label.new()

	transition_label.name = "TransitionLabel"

	transition_label.text = ""

	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	transition_label.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	transition_label.add_theme_font_size_override(
		"font_size",
		48
	)

	transition_label.modulate = Color(1, 1, 1, 0)

	transition_label.z_index = 1


	transition_panel.add_child(transition_label)
# CREAR AUDIO DE PUERTAS

func _crear_audio_puertas() -> void:

	if audio_puertas and is_instance_valid(audio_puertas):
		return

	audio_puertas = AudioStreamPlayer.new()
	audio_puertas.name = "DoorAudio"
	audio_puertas.bus = "Efectos"
	add_child(audio_puertas)


# REPRODUCIR SONIDO DE PUERTA

func _reproducir_sonido_puerta() -> void:

	if SONIDOS_PUERTA.is_empty():
		return

	_crear_audio_puertas()

	var sonido: AudioStream = SONIDOS_PUERTA.pick_random()
	audio_puertas.stream = sonido
	audio_puertas.play()


# MOSTRAR NOMBRE DE SALA


# CREAR JUGADOR

# Todos los personajes de la partida (hot-seat).
var jugadores_partida: Array = []


func crear_jugador():

	# PERSONAJES DE LA PARTIDA
	# Vienen de la pantalla de selección (autoload
	# GameSession): uno por jugador, en orden. Sin
	# selección válida se usa el primer personaje.

	var datos_jugadores: Array = (
		GameSession.personajes_en_juego()
	)

	if datos_jugadores.is_empty():

		var datos_solo := GameSession.personaje_actual()

		if datos_solo == null:

			datos_solo = CatalogoPersonajes.por_indice(0)

		if datos_solo != null:

			datos_jugadores.append(datos_solo)

	if datos_jugadores.is_empty():

		push_error("No hay personajes para crear jugadores")

		return

	# CREAR UN PERSONAJE POR JUGADOR

	jugadores_partida = []

	var sala = laboratorio.salas[0]

	for datos_j in datos_jugadores:

		# ESCENA DEL PERSONAJE

		var escena_personaje: PackedScene = (
			datos_j.escena
		)

		if escena_personaje == null:

			push_error(
				"El personaje " + datos_j.id
				+ " no tiene escena asignada"
			)

			continue

		var nuevo = escena_personaje.instantiate()

		# Las habilidades viajan con los datos del
		# personaje: Character las guarda y la interfaz
		# las consulta.
		nuevo.configurar_habilidades(
			datos_j.habilidades
		)

		# AÑADIR Y POSICIÓN INICIAL

		displayed_room.add_child(nuevo)

		nuevo.position = _buscar_spawn_inicial_libre(
			sala, nuevo
		)

		nuevo.establecer_sala_actual(0)

		# Solo el jugador 1 controla al principio; el
		# gestor de turnos irá repartiendo el control.
		nuevo.movimiento_bloqueado = (
			jugadores_partida.size() > 0
		)

		jugadores_partida.append(nuevo)

	if jugadores_partida.is_empty():

		return

	# Los personajes no deben empujarse ni engancharse entre sí.
	# Mantienen la colisión con paredes y objetos del laboratorio.
	for i in range(jugadores_partida.size()):
		for j in range(i + 1, jugadores_partida.size()):
			var jugador_a := jugadores_partida[i] as CharacterBody2D
			var jugador_b := jugadores_partida[j] as CharacterBody2D
			if jugador_a != null and jugador_b != null:
				jugador_a.add_collision_exception_with(jugador_b)
				jugador_b.add_collision_exception_with(jugador_a)

	# COMPATIBILIDAD CON EL RESTO DE MAIN
	# `jugador` apunta al jugador 1 (primer turno).

	jugador = jugadores_partida[0]

	personaje_actual = datos_jugadores[0]

	jugador_data = CharacterData.new()

	jugador_data.id = personaje_actual.id

	jugador_data.nombre = personaje_actual.nombre

	_crear_gestor_turnos()


# GESTOR DE TURNOS (HOT-SEAT)

func _crear_gestor_turnos() -> void:

	# Con un solo jugador no hay turnos ni HUD.
	if jugadores_partida.size() < 2:

		return

	# Preload explicito: no depende de la cache de
	# clases globales del editor.
	var gestor_script: GDScript = preload(
		"res://Scripts/Main/GestorTurnos.gd"
	)

	var gestor: Node = gestor_script.new()

	add_child(gestor)

	gestor.configurar(
		jugadores_partida,
		movement_controls,
		interaction_manager,
		get_tree().get_first_node_in_group("inventory_manager") as InventoryManager
	)


func _buscar_spawn_inicial_libre(
	sala: RoomData,
	excluir: Node2D = null
) -> Vector2:

	var forma := RectangleShape2D.new()
	forma.size = Vector2(62, 82)

	var candidatos: Array[Vector2] = []
	var centro := Vector2(
		(sala.ancho + 1) * sala.tam_celda / 2.0,
		(sala.alto + 1) * sala.tam_celda / 2.0
	)
	candidatos.append(centro)

	for y in range(2, max(3, sala.alto - 1)):
		for x in range(2, max(3, sala.ancho - 1)):
			candidatos.append(Vector2(
				(x + 1) * sala.tam_celda,
				(y + 1) * sala.tam_celda
			))

	var espacio := get_world_2d().direct_space_state
	var spawn_lateral := Vector2(
		3.0 * sala.tam_celda,
		(sala.alto / 2.0 + 1.0) * sala.tam_celda
	)
	candidatos.push_front(spawn_lateral)

	# Excluir de la consulta SOLO al personaje que se
	# está colocando (ya está en el árbol y su propio
	# cuerpo bloquearía todas las casillas). Los demás
	# jugadores SÍ son obstáculos: nadie nace encima
	# de nadie.
	var excluidos: Array[RID] = []

	if excluir != null:
		excluidos.append(excluir.get_rid())

	for candidato in candidatos:
		# Doble seguro (hot-seat): separación mínima
		# respecto a los jugadores ya colocados, por si
		# su cuerpo aún no está registrado en la física
		# en este mismo frame.
		var ocupado := false

		for j in jugadores_partida:
			if j != null and j != excluir:
				if candidato.distance_to(
						j.position) < 90.0:
					ocupado = true
					break

		if ocupado:
			continue

		var consulta := PhysicsShapeQueryParameters2D.new()
		consulta.shape = forma
		consulta.transform = Transform2D(
			0.0,
			candidato + Vector2(22, -1)
		)
		consulta.collision_mask = 1
		consulta.collide_with_bodies = true
		consulta.exclude = excluidos

		if espacio.intersect_shape(consulta, 1).is_empty():
			return candidato

	push_warning("No se encontró un spawn libre; usando el lateral izquierdo.")
	return spawn_lateral


# CONECTAR PUERTAS

func conectar_puertas():

	if room_actual == null:

		return


	var doors = room_actual.get_node_or_null("Doors")

	if doors == null:

		print("ERROR: No se encontró Doors en Room")

		return


	# RECORRER TODAS LAS PUERTAS

	for hijo in doors.get_children():

		if hijo is Door:

			var puerta: Door = hijo


			# Evitar conectar dos veces

			if not puerta.body_entered.is_connected(
				_puerta_activada
			):

				puerta.body_entered.connect(
					_puerta_activada.bind(puerta)
				)


			print(
				"Puerta conectada: ",
				puerta.name,
				" -> Sala ",
				puerta.sala_destino
			)


# PUERTA ACTIVADA

func _puerta_activada(
	body: Node2D,
	puerta: Door
):

	# COMPROBAR JUGADOR

	if body != jugador:
		return


	# EVITAR DOBLE ACTIVACIÓN

	if cambiando_sala:
		return


	# COMPROBAR PUERTA

	if puerta.bloqueada:
		return

	if puerta.cerrada:
		return

	if puerta.sala_destino == -1:
		return


	# ACTIVAR TRANSICIÓN

	cambiando_sala = true


	var destino: int = puerta.sala_destino
	var direccion_entrada: String = puerta.direccion
	var sala_destino: RoomData = laboratorio.salas[destino]

	var nombre_destino: String = (
		RoomData.TipoSala.keys()[sala_destino.tipo]
	)


	print(
		"Entrando por ",
		puerta.name,
		" -> Sala ",
		destino
	)


	# PARAR JUGADOR

	if jugador and is_instance_valid(jugador):

		jugador.direccion_tactil = Vector2.ZERO
		jugador.velocity = Vector2.ZERO


	# ASEGURAR TRANSICIÓN

	_crear_overlay_transicion()


	# CONFIGURAR NOMBRE

	transition_label.text = nombre_destino

	transition_label.modulate = Color(
		1,
		1,
		1,
		0
	)

	transition_label.visible = true

	transition_panel.visible = true


	# ASEGURAR ESTADO INICIAL

	transition_panel.color = Color(
		0,
		0,
		0,
		0
	)


	# CREAR TWEEN

	var tween := create_tween()

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)


	# 1. FUNDIDO A NEGRO
	# 0.45 SEGUNDOS

	tween.tween_property(
		transition_panel,
		"color",
		Color(0, 0, 0, 1),
		0.45
	)


	# 2. APARECER NOMBRE
	# 0.25 SEGUNDOS

	tween.tween_property(
		transition_label,
		"modulate",
		Color(1, 1, 1, 1),
		0.25
	)


	# 3. MANTENER NOMBRE
	# 0.75 SEGUNDOS

	tween.tween_interval(0.75)


	# 4. CAMBIAR DE SALA

	tween.tween_callback(func():
		jugador.establecer_sala_actual(destino)

		mostrar_sala(
			destino,
			true
		)

		call_deferred(
			"_colocar_jugador_tras_reconstruir",
			sala_destino,
			direccion_entrada
		)

	)


	# 5. MANTENER NEGRO
	# 0.20 SEGUNDOS

	tween.tween_interval(0.20)


	# 6. DESAPARECER NOMBRE
	# 0.20 SEGUNDOS

	tween.tween_property(
		transition_label,
		"modulate",
		Color(1, 1, 1, 0),
		0.20
	)


	# 7. VOLVER A MOSTRAR SALA
	# 0.45 SEGUNDOS

	tween.tween_property(
		transition_panel,
		"color",
		Color(0, 0, 0, 0),
		0.45
	)


	# ESPERAR

	await tween.finished


	# LIMPIAR

	transition_label.text = ""

	transition_label.visible = false

	transition_panel.visible = false

	transition_panel.color = Color(
		0,
		0,
		0,
		0
	)


	transition_label.modulate = Color(
		1,
		1,
		1,
		0
	)


	# FIN DE TRANSICIÓN

	cambiando_sala = false


func _colocar_jugador_tras_reconstruir(
	sala: RoomData,
	direccion_entrada: String
) -> void:
	await get_tree().physics_frame
	if jugador == null or not is_instance_valid(jugador):
		return
	colocar_jugador_en_entrada(sala, direccion_entrada)


# COLOCAR JUGADOR EN LA NUEVA SALA

func colocar_jugador_en_entrada(
	sala: RoomData,
	direccion_entrada: String
):
	var indice_sala: int = laboratorio.salas.find(sala)
	if indice_sala < 0:
		indice_sala = sala_actual

	var posicion_entrada: Vector2 = posicion_entrada_sala(
		indice_sala,
		direccion_entrada
	)
	jugador.position = posicion_entrada

	# Mantener el personaje dentro del rectángulo jugable y
	# dejar espacio para su collider al aparecer junto a la puerta.
	var margen := 36.0
	var celda := sala.tam_celda
	jugador.position.x = clampf(
		jugador.position.x,
		celda + margen,
		(sala.ancho + 1) * celda - margen
	)
	jugador.position.y = clampf(
		jugador.position.y,
		celda + margen,
		(sala.alto + 1) * celda - margen
	)

	if _entrada_ocupada(jugador.position, jugador):
		jugador.position = _buscar_spawn_central_libre(sala, jugador)

	# Evitar solapamiento con otros personajes que ya estaban en esta sala.
	for otro in jugadores_partida:
		if otro == null or not is_instance_valid(otro) or otro == jugador:
			continue
		if otro.sala_actual_idx != sala_actual:
			continue
		if otro.position.distance_to(jugador.position) < 72.0:
			jugador.position = _buscar_spawn_central_libre(sala, jugador)

	# Último seguro: nunca permitir una posición fuera del rectángulo
	# jugable aunque la entrada esté ocupada o la sala se haya reconstruido.
	jugador.position.x = clampf(
		jugador.position.x,
		sala.tam_celda + margen,
		(sala.ancho + 1) * sala.tam_celda - margen
	)
	jugador.position.y = clampf(
		jugador.position.y,
		sala.tam_celda + margen,
		(sala.alto + 1) * sala.tam_celda - margen
	)

	jugador.velocity = Vector2.ZERO


func _buscar_spawn_cerca_de_entrada(
	sala: RoomData,
	direccion: String,
	excluir: Node2D
) -> Vector2:
	var base := posicion_entrada_sala(
		laboratorio.salas.find(sala),
		direccion
	)
	var celda := sala.tam_celda
	var hacia_dentro := Vector2.ZERO

	match direccion:
		"arriba":
			hacia_dentro = Vector2.DOWN
		"abajo":
			hacia_dentro = Vector2.UP
		"izquierda":
			hacia_dentro = Vector2.RIGHT
		"derecha":
			hacia_dentro = Vector2.LEFT

	var candidatos: Array[Vector2] = []
	for distancia: float in [0.75, 1.0, 1.5, 2.0, 2.5]:
		var candidato: Vector2 = (
			base + hacia_dentro * celda * distancia
		)
		candidato.x = clampf(
			candidato.x,
			celda + 36.0,
			(sala.ancho + 1) * celda - 36.0
		)
		candidato.y = clampf(
			candidato.y,
			celda + 36.0,
			(sala.alto + 1) * celda - 36.0
		)
		candidatos.append(candidato)

	for candidato in candidatos:
		if not _entrada_ocupada(candidato, excluir):
			return candidato

	# Nunca devolver la posición de la puerta: si todas están ocupadas,
	# se usa la posición más interior para evitar aparecer fuera de la sala.
	return candidatos.back()


func _entrada_ocupada(posicion: Vector2, excluir: Node2D) -> bool:
	var espacio := get_world_2d().direct_space_state
	var forma := RectangleShape2D.new()
	forma.size = Vector2(62.0, 82.0)
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.transform = Transform2D(0.0, posicion)
	consulta.collision_mask = 1
	consulta.collide_with_bodies = true
	consulta.collide_with_areas = false
	if excluir != null:
		consulta.exclude = [excluir.get_rid()]
	return not espacio.intersect_shape(consulta, 1).is_empty()


# TELETRANSPORTE (CIENTÍFICO TELEPORTADOR)
# El selector del inventario teletransporta al jugador
# (o un objeto) a una sala adyacente. El jugador
# aparece junto a la puerta de entrada, exactamente
# donde aparecería al cruzar la puerta normalmente.

func teletransportar_jugador(
	indice: int,
	_direccion: String
) -> void:

	if indice < 0 or indice >= laboratorio.salas.size():

		return

	if jugador != null and is_instance_valid(jugador):
		jugador.establecer_sala_actual(indice)

	mostrar_sala(indice, true)
	sala_actual = indice

	var sala_destino: RoomData = laboratorio.salas[indice]
	if jugador != null and is_instance_valid(jugador):
		jugador.position = _buscar_spawn_central_libre(sala_destino, jugador)

	if jugador != null and is_instance_valid(jugador):

		jugador.velocity = Vector2.ZERO

		jugador.direccion_tactil = Vector2.ZERO

		if jugador.has_method("dejar_de_empujar"):

			jugador.dejar_de_empujar()


func _buscar_spawn_central_libre(
	sala: RoomData,
	excluir: Node2D
) -> Vector2:
	var centro := Vector2(
		(sala.ancho + 1) * sala.tam_celda / 2.0,
		(sala.alto + 1) * sala.tam_celda / 2.0
	)
	var margen := 36.0
	var minimo := Vector2(sala.tam_celda + margen, sala.tam_celda + margen)
	var maximo := Vector2(
		(sala.ancho + 1) * sala.tam_celda - margen,
		(sala.alto + 1) * sala.tam_celda - margen
	)
	var candidatos: Array[Vector2] = [centro]
	var max_radio: int = max(sala.ancho, sala.alto)
	for radio in range(1, max_radio):
		for x in range(-radio, radio + 1):
			for y in range(-radio, radio + 1):
				if maxi(abs(x), abs(y)) != radio:
					continue
				candidatos.append(
					centro + Vector2(x, y) * sala.tam_celda
				)

	for candidato in candidatos:
		var limitado := Vector2(
			clampf(candidato.x, minimo.x, maximo.x),
			clampf(candidato.y, minimo.y, maximo.y)
		)
		if not _entrada_ocupada(limitado, excluir):
			return limitado

	return Vector2(
		clampf(centro.x, minimo.x, maximo.x),
		clampf(centro.y, minimo.y, maximo.y)
	)


func teletransportar_objeto(
	nombre_datos: String,
	descripcion: String,
	indice: int,
	direccion: String,
	textura: Texture2D
) -> void:

	if indice < 0 or indice >= laboratorio.salas.size():

		return

	var sala_destino := laboratorio.salas[indice]

	var od := ObjectData.crear(
		nombre_datos,
		ObjectData.TipoObjeto.INTERACTUABLE,
		textura,
		posicion_entrada_sala(indice, direccion),
		0.09 if nombre_datos == "bateria" else 1.0,
		true,
		descripcion
	)

	sala_destino.añadir_objeto(od)

	print(
		"🌀 Objeto '", nombre_datos,
		"' teletransportado a la sala ", indice
	)


func _direccion_opuesta(direccion: String) -> String:
	match direccion:
		"arriba":
			return "abajo"
		"abajo":
			return "arriba"
		"izquierda":
			return "derecha"
		"derecha":
			return "izquierda"
	return direccion


# Posición junto a la puerta de entrada de una sala
# (la misma que colocar_jugador_en_entrada usa).
func posicion_entrada_sala(
	indice: int,
	direccion: String
) -> Vector2:

	var sala := laboratorio.salas[indice]

	var centro_x := (
		(sala.ancho + 1) * sala.tam_celda / 2.0
	)

	var centro_y := (
		(sala.alto + 1) * sala.tam_celda / 2.0
	)

	var celda := sala.tam_celda

	match direccion:

		"arriba":

			return Vector2(
				centro_x,
				(sala.alto - 1) * celda
			)

		"abajo":

			return Vector2(centro_x, 2 * celda)

		"izquierda":

			return Vector2(
				(sala.ancho - 1) * celda,
				centro_y
			)

		"derecha":

			return Vector2(2 * celda, centro_y)

	return Vector2(centro_x, centro_y)


func teletransportar_por_conducto(conexion_id: int) -> bool:
	if not puede_teletransportar_por_conducto(conexion_id):
		return false

	var destino: int = _buscar_sala_conducto(conexion_id)

	var sala_destino: RoomData = laboratorio.salas[destino]
	var superficie_destino: ObjectBase.Superficie = _superficie_conducto(
		sala_destino,
		conexion_id
	)
	if superficie_destino == ObjectBase.Superficie.SUELO:
		return false

	cambiando_sala = true
	if jugador != null and is_instance_valid(jugador):
		jugador.velocity = Vector2.ZERO
		jugador.direccion_tactil = Vector2.ZERO
		jugador.movimiento_bloqueado = true

	_crear_overlay_transicion()
	transition_label.text = RoomData.TipoSala.keys()[sala_destino.tipo]
	transition_label.modulate = Color(1, 1, 1, 0)
	transition_label.visible = true
	transition_panel.visible = true
	transition_panel.color = Color(0, 0, 0, 0)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(transition_panel, "color", Color(0, 0, 0, 1), 0.35)
	tween.tween_property(transition_label, "modulate", Color.WHITE, 0.2)
	tween.tween_interval(0.55)
	tween.tween_callback(func():
		if jugador != null and is_instance_valid(jugador):
			jugador.establecer_sala_actual(destino)
		mostrar_sala(destino, true)
		_colocar_jugador_en_conducto_destino(
			sala_destino,
			superficie_destino,
			conexion_id
		)
		)
	tween.tween_interval(0.15)
	tween.tween_property(transition_label, "modulate", Color(1, 1, 1, 0), 0.15)
	tween.tween_property(transition_panel, "color", Color(0, 0, 0, 0), 0.35)
	tween.tween_callback(func():
		transition_label.text = ""
		transition_label.visible = false
		transition_panel.visible = false
		cambiando_sala = false
		if jugador != null and is_instance_valid(jugador):
			jugador.movimiento_bloqueado = false
		)
	return true


func puede_teletransportar_por_conducto(conexion_id: int) -> bool:
	if laboratorio == null or conexion_id < 0 or cambiando_sala:
		return false
	_preparar_datos_conducto_destino(conexion_id)
	return _buscar_sala_conducto(conexion_id) >= 0


func _buscar_sala_conducto(conexion_id: int) -> int:
	for indice in range(laboratorio.salas.size()):
		if indice == sala_actual:
			continue
		if laboratorio.salas[indice].conducto_conexion_id != conexion_id:
			continue
		for objeto in laboratorio.salas[indice].objetos:
			if objeto.nombre == "conductoventilacion" \
					and objeto.conducto_conexion_id == conexion_id:
				return indice
	return -1


func _preparar_datos_conducto_destino(conexion_id: int) -> void:
	if laboratorio == null:
		return
	for sala in laboratorio.salas:
		if sala.conducto_conexion_id != conexion_id or not sala.objetos.is_empty():
			continue
		var contenedor_temporal := Node2D.new()
		ObjectGenerator.generar(contenedor_temporal, sala)
		contenedor_temporal.free()


func _superficie_conducto(
	sala: RoomData,
	conexion_id: int
) -> ObjectBase.Superficie:
	for objeto in sala.objetos:
		if objeto.nombre == "conductoventilacion" \
				and objeto.conducto_conexion_id == conexion_id:
			return objeto.superficie
	return ObjectBase.Superficie.SUELO


func _colocar_jugador_en_conducto_destino(
	sala: RoomData,
	superficie: ObjectBase.Superficie,
	conexion_id: int
) -> void:
	if jugador == null or not is_instance_valid(jugador):
		return

	var conducto_destino: ConductoVentilacion = null
	var datos_conducto_destino: ObjectData = null
	var objetos := room_actual.get_node_or_null("Objects")
	if objetos != null:
		for nodo in get_tree().get_nodes_in_group("conductos_ventilacion"):
			if not objetos.is_ancestor_of(nodo):
				continue
			var candidato := nodo as ConductoVentilacion
			if candidato != null and candidato.objeto_datos != null \
					and candidato.objeto_datos.conducto_conexion_id == conexion_id:
				conducto_destino = candidato
				datos_conducto_destino = candidato.objeto_datos
				break

	if datos_conducto_destino == null:
		for objeto in sala.objetos:
			if objeto.nombre == "conductoventilacion" \
					and objeto.conducto_conexion_id == conexion_id:
				datos_conducto_destino = objeto
				break

	if datos_conducto_destino == null:
		return

	var posicion: Vector2 = (
		conducto_destino.position if conducto_destino != null
		else datos_conducto_destino.posicion
	)
	var margen: float = sala.tam_celda * 1.25
	match superficie:
		ObjectBase.Superficie.PARED_ARRIBA:
			posicion.y += margen
		ObjectBase.Superficie.PARED_ABAJO:
			posicion.y -= margen
		ObjectBase.Superficie.PARED_IZQUIERDA:
			posicion.x += margen
		ObjectBase.Superficie.PARED_DERECHA:
			posicion.x -= margen

	jugador.position = posicion
	jugador.velocity = Vector2.ZERO
	jugador.direccion_tactil = Vector2.ZERO
	jugador._activar_animacion_salida_conducto(superficie)

# IMPRIMIR LABORATORIO
func imprimir_laboratorio():

	print("===== LABORATORIO =====")


	for i in range(laboratorio.salas.size()):

		var sala = laboratorio.salas[i]

		print(
			"Sala ",
			i,
			" | ",
			RoomData.TipoSala.keys()[sala.tipo],
			" | ",
			sala.ancho,
			"x",
			sala.alto,
			" | Posición: ",
			sala.posicion,
			" Vecinos: ",
			sala.vecinos,
			" Distancia: ",
			sala.distancia_inicio,
			" | Puertas: ",
			"Arriba=", sala.puerta_arriba,
			" Abajo=", sala.puerta_abajo,
			" Izquierda=", sala.puerta_izquierda,
			" Derecha=", sala.puerta_derecha
		)


# TERMINAL ABIERTA / CERRADA

func _on_terminal_estado_cambiado(abierto: bool) -> void:

	movement_controls.establecer_activo(not abierto)
	interaction_manager.establecer_activo(not abierto)

	var jugador_activo: Character = interaction_manager.jugador
	if jugador_activo != null:
		jugador_activo.movimiento_bloqueado = abierto
		if abierto:
			jugador_activo.detener_movimiento()

	if not abierto:
		var gestor := get_tree().get_first_node_in_group("gestor_turnos") as GestorTurnos
		if gestor != null:
			gestor.reaplicar_turno()
