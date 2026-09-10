extends Control

# SELECCION DE NUMERO DE JUGADORES (2 - 8)
# Pantalla estilo terminal CRT entre el inicio y la
# seleccion de personaje. Esteticamente identica a
# PantallaInicio (verde fosforo sobre negro).

const ESCENA_SELECCION := "res://Scenes/UI/SeleccionPersonaje.tscn"
const ESCENA_INICIO := "res://Scenes/UI/PantallaInicio.tscn"
const FUENTE := "res://DePixelBreit.ttf"
const AJUSTES_UI := preload("res://Scripts/UI/AjustesUI.gd")

const MIN_JUGADORES := 2
const MAX_JUGADORES := 8

const COLOR_VERDE := Color("3dff6e")
const COLOR_VERDE_CLARO := Color("baffc9")
const COLOR_VERDE_TENUE := Color(0.24, 0.6, 0.35)

var _num_jugadores: int = MIN_JUGADORES
var _lbl_numero: Label = null
var _fuente: FontFile = null


func _ready() -> void:

	_fuente = load(FUENTE)

	var ajustes_ui: CanvasLayer = AJUSTES_UI.new()
	add_child(ajustes_ui)

	_construir_interfaz()


func _construir_interfaz() -> void:

	# --- Fondo negro ---
	var fondo := ColorRect.new()
	fondo.color = Color.BLACK
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	# --- Columna central ---
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 18)
	centro.add_child(columna)

	# --- Titulo ---
	var titulo := _crear_label(
		"SELECCION DE JUGADORES", 28, COLOR_VERDE_CLARO
	)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)

	var subtitulo := _crear_label(
		"CUANTOS CIENTIFICOS ENTRAN AL LABORATORIO?",
		16, COLOR_VERDE
	)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(subtitulo)

	# --- Selector:  -  numero  +  ---
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 30)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_child(fila)

	var btn_menos := _crear_boton("-")
	btn_menos.pressed.connect(_cambiar_numero.bind(-1))
	fila.add_child(btn_menos)

	_lbl_numero = _crear_label(
		str(_num_jugadores), 48, COLOR_VERDE_CLARO
	)
	_lbl_numero.custom_minimum_size = Vector2(120, 0)
	_lbl_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fila.add_child(_lbl_numero)

	var btn_mas := _crear_boton("+")
	btn_mas.pressed.connect(_cambiar_numero.bind(1))
	fila.add_child(btn_mas)

	# --- Continuar / Volver ---
	var btn_continuar := _crear_boton("CONTINUAR (ENTER)")
	btn_continuar.pressed.connect(_confirmar)
	columna.add_child(btn_continuar)

	var btn_volver := _crear_boton("VOLVER (ESC)")
	btn_volver.pressed.connect(_volver)
	columna.add_child(btn_volver)

	# --- Ayuda de controles ---
	var ayuda := _crear_label(
		"<- -> PARA CAMBIAR   |   ENTER PARA CONTINUAR",
		14, COLOR_VERDE_TENUE
	)
	ayuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(ayuda)


func _crear_label(
	texto: String, tamano: int, color: Color
) -> Label:

	var lbl := Label.new()
	lbl.text = texto

	if _fuente != null:
		lbl.add_theme_font_override("font", _fuente)

	lbl.add_theme_font_size_override("font_size", tamano)
	lbl.add_theme_color_override("font_color", color)

	return lbl


func _crear_boton(texto: String) -> Button:

	var btn := Button.new()
	btn.text = texto
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL

	if _fuente != null:
		btn.add_theme_font_override("font", _fuente)

	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", COLOR_VERDE)
	btn.add_theme_color_override(
		"font_hover_color", COLOR_VERDE_CLARO
	)
	btn.add_theme_color_override(
		"font_pressed_color", COLOR_VERDE_CLARO
	)
	btn.add_theme_color_override(
		"font_focus_color", COLOR_VERDE_CLARO
	)

	return btn


func _cambiar_numero(delta: int) -> void:

	_num_jugadores = clampi(
		_num_jugadores + delta, MIN_JUGADORES, MAX_JUGADORES
	)

	if _lbl_numero != null:
		_lbl_numero.text = str(_num_jugadores)


func _confirmar() -> void:

	GameSession.configurar_partida(_num_jugadores)

	get_tree().change_scene_to_file(ESCENA_SELECCION)


func _volver() -> void:

	get_tree().change_scene_to_file(ESCENA_INICIO)


func _unhandled_input(evento: InputEvent) -> void:

	if evento.is_action_pressed("ui_left"):
		_cambiar_numero(-1)
	elif evento.is_action_pressed("ui_right"):
		_cambiar_numero(1)
	elif evento.is_action_pressed("ui_accept"):
		_confirmar()
	elif evento.is_action_pressed("ui_cancel"):
		_volver()
