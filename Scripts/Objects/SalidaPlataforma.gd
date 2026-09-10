extends Node2D

class_name SalidaPlataforma

# PLATAFORMA DE SALIDA
# Controla los cuatro estados visuales de la plataforma
# y activa la zona de salida solo cuando está completa.
# Requisitos de la escena:
# - Un Sprite2D llamado "Sprite2D" o se crea automáticamente.
# - Un Area2D llamado "AreaOrdenador" o "Ordenador".
# - Un Area2D llamado "AreaSalida" o "Salida".
# - La zona de salida debe tener un CollisionShape2D activo
#   para detectar al jugador cuando la plataforma esté lista.

@export var fases: Array[Texture2D] = []
@export var piezas_necesarias: int = 5
@export var fase_actual: int = 0
@export var completada: bool = false

@export var texturas_fases: Array[Texture2D] = []

var piezas_colocadas: int = 0
var jugador_cerca_ordenador: bool = false
var jugador_cerca_salida: bool = false
var jugador: Character = null
var pantalla_salida: CanvasLayer = null
var confirmacion_salida: Panel = null
var salida_realizada: bool = false
var creditos_activos: bool = false
var resultados_activos: bool = false
var _creditos_contenido: VBoxContainer = null
var _creditos_tween: Tween = null

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var area_ordenador: Area2D = _buscar_area("AreaOrdenador", "Ordenador")
@onready var area_salida: Area2D = _buscar_area("AreaSalida", "Salida")


func _ready() -> void:
	if texturas_fases.size() > 0:
		fases = texturas_fases

	var sprite_existente := get_node_or_null("Salida1") as Sprite2D
	if sprite_existente != null:
		sprite = sprite_existente
	elif sprite == null:
		var nuevo_sprite := Sprite2D.new()
		nuevo_sprite.name = "Sprite2D"
		add_child(nuevo_sprite)
		sprite = nuevo_sprite

	if fases.is_empty():
		for i in range(1, 5):
			var sprite_fase := get_node_or_null("Salida%d" % i) as Sprite2D
			if sprite_fase != null:
				fases.append(sprite_fase.texture)

	if fases.is_empty():
		push_warning("SalidaPlataforma: no hay fases cargadas.")

	_cargar_progreso()

	_refrescar_visual()
	_conectar_areas()
	_actualizar_estado_salida()
	call_deferred("_actualizar_jugador_en_salida")


func _buscar_area(nombre_1: String, nombre_2: String) -> Area2D:
	var area := get_node_or_null(nombre_1) as Area2D
	if area != null:
		return area
	area = get_node_or_null(nombre_2) as Area2D
	return area


func _conectar_areas() -> void:
	if area_ordenador != null:
		area_ordenador.body_entered.connect(_jugador_entra_ordenador)
		area_ordenador.body_exited.connect(_jugador_sale_ordenador)

	if area_salida != null:
		area_salida.body_entered.connect(_jugador_entra_salida)
		area_salida.body_exited.connect(_jugador_sale_salida)


func _jugador_entra_ordenador(body: Node2D) -> void:
	if not body is Character:
		return
	if not _es_jugador_activo(body as Character):
		return
	jugador = body as Character
	jugador_cerca_ordenador = true
	print("[Salida] Jugador cerca del ordenador")


func _jugador_sale_ordenador(body: Node2D) -> void:
	if body == jugador and not jugador_cerca_salida:
		jugador = null
		jugador_cerca_ordenador = false
		print("[Salida] Jugador se aleja del ordenador")


func _jugador_entra_salida(body: Node2D) -> void:
	if not body is Character:
		return
	if not completada:
		return
	if not _es_jugador_activo(body as Character):
		return
	if salida_realizada:
		return
	jugador = body as Character
	jugador_cerca_salida = true
	print("[Salida] Jugador en la zona de salida")
	_mostrar_confirmacion_salida()


func _jugador_sale_salida(body: Node2D) -> void:
	if body == jugador:
		jugador_cerca_salida = false
		print("[Salida] Jugador sale de la zona de salida")


func _crear_pantalla_salida() -> void:
	if pantalla_salida != null and is_instance_valid(pantalla_salida):
		return

	pantalla_salida = CanvasLayer.new()
	pantalla_salida.name = "PantallaSalida"
	pantalla_salida.layer = 1000
	pantalla_salida.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(pantalla_salida)

	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(0.01, 0.02, 0.01, 0.9)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	pantalla_salida.add_child(fondo)

	confirmacion_salida = Panel.new()
	confirmacion_salida.name = "ConfirmacionSalida"
	confirmacion_salida.set_anchors_preset(Control.PRESET_CENTER)
	confirmacion_salida.position = Vector2(-280, -130)
	confirmacion_salida.size = Vector2(560, 260)
	pantalla_salida.add_child(confirmacion_salida)

	var pregunta := Label.new()
	pregunta.text = "PLATAFORMA OPERATIVA\n¿Quieres salir del laboratorio?"
	pregunta.position = Vector2(35, 35)
	pregunta.size = Vector2(490, 75)
	pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pregunta.add_theme_font_size_override("font_size", 22)
	confirmacion_salida.add_child(pregunta)

	var aceptar := Button.new()
	aceptar.text = "SI, SALIR"
	aceptar.position = Vector2(65, 155)
	aceptar.size = Vector2(190, 55)
	aceptar.add_theme_font_size_override("font_size", 18)
	aceptar.pressed.connect(_confirmar_salida)
	confirmacion_salida.add_child(aceptar)

	var cancelar := Button.new()
	cancelar.text = "NO"
	cancelar.position = Vector2(305, 155)
	cancelar.size = Vector2(190, 55)
	cancelar.add_theme_font_size_override("font_size", 18)
	cancelar.pressed.connect(_cancelar_salida)
	confirmacion_salida.add_child(cancelar)

	pantalla_salida.visible = false


func _mostrar_confirmacion_salida() -> void:
	if salida_realizada or jugador == null:
		return
	_crear_pantalla_salida()
	pantalla_salida.visible = true
	confirmacion_salida.visible = true
	_bloquear_jugador(true)


func _cancelar_salida() -> void:
	if pantalla_salida != null:
		pantalla_salida.visible = false
	_bloquear_jugador(false)


func _confirmar_salida() -> void:
	if salida_realizada or not completada or not jugador_cerca_salida:
		return
	if jugador == null or not _es_jugador_activo(jugador):
		_cancelar_salida()
		return
	var jugador_confirmado: Character = jugador
	salida_realizada = true
	jugador_cerca_salida = false

	var gestor := get_tree().get_first_node_in_group("gestor_turnos") as GestorTurnos
	if gestor != null:
		gestor.set("_victoria_mostrada", true)

	confirmacion_salida.visible = false
	_mostrar_mensaje_ganador_y_continuar(
		gestor,
		gestor == null or gestor.es_ultimo_jugador_activo()
	)
	call_deferred("_finalizar_salida", jugador_confirmado, gestor)


func _finalizar_salida(
	jugador_confirmado: Character,
	gestor: GestorTurnos
) -> void:
	if gestor != null:
		gestor.registrar_jugador_ganador(jugador_confirmado)
	else:
		jugador_confirmado.movimiento_bloqueado = true
		jugador_confirmado.visible = false
		jugador_confirmado.sala_actual_idx = -1


func _mostrar_mensaje_ganador_diferido(
	gestor: GestorTurnos,
	ultima_victoria: bool
) -> void:
	if not is_inside_tree():
		return
	_mostrar_mensaje_ganador_y_continuar(gestor, ultima_victoria)


func _mostrar_mensaje_ganador_y_continuar(
	gestor: GestorTurnos,
	ultima_victoria: bool
) -> void:
	_crear_pantalla_salida()
	_bloquear_jugador(true)
	pantalla_salida.visible = true
	_limpiar_creditos_previos()

	var fondo := ColorRect.new()
	fondo.name = "MensajeGanador"
	fondo.color = Color(0.01, 0.03, 0.02, 0.94)
	fondo.position = Vector2.ZERO
	fondo.size = get_viewport().get_visible_rect().size
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	pantalla_salida.add_child(fondo)

	var texto := Label.new()
	texto.text = "HAS GANADO"
	var centro := fondo.size / 2.0
	texto.position = centro + Vector2(-300, -110)
	texto.size = Vector2(600, 140)
	texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.add_theme_font_size_override("font_size", 46)
	texto.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	fondo.add_child(texto)

	var continuar := Button.new()
	continuar.name = "ContinuarDespuesDeGanar"
	continuar.text = "CONTINUAR"
	continuar.position = centro + Vector2(-140, 70)
	continuar.size = Vector2(280, 55)
	continuar.z_index = 2
	continuar.add_theme_font_size_override("font_size", 20)
	continuar.pressed.connect(
		_continuar_despues_de_mensaje_ganador.bind(
			gestor,
			fondo,
			ultima_victoria
		)
	)
	fondo.add_child(continuar)


func _continuar_despues_de_mensaje_ganador(
	gestor: GestorTurnos,
	fondo: Control,
	ultima_victoria: bool
) -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(pantalla_salida):
		pantalla_salida.visible = false
	if is_instance_valid(fondo):
		fondo.queue_free()
	salida_realizada = false
	jugador_cerca_salida = false
	jugador = null
	if ultima_victoria:
		_mostrar_resultados()
	else:
		gestor.continuar_despues_de_ganador()


func _mostrar_resultados() -> void:
	if resultados_activos or creditos_activos:
		return

	resultados_activos = true
	_crear_pantalla_salida()
	_bloquear_jugador(true)
	_limpiar_creditos_previos()
	pantalla_salida.visible = true

	var panel := Panel.new()
	panel.name = "ResultadosPartida"
	var centro := get_viewport().get_visible_rect().size / 2.0
	panel.position = centro + Vector2(-320, -220)
	panel.size = Vector2(640, 440)
	panel.z_index = 2
	pantalla_salida.add_child(panel)

	var contenido := VBoxContainer.new()
	contenido.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 36)
	contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.add_theme_constant_override("separation", 14)
	panel.add_child(contenido)

	var titulo := Label.new()
	titulo.text = "RESULTADOS DE LA PARTIDA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	contenido.add_child(titulo)

	var tiempo := Label.new()
	tiempo.text = "Tiempo total: %s" % _formatear_tiempo(GameSession.tiempo_partida_segundos())
	tiempo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tiempo.add_theme_font_size_override("font_size", 20)
	contenido.add_child(tiempo)

	var orden := Label.new()
	orden.text = "\n".join(_lineas_clasificacion())
	orden.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orden.add_theme_font_size_override("font_size", 19)
	contenido.add_child(orden)

	var continuar := Button.new()
	continuar.text = "VER CREDITOS"
	continuar.custom_minimum_size = Vector2(230, 48)
	continuar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continuar.pressed.connect(_continuar_a_creditos)
	contenido.add_child(continuar)


func _lineas_clasificacion() -> Array[String]:
	var lineas: Array[String] = []
	for indice in range(GameSession.orden_llegada.size()):
		lineas.append("%d. %s" % [indice + 1, GameSession.orden_llegada[indice]])
	return lineas


func _formatear_tiempo(segundos: int) -> String:
	return "%02d:%02d" % [floori(segundos / 60.0), segundos % 60]


func _continuar_a_creditos() -> void:
	resultados_activos = false
	var panel := pantalla_salida.get_node_or_null("ResultadosPartida")
	if panel != null:
		panel.queue_free()
	_mostrar_creditos()


func _mostrar_creditos() -> void:

	if creditos_activos:
		return

	creditos_activos = true

	_crear_pantalla_salida()

	if confirmacion_salida:
		confirmacion_salida.visible = false

	_bloquear_jugador(true)

	_limpiar_creditos_previos()

	# TELÓN NEGRO DE FONDO

	var telon := ColorRect.new()
	telon.name = "TelonCreditos"
	telon.color = Color(0.02, 0.03, 0.06, 1.0)
	telon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	telon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla_salida.add_child(telon)

	# BOTÓN INVISIBLE PARA OMITIR (toque o clic)

	var boton_omitir := Button.new()
	boton_omitir.name = "BotonOmitir"
	boton_omitir.flat = true
	boton_omitir.text = ""
	boton_omitir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	boton_omitir.pressed.connect(_saltar_creditos)
	pantalla_salida.add_child(boton_omitir)

	# CONTENIDO EN SCROLL

	_creditos_contenido = VBoxContainer.new()
	_creditos_contenido.name = "ContenidoCredito"
	_creditos_contenido.anchor_left = 0.0
	_creditos_contenido.anchor_right = 1.0
	_creditos_contenido.alignment = BoxContainer.ALIGNMENT_CENTER
	_creditos_contenido.position = Vector2(0, 720)
	_creditos_contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla_salida.add_child(_creditos_contenido)

	_rellenar_creditos(_creditos_contenido)

	# FUNDIDOS SUPERIOR E INFERIOR (estilo cine)

	pantalla_salida.add_child(_crear_fade_creditos(true))
	pantalla_salida.add_child(_crear_fade_creditos(false))

	# HINTA PARA OMITIR

	var hint := Label.new()
	hint.name = "HintOmitir"
	hint.text = "TOCA EN CUALQUIER PUNTO PARA OMITIR"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -64
	hint.offset_bottom = -16
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(1, 1, 1, 0.5)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla_salida.add_child(hint)

	# ARRANCAR LA SUBIDA

	_tween_creditos()


func _tween_creditos() -> void:

	if _creditos_contenido == null:
		return

	# Esperar un frame para que el contenedor calcule su altura.
	await get_tree().process_frame

	if not is_inside_tree():
		return

	if not creditos_activos:
		return

	if _creditos_contenido == null or not is_instance_valid(_creditos_contenido):
		return

	# El contenedor calcula su altura según los hijos; sin esto,
	# la altura quedaría en 0 y el scroll no se vería.
	var altura_minima: float = _creditos_contenido.get_combined_minimum_size().y
	_creditos_contenido.size = Vector2(1280.0, max(altura_minima, 1.0))

	var altura_total: float = _creditos_contenido.size.y
	var inicio_y: float = 720.0
	var final_y: float = -altura_total - 160.0
	var velocidad: float = 90.0
	var duracion: float = max(3.0, (inicio_y - final_y) / velocidad)

	_creditos_contenido.position.y = inicio_y

	if _creditos_tween and _creditos_tween.is_valid():
		_creditos_tween.kill()

	_creditos_tween = create_tween()
	_creditos_tween.tween_property(
		_creditos_contenido,
		"position:y",
		final_y,
		duracion
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_creditos_tween.tween_callback(_finalizar_creditos)


func _saltar_creditos() -> void:

	if not creditos_activos:
		return

	if _creditos_tween and _creditos_tween.is_valid():
		_creditos_tween.kill()

	_finalizar_creditos()


func _finalizar_creditos() -> void:

	creditos_activos = false

	_limpiar_creditos_previos()

	# PANTALLA FINAL CENTRADA

	var fin := VBoxContainer.new()
	fin.name = "FinCreditos"
	fin.anchor_left = 0.0
	fin.anchor_right = 1.0
	fin.anchor_top = 0.0
	fin.anchor_bottom = 1.0
	fin.alignment = BoxContainer.ALIGNMENT_CENTER
	fin.add_theme_constant_override("separation", 18)
	pantalla_salida.add_child(fin)

	var gracias := Label.new()
	gracias.text = "GRACIAS POR JUGAR"
	gracias.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gracias.add_theme_font_size_override("font_size", 44)
	gracias.size_flags_horizontal = Control.SIZE_FILL
	fin.add_child(gracias)

	var subtitulo := Label.new()
	subtitulo.text = "HAS CONSEGUIDO ESCAPAR DEL LABORATORIO LOCO"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 18)
	subtitulo.modulate = Color(0.75, 0.85, 1.0, 0.9)
	subtitulo.size_flags_horizontal = Control.SIZE_FILL
	fin.add_child(subtitulo)

	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, 46)
	fin.add_child(espacio)

	var boton_volver := Button.new()
	boton_volver.text = "VOLVER A JUGAR"
	boton_volver.custom_minimum_size = Vector2(280, 56)
	boton_volver.add_theme_font_size_override("font_size", 20)
	boton_volver.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton_volver.pressed.connect(_reiniciar_juego)
	fin.add_child(boton_volver)

	var boton_salir := Button.new()
	boton_salir.text = "SALIR DEL JUEGO"
	boton_salir.custom_minimum_size = Vector2(280, 56)
	boton_salir.add_theme_font_size_override("font_size", 20)
	boton_salir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boton_salir.pressed.connect(_salir_del_juego)
	fin.add_child(boton_salir)


func _reiniciar_juego() -> void:
	get_tree().reload_current_scene()


func _salir_del_juego() -> void:
	get_tree().quit()


func _limpiar_creditos_previos() -> void:

	if pantalla_salida == null or not is_instance_valid(pantalla_salida):
		return

	var nombres_limpiar := [
		"ResultadosPartida",
		"TelonCreditos",
		"BotonOmitir",
		"ContenidoCredito",
		"HintOmitir",
		"FadeCreditoArriba",
		"FadeCreditoAbajo",
		"FinCreditos"
	]

	for hijo in pantalla_salida.get_children():
		if hijo.name in nombres_limpiar:
			hijo.queue_free()

	_creditos_contenido = null


func _crear_fade_creditos(arriba: bool) -> TextureRect:

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([
		Color(0, 0, 0, 1.0),
		Color(0, 0, 0, 0.0)
	])

	var tex := GradientTexture2D.new()
	tex.gradient = grad
	if arriba:
		tex.fill_from = Vector2(0.5, 0.0)
		tex.fill_to = Vector2(0.5, 1.0)
	else:
		tex.fill_from = Vector2(0.5, 1.0)
		tex.fill_to = Vector2(0.5, 0.0)

	var rect := TextureRect.new()
	rect.name = "FadeCreditoArriba" if arriba else "FadeCreditoAbajo"
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = 0.0
	rect.anchor_right = 1.0
	if arriba:
		rect.anchor_top = 0.0
		rect.anchor_bottom = 0.0
		rect.offset_bottom = 90.0
	else:
		rect.anchor_top = 1.0
		rect.anchor_bottom = 1.0
		rect.offset_top = -210.0
	return rect


func _anadir_espacio_credito(contenedor: VBoxContainer, alto: int) -> void:

	var espacio := Control.new()
	espacio.custom_minimum_size = Vector2(0, alto)
	espacio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contenedor.add_child(espacio)


func _etiqueta_credito(texto: String, tam: int, color: Color) -> Label:

	var label := Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", tam)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_FILL
	return label


func _anadir_seccion_credito(contenedor: VBoxContainer, titulo: String, nombres: Array) -> void:

	_anadir_espacio_credito(contenedor, 52)

	var etiqueta := _etiqueta_credito(titulo, 21, Color(0.35, 0.95, 0.6))
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	etiqueta.add_theme_constant_override("outline_size", 5)
	contenedor.add_child(etiqueta)

	_anadir_espacio_credito(contenedor, 12)

	for nombre in nombres:
		contenedor.add_child(
			_etiqueta_credito(str(nombre), 27, Color(0.96, 0.97, 1.0))
		)


func _rellenar_creditos(contenedor: VBoxContainer) -> void:

	_anadir_espacio_credito(contenedor, 130)

	contenedor.add_child(
		_etiqueta_credito("LABORATORIO LOCO", 62, Color(0.35, 0.95, 0.6))
	)
	_anadir_espacio_credito(contenedor, 14)
	contenedor.add_child(
		_etiqueta_credito("Desarrollo de un videojuego para móviles con Godot", 20, Color(0.8, 0.85, 0.9))
	)
	contenedor.add_child(
		_etiqueta_credito("Una sala de puzles, cables y mucha ciencia", 16, Color(0.7, 0.75, 0.8))
	)
	_anadir_espacio_credito(contenedor, 140)

	var secciones: Array = [
		["DIRECCIÓN", ["Jesus Miguel Jordá Gomez"]],
		["DISEÑO DEL JUEGO", ["Jesus Miguel Jordá Gomez"]],
		["PROGRAMACIÓN", ["Jesus Miguel Jordá Gomez"]],
		["GENERACIÓN PROCEDURAL", ["Jesus Miguel Jordá Gomez"]],
		["PUZLES Y MECÁNICAS", ["Jesus Miguel Jordá Gomez"]],
		["SISTEMAS DE INTERACCIÓN", ["Jesus Miguel Jordá Gomez"]],
		["GUION Y NARRATIVA", ["Jesus Miguel Jordá Gomez"]],
		["ARTE Y ANIMACIÓN", [
			"Jesus Miguel Jordá Gomez",
			"Imágenes generadas con ChatGPT",
			"Edición de imágenes: PhotoRoom y Photopea"
		]],
		["DISEÑO SONORO", [
			"Jesus Miguel Jordá Gomez",
			"Efectos sonoros: Pixabay"
		]],
		["PRUEBAS Y CALIDAD", ["Jesus Miguel Jordá Gomez"]],
		["MÚSICA", ["Música generada con Suno"]],
		["ELENCO DEL LABORATORIO", [
			"El Vegetariano",
			"La Científica",
			"El Científico",
			"El Electricista",
			"La Ingeniera Patosa",
			"El Robot",
			"El Niño",
			"La Naranja"
		]],
		["AGRADECIMIENTOS ESPECIALES", [
			"Fidel Aznar Gregori",
			"A mi familia y amigos por aguantar tantas partidas"
		]],
		["UNIVERSIDAD", [
			"Escuela Politécnica Superior",
			"Universidad de Alicante",
			"Máster Universitario en Desarrollo de Software para Dispositivos Móviles",
			"Septiembre 2026"
		]],
		["HERRAMIENTAS", [
			"Godot Engine 4.6",
			"GDScript"
		]]
	]

	for seccion in secciones:
		_anadir_seccion_credito(
			contenedor,
			seccion[0] as String,
			seccion[1] as Array
		)

	_anadir_espacio_credito(contenedor, 140)

	contenedor.add_child(
		_etiqueta_credito("FIN", 30, Color(0.35, 0.95, 0.6))
	)

	_anadir_espacio_credito(contenedor, 20)

	contenedor.add_child(
		_etiqueta_credito("GRACIAS POR JUGAR", 40, Color(0.96, 0.97, 1.0))
	)

	_anadir_espacio_credito(contenedor, 90)


func _bloquear_jugador(bloqueado: bool) -> void:
	var interaction_manager := get_tree().get_first_node_in_group("interaction_manager") as InteractionManager
	if interaction_manager != null:
		interaction_manager.establecer_activo(not bloqueado)
	if jugador != null:
		jugador.movimiento_bloqueado = bloqueado


# AVANCE DE LA PLATAFORMA
# Se llama desde el script del ordenador / puzzle cuando
# una pieza se instala correctamente.
func registrar_pieza_colocada() -> void:
	if completada:
		return

	piezas_colocadas += 1
	piezas_colocadas = min(piezas_colocadas, piezas_necesarias)
	# Las cuatro imágenes representan: vacía, batería, fusibles y cintas.
	if piezas_colocadas == 0:
		fase_actual = 0
	elif piezas_colocadas == 1:
		fase_actual = 1
	elif piezas_colocadas <= 3:
		fase_actual = 2
	elif piezas_colocadas < piezas_necesarias:
		fase_actual = 2
	else:
		fase_actual = 3

	_guardar_progreso()

	if piezas_colocadas >= piezas_necesarias:
		completar_plataforma()
	else:
		_refrescar_visual()


func completar_plataforma() -> void:
	if completada:
		_actualizar_estado_salida()
		call_deferred("_actualizar_jugador_en_salida")
		return
	completada = true
	fase_actual = 3
	_guardar_progreso()
	_refrescar_visual()
	_actualizar_estado_salida()
	call_deferred("_actualizar_jugador_en_salida")
	print("[Salida] Plataforma completada: salida activada")


func reiniciar_plataforma() -> void:
	completada = false
	piezas_colocadas = 0
	fase_actual = 0
	_guardar_progreso()
	_refrescar_visual()
	_actualizar_estado_salida()
	print("[Salida] Plataforma reiniciada")


func _refrescar_visual() -> void:
	if sprite == null:
		return

	if fases.is_empty():
		sprite.texture = null
		return

	if get_node_or_null("Salida1") != null:
		for i in range(1, 5):
			var sprite_fase := get_node_or_null("Salida%d" % i) as Sprite2D
			if sprite_fase != null:
				sprite_fase.visible = false

		var indice_fase: int = clampi(fase_actual, 0, 3) + 1
		var sprite_actual := get_node_or_null("Salida%d" % indice_fase) as Sprite2D
		if sprite_actual != null:
			sprite_actual.visible = true
			sprite = sprite_actual
		return

	var indice: int = clampi(fase_actual, 0, fases.size() - 1)
	sprite.texture = fases[indice]

	if completada:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _actualizar_estado_salida() -> void:
	if area_salida == null:
		return

	var collision := area_salida.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.disabled = not completada

	if completada:
		area_salida.monitoring = true
		area_salida.monitorable = true
	else:
		area_salida.monitoring = false
		area_salida.monitorable = false

	for hijo in area_salida.get_children():
		if hijo is Sprite2D:
			hijo.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _actualizar_jugador_en_salida() -> void:
	if area_salida == null or not completada:
		return

	for body in area_salida.get_overlapping_bodies():
		if body is Character and _es_jugador_activo(body as Character):
			jugador = body as Character
			jugador_cerca_salida = true
			_mostrar_confirmacion_salida()
			return


func _es_jugador_activo(candidato: Character) -> bool:
	var gestor := get_tree().get_first_node_in_group("gestor_turnos") as GestorTurnos
	if gestor != null and gestor.has_method("_jugador_activo"):
		return gestor.call("_jugador_activo") == candidato
	return true


func _obtener_datos_sala() -> RoomData:
	var nodo_sala := get_parent().get_parent()
	if nodo_sala != null and nodo_sala.has_meta("room_data"):
		return nodo_sala.get_meta("room_data") as RoomData
	return null


func _cargar_progreso() -> void:
	var datos := _obtener_datos_sala()
	if datos == null:
		return

	piezas_colocadas = clampi(datos.salida_piezas_colocadas, 0, piezas_necesarias)
	completada = datos.salida_completada
	if completada:
		fase_actual = 3
	elif piezas_colocadas == 0:
		fase_actual = 0
	elif piezas_colocadas == 1:
		fase_actual = 1
	elif piezas_colocadas <= 3:
		fase_actual = 2
	elif piezas_colocadas < piezas_necesarias:
		fase_actual = 2
	else:
		fase_actual = 3


func _guardar_progreso() -> void:
	var datos := _obtener_datos_sala()
	if datos == null:
		return

	datos.salida_piezas_colocadas = piezas_colocadas
	datos.salida_completada = completada


# INTERACCIÓN CON EL ORDENADOR
# Si la plataforma no está completa, el jugador puede
# interactuar con el ordenador para ir colocando piezas.
func puede_interactuar_ordenador() -> bool:
	return jugador_cerca_ordenador and not completada


func se_puede_salir() -> bool:
	return completada and jugador_cerca_salida
