extends CanvasLayer


# PANTALLA DE SELECCIÓN DE PERSONAJE
# Genera una tarjeta por CADA personaje del
# CatalogoPersonajes (sin hardcodear): retrato vivo del
# propio personaje, nombre, iconos de sus habilidades
# y un panel inferior con la descripción del personaje
# y el detalle (qué hacen) de cada habilidad.

const FUENTE: FontFile = preload(
	"res://DePixelBreit.ttf"
)

const ESCENA_JUEGO := "res://Scenes/Main/Main.tscn"

const AJUSTES_UI := preload("res://Scripts/UI/AjustesUI.gd")

const COLOR_FONDO := Color(0.05, 0.06, 0.09)

const COLOR_TARJETA := Color(0.10, 0.11, 0.16, 0.97)

const COLOR_BORDE := Color(0.75, 0.58, 0.28)

const COLOR_SELECCION := Color(0.95, 0.78, 0.30)


# AJUSTES DE ENCUADRE POR PERSONAJE
# Desplazamiento (en píxeles de PANTALLA, positivo =
# derecha/abajo) para centrar manualmente cada retrato.
# Se aplica a la cámara del viewport. Cada sprite trae su
# propio encuadre, así que se afina por id.

const OFFSETS_RETRATO := {
	"patosa": Vector2.ZERO,
	"teleportador": Vector2.ZERO,
	"forzudo": Vector2.ZERO,
	"nino": Vector2.ZERO,
	"robot": Vector2.ZERO,
	"electricista": Vector2.ZERO,
	"cientifico": Vector2.ZERO,
	"cientifica": Vector2.ZERO
}

var OFFSET_DEFECTO_RETRATO := Vector2.ZERO


var _id_seleccionado: String = ""

var _tarjetas: Array[Dictionary] = []

var _lbl_nombre: Label = null

var _lbl_desc: Label = null

var _lbl_habs: Label = null

# Botón de confirmar (su texto cambia por turno, así que
# se guarda la referencia directa al crearlo).
var _btn_confirmar: Button = null

# Estilos del botón ELEGIR (se crean una sola vez y se
# comparten entre las 8 tarjetas).
var _estilo_boton_normal: StyleBoxFlat = null

var _estilo_boton_hover: StyleBoxFlat = null

var _estilo_boton_pulsado: StyleBoxFlat = null

var _estilo_boton_elegido: StyleBoxFlat = null


# READY

func _ready() -> void:

	var ajustes_ui: CanvasLayer = AJUSTES_UI.new()
	add_child(ajustes_ui)

	_construir_interfaz()

	# Seleccionar por defecto el primer personaje libre
	# (si se vuelve a una selección a medias, el de
	# defecto puede estar ya cogido por otro jugador).
	_seleccionar(_primer_id_libre())

	_preparar_turno_seleccion()


# CONSTRUIR LA INTERFAZ

func _construir_interfaz() -> void:

	var fondo := ColorRect.new()

	fondo.color = COLOR_FONDO

	fondo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fondo.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(fondo)


	var titulo := _crear_etiqueta(
		"SELECCIONA TU PERSONAJE",
		34,
		Color(1.0, 0.92, 0.74)
	)

	titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	titulo.offset_top = 10.0
	titulo.offset_bottom = 54.0

	titulo.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	fondo.add_child(titulo)


	# Cuadrícula de tarjetas (4 columnas)
	var rejilla := GridContainer.new()

	rejilla.columns = 4

	rejilla.add_theme_constant_override(
		"h_separation", 14
	)

	rejilla.add_theme_constant_override(
		"v_separation", 12
	)

	var centro := CenterContainer.new()

	centro.anchor_left = 0.0
	centro.anchor_top = 0.0
	centro.anchor_right = 1.0
	centro.anchor_bottom = 0.0
	centro.grow_horizontal = Control.GROW_DIRECTION_BOTH
	centro.offset_top = 92.0
	centro.offset_bottom = 578.0

	centro.add_child(rejilla)

	fondo.add_child(centro)

	for dato in CatalogoPersonajes.todos():

		rejilla.add_child(_crear_tarjeta(dato))


	# Panel de detalle (descripción + habilidades)
	var detalle := PanelContainer.new()

	var estilo_d := StyleBoxFlat.new()

	estilo_d.bg_color = Color(0.08, 0.09, 0.13, 0.97)

	estilo_d.border_color = COLOR_BORDE

	estilo_d.set_border_width_all(1)

	estilo_d.set_corner_radius_all(8)

	estilo_d.content_margin_left = 14.0

	estilo_d.content_margin_right = 14.0

	estilo_d.content_margin_top = 8.0

	estilo_d.content_margin_bottom = 8.0

	detalle.add_theme_stylebox_override("panel", estilo_d)

	detalle.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	detalle.offset_left = 20.0
	detalle.offset_top = -132.0
	detalle.offset_right = -192.0
	detalle.offset_bottom = -10.0

	fondo.add_child(detalle)


	var fila := HBoxContainer.new()

	fila.add_theme_constant_override("separation", 26)

	detalle.add_child(fila)


	var col_izq := VBoxContainer.new()

	col_izq.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	fila.add_child(col_izq)


	_lbl_nombre = _crear_etiqueta(
		"", 20, COLOR_SELECCION
	)

	col_izq.add_child(_lbl_nombre)


	_lbl_desc = _crear_etiqueta(
		"", 13, Color(0.9, 0.88, 0.8)
	)

	_lbl_desc.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	_lbl_desc.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	_lbl_desc.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	col_izq.add_child(_lbl_desc)


	var col_der := VBoxContainer.new()

	col_der.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	fila.add_child(col_der)


	# Empuje hacia abajo para que las habilidades no
	# queden pegadas al borde superior del panel.
	var empuje_habs := Control.new()

	empuje_habs.custom_minimum_size = Vector2(0.0, 34.0)

	col_der.add_child(empuje_habs)


	_lbl_habs = _crear_etiqueta(
		"", 13, Color(0.85, 0.92, 1.0)
	)

	_lbl_habs.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	_lbl_habs.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	col_der.add_child(_lbl_habs)


	# Botón JUGAR
	var jugar := Button.new()

	jugar.text = "JUGAR"

	jugar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	jugar.offset_left = -178.0
	jugar.offset_top = -108.0
	jugar.offset_right = -20.0
	jugar.offset_bottom = -20.0

	jugar.add_theme_font_override("font", FUENTE)

	jugar.add_theme_font_size_override("font_size", 26)

	jugar.focus_mode = Control.FOCUS_NONE

	jugar.pressed.connect(_jugar_pulsado)

	# Referencia directa: el texto del botón cambia por
	# turno (CONFIRMAR JUGADOR N), así que buscarlo por
	# su texto dejaría de funcionar tras el primero.
	_btn_confirmar = jugar

	fondo.add_child(jugar)


# RETRATO VIVO DEL PERSONAJE
# Instancia la escena (PackedScene) del personaje y la
# muestra en miniatura mediante un SubViewport anclado a
# su cámara. Así cada tarjeta enseña al propio personaje
# en movimiento, no un logo. La física del cuerpo se
# desactiva para que se quede quieto en el HUD.

func _crear_retrato(dato: CharacterData) -> Control:

	if dato.escena == null:

		return null

	var escena: Node = dato.escena.instantiate()

	var cuerpo: CharacterBody2D = escena as CharacterBody2D

	if cuerpo == null:

		for hijo in escena.get_children():

			if hijo is CharacterBody2D:

				cuerpo = hijo

				break

	if cuerpo == null:

		escena.free()

		return null


	# El cuerpo se queda quieto (sin gravedad ni movimiento)
	cuerpo.set_physics_process(false)


	# Cámara del personaje (si la escena no trae una, se crea)
	var camara: Camera2D = (
		cuerpo.get_node_or_null("Camera2D") as Camera2D
	)

	if camara == null:

		camara = Camera2D.new()

		camara.position = Vector2.ZERO

		cuerpo.add_child(camara)

	camara.enabled = true


	# Normalizar el zoom para que el sprite encaje en el hueco
	var anim: AnimatedSprite2D = (
		cuerpo.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	)

	if anim != null and anim.sprite_frames != null:

		var frames := anim.sprite_frames

		var nombre_anim := "abajo"

		if not frames.has_animation(nombre_anim):

			var nombres := frames.get_animation_names()

			if nombres.size() > 0:

				nombre_anim = nombres[0]

		var textura: Texture2D = (
			frames.get_frame_texture(nombre_anim, 0)
		)

		if textura != null:

			var tam: Vector2 = (
				textura.get_size() as Vector2
			) * anim.scale

			if tam.x > 0.0 and tam.y > 0.0:

				# Hueco vertical: escala por la ALTURA para que el
				# cuerpo llene el alto y quede centrado en ancho.
				var objetivo: float = 100.0

				var zoom_val: float = objetivo / tam.y

				camara.zoom = Vector2(zoom_val, zoom_val)

				# Centrar la cámara en el centro VISUAL del
				# sprite. AnimatedSprite2D dibuja su frame
				# CENTRADO en su propia posición, así que el
				# centro del personaje es exactamente
				# anim.position (sumarle tamaño/2 apuntaba a
				# la esquina inferior-derecha del sprite y
				# sacaba al personaje del encuadre: por eso
				# la patosa no se veía y el resto salía
				# descentrado).
				var centro: Vector2 = anim.position

				camara.position = centro

				# Aplicar el ajuste de encuadre por personaje.
				# En pantalla la cámara va "a contracorriente" del
				# sprite, así que desplazamos la cámara en sentido
				# opuesto y escalado por el zoom.
				var offset_pantallas: Vector2 = (
					OFFSETS_RETRATO.get(dato.id, OFFSET_DEFECTO_RETRATO)
				)

				camara.position += (
					offset_pantallas
					* Vector2(-1.0 / zoom_val, -1.0 / zoom_val)
				)


	# El retrato es un SubViewportContainer (Control) que
	# muestra a su SubViewport interno. El personaje vive
	# DENTRO del viewport para que su cámara lo dibuje.
	var contenedor := SubViewportContainer.new()

	contenedor.stretch = true

	contenedor.custom_minimum_size = Vector2(76.0, 100.0)

	contenedor.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	contenedor.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	contenedor.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Fondo transparente: sin recuadro detrás del personaje.
	var estilo_transparente := StyleBoxFlat.new()

	estilo_transparente.bg_color = Color(0.0, 0.0, 0.0, 0.0)

	estilo_transparente.set_border_width_all(0)

	estilo_transparente.set_corner_radius_all(0)

	contenedor.add_theme_stylebox_override(
		"panel", estilo_transparente
	)


	var retrato := SubViewport.new()

	retrato.size = Vector2(76.0, 100.0)

	# Fondo transparente: sin recuadro gris detrás del sprite.
	retrato.transparent_bg = true

	retrato.render_target_update_mode = (
		SubViewport.UPDATE_ALWAYS
	)

	contenedor.add_child(retrato)

	retrato.add_child(cuerpo)

	# La cámara del personaje (de la escena) es la que ya
	# dibuja el SubViewport. No hace falta make_current aquí
	# (la cámara debe estar en el árbol para poder activarla).

	return contenedor


# TARJETA DE PERSONAJE
# Cada tarjeta se genera a partir de CharacterData:
# retrato del personaje, iconos de sus habilidades y
# botón ELEGIR. Con 8 personajes la cuadrícula queda
# en 4x2.

func _crear_tarjeta(dato: CharacterData) -> Control:

	var panel := PanelContainer.new()

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = COLOR_TARJETA

	estilo.border_width_left = 2

	estilo.border_width_top = 2

	estilo.border_width_right = 2

	estilo.border_width_bottom = 2

	estilo.border_color = COLOR_BORDE

	estilo.set_corner_radius_all(8)

	estilo.content_margin_left = 8.0

	estilo.content_margin_right = 8.0

	estilo.content_margin_top = 6.0

	estilo.content_margin_bottom = 6.0

	panel.add_theme_stylebox_override("panel", estilo)

	# Tarjetas compactas: 4 columnas x 2 filas deben
	# caber sin pisar el panel de descripción inferior.
	panel.custom_minimum_size = Vector2(232.0, 196.0)


	var columna := VBoxContainer.new()

	columna.alignment = BoxContainer.ALIGNMENT_BEGIN

	columna.add_theme_constant_override("separation", 6)

	panel.add_child(columna)


	# Retrato vivo del personaje (renderiza su escena en miniatura)
	var retrato := _crear_retrato(dato)

	if retrato != null:

		columna.add_child(retrato)


	# Nombre del personaje
	var nombre := _crear_etiqueta(dato.nombre, 14, Color.WHITE)

	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	columna.add_child(nombre)


	# Iconos de las habilidades (dinámicos según el catálogo)
	var iconos := HBoxContainer.new()

	iconos.alignment = BoxContainer.ALIGNMENT_CENTER

	iconos.add_theme_constant_override("separation", 14)

	columna.add_child(iconos)

	if dato.habilidades.is_empty():

		# Misma fila que los logos: la etiqueta se mete dentro
		# del HBox de iconos y reserva la misma altura mínima,
		# así la tarjeta queda igual y el botón ELEGIR alineado.
		var sin_hab := _crear_etiqueta(
			"(sin habilidades)",
			11,
			Color(0.70, 0.70, 0.78)
		)

		sin_hab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		sin_hab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		sin_hab.custom_minimum_size = Vector2(0.0, 40.0)

		iconos.add_child(sin_hab)

	else:

		for hab in dato.habilidades:

			if hab.icono != null:

				var icono := TextureRect.new()

				icono.texture = hab.icono

				icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

				icono.stretch_mode = (
					TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				)

				icono.custom_minimum_size = Vector2(40.0, 40.0)

				icono.tooltip_text = hab.nombre

				iconos.add_child(icono)

			else:

				var lbl_hab := _crear_etiqueta(
					hab.nombre,
					11,
					Color(0.85, 0.92, 1.0)
				)

				lbl_hab.horizontal_alignment = (
					HORIZONTAL_ALIGNMENT_CENTER
				)

				iconos.add_child(lbl_hab)


	# Espaciador elástico: empuja el botón ELEGIR al fondo de
	# la tarjeta para que quede a la misma altura siempre,
	# haya logos de habilidades o no.
	var spacer := Control.new()

	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL

	columna.add_child(spacer)


	# Botón ELEGIR: con estilo propio (normal / hover /
	# pulsado). Al seleccionar la tarjeta pasa a modo
	# ELEGIDO dorado (ver _configurar_boton_elegir).
	var elegir := Button.new()

	elegir.custom_minimum_size = Vector2(0.0, 40.0)

	elegir.add_theme_font_override("font", FUENTE)

	elegir.add_theme_font_size_override("font_size", 16)

	elegir.focus_mode = Control.FOCUS_NONE

	elegir.mouse_filter = Control.MOUSE_FILTER_STOP

	elegir.pressed.connect(_seleccionar_o_confirmar.bind(dato.id))

	_configurar_boton_elegir(elegir, false)

	columna.add_child(elegir)


	_tarjetas.append(
		{
			"id": dato.id,
			"panel": panel,
			"estilo": estilo,
			"boton": elegir
		}
	)

	return panel

# SELECCIONAR PERSONAJE

func _seleccionar(id: String) -> void:

	# Un personaje ya cogido por otro jugador no se puede
	# elegir: su tarjeta queda marcada con su dueño.
	if GameSession.jugador_que_eligio(id) > 0:

		return

	_id_seleccionado = id

	_refrescar_tarjetas()


	# Actualizar el panel de detalle (descripción + habilidades)
	var dato := CatalogoPersonajes.obtener(id)

	if dato != null:

		_lbl_nombre.text = dato.nombre

		_lbl_desc.text = dato.descripcion

		var lineas := ""

		if dato.habilidades.is_empty():

			lineas = "Sin habilidades especiales."

		else:

			for hab in dato.habilidades:

				lineas += "- " + hab.nombre + ": " + hab.descripcion + "\n"

		_lbl_habs.text = lineas


func _seleccionar_o_confirmar(id: String) -> void:
	if _id_seleccionado == id:
		_jugar_pulsado()
		return
	_seleccionar(id)


# ESTILOS DEL BOTÓN ELEGIR
# Crea una sola vez los tres estados del botón (normal,
# hover y pulsado) más el dorado de ELEGIDO. Los
# comparten las 8 tarjetas.

func _crear_estilos_boton() -> void:

	_estilo_boton_normal = _estilo_boton(
		Color(0.13, 0.15, 0.22),
		Color(0.45, 0.38, 0.22)
	)

	_estilo_boton_hover = _estilo_boton(
		Color(0.19, 0.22, 0.32),
		COLOR_SELECCION
	)

	_estilo_boton_pulsado = _estilo_boton(
		Color(0.08, 0.09, 0.14),
		COLOR_SELECCION
	)

	_estilo_boton_elegido = _estilo_boton(
		COLOR_SELECCION,
		Color(1.0, 0.92, 0.65)
	)


func _estilo_boton(
	fondo: Color,
	borde: Color
) -> StyleBoxFlat:

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = fondo

	estilo.border_width_left = 2

	estilo.border_width_top = 2

	estilo.border_width_right = 2

	estilo.border_width_bottom = 2

	estilo.border_color = borde

	estilo.corner_radius_top_left = 8

	estilo.corner_radius_top_right = 8

	estilo.corner_radius_bottom_left = 8

	estilo.corner_radius_bottom_right = 8

	estilo.content_margin_left = 12.0

	estilo.content_margin_right = 12.0

	estilo.content_margin_top = 8.0

	estilo.content_margin_bottom = 8.0

	return estilo


# PONER EL BOTÓN EN MODO ELEGIR / ELEGIDO
# ELEGIR: fondo oscuro con borde dorado al pasar el
# ratón. ELEGIDO: relleno dorado con texto oscuro, para
# que se vea de un vistazo quién está seleccionado.

func _configurar_boton_elegir(
	boton: Button,
	elegido: bool,
	texto := "ELEGIDO"
) -> void:

	if _estilo_boton_normal == null:

		_crear_estilos_boton()

	if elegido:

		boton.text = texto

		# El texto largo de "ELEGIDO POR JUGADOR N"
		# necesita un cuerpo más pequeño para caber.
		boton.add_theme_font_size_override(
			"font_size",
			14 if texto.length() > 10 else 16
		)

		boton.add_theme_stylebox_override(
			"normal", _estilo_boton_elegido
		)

		boton.add_theme_stylebox_override(
			"hover", _estilo_boton_elegido
		)

		boton.add_theme_stylebox_override(
			"pressed", _estilo_boton_elegido
		)

		var texto_oscuro := Color(0.16, 0.12, 0.04)

		boton.add_theme_color_override(
			"font_color", texto_oscuro
		)

		boton.add_theme_color_override(
			"font_hover_color", texto_oscuro
		)

		boton.add_theme_color_override(
			"font_pressed_color", texto_oscuro
		)

	else:

		boton.text = "ELEGIR"

		boton.add_theme_font_size_override(
			"font_size", 16
		)

		boton.add_theme_stylebox_override(
			"normal", _estilo_boton_normal
		)

		boton.add_theme_stylebox_override(
			"hover", _estilo_boton_hover
		)

		boton.add_theme_stylebox_override(
			"pressed", _estilo_boton_pulsado
		)

		var texto_claro := Color(0.95, 0.92, 0.82)

		boton.add_theme_color_override(
			"font_color", texto_claro
		)

		boton.add_theme_color_override(
			"font_hover_color", Color(1.0, 0.98, 0.9)
		)

		boton.add_theme_color_override(
			"font_pressed_color", texto_claro
		)


# EMPEZAR LA PARTIDA

# Banner superior con el turno de selección.
var _lbl_turno: Label = null


# TURNO DE SELECCIÓN (MULTIJUGADOR)
# Los jugadores eligen personaje por orden: el botón
# inferior confirma la elección del jugador en turno
# y pasa al siguiente hasta completar la partida.

func _preparar_turno_seleccion() -> void:

	# Retomar una selección a medias (vuelta atrás).
	if GameSession.selecciones.size() > 0 \
			and not GameSession.seleccion_completa():

		GameSession.jugador_en_turno = (
			GameSession.selecciones.size()
		)

	_lbl_turno = _crear_banner_turno()

	_actualizar_textos_turno()


func _crear_banner_turno() -> Label:

	var banner := Label.new()

	banner.text = ""

	banner.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)

	banner.add_theme_font_override(
		"font", load("res://DePixelBreit.ttf")
	)

	banner.add_theme_font_size_override(
		"font_size", 20
	)

	banner.add_theme_color_override(
		"font_color", Color("baffc9")
	)

	banner.add_theme_color_override(
		"font_outline_color", Color(0.0, 0.15, 0.05)
	)

	banner.add_theme_constant_override(
		"outline_size", 6
	)

	banner.set_anchors_preset(Control.PRESET_TOP_WIDE)

	# Debajo del título (este ocupa y10-54): así no se
	# tapan entre ellos.
	banner.offset_top = 54.0

	banner.offset_bottom = 86.0

	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(banner)

	return banner


func _actualizar_textos_turno() -> void:

	var total := GameSession.numero_jugadores

	var turno := GameSession.jugador_en_turno

	if _lbl_turno != null:

		if total <= 1:

			_lbl_turno.text = "ELIGE TU PERSONAJE"

		else:

			_lbl_turno.text = (
				"JUGADOR %d DE %d - ELIGE TU PERSONAJE"
					% [turno + 1, total]
			)

	var boton := _btn_confirmar

	if boton != null:

		if total <= 1:

			boton.text = "JUGAR"

		elif not GameSession.seleccion_completa():

			boton.text = (
				"CONFIRMAR JUGADOR %d" % [turno + 1]
			)

		else:

			boton.text = "EMPEZAR PARTIDA"


func _avanzar_turno_seleccion() -> void:

	GameSession.avanzar_turno_seleccion()

	# Dejar seleccionado el primer personaje libre para
	# el siguiente jugador (los ya cogidos quedan
	# marcados como ELEGIDO POR JUGADOR N).
	_seleccionar(_primer_id_libre())

	_actualizar_textos_turno()


func _primer_id_libre() -> String:

	for tarjeta in _tarjetas:

		if GameSession.jugador_que_eligio(
				tarjeta["id"]) == 0:

			return tarjeta["id"]

	return CatalogoPersonajes.ID_DEFECTO


# REFRESCAR TARJETAS (LIBRE / ELEGIDO / COGIDO)
# Cada tarjeta muestra: ELEGIR (libre), ELEGIDO
# (selección pendiente del jugador en turno) o
# ELEGIDO POR JUGADOR N (ya cogida por otro).

func _refrescar_tarjetas() -> void:

	for tarjeta in _tarjetas:

		var propietario: int = (
			GameSession.jugador_que_eligio(tarjeta["id"])
		)

		var es_actual: bool = (
			tarjeta["id"] == _id_seleccionado
		)

		var resaltada: bool = (
			es_actual and propietario == 0
		)

		tarjeta["estilo"].border_color = (
			COLOR_SELECCION if resaltada else COLOR_BORDE
		)

		var ancho := 3 if resaltada else 2

		tarjeta["estilo"].border_width_left = ancho

		tarjeta["estilo"].border_width_top = ancho

		tarjeta["estilo"].border_width_right = ancho

		tarjeta["estilo"].border_width_bottom = ancho

		if propietario > 0:

			_configurar_boton_elegir(
				tarjeta["boton"],
				true,
				"ELEGIDO POR JUGADOR %d" % propietario
			)

		else:

			_configurar_boton_elegir(
				tarjeta["boton"],
				es_actual,
				"ELEGIDO - CONFIRMAR" if es_actual else "ELEGIR"
			)


# EMPEZAR LA PARTIDA

func _jugar_pulsado() -> void:

	if _id_seleccionado == "":

		return

	# Registrar la elección del jugador en turno.
	GameSession.registrar_seleccion(_id_seleccionado)

	if not GameSession.seleccion_completa():

		_avanzar_turno_seleccion()

		return

	get_tree().change_scene_to_file(ESCENA_JUEGO)


# ETIQUETA DE TEXTO

func _crear_etiqueta(
	texto: String,
	tamano: int,
	color: Color
) -> Label:

	var etiqueta := Label.new()

	etiqueta.text = texto

	etiqueta.add_theme_font_override("font", FUENTE)

	etiqueta.add_theme_font_size_override("font_size", tamano)

	etiqueta.add_theme_color_override("font_color", color)

	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return etiqueta
