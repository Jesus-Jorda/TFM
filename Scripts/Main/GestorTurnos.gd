extends CanvasLayer

class_name GestorTurnos


# GESTOR DE TURNOS (HOT-SEAT)
# Reparte el control entre los jugadores de la
# partida: 20 segundos por turno, cuenta atrás en
# pantalla y congelación del resto de personajes.

const DURACION_TURNO := 20.0

const COLOR_FONDO := Color(0.0, 0.03, 0.0, 0.85)

const COLOR_VERDE := Color("3dff6e")

const COLOR_VERDE_CLARO := Color("baffc9")

const COLOR_VERDE_OSCURO := Color(0.1, 0.45, 0.2)

var _jugadores: Array = []

var _datos: Array = []

var _indice: int = 0
var _turno_actual: int = 0
var _ronda: int = 1

var _restante: float = DURACION_TURNO

var _movement_controls: Node = null

var _interaction_manager: Node = null

var _inventario: InventoryManager = null

var _lbl_titulo: Label = null

var _lbl_turno: Label = null
var _lbl_ronda: Label = null

var _lbl_tiempo: Label = null

var _barra: ColorRect = null

var _ancho_barra: float = 0.0

var _boton_pasar_turno: Button = null

var _transicion: CanvasLayer = null

var _cambiando: bool = false

var _en_puzzle: bool = false
var _cafe_usado_turno: bool = false
var _jugadores_finalizados: Array[Node] = []
var _victoria_mostrada: bool = false


# LISTO

func _ready() -> void:

	layer = 15
	add_to_group("gestor_turnos")


# CONFIGURAR EL GESTOR

func configurar(
	jugadores: Array,
	movement_controls: Node = null,
	interaction_manager: Node = null,
	inventario: InventoryManager = null
) -> void:

	_jugadores = jugadores

	_datos = GameSession.personajes_en_juego()

	_movement_controls = movement_controls

	_interaction_manager = interaction_manager
	_inventario = inventario
	_restante = DURACION_TURNO

	_construir_hud()

	_aplicar_turno()


# CUENTA ATRÁS

func _process(delta: float) -> void:

	if _jugadores.is_empty():

		return

	var main := get_tree().get_first_node_in_group("main")
	if main != null and bool(main.get("cambiando_sala")):
		return

	# Solo las transiciones bloquean el avance del contador.
	# Los puzzles y terminales siguen consumiendo el turno.
	if _cambiando:

		return
	if _victoria_mostrada:
		return

	_restante -= delta

	if _restante <= 0.0:

		_siguiente_turno()

		return

	_actualizar_hud()


# CAMBIO DE TURNO

func _siguiente_turno() -> void:

	# Los puzzles no detienen el turno: solo la transición
	# entre jugadores impide iniciar otro cambio simultáneo.
	if _cambiando:

		return

	if _jugadores.is_empty():

		return

	var ga := get_tree().get_first_node_in_group("gestor_audio") as AudioManager
	if ga:
		ga.reproducir_efecto_corto("finturno", 0.75, -2.0)

	_cerrar_interfaces_modal()

	# El inventario es compartido por la interfaz, pero los objetos
	# pertenecen al jugador que termina su turno: se dejan en el suelo.
	if _inventario != null:
		if _inventario.has_method("_cerrar_mensajes_turno"):
			_inventario._cerrar_mensajes_turno()
		_inventario.soltar_todos_al_suelo()

	_indice = (_indice + 1) % _jugadores.size()
	if _indice == 0:
		_ronda += 1
	_turno_actual += 1
	_restante = DURACION_TURNO
	_cafe_usado_turno = false

	var main: Node = get_tree().get_first_node_in_group("main")
	if main != null and main.has_method("reponer_objetos_al_cambiar_turno"):
		main.call("reponer_objetos_al_cambiar_turno")

	_cambiando = true
	# Preparar jugador, sala y cámara antes de mostrar la transición.
	_aplicar_turno()

	_reproducir_transicion()


func añadir_tiempo_turno(segundos: float) -> void:
	_restante += maxf(0.0, segundos)
	_actualizar_hud()


func pasar_turno() -> void:
	if _jugadores.is_empty() or _cambiando:
		return
	_restante = 0.0
	_siguiente_turno()


func resultado_accion_impredecible() -> bool:
	var exito: bool = randf() < 0.8
	if exito:
		añadir_tiempo_turno(10.0)
	return exito


func usar_cafe() -> bool:
	if _cafe_usado_turno:
		return false
	_cafe_usado_turno = true
	añadir_tiempo_turno(10.0)
	return true


func registrar_jugador_ganador(jugador_ganador: Node) -> void:
	if jugador_ganador == null or not _jugadores.has(jugador_ganador):
		return
	if _jugadores_finalizados.has(jugador_ganador):
		return

	var indice_ganador: int = _jugadores.find(jugador_ganador)
	var era_el_turno_del_ganador: bool = indice_ganador == _indice
	var nombre: String = "Jugador %d" % (indice_ganador + 1)
	if indice_ganador >= 0 and indice_ganador < _datos.size():
		var datos_ganador := _datos[indice_ganador] as CharacterData
		if datos_ganador != null and not datos_ganador.nombre.is_empty():
			nombre = datos_ganador.nombre

	GameSession.registrar_llegada(nombre)
	_jugadores_finalizados.append(jugador_ganador)
	jugador_ganador.set("movimiento_bloqueado", true)
	jugador_ganador.set("visible", false)
	jugador_ganador.set("sala_actual_idx", -1)
	var camara_ganador := jugador_ganador.get_node_or_null("Camera2D") as Camera2D
	if camara_ganador != null:
		camara_ganador.enabled = false
	_jugadores.remove_at(indice_ganador)
	if indice_ganador < _datos.size():
		_datos.remove_at(indice_ganador)
	_restante = DURACION_TURNO
	if era_el_turno_del_ganador:
		# Al retirar al jugador actual, el siguiente ocupa su índice.
		# Si era el último, el índice vuelve al primer jugador activo.
		_indice = indice_ganador
	elif indice_ganador < _indice:
		_indice -= 1
	if _jugadores.is_empty():
		_indice = 0
	else:
		_indice = _indice % _jugadores.size()


func continuar_despues_de_ganador() -> void:
	if _jugadores.is_empty() or _cambiando:
		return
	_victoria_mostrada = false

	if _movement_controls != null and _movement_controls.has_method("establecer_activo"):
		_movement_controls.establecer_activo(true)
	if _interaction_manager != null and _interaction_manager.has_method("establecer_activo"):
		_interaction_manager.establecer_activo(true)

	_turno_actual += 1
	_restante = DURACION_TURNO
	_cafe_usado_turno = false
	_cambiando = true
	_aplicar_turno()
	_reproducir_transicion()


func quedan_jugadores_activos() -> bool:
	return not _jugadores.is_empty()


func es_ultimo_jugador_activo() -> bool:
	return _jugadores.size() <= 1


func _cerrar_interfaces_modal() -> void:
	var terminal := get_tree().get_first_node_in_group("terminal_interface") as TerminalInterface
	if terminal != null and terminal.abierto:
		terminal.cerrar_terminal()

	for puzzle in get_tree().get_nodes_in_group("puzzle_cables"):
		if puzzle is PuzzleCables and puzzle.abierto:
			puzzle.cerrar()

	for panel in get_tree().get_nodes_in_group("paneles_electricos"):
		if panel.has_method("cerrar_puzzle_por_turno"):
			panel.cerrar_puzzle_por_turno()


# TRANSICIÓN ENTRE TURNOS

func _reproducir_transicion() -> void:

	if _jugadores.is_empty():
		_cambiando = false
		return

	if _transicion == null:

		var script_trans: GDScript = preload(
			"res://Scripts/UI/TransicionTurno.gd"
		)

		_transicion = script_trans.new()

		add_child(_transicion)

	# Mientras dura el cartel nadie se mueve: el estado
	# correcto se reaplica al culminar la transicion.
	for jugador in _jugadores:

		if jugador == null or not is_instance_valid(jugador):

			continue

		jugador.movimiento_bloqueado = true

		if jugador.has_method("detener_movimiento"):

			jugador.detener_movimiento()

	if not _transicion.transicion_culminada.is_connected(
			_al_culminar_transicion):

		_transicion.transicion_culminada.connect(
			_al_culminar_transicion
		)

	var nombre := ""

	if _indice >= 0 and _indice < _datos.size():

		var datos = _datos[_indice]

		if datos != null and "nombre" in datos:

			nombre = str(datos.get("nombre"))

	_transicion.mostrar(_indice + 1, nombre)


func _al_culminar_transicion() -> void:

	_cambiando = false

	_aplicar_turno()


# PAUSA DE TURNO (PUZZLES / TERMINALES)

func establecer_en_puzzle(esta_en_puzzle: bool) -> void:

	_en_puzzle = esta_en_puzzle


func _actualizar_habilidades() -> void:
	if _inventario == null:
		return

	var datos_activos: CharacterData = null
	if _indice >= 0 and _indice < _datos.size():
		datos_activos = _datos[_indice] as CharacterData

	if datos_activos != null:
		_inventario.configurar_habilidades(datos_activos)
	_inventario.establecer_activo(true)

func reaplicar_turno() -> void:

	# Restaura bloqueos, cámara y controles al estado
	# correcto del turno vigente.
	_aplicar_turno()


func _aplicar_turno() -> void:
	for i in _jugadores.size():

		var jugador = _jugadores[i]

		if jugador == null \
				or not is_instance_valid(jugador):

			continue

		var activo := i == _indice

		# El jugador sin turno no se mueve.
		jugador.movimiento_bloqueado = not activo

		if not activo \
				and jugador.has_method("detener_movimiento"):

			jugador.detener_movimiento()

		# Solo la cámara del jugador activo manda.
		var camara := (
			jugador.get_node_or_null("Camera2D")
			as Camera2D
		)

		if camara != null:

			camara.enabled = false

	var activo_actual = _jugador_activo()
	var main := get_tree().get_first_node_in_group("main")
	if activo_actual != null and main != null:
		if activo_actual.has_method("reactivar_control_si_corresponde"):
			activo_actual.reactivar_control_si_corresponde()
		main.jugador = activo_actual
		var sala_jugador: int = activo_actual.sala_actual_idx
		if not bool(main.get("cambiando_sala")) \
				and sala_jugador >= 0 and sala_jugador != main.sala_actual:
			main.mostrar_sala(sala_jugador, true)
		if main.has_method("_aplicar_apagon_sala"):
			main._aplicar_apagon_sala(main.sala_actual)

	var camara_activa := activo_actual.get_node_or_null("Camera2D") as Camera2D
	if camara_activa != null:
		camara_activa.enabled = true

	# Los controles táctiles/botones y las
	# interacciones apuntan al jugador activo.
	if activo_actual != null:
		if _movement_controls != null \
				and _movement_controls.has_method(
					"asignar_jugador"
				):

			_movement_controls.asignar_jugador(
				activo_actual
			)

		if _interaction_manager != null \
				and _interaction_manager.has_method(
					"asignar_jugador"
				):

			_interaction_manager.asignar_jugador(
				activo_actual
			)
			if _interaction_manager.has_method("refrescar_para_jugador"):
				_interaction_manager.refrescar_para_jugador(activo_actual)
				_interaction_manager.call_deferred(
					"refrescar_para_jugador", activo_actual
				)

		_actualizar_hud()

	_actualizar_habilidades()


func _jugador_activo():

	if _indice < 0 or _indice >= _jugadores.size():

		return null

	var jugador = _jugadores[_indice]

	if jugador == null or not is_instance_valid(jugador):

		return null

	return jugador


# HUD DEL TURNO

func _construir_hud() -> void:

	var fuente: Font = load("res://DePixelBreit.ttf")

	var panel := PanelContainer.new()

	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)

	panel.offset_left = -190.0

	panel.offset_right = 190.0

	panel.offset_top = 10.0

	panel.offset_bottom = 120.0

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = COLOR_FONDO

	estilo.border_color = COLOR_VERDE_OSCURO

	estilo.set_border_width_all(2)

	estilo.set_corner_radius_all(4)

	estilo.content_margin_left = 12.0

	estilo.content_margin_right = 12.0

	estilo.content_margin_top = 6.0

	estilo.content_margin_bottom = 8.0

	panel.add_theme_stylebox_override(
		"panel", estilo
	)

	add_child(panel)

	var columna := VBoxContainer.new()

	columna.add_theme_constant_override("separation", 4)

	panel.add_child(columna)

	_lbl_titulo = Label.new()

	_lbl_titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_lbl_titulo.add_theme_font_override(
		"font", fuente
	)

	_lbl_titulo.add_theme_font_size_override(
		"font_size", 14
	)

	_lbl_titulo.add_theme_color_override(
		"font_color", COLOR_VERDE_CLARO
	)


	_lbl_turno = Label.new()
	_lbl_turno.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_turno.add_theme_font_override("font", fuente)
	_lbl_turno.add_theme_font_size_override("font_size", 12)
	_lbl_turno.add_theme_color_override("font_color", COLOR_VERDE_CLARO)
	columna.add_child(_lbl_turno)

	_lbl_ronda = Label.new()
	_lbl_ronda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_ronda.add_theme_font_override("font", fuente)
	_lbl_ronda.add_theme_font_size_override("font_size", 11)
	_lbl_ronda.add_theme_color_override("font_color", COLOR_VERDE_OSCURO)
	columna.add_child(_lbl_ronda)

	# Barra de tiempo (fondo + relleno).
	var barra_fondo := ColorRect.new()

	barra_fondo.color = Color(0.0, 0.15, 0.05, 0.9)

	barra_fondo.custom_minimum_size = Vector2(0, 10)

	columna.add_child(barra_fondo)

	_barra = ColorRect.new()

	_barra.color = COLOR_VERDE

	barra_fondo.add_child(_barra)

	_ancho_barra = 0.0

	_lbl_tiempo = Label.new()

	_lbl_tiempo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_lbl_tiempo.add_theme_font_override(
		"font", fuente
	)

	_lbl_tiempo.add_theme_font_size_override(
		"font_size", 11
	)

	_lbl_tiempo.add_theme_color_override(
		"font_color", COLOR_VERDE
	)

	columna.add_child(_lbl_tiempo)

	_boton_pasar_turno = Button.new()
	_boton_pasar_turno.text = "PASAR TURNO"
	_boton_pasar_turno.custom_minimum_size = Vector2(150, 28)
	_boton_pasar_turno.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boton_pasar_turno.add_theme_font_override("font", fuente)
	_boton_pasar_turno.add_theme_font_size_override("font_size", 11)
	_boton_pasar_turno.pressed.connect(pasar_turno)
	columna.add_child(_boton_pasar_turno)


func _actualizar_hud() -> void:

	if _lbl_titulo == null:

		return

	var nombre := "—"

	if _indice < _datos.size() \
			and _datos[_indice] != null:

		nombre = str(_datos[_indice].nombre)

	_lbl_titulo.text = (
		"TURNO DEL JUGADOR %d - %s"
			% [_indice + 1, nombre.to_upper()]

	)

	if _lbl_turno != null:
		_lbl_turno.text = "TURNO %d | RONDA %d" % [_turno_actual, _ronda]
	if _lbl_ronda != null:
		_lbl_ronda.text = "JUGADOR %d / %d" % [_indice + 1, _jugadores.size()]

	_lbl_tiempo.text = "%.1f s" % maxf(0.0, _restante)

	# Ancho de la barra proporcional al tiempo restante.
	if _barra != null:

		var fondo := _barra.get_parent() as Control

		if fondo != null:

			var ancho := fondo.size.x

			_barra.position = Vector2.ZERO

			var proporcion: float = clampf(
				_restante / DURACION_TURNO,
				0.0,
				1.0
			)
			_barra.size = Vector2(
				ancho * proporcion,
				fondo.size.y
			)
