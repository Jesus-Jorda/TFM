extends CanvasLayer

class_name AjustesUI


# TEXTURAS

const TEXTURA_ENGRANAJE: Texture2D = preload(
	"res://Sprites/ajustes.png"
)


# NODOS

var boton_ajustes: TextureButton = null

var panel: Panel = null

var slider_musica: HSlider = null

var slider_efectos: HSlider = null

var btn_pantalla: Button = null

var btn_mute_musica: Button = null

var btn_mute_efectos: Button = null


# READY

func _ready() -> void:

	layer = 6

	_crear_boton_ajustes()

	_crear_panel()


# BOTÓN DE AJUSTES (ESQUINA SUPERIOR DERECHA)

func _crear_boton_ajustes() -> void:

	boton_ajustes = TextureButton.new()

	boton_ajustes.name = "BotonAjustes"

	boton_ajustes.texture_normal = TEXTURA_ENGRANAJE

	boton_ajustes.ignore_texture_size = true

	boton_ajustes.stretch_mode = TextureButton.STRETCH_SCALE

	boton_ajustes.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	boton_ajustes.offset_left = -74.0
	boton_ajustes.offset_top = 10.0
	boton_ajustes.offset_right = -10.0
	boton_ajustes.offset_bottom = 74.0

	boton_ajustes.pressed.connect(_alternar_panel)

	add_child(boton_ajustes)


# PANEL DE AJUSTES

func _crear_panel() -> void:

	panel = Panel.new()

	panel.name = "PanelAjustes"

	panel.position = Vector2(360, 90)

	panel.size = Vector2(560, 540)

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color(0.04, 0.13, 0.06)

	estilo.border_color = Color(0.25, 1.0, 0.35)

	estilo.set_border_width_all(3)

	estilo.set_corner_radius_all(10)

	panel.add_theme_stylebox_override("panel", estilo)

	panel.visible = false

	add_child(panel)

	_construir_contenido(panel)


# CONTENIDO DEL PANEL

func _construir_contenido(padre: Control) -> void:

	# TÍTULO + CERRAR

	var titulo := Label.new()

	titulo.text = "AJUSTES"

	titulo.position = Vector2(24, 18)

	titulo.size = Vector2(300, 40)

	titulo.add_theme_font_size_override("font_size", 30)

	titulo.add_theme_color_override(
		"font_color",
		Color(0.25, 1.0, 0.35)
	)

	padre.add_child(titulo)

	var btn_cerrar := Button.new()

	btn_cerrar.text = "✖"

	btn_cerrar.position = Vector2(486, 16)

	btn_cerrar.size = Vector2(50, 36)

	btn_cerrar.pressed.connect(_alternar_panel)

	padre.add_child(btn_cerrar)

	_construir_volumenes(padre)

	_construir_controles(padre)

	_construir_pantalla_y_salir(padre)


func _construir_volumenes(padre: Control) -> void:

	# MÚSICA

	var lbl_musica := Label.new()

	lbl_musica.text = "🎵  MÚSICA"

	lbl_musica.position = Vector2(24, 92)

	lbl_musica.size = Vector2(160, 28)

	lbl_musica.add_theme_font_size_override("font_size", 17)

	padre.add_child(lbl_musica)


	btn_mute_musica = Button.new()

	btn_mute_musica.text = "SONIDO ON"

	btn_mute_musica.position = Vector2(186, 90)

	btn_mute_musica.size = Vector2(110, 30)

	btn_mute_musica.pressed.connect(_silencio_musica_pulsado)

	padre.add_child(btn_mute_musica)


	slider_musica = HSlider.new()

	slider_musica.min_value = 0.0

	slider_musica.max_value = 1.0

	slider_musica.step = 0.05

	slider_musica.position = Vector2(310, 96)

	slider_musica.size = Vector2(220, 26)

	slider_musica.value_changed.connect(_volumen_musica_cambiado)

	padre.add_child(slider_musica)


	# EFECTOS

	var lbl_efectos := Label.new()

	lbl_efectos.text = "🔔  EFECTOS"

	lbl_efectos.position = Vector2(24, 152)

	lbl_efectos.size = Vector2(160, 28)

	lbl_efectos.add_theme_font_size_override("font_size", 17)

	padre.add_child(lbl_efectos)


	btn_mute_efectos = Button.new()

	btn_mute_efectos.text = "SONIDO ON"

	btn_mute_efectos.position = Vector2(186, 150)

	btn_mute_efectos.size = Vector2(110, 30)

	btn_mute_efectos.pressed.connect(_silencio_efectos_pulsado)

	padre.add_child(btn_mute_efectos)


	slider_efectos = HSlider.new()

	slider_efectos.min_value = 0.0

	slider_efectos.max_value = 1.0

	slider_efectos.step = 0.05

	slider_efectos.position = Vector2(310, 156)

	slider_efectos.size = Vector2(220, 26)

	slider_efectos.value_changed.connect(_volumen_efectos_cambiado)

	padre.add_child(slider_efectos)


func _silencio_musica_pulsado() -> void:

	var ga := _gestor_audio()

	if ga == null:
		return

	ga.set_silencio_musica(not ga.esta_musica_silenciada())

	if btn_mute_musica:
		btn_mute_musica.text = (
			"SONIDO OFF" if ga.esta_musica_silenciada()
			else "SONIDO ON"
		)


func _silencio_efectos_pulsado() -> void:

	var ga := _gestor_audio()

	if ga == null:
		return

	ga.set_silencio_efectos(not ga.esta_efectos_silenciado())

	if btn_mute_efectos:
		btn_mute_efectos.text = (
			"SONIDO OFF" if ga.esta_efectos_silenciado()
			else "SONIDO ON"
		)


func _construir_controles(padre: Control) -> void:

	var controles := Label.new()

	controles.text = (
		"🎮  CONTROLES\n\n" +
		"   MOVER ............ W A S D\n\n" +
		"   INTERACTUAR ...... E\n\n" +
		"   INVENTARIO ....... TOCA UNA RANURA"
	)

	controles.position = Vector2(24, 220)

	controles.size = Vector2(500, 170)

	controles.add_theme_font_size_override("font_size", 17)

	padre.add_child(controles)


func _construir_pantalla_y_salir(padre: Control) -> void:

	btn_pantalla = Button.new()

	btn_pantalla.text = _texto_pantalla()

	btn_pantalla.position = Vector2(24, 400)

	btn_pantalla.size = Vector2(320, 44)

	btn_pantalla.pressed.connect(_alternar_pantalla_completa)

	padre.add_child(btn_pantalla)

	var btn_salir := Button.new()

	btn_salir.text = "❌ SALIR DEL JUEGO"

	btn_salir.position = Vector2(24, 464)

	btn_salir.size = Vector2(320, 44)

	btn_salir.pressed.connect(_salir_del_juego)

	padre.add_child(btn_salir)

	var ga := _gestor_audio()

	if ga:

		if slider_musica:
			slider_musica.value = ga.get_volumen_musica()

		if slider_efectos:
			slider_efectos.value = ga.get_volumen_efectos()


# ACCIONES

func _alternar_panel() -> void:

	if panel == null:
		return

	panel.visible = not panel.visible


func _gestor_audio() -> AudioManager:

	return (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)


func _volumen_musica_cambiado(valor: float) -> void:

	var ga := _gestor_audio()

	if ga:
		ga.set_volumen_musica(valor)


func _volumen_efectos_cambiado(valor: float) -> void:

	var ga := _gestor_audio()

	if ga:
		ga.set_volumen_efectos(valor)


func _texto_pantalla() -> String:

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return "🖥️ PANTALLA COMPLETA: SÍ"

	return "🖥️ PANTALLA COMPLETA: NO"


func _alternar_pantalla_completa() -> void:

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:

		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)

	else:

		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)

	if btn_pantalla:
		btn_pantalla.text = _texto_pantalla()


func _salir_del_juego() -> void:

	get_tree().quit()
