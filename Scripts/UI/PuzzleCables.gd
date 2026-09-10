extends CanvasLayer

class_name PuzzleCables


# SEÑALES

signal resuelto
signal cerrado


# RECURSOS DEL PUZLE

const RUTA_FONDO := "res://Sprites/fondoele.jpg"

const RUTA_PANEL := "res://Sprites/fondopele.png"

const RUTAS_CONECTORES := {
	"rojo": "res://Sprites/crojo.png",
	"lila": "res://Sprites/clila.png",
	"azul": "res://Sprites/cazul.png",
	"amarillo": "res://Sprites/camarillo.png"
}

# Imagen con el texto del voltaje (5V, 12V, 24V, 48V)
const RUTA_VOLTAJES := {
	"5V": "res://Sprites/5v.png",
	"12V": "res://Sprites/12v.png",
	"24V": "res://Sprites/24v.png",
	"48V": "res://Sprites/48v.png"
}

const COLORES := {
	"rojo": Color(0.92, 0.25, 0.22),
	"lila": Color(0.66, 0.45, 0.95),
	"azul": Color(0.28, 0.58, 1.0),
	"amarillo": Color(0.96, 0.85, 0.30)
}

# Voltaje -> color correcto que necesita cada salida.
# El jugador debe casar AMBOS: colordel cable y voltaje de la etiqueta.
const VOLTAJE_COLOR := {
	"5V": "rojo",
	"12V": "lila",
	"24V": "azul",
	"48V": "amarillo"
}

# Entradas (más cables que salidas: hay señuelos que no casan nunca)
const ENTRADAS := [
	{ "color": "rojo", "voltaje": "5V" },
	{ "color": "lila", "voltaje": "12V" },
	{ "color": "azul", "voltaje": "24V" },
	{ "color": "amarillo", "voltaje": "48V" },
	{ "color": "rojo", "voltaje": "24V" },
	{ "color": "amarillo", "voltaje": "12V" }
]

# Salidas: solo voltaje necesario. Su color real se deduce de VOLTAJE_COLOR.
# Van barajadas a propósito para no coincidir con la columna de entradas.
const SALIDAS := [
	{ "voltaje": "12V" },
	{ "voltaje": "48V" },
	{ "voltaje": "5V" },
	{ "voltaje": "24V" }
]


# ESTADO

var abierto: bool = false

var _conectores: Array[Dictionary] = []

var _cables: Array[Dictionary] = []

var _arrastre: int = -1

var _linea_temporal: Line2D = null

var _capa_cables: Node2D = null

var _mensaje: Label = null

var _resuelto: bool = false

var _marcas: Array[Dictionary] = []

var _resultado: Label = null

var _boton_prueba: Button = null
var _boton_salir: Button = null

# Sobrecarga del electricista: el puzzle se abre con la
# mitad de los cables ya conectados y correctos.
var sobrecargado: bool = false


# READY

func _ready() -> void:

	layer = 7

	visible = false

	add_to_group("puzzle_cables")

	_construir_boton_salir()


# BOTÓN SALIR (abandona el puzzle sin resolverlo)

func _construir_boton_salir() -> void:

	_boton_salir = Button.new()

	_boton_salir.text = "SALIR (ESC)"

	_boton_salir.position = Vector2(1080, 16)
	_boton_salir.size = Vector2(180, 44)
	_boton_salir.focus_mode = Control.FOCUS_NONE
	_boton_salir.z_index = 100
	_boton_salir.mouse_filter = Control.MOUSE_FILTER_STOP
	_boton_salir.modulate = Color.WHITE
	_boton_salir.pressed.connect(cerrar)
	add_child(_boton_salir)


func _unhandled_input(event: InputEvent) -> void:

	if not abierto:

		return

	if event is InputEventKey \
			and event.pressed \
			and event.keycode == KEY_ESCAPE:

		cerrar()

		get_viewport().set_input_as_handled()


# ABRIR / CERRAR

func abrir() -> void:

	if abierto:
		return

	abierto = true

	visible = true

	_construir_escena()
	if _boton_salir != null:
		_boton_salir.z_index = 100
		_boton_salir.show()
		move_child(_boton_salir, get_child_count() - 1)

	_bloquear_jugador(true)

	# El contador de turno se congela mientras el
	# puzzle está abierto.
	get_tree().call_group(
		"gestor_turnos", "establecer_en_puzzle", true
	)

	# Sobrecarga del electricista: mitad de los cables
	# ya conectados y correctos.
	if sobrecargado:

		_preconectar_mitad()


func cerrar() -> void:
	if not abierto:
		return

	abierto = false

	visible = false

	_bloquear_jugador(false)

	# Reactivar el contador de turno al cerrar.
	get_tree().call_group(
		"gestor_turnos", "establecer_en_puzzle", false
	)
	cerrado.emit()


func _bloquear_jugador(bloqueado: bool) -> void:

	# Si el nodo aún no está en el árbol (p.ej. tests),
	# no hay jugador ni manager que bloquear.
	if not is_inside_tree():
		return

	var im := (
		get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
	)

	if im:

		im.establecer_activo(not bloqueado)

		if im.jugador:
			im.jugador.movimiento_bloqueado = bloqueado


# SOBRECARGA (ELECTRICISTA LOCO)
# Preconecta correctamente la mitad de las salidas:
# el jugador solo tiene que completar el resto.

func _preconectar_mitad() -> void:

	if _resuelto or _conectores.is_empty():

		return

	var objetivo: int = int(SALIDAS.size() / 2.0)

	var conectadas: int = 0

	for s in range(SALIDAS.size()):

		if conectadas >= objetivo:

			break

		var salida_indice: int = ENTRADAS.size() + s

		if _cable_es_correcto(salida_indice):

			conectadas += 1

			continue

		var entrada: int = _entrada_correcta_para(
			salida_indice
		)

		if entrada == -1:

			continue

		_quitar_cable_de_entrada(entrada)

		_quitar_cable_de_salida(salida_indice)

		var linea := _nueva_linea(
			_conectores[entrada]["color"]
		)

		_rellenar_linea(
			linea,
			_conectores[entrada]["centro"],
			_conectores[salida_indice]["centro"]
		)

		_cables.append({
			"izq": entrada,
			"der": salida_indice,
			"linea": linea
		})

		conectadas += 1

	_refrescar_marcas()

	print(
		"⚡ Sobrecarga: ", conectadas,
		" cable(s) ya conectado(s) de ", SALIDAS.size()
	)


# Índice de la entrada que casaría con esta salida
# (mismo color y voltaje). -1 si no hay ninguna.
func _entrada_correcta_para(salida_indice: int) -> int:

	var sal: Dictionary = _conectores[salida_indice]

	for i in range(_conectores.size()):

		var c: Dictionary = _conectores[i]

		if c["lado"] != "izq":

			continue

		if c["voltaje"] == sal["voltaje"] \
				and c["color"] == sal["color"]:

			return i

	return -1


# VIBRACIÓN DEL GOLPE DE SUELO
# Suelta todos los cables conectados: las conexiones hay
# que rehacerlas desde cero.

func desordenar_piezas() -> void:

	if _resuelto or _conectores.is_empty():
		return

	for cable in _cables:
		var linea: Line2D = cable["linea"]
		if linea != null and is_instance_valid(linea):
			linea.queue_free()

	_cables.clear()

	# Si había un cable a medio arrastrar, se corta.
	if _linea_temporal != null and is_instance_valid(_linea_temporal):
		_linea_temporal.queue_free()
	_linea_temporal = null
	_arrastre = -1

	_refrescar_marcas()


# CONSTRUIR LA ESCENA DEL PUZLE

func _construir_escena() -> void:

	_conectores.clear()

	_cables.clear()

	_arrastre = -1


	# FONDO OSCURECIDO + FONDO ELÉCTRICO

	var fondo_oscuro := ColorRect.new()

	fondo_oscuro.color = Color(0, 0, 0, 0.55)

	fondo_oscuro.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fondo_oscuro.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(fondo_oscuro)


	var fondo := TextureRect.new()

	fondo.texture = _tex(RUTA_FONDO)

	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	fondo.stretch_mode = TextureRect.STRETCH_SCALE

	fondo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(fondo)


	# PANEL METÁLICO CENTRAL

	var textura_panel := _tex(RUTA_PANEL)

	if textura_panel:

		var rect_panel := TextureRect.new()

		rect_panel.texture = textura_panel

		rect_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

		rect_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		rect_panel.position = Vector2(352, 39)

		rect_panel.size = Vector2(576, 642)

		rect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		add_child(rect_panel)

	else:

		var panel_alt := Panel.new()

		panel_alt.position = Vector2(352, 39)

		panel_alt.size = Vector2(576, 642)

		add_child(panel_alt)


	# CAPA DONDE SE DIBUJAN LOS CABLES

	_capa_cables = Node2D.new()

	_capa_cables.name = "CapaCables"

	add_child(_capa_cables)


	# CONECTORES DE ENTRADA (izquierda, con señuelos)

	for i in range(ENTRADAS.size()):

		var datos: Dictionary = ENTRADAS[i]

		_crear_conector(
			i, "izq", datos["color"],
			datos["voltaje"],
			Vector2(430, 170 + i * 76)
		)


	# CONECTORES DE SALIDA (derecha, reordenados)

	for i in range(SALIDAS.size()):

		var datos_salida: Dictionary = SALIDAS[i]

		var color_necesario: String = VOLTAJE_COLOR[datos_salida["voltaje"]]

		# Índice plano: primero van las 6 entradas
		var indice_plano := ENTRADAS.size() + i

		_crear_conector(
			indice_plano, "der", color_necesario,
			datos_salida["voltaje"],
			Vector2(842, 244 + i * 96)
		)


	# MARCADORES ✓ / ✗ de cada salida

	_construir_marcas()


	# PANEL DE RESULTADO DE LA PRUEBA

	_construir_panel_prueba()


	var pista := Label.new()

	pista.text = "CONECTA CADA CABLE AL VOLTAJE CORRECTO\n(COLOR + VOLTAJE DEBEN COINCIDIR)"

	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	pista.position = Vector2(352, 648)

	pista.size = Vector2(576, 50)

	pista.add_theme_font_size_override("font_size", 15)

	pista.add_theme_color_override(
		"font_color",
		Color(0.7, 0.9, 0.75)
	)

	add_child(pista)


func _crear_conector(
	indice: int,
	lado: String,
	color_nombre: String,
	voltaje: String,
	centro: Vector2
) -> void:

	var color: Color = COLORES[color_nombre]


	# CUERPO DEL CONECTOR
	# Entrada -> sprite con el color visible.
	# Salida  -> zócalo metálico neutro (color oculto).

	if lado == "izq":

		var textura := _tex(RUTAS_CONECTORES[color_nombre])

		if textura:

			var rect := TextureRect.new()

			rect.texture = textura

			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			rect.size = Vector2(64, 64)

			rect.position = centro - Vector2(32, 32)

			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

			add_child(rect)

		else:

			var placa := Panel.new()

			var estilo := StyleBoxFlat.new()

			estilo.bg_color = color

			estilo.set_corner_radius_all(24)

			placa.add_theme_stylebox_override("panel", estilo)

			placa.size = Vector2(56, 56)

			placa.position = centro - Vector2(28, 28)

			placa.mouse_filter = Control.MOUSE_FILTER_IGNORE

			add_child(placa)

	else:

		# Zócalo de salida: gris metálico
		var zocalo := Panel.new()

		var flame := StyleBoxFlat.new()

		flame.bg_color = Color(0.45, 0.48, 0.52)

		flame.border_color = Color(0.22, 0.24, 0.27)

		flame.set_border_width_all(4)

		flame.set_corner_radius_all(18)

		zocalo.add_theme_stylebox_override("panel", flame)

		zocalo.size = Vector2(64, 64)

		zocalo.position = centro - Vector2(32, 32)

		zocalo.mouse_filter = Control.MOUSE_FILTER_IGNORE

		add_child(zocalo)


		# Conector de salida: sprite con el color requerido por esta salida
		var textura_salida := _tex(RUTAS_CONECTORES[color_nombre])

		if textura_salida:

			var rect_salida := TextureRect.new()

			rect_salida.texture = textura_salida

			rect_salida.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

			rect_salida.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			rect_salida.size = Vector2(64, 64)

			rect_salida.position = centro - Vector2(32, 32)

			rect_salida.mouse_filter = Control.MOUSE_FILTER_IGNORE

			add_child(rect_salida)


	# ETIQUETAS
	# Entrada -> voltaje pequeño debajo del conector.
	# Salida  -> placa pintada del color requerido + voltaje.

	if lado == "izq":

		var etiqueta := Label.new()

		var tex_volt := _tex(RUTA_VOLTAJES.get(voltaje, ""))

		if tex_volt:

			var rect_volt := TextureRect.new()

			rect_volt.texture = tex_volt

			rect_volt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

			rect_volt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			rect_volt.mouse_filter = Control.MOUSE_FILTER_IGNORE

			rect_volt.size = Vector2(70, 46)

			rect_volt.position = centro + Vector2(-118, -23)

			add_child(rect_volt)

		else:

			etiqueta.text = voltaje

			etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

			etiqueta.position = centro + Vector2(-40, 32)

			etiqueta.size = Vector2(80, 26)

			etiqueta.add_theme_font_size_override("font_size", 17)

			etiqueta.add_theme_color_override(
				"font_color",
				Color(0.8, 0.85, 0.9)
			)

			etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

			add_child(etiqueta)

	else:

		# Etiqueta de la salida: imagen real del voltaje (5V/12V/24V/48V)
		var tex_volt := _tex(RUTA_VOLTAJES.get(voltaje, ""))

		if tex_volt:

			var rect_volt := TextureRect.new()

			rect_volt.texture = tex_volt

			rect_volt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

			rect_volt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

			rect_volt.mouse_filter = Control.MOUSE_FILTER_IGNORE

			rect_volt.size = Vector2(70, 46)

			rect_volt.position = centro + Vector2(48, -23)

			add_child(rect_volt)

		else:

			var etiqueta_volt := Label.new()

			etiqueta_volt.text = voltaje

			etiqueta_volt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

			etiqueta_volt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

			etiqueta_volt.position = centro + Vector2(50, -14)

			etiqueta_volt.size = Vector2(84, 32)

			etiqueta_volt.add_theme_font_size_override("font_size", 18)

			etiqueta_volt.add_theme_color_override(
				"font_color",
				Color(0.12, 0.10, 0.08)
			)

			etiqueta_volt.mouse_filter = Control.MOUSE_FILTER_IGNORE

			add_child(etiqueta_volt)


	# ÁREA DE DETECCIÓN (para pulsar/soltar)

	var caja := Rect2(
		centro.x - 42.0,
		centro.y - 42.0,
		84.0,
		84.0
	)

	_conectores.append({
		"lado": lado,
		"indice": indice,
		"color": color,
		"voltaje": voltaje,
		"centro": centro,
		"rect": caja.grow(8)
	})


# ENTRADA (RATÓN / TÁCTIL EMULADO)

func _input(event: InputEvent) -> void:

	if not abierto:
		return


	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT:

		var punto: Vector2 = event.position

		if event.pressed:
			_pulsar(punto)
		else:
			_soltar(punto)


	elif event is InputEventMouseMotion and _arrastre != -1:

		_actualizar_linea_temporal(event.position)


# PULSAR

func _pulsar(punto: Vector2) -> void:

	if _resuelto:
		return

	# PULSAR SALIDA: QUITAR CABLE CONECTADO

	var salida := _conector_en(punto, "der")

	if salida != -1:

		if _quitar_cable_de_salida(salida):

			_arrastre = -1

			_refrescar_marcas()

			return


	# PULSAR ENTRADA: EMPEZAR A TIRAR DEL CABLE

	var entrada := _conector_en(punto, "izq")

	if entrada == -1:
		return

	# Si ya tenía cable, se sustituye
	_quitar_cable_de_entrada(entrada)

	_arrastre = entrada

	_linea_temporal = _nueva_linea(
		_conectores[entrada]["color"]
	)

	var inicio: Vector2 = _conectores[entrada]["centro"]

	_actualizar_linea_temporal(inicio)


# SOLTAR

func _soltar(punto: Vector2) -> void:

	if _arrastre == -1 or _resuelto:
		return

	var salida := _conector_en(punto, "der")

	if salida != -1:

		_quitar_cable_de_salida(salida)

		var linea := _linea_temporal

		_linea_temporal = null

		_cables.append({
			"izq": _arrastre,
			"der": salida,
			"linea": linea
		})

		_refrescar_marcas()

	else:

		if _linea_temporal:
			_linea_temporal.queue_free()

		_linea_temporal = null

	_arrastre = -1


# ACTUALIZAR CABLE MIENTRAS SE ARRASTRA

func _actualizar_linea_temporal(punto: Vector2) -> void:

	if _linea_temporal == null or _arrastre == -1:
		return

	var inicio: Vector2 = _conectores[_arrastre]["centro"]

	_rellenar_linea(_linea_temporal, inicio, punto)


# GESTIÓN DE CABLES

func _quitar_cable_de_entrada(indice: int) -> void:

	for i in range(_cables.size()):

		if _cables[i]["izq"] == indice:

			_cables[i]["linea"].queue_free()

			_cables.remove_at(i)

			return


func _quitar_cable_de_salida(indice: int) -> bool:

	for i in range(_cables.size()):

		if _cables[i]["der"] == indice:

			_cables[i]["linea"].queue_free()

			_cables.remove_at(i)

			return true

	return false


func _nueva_linea(color: Color) -> Line2D:

	var linea := Line2D.new()

	linea.width = 7.0

	linea.default_color = color

	linea.joint_mode = Line2D.LINE_JOINT_ROUND

	linea.begin_cap_mode = Line2D.LINE_CAP_ROUND

	linea.end_cap_mode = Line2D.LINE_CAP_ROUND

	_capa_cables.add_child(linea)

	return linea


func _rellenar_linea(
	linea: Line2D,
	desde: Vector2,
	hasta: Vector2
) -> void:

	linea.clear_points()

	var puntos := 14

	for i in range(puntos + 1):

		var t := float(i) / float(puntos)

		var p := desde.lerp(hasta, t)

		# Caída natural del cable
		p.y += sin(t * PI) * 18.0

		linea.add_point(p)


func _conector_en(punto: Vector2, lado: String) -> int:

	for i in range(_conectores.size()):

		var c: Dictionary = _conectores[i]

		if c["lado"] == lado and (c["rect"] as Rect2).has_point(punto):
			return i

	return -1


# MARCADORES ✓ / ✗ (uno por salida)

func _construir_marcas() -> void:

	for i in range(SALIDAS.size()):

		var etiqueta := Label.new()

		etiqueta.text = ""

		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		etiqueta.size = Vector2(52, 52)

		etiqueta.position = Vector2(664, 244 + i * 96 - 22)

		etiqueta.add_theme_font_size_override("font_size", 44)

		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

		add_child(etiqueta)

		_marcas.append({
			"label": etiqueta,
			"correct": false,
			"estimado": false
		})


func _cable_es_correcto(salida_indice: int) -> bool:

	for cable in _cables:

		if cable["der"] == salida_indice:

			var entrada: Dictionary = _conectores[cable["izq"]]

			var sal: Dictionary = _conectores[salida_indice]

			# Color y voltaje tienen que coincidir ambos
			return (
				entrada["voltaje"] == sal["voltaje"]
				and entrada["color"] == sal["color"]
			)

	return false


func _refrescar_marcas() -> void:

	for i in range(SALIDAS.size()):

		var salida_indice := ENTRADAS.size() + i

		var correcto := _cable_es_correcto(salida_indice)

		_marcas[i]["correct"] = correcto

		_marcas[i]["estimado"] = true

		_actualizar_marca(i)


func _actualizar_marca(i: int) -> void:

	var marca: Dictionary = _marcas[i]

	var label: Label = marca["label"]

	var correct: bool = marca["correct"]

	label.text = "✓" if correct else "✗"

	label.add_theme_color_override(
		"font_color",
		Color(0.30, 1.0, 0.40) if correct else Color(1.0, 0.35, 0.30)
	)


# PROBAR (BOTÓN)

func _probar() -> void:

	if _resuelto:
		return

	var todas_ok := true

	_limpiar_resultado()


	for i in range(SALIDAS.size()):

		var salida_indice := ENTRADAS.size() + i

		var ok := _cable_es_correcto(salida_indice)

		if not ok:
			todas_ok = false

		var marca: Dictionary = _marcas[i]

		marca["correct"] = ok

		marca["estimado"] = true

		_actualizar_marca(i)

	if todas_ok:

		_resolver()

	else:

		_mostrar_resultado(
			"> CONEXIÓN INCORRECTA",
			Color(1.0, 0.35, 0.30)
		)


# PANEL DE RESULTADO / PRUEBA

func _construir_panel_prueba() -> void:

	# Marco metálico a la derecha del panel
	var marco := Panel.new()

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color(0.32, 0.35, 0.38)

	estilo.border_color = Color(0.18, 0.20, 0.22)

	estilo.set_border_width_all(4)

	estilo.set_corner_radius_all(10)

	marco.add_theme_stylebox_override("panel", estilo)

	marco.size = Vector2(220, 180)

	marco.position = Vector2(975, 120)

	marco.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(marco)


	# Título
	var titulo := Label.new()

	titulo.text = "PRUEBA"

	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	titulo.position = Vector2(989, 128)

	titulo.size = Vector2(102, 28)

	titulo.add_theme_font_size_override("font_size", 20)

	titulo.add_theme_color_override(
		"font_color",
		Color(0.85, 0.88, 0.92)
	)

	add_child(titulo)


	# Resultado
	_resultado = Label.new()

	_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_resultado.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_resultado.text = "PULSA PARA PROBAR"

	_resultado.position = Vector2(975, 156)

	_resultado.size = Vector2(220, 66)

	_resultado.add_theme_font_size_override("font_size", 15)

	_resultado.add_theme_color_override(
		"font_color",
		Color(0.9, 0.9, 0.9)
	)

	add_child(_resultado)


	# Botón
	_boton_prueba = Button.new()

	_boton_prueba.text = "PROBAR CONEXIÓN"

	_boton_prueba.position = Vector2(990, 234)

	_boton_prueba.size = Vector2(185, 44)

	_boton_prueba.pressed.connect(_probar)

	add_child(_boton_prueba)


func _limpiar_resultado() -> void:

	if _resultado:

		_resultado.text = "PULSA PARA PROBAR"

		_resultado.add_theme_color_override(
			"font_color",
			Color(0.9, 0.9, 0.95)
		)


func _mostrar_resultado(texto: String, color_val: Color) -> void:

	if _resultado:

		_resultado.text = texto

		_resultado.add_theme_color_override(
			"font_color",
			color_val
		)

	var tree := get_tree()

	if tree == null:
		return

	var ga := (
		tree.get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto("romper")


func _resolver() -> void:

	_resuelto = true

	var tree := get_tree()

	if tree == null:
		return

	var ga := (
		tree.get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto("cableresuelto")


	_mostrar_mensaje("> SUMINISTRO RESTABLECIDO")


	await tree.create_timer(1.0).timeout


	resuelto.emit()

	cerrar()

	queue_free()


func _mostrar_mensaje(texto: String) -> void:

	if _mensaje:
		_mensaje.queue_free()

	_mensaje = Label.new()

	_mensaje.text = texto

	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_mensaje.position = Vector2(352, 60)

	_mensaje.size = Vector2(576, 40)

	_mensaje.add_theme_font_size_override("font_size", 24)

	_mensaje.add_theme_color_override(
		"font_color",
		Color(0.3, 1.0, 0.45)
	)

	add_child(_mensaje)


# CARGA TOLERANTE DE TEXTURAS
# Devuelve null si el archivo aún no existe (p.ej.
# cverde.png), y la interfaz usa su placeholder.

func _tex(ruta: String) -> Texture2D:

	if ResourceLoader.exists(ruta):
		return load(ruta) as Texture2D

	return null
