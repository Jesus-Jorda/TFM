extends CanvasLayer


# PANTALLA DE INICIO — TERMINAL CRT "LABORATORIO LOCO"
# Auténtica estética de ordenador antiguo: scanlines,
# glitches, apagones y texto verde que se escribe
# letra a letra. Avanza con ENTER, clic
# o toque táctil.

const FUENTE: FontFile = preload(
	"res://DePixelBreit.ttf"
)

const AJUSTES_UI := preload(
	"res://Scripts/UI/AjustesUI.gd"
)

const ESCENA_SELECCION := (
	"res://Scenes/UI/SeleccionPersonaje.tscn"
)

# COLORES DEL TERMINAL
const COLOR_VERDE := Color(0.28, 1.0, 0.42)
const COLOR_VERDE_OSCURO := Color(0.16, 0.65, 0.28)
const COLOR_VERDE_BRILLO := Color(0.6, 1.0, 0.7)
const COLOR_FONDO := Color(0.0, 0.0, 0.0)

# Hex equivalentes para el BBCode de texto.
const HEX_TEXTO := "47ff6b"   # verde terminal (lore)
const HEX_TITULO := "99ffb3"  # verde brillante (título)

# TEXTOS
const TEXTO_TITULO := (
	"LABORATORIO LOCO\n"
	+ "==================\n\n"
	+ "PROTOTIPO DE INVESTIGACIÓN"
)

const TEXTO_LORE := [
	"INTRODUCCIÓN DE SEGURIDAD v2.71",
	"> ACCESO CONCEDIDO - PERSONAL AUTORIZADO",
	"En este laboratorio se experimentaba\ncon personas. Una instalación dedicada\na la investigación de medicamentos,\nen el corazón de un edificio lleno de\ntrabajadores... y de personas que\nvivían demasiado cerca de él.",
	"El experimento se descontroló.\nLas instalaciones están contaminadas\ny la salida es nuestra única misión.",
	"Elige un personaje y escapa del\nlaboratorio. Toca todo lo que tengan\na su alcance, pero recuerda:\naquí nada funciona como parece."
]

# ESTADO
var _fase := 0
var _lineas_terminal: RichTextLabel = null
var _cursor_label: Label = null
var _lore_index := 0
var _texto_escribiendo := ""
var _esperando_input := false
var _cursor_parpadeo := 0.0
var _cursor_visible := true
var _tiempo_linea := 0.0

# Glitches y apagones
var _glitch_timer := 0.0
var _next_glitch := 3.0
var _glitch_active := false
var _glitch_tiempo := 0.0
var _glitch_offset := 0.0
var _flicker := 1.0
var _apagon_activo := false
var _apagon_tiempo := 0.0
var _boot_completo := false

# Nodos de efectos
var _contenido: CenterContainer = null
var _scanlines: ColorRect = null
var _vignette: ColorRect = null
var _glitch_overlay: ColorRect = null

# Flanco de entrada
var _mouse_prev := false
var _enter_prev := false
var _space_prev := false


func _ready() -> void:

	layer = 40

	var ajustes_ui: CanvasLayer = AJUSTES_UI.new()
	add_child(ajustes_ui)

	_construir_interfaz()

	_secuencia_arranque()


func _construir_interfaz() -> void:

	# FONDO NEGRO
	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	# CAPA DE CONTENIDO CENTRADA
	_contenido = CenterContainer.new()
	_contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_contenido)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 14)
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contenido.add_child(columna)

	# TERMINAL DE TEXTO (centrado)
	_lineas_terminal = RichTextLabel.new()
	_lineas_terminal.bbcode_enabled = true
	_lineas_terminal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lineas_terminal.fit_content = true
	_lineas_terminal.custom_minimum_size = Vector2(640.0, 360.0)
	_lineas_terminal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lineas_terminal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lineas_terminal.add_theme_font_override("normal_font", FUENTE)
	_lineas_terminal.add_theme_font_size_override("normal_font_size", 24)
	_lineas_terminal.add_theme_color_override("font_color", COLOR_VERDE)
	_lineas_terminal.add_theme_color_override("font_outline_color", COLOR_VERDE_OSCURO)
	_lineas_terminal.scroll_active = false
	columna.add_child(_lineas_terminal)

	# Cursor parpadeante del terminal.
	var cursor_box := HBoxContainer.new()
	cursor_box.alignment = BoxContainer.ALIGNMENT_CENTER
	cursor_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(cursor_box)

	_cursor_label = Label.new()
	_cursor_label.text = "_"
	_cursor_label.add_theme_font_override("font", FUENTE)
	_cursor_label.add_theme_font_size_override("font_size", 24)
	_cursor_label.add_theme_color_override("font_color", COLOR_VERDE)
	cursor_box.add_child(_cursor_label)

	# BOTÓN CONTINUAR
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(btn_box)

	var boton := Button.new()
	boton.text = "CONTINUAR [ENTER]"
	boton.add_theme_font_override("font", FUENTE)
	boton.add_theme_font_size_override("font_size", 22)
	boton.add_theme_color_override("font_color", COLOR_VERDE_OSCURO)
	boton.add_theme_color_override("font_hover_color", COLOR_VERDE)
	boton.add_theme_color_override("font_focus_color", COLOR_VERDE)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.02, 0.08, 0.03)
	estilo.border_color = COLOR_VERDE_OSCURO
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	boton.add_theme_stylebox_override("normal", estilo)
	var estilo_hover := estilo.duplicate()
	estilo_hover.bg_color = Color(0.05, 0.18, 0.08)
	boton.add_theme_stylebox_override("hover", estilo_hover)
	boton.pressed.connect(_on_boton_continuar)
	btn_box.add_child(boton)

	# SCANLÍNEAS (líneas horizontales CRT)
	_scanlines = ColorRect.new()
	_scanlines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scanlines.material = _crear_material_scanlines()
	add_child(_scanlines)

	# VIÑETADO (esquinas oscuras)
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.material = _crear_material_vignette()
	add_child(_vignette)

	# OVERLAY DE GLITCH (flash de color)
	_glitch_overlay = ColorRect.new()
	_glitch_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glitch_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glitch_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_glitch_overlay.visible = false
	add_child(_glitch_overlay)


# EFECTOS CRT

func _crear_material_scanlines() -> ShaderMaterial:

	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\n"
	sh.code += "render_mode unshaded;\n"
	sh.code += "uniform float intensity = 0.35;\n"
	sh.code += "void fragment() {\n"
	sh.code += "    float line = floor(FRAGCOORD.y);\n"
	sh.code += "    float dark = mod(line, 2.0);\n"
	sh.code += "    float alpha = dark * intensity;\n"
	sh.code += "    COLOR = vec4(0.0, 0.0, 0.0, alpha);\n"
	sh.code += "}"
	mat.shader = sh
	return mat


func _crear_material_vignette() -> ShaderMaterial:

	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\n"
	sh.code += "render_mode unshaded;\n"
	sh.code += "uniform float strength = 1.6;\n"
	sh.code += "void fragment() {\n"
	sh.code += "    vec2 uv = SCREEN_UV;\n"
	sh.code += "    vec2 center = uv - 0.5;\n"
	sh.code += "    float dist = dot(center, center);\n"
	sh.code += "    float vig = 1.0 - dist * strength;\n"
	sh.code += "    vig = clamp(vig, 0.0, 1.0);\n"
	sh.code += "    COLOR = vec4(0.0, 0.0, 0.0, 1.0 - vig);\n"
	sh.code += "}"
	mat.shader = sh
	return mat


func _secuencia_arranque() -> void:

	# Parpadeo inicial de encendido.
	_lineas_terminal.text = ""
	_flicker = 0.02
	await get_tree().create_timer(0.15).timeout
	_flicker = 1.0
	await get_tree().create_timer(0.1).timeout
	_flicker = 0.05
	await get_tree().create_timer(0.08).timeout
	_flicker = 1.0
	await get_tree().create_timer(0.3).timeout
	_pintar_titulo()
	_boot_completo = true


func _procesar_efectos(delta: float) -> void:

	# --- Flicker continuo (leve) ---
	var base := 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.015
	base += sin(Time.get_ticks_msec() * 0.037) * 0.01
	_flicker = base

	# --- Apagones aleatorios ---
	if not _apagon_activo and _boot_completo:
		_glitch_timer += delta
		if _glitch_timer >= _next_glitch:
			_glitch_timer = 0.0
			_next_glitch = randf_range(2.0, 6.0)
			_apagon_activo = true
			_apagon_tiempo = randf_range(0.08, 0.25)
			_glitch_overlay.visible = true

	if _apagon_activo:
		_apagon_tiempo -= delta
		_flicker *= 0.15
		# Glitch de desplazamiento.
		_glitch_offset = randf_range(-8.0, 8.0)
		_glitch_overlay.color = Color(
			randf_range(0.0, 0.3),
			randf_range(0.2, 0.5),
			randf_range(0.0, 0.1),
			randf_range(0.1, 0.4)
		)
		if _apagon_tiempo <= 0.0:
			_apagon_activo = false
			_glitch_offset = 0.0
			_glitch_overlay.visible = false
			_glitch_overlay.color = Color(0.0, 0.0, 0.0, 0.0)

	# --- Aplicar flicker al contenido ---
	if _contenido != null:
		_contenido.modulate = Color(1.0, 1.0, 1.0, _flicker)
		# Desplazamiento horizontal durante el apagón.
		if _apagon_activo:
			_contenido.position.x = _glitch_offset
		else:
			_contenido.position.x = 0.0


func _on_boton_continuar() -> void:

	_siguiente_fase()


func _process(delta: float) -> void:

	_procesar_efectos(delta)

	# --- Detección de flanco: solo el frame en el que se pulsa ---
	var mouse_now := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var enter_now := Input.is_physical_key_pressed(KEY_ENTER)
	var space_now := Input.is_physical_key_pressed(KEY_SPACE)

	var flanco := (
		(mouse_now and not _mouse_prev)
		or (enter_now and not _enter_prev)
		or (space_now and not _space_prev)
		or Input.is_action_just_pressed("interactuar")
	)

	# Guardar estado para el siguiente frame.
	_mouse_prev = mouse_now
	_enter_prev = enter_now
	_space_prev = space_now

	# Un clic/toque = un avance (aunque se mantenga pulsado).
	if flanco:

		_siguiente_fase()

		return

	# No hay entrada nueva: seguir parpadeando / escribiendo.
	if _esperando_input:

		_tick_cursor(delta)

	elif _fase == 1:

		_tiempo_linea -= delta

		if _tiempo_linea <= 0.0:

			_tiempo_linea = 0.045

			_escribir_siguiente_caracter()


func _tick_cursor(delta: float) -> void:

	_cursor_parpadeo -= delta

	if _cursor_parpadeo <= 0.0:

		_cursor_parpadeo = 0.5

		_cursor_visible = not _cursor_visible

	_actualizar_cursor()


func _actualizar_cursor() -> void:

	if _cursor_label != null:

		_cursor_label.visible = _cursor_visible


func _pintar_titulo() -> void:

	_fase = 0

	# Título centrado en verde brillante (sin [b]: la fuente
	# pixel no tiene negrita y forzaría una fuente de respaldo).
	var titulo := _escapar(TEXTO_TITULO)
	_lineas_terminal.text = (
		"[center][color=#" + HEX_TITULO + "]"
		+ titulo + "[/color][/center]"
	)

	_esperando_input = true
	_cursor_visible = true


func _escapar(t: String) -> String:

	# Los saltos de línea se dejan tal cual: RichTextLabel
	# respeta los \n nativamente. La etiqueta [br] NO existe
	# en el BBCode de Godot 4 (se descartaba y colapsaba el
	# texto en una sola línea). El texto no contiene
	# corchetes, así que no hace falta otro escapado.
	return t


func _envolver(contenido: String) -> String:

	# Envoltorio BBCode común del texto: centrado + verde.
	return (
		"[center][color=#" + HEX_TEXTO + "]"
		+ contenido + "[/color][/center]"
	)


func _contenido_actual() -> String:

	# Texto acumulado en el terminal sin el envoltorio BBCode.
	return (
		_lineas_terminal.text
		.replace("[center]", "").replace("[/center]", "")
		.replace("[color=#" + HEX_TEXTO + "]", "")
		.replace("[/color]", "")
	)


func _siguiente_fase() -> void:

	# Estado 0: título -> se muestra el lore (escribe frase 1)
	if _fase == 0:

		_fase = 1
		_esperando_input = false
		_lore_index = 0
		_lineas_terminal.text = ""

		_cargar_siguiente_frase()

		return

	# Estado 1: escribiendo una frase -> completarla
	if _fase == 1 and not _texto_escribiendo.is_empty():

		# Mantener centrado y color: reconstruir con el
		# envoltorio alrededor de lo acumulado + el resto.
		_lineas_terminal.text = _envolver(
			_contenido_actual() + _escapar(_texto_escribiendo)
		)

		_texto_escribiendo = ""
		_esperando_input = true
		_cursor_visible = true

		return

	# Estado 1 frase terminada -> frase siguiente o fin
	if _fase == 1:

		_cargar_siguiente_frase()

		return

	# Cualquier otro caso: ir a selección
	_ir_a_seleccion()


func _cargar_siguiente_frase() -> void:

	if _lore_index >= TEXTO_LORE.size():

		_ir_a_seleccion()

		return

	# Separar cada frase de la anterior con una línea en
	# blanco, para que no queden pegadas entre sí.
	if _lore_index > 0:
		_lineas_terminal.text = _envolver(_contenido_actual() + "\n\n")

	_texto_escribiendo = TEXTO_LORE[_lore_index]
	_lore_index += 1
	_esperando_input = false


func _escribir_siguiente_caracter() -> void:

	if _texto_escribiendo.is_empty():

		# Frase terminada
		_esperando_input = true
		_cursor_visible = true
		_actualizar_cursor()
		return

	# Escribir centrado y en verde: reconstruir todo el texto.
	var escrito := _contenido_actual()
	escrito += _escapar(_texto_escribiendo.substr(0, 1))
	_lineas_terminal.text = _envolver(escrito)

	_texto_escribiendo = _texto_escribiendo.substr(1)


func _ir_a_seleccion() -> void:

	get_tree().change_scene_to_file(
		"res://Scenes/UI/SeleccionJugadores.tscn"
	)
