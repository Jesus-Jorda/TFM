extends CanvasLayer
## Overlay de transición entre turnos: oscurece la pantalla y muestra
## "TURNO DEL JUGADOR X" junto al nombre del personaje.
## Espera a que el jugador pulse una tecla o click para continuar.
## Uso: overlay.mostrar(2, "Forzudo") -> emite transicion_culminada al acabar.

signal transicion_culminada

const DURACION_ENTRADA := 0.35
const DURACION_REVELAR := 0.15
const DURACION_SALIDA := 0.45
const COLOR_FOSFORO := Color("3dff6e")
const COLOR_CLARO := Color("baffc9")

var _fondo: ColorRect
var _caja: VBoxContainer
var _titulo: Label
var _nombre: Label
var _indicacion: Label
var _tween: Tween
var _tween_indicacion: Tween
var _reproduciendo := false
var _cerrando := false


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	visible = false
	_construir_ui()


func _construir_ui() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 1)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.add_child(centro)

	_caja = VBoxContainer.new()
	_caja.alignment = BoxContainer.ALIGNMENT_CENTER
	_caja.add_theme_constant_override("separation", 16)
	centro.add_child(_caja)

	var fuente: Font = load("res://DePixelBreit.ttf")

	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_titulo.add_theme_font_override("font", fuente)
	_titulo.add_theme_font_size_override("font_size", 40)
	_titulo.add_theme_color_override("font_color", COLOR_FOSFORO)
	_caja.add_child(_titulo)

	_nombre = Label.new()
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.add_theme_font_override("font", fuente)
	_nombre.add_theme_font_size_override("font_size", 24)
	_nombre.add_theme_color_override("font_color", COLOR_CLARO)
	_caja.add_child(_nombre)

	# Indicacion parpadeante: funciona tanto con raton como con pantalla tactil.
	_indicacion = Label.new()
	_indicacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_indicacion.add_theme_font_override("font", fuente)
	_indicacion.add_theme_font_size_override("font_size", 13)
	_indicacion.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
	_indicacion.text = "TOCA O HAZ CLIC PARA CONTINUAR"
	_indicacion.visible = false
	_caja.add_child(_indicacion)


func mostrar(num_jugador: int, nombre_personaje: String = "") -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if _tween_indicacion and _tween_indicacion.is_valid():
		_tween_indicacion.kill()

	_titulo.text = "TURNO DEL JUGADOR %d" % num_jugador
	_nombre.text = nombre_personaje
	_nombre.visible = nombre_personaje != ""

	# Mostrar indicacion de pulsar con un pequeno parpadeo.
	_indicacion.visible = true
	_indicacion.self_modulate.a = 0.0
	_tween_indicacion = create_tween()
	_tween_indicacion.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween_indicacion.tween_property(_indicacion, "self_modulate:a", 0.6, 0.4)
	_tween_indicacion.tween_property(_indicacion, "self_modulate:a", 0.2, 0.4)
	_tween_indicacion.set_loops()

	visible = true
	_reproduciendo = true
	_cerrando = false

	_fondo.modulate.a = 0.0
	_caja.modulate.a = 0.0

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(_fondo, "modulate:a", 1.0, DURACION_ENTRADA)
	_tween.tween_property(_caja, "modulate:a", 1.0, DURACION_ENTRADA)
	_tween.finished.connect(_comenzar_parpadeo, CONNECT_ONE_SHOT)


func _comenzar_parpadeo() -> void:
	# Estado estable: esperando clic del jugador para continuar.
	pass


func _input(event: InputEvent) -> void:
	# Solo avanza mediante clic del raton o el primer toque de pantalla.
	if not _reproduciendo or _cerrando:
		return

	var confirmar := false
	if event is InputEventMouseButton:
		confirmar = event.pressed
	elif event is InputEventScreenTouch:
		confirmar = event.pressed

	if confirmar:
		_cerrando = true
		get_viewport().set_input_as_handled()
		_comenzar_salida()


func _comenzar_salida() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	if _tween_indicacion and _tween_indicacion.is_valid():
		_tween_indicacion.kill()

	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(_caja, "modulate:a", 0.0, DURACION_SALIDA)
	_tween.tween_property(_fondo, "modulate:a", 0.0, DURACION_SALIDA)
	_tween.finished.connect(_terminar, CONNECT_ONE_SHOT)


func _terminar() -> void:
	visible = false
	_reproduciendo = false
	_cerrando = false
	transicion_culminada.emit()


func esta_reproduciendo() -> bool:
	return _reproduciendo
