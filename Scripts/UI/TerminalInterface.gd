extends Control

class_name TerminalInterface


# SEÑALES

signal estado_cambiado(abierto: bool)


# NODOS

@onready var background: ColorRect = $Background
@onready var window: Panel = $Window

@onready var header: Label = $Window/Header
@onready var text_label: Label = $Window/Text
@onready var riddle_label: Label = $Window/Riddle
@onready var password_label: Label = $Window/PasswordLabel
@onready var password_input: LineEdit = $Window/PasswordInput
@onready var send_button: Button = $Window/SendButton
@onready var result_label: Label = $Window/Result
@onready var close_button: Button = $Window/CloseButton
@onready var close_hint: Label = $CloseHint


# DATOS

var respuesta_correcta: String = ""
var abierto: bool = false
var cerrando: bool = false
var terminal_actual: Node = null
var terminal_direccion_texto: String = ""
var terminal_room: Node = null

# Permite saltar la animación de arranque al pulsar la pantalla
var animacion_skippeada: bool = false
# EFECTOS DE INTERFERENCIA

var interferencias_activas: bool = false

var rng := RandomNumberGenerator.new()

# COLORES

const COLOR_VERDE := Color(0.25, 1.0, 0.35)
const COLOR_ROJO := Color(1.0, 0.15, 0.15)

const GLITCH_CHARS := [
	"#",
	"%",
	"/",
	"\\",
	"_",
	"-",
	"!",
	"?",
	"0",
	"1"
]


# READY

func _ready() -> void:

	add_to_group("terminal_interface")

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	visible = false

	password_input.text = ""

	password_input.visible = false
	riddle_label.visible = false
	password_label.visible = false
	result_label.visible = false
	close_hint.visible = false

	# CONFIGURAR BACKGROUND

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.color = Color(
		0.02,
		0.08,
		0.03,
		1.0
	)
	background.modulate = Color.WHITE

	# ESTILO DE LA VENTANA TERMINAL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(
		0.04,
		0.13,
		0.06,
		1.0
	)
	panel_style.border_color = Color(
		0.55,
		1.0,
		0.65,
		0.8
	)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.shadow_color = Color(
		0.15,
		1.0,
		0.25,
		0.12
	)
	panel_style.shadow_size = 12
	window.add_theme_stylebox_override("panel", panel_style)

	var verde_texto := Color(0.55, 1.0, 0.62)
	var verde_suave := Color(0.35, 0.86, 0.45)

	header.add_theme_color_override("font_color", verde_texto)
	text_label.add_theme_color_override("font_color", verde_texto)
	riddle_label.add_theme_color_override("font_color", verde_texto)
	password_label.add_theme_color_override("font_color", verde_suave)
	result_label.add_theme_color_override("font_color", COLOR_VERDE)
	close_hint.add_theme_color_override("font_color", verde_suave)

	password_input.add_theme_color_override("font_color", verde_texto)
	password_input.add_theme_color_override("placeholder_text_color", Color(0.6, 1.0, 0.7, 0.7))
	password_input.modulate = Color(1.0, 1.0, 1.0, 1.0)

	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(0.02, 0.08, 0.03, 1.0)
	input_style.border_color = Color(0.45, 1.0, 0.55, 0.9)
	input_style.border_width_left = 1
	input_style.border_width_top = 1
	input_style.border_width_right = 1
	input_style.border_width_bottom = 1
	input_style.corner_radius_top_left = 6
	input_style.corner_radius_top_right = 6
	input_style.corner_radius_bottom_left = 6
	input_style.corner_radius_bottom_right = 6
	password_input.add_theme_stylebox_override("normal", input_style)
	password_input.add_theme_stylebox_override("focus", input_style)

	if close_button:
		close_button.pressed.connect(_solicitar_cierre)
		close_button.text = "SALIR"
		close_button.add_theme_color_override("font_color", verde_texto)

		var close_style := StyleBoxFlat.new()
		close_style.bg_color = Color(0.02, 0.08, 0.03, 1.0)
		close_style.border_color = Color(0.45, 1.0, 0.55, 0.9)
		close_style.border_width_left = 1
		close_style.border_width_top = 1
		close_style.border_width_right = 1
		close_style.border_width_bottom = 1
		close_style.corner_radius_top_left = 6
		close_style.corner_radius_top_right = 6
		close_style.corner_radius_bottom_left = 6
		close_style.corner_radius_bottom_right = 6
		close_button.add_theme_stylebox_override("normal", close_style)
		close_button.add_theme_stylebox_override("hover", close_style)
		close_button.add_theme_stylebox_override("pressed", close_style)

	# CONECTAR ENTER

	password_input.text_submitted.connect(
		_comprobar_password
	)
	password_input.focus_entered.connect(
		_mostrar_teclado_al_recibir_foco
	)
	password_input.gui_input.connect(_entrada_password_pulsada)

	# CONECTAR BOTÓN ENVIAR (TÁCTIL)

	if send_button:
		send_button.pressed.connect(_enviar_password)
		send_button.visible = false

		var send_style := StyleBoxFlat.new()
		send_style.bg_color = Color(0.02, 0.08, 0.03, 1.0)
		send_style.border_color = Color(0.45, 1.0, 0.55, 0.9)
		send_style.border_width_left = 1
		send_style.border_width_top = 1
		send_style.border_width_right = 1
		send_style.border_width_bottom = 1
		send_style.corner_radius_top_left = 6
		send_style.corner_radius_top_right = 6
		send_style.corner_radius_bottom_left = 6
		send_style.corner_radius_bottom_right = 6
		send_button.add_theme_stylebox_override("normal", send_style)
		send_button.add_theme_stylebox_override("hover", send_style)
		send_button.add_theme_stylebox_override("pressed", send_style)
		send_button.add_theme_color_override("font_color", verde_texto)

	rng.randomize()
	call_deferred("_centrar_ventana")
	get_viewport().size_changed.connect(_centrar_ventana)


# CENTRAR VENTANA

func _centrar_ventana() -> void:

	if window == null:
		return

	window.anchor_left = 0.5
	window.anchor_top = 0.5
	window.anchor_right = 0.5
	window.anchor_bottom = 0.5
	window.offset_left = -450
	window.offset_top = -250
	window.offset_right = 450
	window.offset_bottom = 250


# CONFIGURAR TERMINAL ACTIVO

func configurar_terminal(
	terminal: Node,
	direccion_texto: String,
	room: Node
) -> void:

	terminal_actual = terminal
	terminal_direccion_texto = direccion_texto
	terminal_room = room

# ABRIR TERMINAL

func abrir_terminal(
	pregunta: String,
	respuesta: String,
	texto_previo: String = ""
) -> void:

	if abierto:
		return

	abierto = true

	respuesta_correcta = respuesta.strip_edges().to_lower()

	visible = true
	emit_signal("estado_cambiado", true)
	cerrando = false

	# Resetear skip de animación
	animacion_skippeada = false


	# ACTIVAR INTERFERENCIAS

	if not interferencias_activas:

		interferencias_activas = true

		_efecto_interferencias()
	# RESET

	text_label.text = ""
	riddle_label.text = ""
	result_label.text = ""

	# Sobrecarga del electricista: parte de la respuesta
	# ya aparece escrita (solo respuestas numéricas).
	password_input.text = texto_previo

	riddle_label.visible = false
	password_label.visible = false
	result_label.visible = false
	password_input.visible = false
	send_button.visible = false
	close_hint.visible = true

	password_input.editable = true
	password_input.focus_mode = Control.FOCUS_ALL
	password_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	password_input.mouse_filter = Control.MOUSE_FILTER_STOP
	password_input.z_index = 20

	# Color por defecto
	result_label.add_theme_color_override(
		"font_color",
		COLOR_VERDE
	)

	# EFECTO ENCENDIDO TERMINAL

	await _efecto_encendido()

	#aqui
	if not abierto:
		return


	# TEXTO DE ARRANQUE

	await _escribir_texto(
		"> INITIALIZING TERMINAL..."
	)

	if animacion_skippeada:
		_mostrar_pregunta_directa(pregunta)
		return

	await get_tree().create_timer(
		0.20
	).timeout


	await _escribir_texto(
		"> SYSTEM ONLINE"
	)

	if animacion_skippeada:
		_mostrar_pregunta_directa(pregunta)
		return

	await get_tree().create_timer(
		0.20
	).timeout


	await _escribir_texto(
		"> SECURITY CHECK..."
	)

	if animacion_skippeada:
		_mostrar_pregunta_directa(pregunta)
		return

	await get_tree().create_timer(
		0.30
	).timeout


	await _escribir_texto(
		"> ACCESS REQUESTED"
	)

	if animacion_skippeada:
		_mostrar_pregunta_directa(pregunta)
		return

	await get_tree().create_timer(
		0.30
	).timeout


	# MOSTRAR ACERTIJO

	riddle_label.text = ""
	riddle_label.visible = true

	await _escribir_acertijo(pregunta)

	if not abierto:
		return

	if animacion_skippeada:
		_mostrar_pregunta_directa(pregunta)
		return


	# PASSWORD

	await get_tree().create_timer(
		0.25
	).timeout

	_mostrar_pregunta_directa(pregunta)


# EFECTO ENCENDIDO

func _efecto_encendido() -> void:

	background.modulate.a = 0.0

	text_label.modulate.a = 0.0
	header.modulate.a = 0.0

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		0.35
	)

	tween.tween_property(
		header,
		"modulate:a",
		1.0,
		0.35
	)

	tween.tween_property(
		text_label,
		"modulate:a",
		1.0,
		0.35
	)

	await tween.finished

# INTERFERENCIAS DEL TERMINAL

func _efecto_interferencias() -> void:

	while abierto:

		# Esperar un tiempo aleatorio
		var espera := rng.randf_range(1.0, 3.0)

		await get_tree().create_timer(
			espera
		).timeout

		if not abierto:
			return

		var tipo := rng.randi_range(0, 2)

		match tipo:

			0:
				await _parpadeo_pantalla()

			1:
				await _raya_interferencia()

			2:
				await _interferencia_fuerte()


# PARPADEO DE PANTALLA

func _parpadeo_pantalla() -> void:

	if not abierto:
		return

	var tween := create_tween()

	tween.tween_property(
		background,
		"modulate",
		Color(1.4, 1.4, 1.4, 1),
		0.04
	)

	tween.tween_property(
		background,
		"modulate",
		Color(0.55, 0.8, 0.6, 1),
		0.05
	)

	tween.tween_property(
		background,
		"modulate",
		Color.WHITE,
		0.08
	)

	await tween.finished


# RAYA DE INTERFERENCIA

func _raya_interferencia() -> void:

	if not abierto:
		return

	var area_size := get_rect().size
	if area_size.x <= 0 or area_size.y <= 0:
		area_size = get_viewport_rect().size

	var raya := ColorRect.new()

	raya.name = "GlitchLine"

	raya.color = Color(
		0.8,
		1.0,
		0.85,
		rng.randf_range(0.15, 0.45)
	)

	raya.mouse_filter = Control.MOUSE_FILTER_IGNORE

	raya.z_index = 100

	raya.position = Vector2(
		0,
		rng.randf_range(
			0,
			area_size.y
		)
	)

	raya.size = Vector2(
		area_size.x,
		rng.randf_range(1.0, 3.0)
	)

	add_child(raya)

	var duracion := rng.randf_range(
		0.04,
		0.15
	)

	var tween := create_tween()

	tween.tween_property(
		raya,
		"position:y",
		raya.position.y + rng.randf_range(
			20.0,
			100.0
		),
		duracion
	)

	tween.parallel().tween_property(
		raya,
		"modulate:a",
		0.0,
		duracion
	)

	await tween.finished

	if is_instance_valid(raya):
		raya.queue_free()


# INTERFERENCIA FUERTE

func _interferencia_fuerte() -> void:

	if not abierto:
		return

	# Varias rayas rápidamente

	for i in range(3):

		if not abierto:
			return

		await _raya_interferencia()

		await get_tree().create_timer(
			0.03
		).timeout

	# Pequeño apagón

	background.modulate = Color(
		0.15,
		0.3,
		0.2,
		1
	)

	await get_tree().create_timer(
		0.04
	).timeout

	background.modulate = Color.WHITE
# ESCRIBIR TEXTO NORMAL

func _escribir_texto(
	texto: String
) -> void:

	var linea := ""

	for caracter in texto:

		if not abierto:
			return

		if animacion_skippeada:
			text_label.text = texto
			return

		linea += caracter

		text_label.text = linea

		await get_tree().create_timer(
			0.025
		).timeout


# ESCRIBIR ACERTIJO

func _escribir_acertijo(
	texto: String
) -> void:

	var linea := ""

	for i in texto.length():

		if not abierto:
			return

		if animacion_skippeada:
			riddle_label.text = texto
			return

		var caracter := texto[i]

		linea += caracter

		riddle_label.text = linea

		# PEQUEÑO GLITCH ALEATORIO

		if randf() < 0.12:

			var glitch_char: String = GLITCH_CHARS[
				randi() % GLITCH_CHARS.size()
			]

			riddle_label.text += glitch_char

			await get_tree().create_timer(
				0.035
			).timeout

			riddle_label.text = linea


		# VELOCIDAD DE ESCRITURA

		var velocidad := 0.035

		# Algunas letras tienen pequeños cortes
		if randf() < 0.08:

			await get_tree().create_timer(
				0.12
			).timeout

		await get_tree().create_timer(
			velocidad
		).timeout


	# GLITCH FINAL

	await _efecto_glitch()


# EFECTO GLITCH

func _efecto_glitch() -> void:

	var texto_original := riddle_label.text

	for i in 3:

		var glitch_text := ""

		for caracter in texto_original:

			if randf() < 0.15:

				glitch_text += GLITCH_CHARS[
					randi() % GLITCH_CHARS.size()
				]

			else:

				glitch_text += caracter


		riddle_label.text = glitch_text

		await get_tree().create_timer(
			0.04
		).timeout


	riddle_label.text = texto_original


# COMPROBAR PASSWORD

func _comprobar_password(
	texto: String
) -> void:

	var respuesta := texto.strip_edges().to_lower()


	# CORRECTA

	if respuesta == respuesta_correcta:
		var ga := get_tree().get_first_node_in_group("gestor_audio")
		if ga != null:
			ga.reproducir_efecto_corto(
				"respuestacorrecta",
				0.9,
				0.0
			)

		result_label.text = (
			"> ACCESS GRANTED"
		)

		result_label.visible = true

		result_label.add_theme_color_override(
			"font_color",
			COLOR_VERDE
		)

		password_input.editable = false

		if terminal_actual != null and terminal_actual.has_method(
			"desbloquear_puerta_asociada"
		):
			terminal_actual.call("desbloquear_puerta_asociada")

		await _efecto_resultado(true)
		cerrar_terminal()


	# INCORRECTA

	else:
		var ga := get_tree().get_first_node_in_group("gestor_audio")
		if ga != null:
			ga.reproducir_efecto_corto(
				"respuestaincorrecta",
				0.8,
				0.0
			)

		result_label.text = (
			"> ACCESS DENIED"
		)

		result_label.visible = true

		result_label.add_theme_color_override(
			"font_color",
			COLOR_ROJO
		)

		password_input.select_all()
		password_input.grab_focus()

		await _efecto_resultado(false)


# SOLICITAR CIERRE

func _solicitar_cierre() -> void:

	if not abierto:
		return

	if cerrando:
		return

	cerrar_terminal()


# EFECTO RESULTADO

func _efecto_resultado(correcto: bool) -> void:

	# Pequeño parpadeo de terminal

	for i in 3:

		if not abierto:
			return

		result_label.modulate.a = 0.2

		await get_tree().create_timer(
			0.05
		).timeout

		result_label.modulate.a = 1.0

		await get_tree().create_timer(
			0.06
		).timeout


	# Si es incorrecta hacemos un pequeño temblor

	if not correcto:

		var posicion_original := result_label.position

		for i in 4:

			result_label.position = (
				posicion_original +
				Vector2(
					randf_range(-2.0, 2.0),
					randf_range(-1.0, 1.0)
				)
			)

			await get_tree().create_timer(
				0.03
			).timeout

		result_label.position = posicion_original


# ENVIAR PASSWORD (BOTÓN TÁCTIL)

func _enviar_password() -> void:

	if not abierto:
		return

	if cerrando:
		return

	_comprobar_password(password_input.text)


# MOSTRAR PREGUNTA DIRECTA (SIN ANIMACIÓN)

func _mostrar_pregunta_directa(pregunta: String) -> void:

	if not abierto:
		return

	# Mostrar texto de arranque completo
	text_label.text = (
		"> INITIALIZING TERMINAL...\n"
		+ "> SYSTEM ONLINE\n"
		+ "> SECURITY CHECK...\n"
		+ "> ACCESS REQUESTED"
	)

	# Mostrar acertijo completo
	riddle_label.text = pregunta
	riddle_label.visible = true

	# Mostrar password
	password_label.visible = true
	password_input.visible = true
	send_button.visible = true

	await get_tree().process_frame
	password_input.editable = true
	password_input.grab_focus()
	call_deferred("_activar_teclado_virtual")


func _activar_teclado_virtual() -> void:
	if not abierto or not is_instance_valid(password_input):
		return
	password_input.visible = true
	password_input.editable = true
	password_input.focus_mode = Control.FOCUS_ALL
	password_input.grab_focus()
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		print("[Terminal] Este dispositivo no expone teclado virtual a Godot")
		return
	var posicion := Rect2i(
		Vector2i(password_input.global_position),
		Vector2i(password_input.size)
	)
	DisplayServer.virtual_keyboard_show(
		password_input.text,
		posicion,
		DisplayServer.KEYBOARD_TYPE_DEFAULT
	)
	print("[Terminal] Solicitud de teclado virtual enviada")


func _mostrar_teclado_al_recibir_foco() -> void:
	if abierto:
		call_deferred("_activar_teclado_virtual")


func _entrada_password_pulsada(event: InputEvent) -> void:
	var pulsado := false
	if event is InputEventScreenTouch:
		pulsado = event.pressed
	elif event is InputEventMouseButton:
		pulsado = event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT

	if not pulsado or not abierto:
		return

	password_input.editable = true
	password_input.grab_focus()
	password_input.caret_column = password_input.text.length()
	get_viewport().set_input_as_handled()
	call_deferred("_activar_teclado_virtual")


func _activar_password_desde_evento(event: InputEvent) -> bool:
	if not abierto or not password_input.visible:
		return false

	var posicion: Vector2
	if event is InputEventScreenTouch and event.pressed:
		posicion = event.position
	elif event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		posicion = event.position
	else:
		return false

	if password_input.get_global_rect().has_point(posicion):
		print("[Terminal] Toque detectado en campo de respuesta")
		password_input.editable = true
		password_input.grab_focus()
		password_input.caret_column = password_input.text.length()
		call_deferred("_activar_teclado_virtual")
		get_viewport().set_input_as_handled()
		return true

	return false


# CERRAR

func cerrar_terminal() -> void:

	if not abierto:
		return

	abierto = false

	interferencias_activas = false

	# Limpiar referencia al terminal activo
	terminal_actual = null
	terminal_direccion_texto = ""
	terminal_room = null

	visible = false
	emit_signal("estado_cambiado", false)

	password_input.text = ""

	password_input.release_focus()

	send_button.visible = false

	background.modulate = Color.WHITE

# DETECTAR TOQUE/PULSACIÓN PARA SKIP

func _input(
	event: InputEvent
) -> void:

	if not abierto:
		return

	if _activar_password_desde_evento(event):
		return

	# Solo durante la animación de arranque
	if animacion_skippeada:
		return

	# Detectar toque táctil o clic de ratón
	if event is InputEventScreenTouch:

		if event.pressed:
			animacion_skippeada = true

	elif event is InputEventMouseButton:

		if event.pressed:
			animacion_skippeada = true


# ESC PARA SALIR

func _unhandled_input(
	event: InputEvent
) -> void:

	if not abierto:
		return


	if event is InputEventKey:

		if event.pressed and event.keycode == KEY_ESCAPE:

			cerrar_terminal()

			get_viewport().set_input_as_handled()
