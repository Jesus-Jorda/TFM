extends CanvasLayer

class_name InventoryManager


# CONFIGURACIÓN

const MAX_SLOTS := 3

const TEXTURA_BATERIA: Texture2D = preload(
	"res://Assets/Objects/Power/bateriaport.png"
)

const TEXTURA_SLOT: Texture2D = preload(
	"res://Sprites/inventario.png"
)

const FUENTE_UI: FontFile = preload(
	"res://DePixelBreit.ttf"
)

# Mapea el nombre visible del inventario con la clave de
# datos que usa ObjectData/PowerGenerator para volver a
# crear el objeto cuando se tira al suelo.
const DROP_DATOS := {
	"Barrita": "barritavege",
	"Cafe": "cafe",
	"Caramelos": "caramelos",
	"Cinta": "cinta",
	"Fusible": "fusible"
}


# DATOS DEL INVENTARIO
# Cada objeto es un diccionario:
#   { "nombre", "icono", "tipo" }
# SIN APILADO: cada objeto ocupa SU PROPIA ranura y en
# total caben MAX_SLOTS (3) objetos, aunque sean del
# mismo tipo (3 baterías llenan el inventario entero).
# tipo: "consumible" (se gasta al usar)
#       "clave" (no desaparece hasta usarse en su sitio)

var items: Array[Dictionary] = []

# Índice de ranura seleccionada (-1 = ninguna)
var _seleccion: int = -1

# Referencias de la interfaz
var _raiz: Control = null
var _slots: Array[Dictionary] = []
var _btn_usar: Button = null
var _btn_tirar: Button = null
var _tooltip_habilidad: RichTextLabel = null
var _habilidad_golpe: TextureButton = null
var _contador_recarga_golpe: Label = null
var _mensaje_vibracion: Label = null
var _golpe_activo: bool = false
var _tiempo_recarga_golpe: float = 0.0
var _golpe_visto: bool = false
const TIEMPO_RECARCA_GOLPE := 30.0

# Sala mostrada actualmente (la asigna Main)
var sala_actual: Node2D = null

# Botones de habilidad generados dinámicamente
# (uno por habilidad del personaje seleccionado).
var _iconos_habilidades: Array[Dictionary] = []

# Personaje actual (CharacterData) que define los
# iconos mostrados. Lo asigna Main al empezar.
var _personaje: CharacterData = null
var _activo: bool = false
var _mensaje_temporal_id: int = 0
var _panel_reactivacion: Panel = null


func _jugador_controlado() -> Node:
	var interaction_manager := get_tree().get_first_node_in_group(
		"interaction_manager"
	) as InteractionManager
	if interaction_manager != null and interaction_manager.jugador != null:
		return interaction_manager.jugador
	return get_tree().get_first_node_in_group("player") as Node


# READY

func _ready() -> void:

	add_to_group("inventory_manager")

	layer = 5

	_construir_interfaz()


func establecer_activo(activo: bool) -> void:
	_activo = activo
	visible = activo
	if not activo:
		_cerrar_mensajes_turno()

	# Refrescar iconos de habilidades para el personaje activo
	for icono in _iconos_habilidades:
		var btn = icono.get("boton")
		if btn is TextureButton and is_instance_valid(btn):
			btn.queue_free()
	_iconos_habilidades.clear()
	if activo and _personaje != null:
		_reconstruir_iconos_habilidades()


func _cerrar_mensajes_turno() -> void:
	_mensaje_temporal_id += 1
	if _tooltip_habilidad != null:
		_tooltip_habilidad.visible = false
		_tooltip_habilidad.text = ""
	if _mensaje_vibracion != null and is_instance_valid(_mensaje_vibracion):
		_mensaje_vibracion.queue_free()
		_mensaje_vibracion = null
	_cerrar_selector()


func soltar_todos_al_suelo() -> void:
	if items.is_empty():
		_seleccion = -1
		_refrescar_ui()
		return

	var pendientes: Array[Dictionary] = items.duplicate()
	for item in pendientes:
		if _soltar_en_suelo(item, true):
			items.erase(item)

	_seleccion = -1
	_refrescar_ui()


func _process(delta: float) -> void:
	if _tiempo_recarga_golpe > 0.0:
		_tiempo_recarga_golpe = max(0.0, _tiempo_recarga_golpe - delta)
		if _contador_recarga_golpe != null:
				_contador_recarga_golpe.text = str(int(ceil(_tiempo_recarga_golpe)))
		if _tiempo_recarga_golpe == 0.0:
			_golpe_activo = false
			_golpe_visto = false
			if _habilidad_golpe != null:
				_habilidad_golpe.disabled = false
				_habilidad_golpe.modulate = Color(1.0, 1.0, 1.0, 0.95)
			if _contador_recarga_golpe != null:
				_contador_recarga_golpe.visible = false
			_mostrar_info_habilidad(
				"Golpe de suelo",
				"Recarga completada. La habilidad vuelve a estar disponible."
			)

	# CONTADORES DE RECARGA GENÉRICOS
	# Cada icono muestra los segundos que le quedan a su
	# habilidad (las recargas viven en el personaje).
	# El golpe de suelo lleva su propio contador especial.
	var jugador_recargas := (
		_jugador_controlado()
	)

	if jugador_recargas != null and _personaje != null \
			and jugador_recargas.has_method(
				"tiempo_recarga_restante"
			):

		for icono_dato in _iconos_habilidades:

			var hab_icono = icono_dato["hab"]

			var contador_icono: Label = icono_dato["contador"]

			if hab_icono == null or contador_icono == null:

				continue

			if hab_icono.id == "golpe_suelo":

				continue

			if float(hab_icono.cooldown) <= 0.0:

				continue

			var restante: float = (
				jugador_recargas.tiempo_recarga_restante(
					hab_icono.id
				)
			)

			if restante > 0.0:

				contador_icono.text = (
					"%.0f" % ceil(restante)
				)

				contador_icono.visible = true

			elif contador_icono.visible:

				contador_icono.visible = false

	# Disparador de TECLADO dinámico: cada habilidad
	# declara su acción de input en HabilidadData
	# ("" = sin atajo). Si el personaje no tiene la
	# habilidad, su tecla no hace nada: la interfaz no
	# queda atada a ningún personaje concreto.
	if _personaje != null:

		for hab in _personaje.habilidades:

			if hab == null or hab.accion_input == "":
				continue

			if not InputMap.has_action(hab.accion_input):
				continue

			if Input.is_action_just_pressed(
				hab.accion_input
			):
				pulsar_habilidad(hab.id)


# AÑADIR OBJETO
# Devuelve false si el inventario está lleno.

func añadir_item(
	nombre: String,
	icono: Texture2D,
	tipo: String = "consumible"
) -> bool:

	# Sin apilado: cada objeto va a su propia ranura.
	# Con las 3 ranuras llenas no cabe nada más,
	# aunque sea el mismo objeto que ya se lleva.
	if items.size() >= MAX_SLOTS:
		return false

	var item_nuevo: Dictionary = {
		"nombre": nombre,
		"icono": icono,
		"tipo": tipo
	}

	items.append(item_nuevo)

	_refrescar_ui()

	return true


# CONSULTAS

func tiene_item(nombre: String) -> bool:

	for item in items:

		if item["nombre"] == nombre:
			return true

	return false


func contar_item(nombre: String) -> int:

	# Cada ejemplar ocupa una ranura propia
	var total := 0

	for item in items:

		if item["nombre"] == nombre:
			total += 1

	return total


func esta_lleno() -> bool:

	return items.size() >= MAX_SLOTS


# QUITAR OBJETO POR NOMBRE

func quitar_item(nombre: String) -> bool:

	for i in range(items.size()):

		if items[i]["nombre"] == nombre:

			# Se retira el ejemplar completo (sin apilado
			# cada ranura es un único objeto)
			items.remove_at(i)

			if _seleccion == i:
				_seleccion = -1

			_refrescar_ui()

			return true

	return false


# USAR / TIRAR (DESDE LA INTERFAZ)

func _usar_pulsado() -> void:

	if _seleccion < 0 or _seleccion >= items.size():
		return

	var item: Dictionary = items[_seleccion]

	# BATERIA: recarga al instante la Descarga eléctrica
	# del robot AL USARLA desde el inventario. Si no
	# recarga nada, no se consume.
	if item["nombre"] == "Bateria":

		var jugador_bateria := (
			_jugador_controlado()
		)

		var recargada := false

		if jugador_bateria != null \
				and jugador_bateria.has_method(
					"recargar_descarga_bateria"
				):

			recargada = (
				jugador_bateria.recargar_descarga_bateria()
			)

		if recargada:

			_mostrar_info_habilidad(
				"Bateria",
				"Descarga eléctrica recargada al instante."
			)

			print(
				"🔋 Bateria usada: Descarga eléctrica recargada al instante."
			)

			items.remove_at(_seleccion)

			_seleccion = -1

			_refrescar_ui()

			return

		_mostrar_info_habilidad(
			"Bateria",
			"Ahora no recarga nada: úsala con el robot cuando la Descarga eléctrica esté en recarga, o instálala en un terminal apagado."
		)

		print(
			"🔋 La batería no recarga nada ahora mismo; sigue en el inventario."
		)

		return

	if item["nombre"] == "Barrita" or item["nombre"] == "Caramelos":
		if _usar_reactivador(item["nombre"]):
			return

	if item["nombre"] == "Fusible" or item["nombre"] == "Cinta":
		if _usar_reactivador(item["nombre"]):
			return

	if item["nombre"] == "Cafe":
		var gestor := get_tree().get_first_node_in_group("gestor_turnos") as GestorTurnos
		if gestor == null or not gestor.usar_cafe():
			_mostrar_info_habilidad_temporal("Cafe", "Solo puedes tomar un cafe por turno.")
			return
		_mostrar_info_habilidad_temporal("Cafe", "+10 segundos para este turno.")

	print("🎒 Has usado: ", item["nombre"])

	items.remove_at(_seleccion)

	_seleccion = -1

	_refrescar_ui()


func _usar_reactivador(nombre_item: String) -> bool:
	var jugador := _jugador_controlado()
	if jugador == null or not jugador.has_method("habilidades_en_recarga"):
		return false

	# La barrita mantiene la excepción del forzudo: recupera
	# completamente su Golpe de suelo en un solo uso.
	if nombre_item == "Barrita" and jugador.es_forzudo:
		if _tiempo_recarga_golpe <= 0.0:
			_mostrar_info_habilidad_temporal(nombre_item, "Golpe de suelo ya está disponible.")
			return true
		_tiempo_recarga_golpe = 0.0
		_golpe_activo = false
		_golpe_visto = false
		if _habilidad_golpe != null:
			_habilidad_golpe.disabled = false
		if _contador_recarga_golpe != null:
			_contador_recarga_golpe.visible = false
		_consumir_item_por_nombre(nombre_item)
		_mostrar_info_habilidad_temporal(nombre_item, "Golpe de suelo recuperado por completo.")
		return true

	var recargas: Array[String] = jugador.habilidades_en_recarga()
	if _tiempo_recarga_golpe > 0.0 and not recargas.has("golpe_suelo"):
		recargas.append("golpe_suelo")
	if recargas.is_empty():
		_mostrar_info_habilidad_temporal(nombre_item, "No tienes habilidades en recarga.")
		return true

	# Los caramelos del niño recuperan todas sus habilidades.
	if nombre_item == "Caramelos":
		var es_nino: bool = false
		var tiene_huecos: bool = false
		var tiene_impredecible: bool = false
		for habilidad in jugador.habilidades:
			if habilidad.id == "pasar_huecos":
				tiene_huecos = true
			if habilidad.id == "accion_impredecible":
				tiene_impredecible = true
		es_nino = tiene_huecos and tiene_impredecible
		if es_nino:
			jugador.recuperar_habilidades()
			_consumir_item_por_nombre(nombre_item)
			_mostrar_info_habilidad_temporal(nombre_item, "Has recuperado todas tus habilidades.")
			return true

	if recargas.size() == 1:
		_aplicar_reactivador(nombre_item, recargas[0])
		return true

	_mostrar_selector_reactivacion(nombre_item, recargas)
	return true


func _mostrar_selector_reactivacion(nombre_item: String, ids: Array[String]) -> void:
	if _panel_reactivacion != null:
		_panel_reactivacion.queue_free()

	_panel_reactivacion = Panel.new()
	_panel_reactivacion.position = Vector2(24, 250)
	_panel_reactivacion.size = Vector2(430, 230)
	_raiz.add_child(_panel_reactivacion)

	var titulo := Label.new()
	titulo.text = "ELIGE UNA HABILIDAD PARA REACTIVAR"
	titulo.position = Vector2(18, 18)
	_panel_reactivacion.add_child(titulo)

	for i in range(ids.size()):
		var boton := Button.new()
		boton.text = ids[i]
		boton.position = Vector2(18, 65 + i * 60)
		boton.size = Vector2(394, 46)
		boton.pressed.connect(_reactivador_elegido.bind(nombre_item, ids[i]))
		_panel_reactivacion.add_child(boton)


func _reactivador_elegido(nombre_item: String, id: String) -> void:
	if _panel_reactivacion != null:
		_panel_reactivacion.queue_free()
		_panel_reactivacion = null
	_aplicar_reactivador(nombre_item, id)


func _aplicar_reactivador(nombre_item: String, id: String) -> void:
	var jugador := _jugador_controlado()
	if jugador == null:
		return
	var completa: bool = nombre_item == "Barrita" and jugador.es_forzudo
	var segundos: float = 5.0 if (
		nombre_item == "Fusible" or nombre_item == "Cinta"
	) else 10.0
	var aplicada: bool = false
	if id == "golpe_suelo":
		var anterior: float = _tiempo_recarga_golpe
		_tiempo_recarga_golpe = 0.0 if completa else maxf(
			0.0,
			anterior - segundos
		)
		aplicada = anterior > 0.0
	else:
		aplicada = jugador.reactivar_habilidad(id, segundos, completa)
	if aplicada:
		_consumir_item_por_nombre(nombre_item)
		if completa:
			_mostrar_info_habilidad_temporal(nombre_item, "Habilidad recuperada por completo.")
		else:
			_mostrar_info_habilidad_temporal(
				nombre_item,
				"Se han recuperado %.0f segundos de recarga." % segundos
			)


func _reponer_consumible_en_sala(nombre_item: String) -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not "laboratorio" in main:
		return
	var indice: int = int(main.get("sala_actual"))
	var salas: Array = main.get("laboratorio").salas
	if indice < 0 or indice >= salas.size():
		return
	var nombre_datos: String = DROP_DATOS.get(nombre_item, "")
	if nombre_datos.is_empty():
		return
	if not ObjectGenerator.reponer_consumible_sala(salas[indice], nombre_datos):
		return
	if main.has_method("mostrar_sala"):
		main.call_deferred("mostrar_sala", indice, true)


func _consumir_item_por_nombre(nombre: String) -> void:
	for i in range(items.size()):
		if items[i]["nombre"] == nombre:
			items.remove_at(i)
			_seleccion = -1
			_refrescar_ui()
			var ga := get_tree().get_first_node_in_group(
				"gestor_audio"
			) as AudioManager
			if ga:
				var efecto := "consumir"
				if nombre == "Barrita" or nombre == "Caramelos" \
						or nombre == "Cafe":
					efecto = "comer"
				ga.reproducir_efecto_corto(efecto, 0.75, -3.0)
			return


func _tirar_pulsado() -> void:

	if _seleccion < 0 or _seleccion >= items.size():
		return

	var item: Dictionary = items[_seleccion]

	if _soltar_en_suelo(item):

		items.remove_at(_seleccion)

		_seleccion = -1

		var ga := (
			get_tree().get_first_node_in_group("gestor_audio")
			as AudioManager
		)

		if ga:
			ga.reproducir_efecto("soltar")

		_refrescar_ui()


# SOLTAR OBJETO EN EL SUELO DE LA SALA ACTUAL

func _soltar_en_suelo(item: Dictionary, centrar: bool = false) -> bool:

	var im := (
		get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
	)

	if im == null or im.sala_actual == null or im.jugador == null:
		print("⚠️ No se puede soltar el objeto aquí")
		return false

	var objects_node := (
		im.sala_actual.get_node_or_null("Objects") as Node2D
	)

	if objects_node == null:
		return false

	var data_sala: RoomData = null
	if im.sala_actual.has_meta("room_data"):
		data_sala = im.sala_actual.get_meta("room_data") as RoomData

	var posicion: Vector2 = objects_node.to_local(
		im.jugador.global_position
	)
	if centrar and data_sala != null:
		# Se dejan junto al personaje, desplazados hacia el centro,
		# para que no aparezcan lejos ni se salgan por una puerta.
		var centro_sala := Vector2(
			(data_sala.ancho + 1) * data_sala.tam_celda / 2.0,
			(data_sala.alto + 1) * data_sala.tam_celda / 2.0
		)
		var desde_personaje: Vector2 = centro_sala - posicion
		if desde_personaje.length_squared() > 0.01:
			posicion += desde_personaje.normalized() * data_sala.tam_celda
		posicion.x = clampf(
			posicion.x,
			data_sala.tam_celda,
			data_sala.ancho * data_sala.tam_celda
		)
		posicion.y = clampf(
			posicion.y,
			data_sala.tam_celda,
			data_sala.alto * data_sala.tam_celda
		)

	# Batería: reaparece como objeto recogible
	if item["nombre"] == "Bateria":

		var od := ObjectData.crear(
			"bateria",
			ObjectData.TipoObjeto.INTERACTUABLE,
			TEXTURA_BATERIA,
			posicion,
			0.09,
			true,
			"Batería portátil"
		)

		if data_sala:
			data_sala.añadir_objeto(od)

		PowerGenerator.crear_bateria(objects_node, od)

		print("🔋 Has tirado la batería al suelo")

		return true

	# Otros objetos de Power: vuelven al suelo como
	# recogibles registrados en los datos de la sala
	elif DROP_DATOS.has(item["nombre"]):

		var od_power := ObjectData.crear(
			DROP_DATOS[item["nombre"]],
			ObjectData.TipoObjeto.INTERACTUABLE,
			item["icono"],
			posicion,
			1.0,
			true,
			item["nombre"]
		)

		if data_sala:
			data_sala.añadir_objeto(od_power)

		PowerGenerator.crear_recogible(objects_node, od_power)

		print("🎒 Has tirado: ", item["nombre"])

		return true

	print("⚠️ Este objeto no se puede soltar")
	return false


# CONSTRUIR LA INTERFAZ
# Barra de 3 ranuras bajo los botones de movimiento.

func _construir_interfaz() -> void:

	_raiz = Control.new()

	_raiz.name = "InventarioUI"

	_raiz.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(_raiz)

	var etiqueta_habilidades := Label.new()
	etiqueta_habilidades.text = "Habilidades"
	etiqueta_habilidades.position = Vector2(18.0, 470.0)
	etiqueta_habilidades.add_theme_font_size_override("font_size", 22)
	etiqueta_habilidades.modulate = Color(1.0, 0.92, 0.74)
	etiqueta_habilidades.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(etiqueta_habilidades)

	# Los iconos de habilidad NO están cableados a un
	# personaje: se generan a partir del CharacterData
	# elegido en la pantalla de selección. Main los
	# rellena llamando a configurar_habilidades().
	_reconstruir_iconos_habilidades()

	var posiciones_x := [24.0, 116.0, 208.0]

	for i in range(MAX_SLOTS):

		_slots.append(
			_crear_ranura(i, posiciones_x[i], 606.0)
		)


	# BOTONES DE ACCIÓN (al seleccionar una ranura)

	_btn_usar = _crear_boton_accion("USAR", 312.0, 612.0)

	_btn_usar.pressed.connect(_usar_pulsado)

	_btn_tirar = _crear_boton_accion("TIRAR", 312.0, 656.0)

	_btn_tirar.pressed.connect(_tirar_pulsado)

	_btn_usar.visible = false

	_btn_tirar.visible = false

	_tooltip_habilidad = RichTextLabel.new()
	_tooltip_habilidad.bbcode_enabled = true
	_tooltip_habilidad.fit_content = true
	_tooltip_habilidad.scroll_active = false
	_tooltip_habilidad.position = Vector2(24.0, 320.0)
	_tooltip_habilidad.size = Vector2(430.0, 100.0)
	_tooltip_habilidad.visible = false
	_tooltip_habilidad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_habilidad.add_theme_color_override("default_color", Color(0.94, 0.91, 0.82))
	_tooltip_habilidad.add_theme_font_override("normal_font", FUENTE_UI)
	_tooltip_habilidad.add_theme_font_size_override("normal_font_size", 15)
	_tooltip_habilidad.add_theme_constant_override("line_separation", 6)
	var estilo_tooltip := StyleBoxFlat.new()
	estilo_tooltip.bg_color = Color(0.06, 0.07, 0.11, 0.92)
	estilo_tooltip.border_width_left = 2
	estilo_tooltip.border_width_top = 2
	estilo_tooltip.border_width_right = 2
	estilo_tooltip.border_width_bottom = 2
	estilo_tooltip.border_color = Color(0.75, 0.58, 0.28, 0.95)
	estilo_tooltip.corner_radius_top_left = 10
	estilo_tooltip.corner_radius_top_right = 10
	estilo_tooltip.corner_radius_bottom_left = 10
	estilo_tooltip.corner_radius_bottom_right = 10
	estilo_tooltip.content_margin_left = 14.0
	estilo_tooltip.content_margin_top = 10.0
	estilo_tooltip.content_margin_right = 14.0
	estilo_tooltip.content_margin_bottom = 10.0
	_tooltip_habilidad.add_theme_stylebox_override("normal", estilo_tooltip)
	_raiz.add_child(_tooltip_habilidad)

	_refrescar_ui()


func _crear_ranura(
	indice: int,
	pos_x: float,
	pos_y: float
) -> Dictionary:

	var boton := TextureButton.new()

	boton.name = "Slot%d" % indice

	boton.texture_normal = TEXTURA_SLOT

	boton.ignore_texture_size = true

	boton.stretch_mode = TextureButton.STRETCH_SCALE

	boton.position = Vector2(pos_x, pos_y)

	boton.size = Vector2(84, 90)

	boton.pressed.connect(_slot_pulsado.bind(indice))

	_raiz.add_child(boton)


	var icono := TextureRect.new()

	icono.name = "Icono"

	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	icono.position = Vector2(14, 10)

	icono.size = Vector2(56, 56)

	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE

	icono.visible = false

	boton.add_child(icono)


	var contador := Label.new()

	contador.name = "Contador"

	contador.text = "x1"

	contador.add_theme_font_size_override("font_size", 16)

	contador.position = Vector2(46, 58)

	contador.size = Vector2(34, 24)

	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	contador.mouse_filter = Control.MOUSE_FILTER_IGNORE

	contador.visible = false

	boton.add_child(contador)


	return {
		"boton": boton,
		"icono": icono,
		"contador": contador
	}


func tiene_superfuerza_pasiva() -> bool:
	var jugador := _jugador_controlado()
	return jugador != null and jugador.has_method("tiene_habilidad_forzudo") \
		and jugador.tiene_habilidad_forzudo()


func puede_mover_objeto_pesado(nombre_objeto: String) -> bool:
	if not tiene_superfuerza_pasiva():
		return false
	if nombre_objeto == "":
		return false
	var texto := nombre_objeto.to_lower()
	var es_caja_metal := texto.contains("caja") and texto.contains("metal") or texto.contains("cajametal")
	return es_caja_metal


func tiempo_recarga_golpe_restante() -> float:
	return _tiempo_recarga_golpe


# HABILIDADES DINÁMICAS
# Main las asigna al empezar con el CharacterData
# elegido en la pantalla de selección. Los iconos se
# reconstruyen a partir de sus habilidades: cambiar de
# personaje cambia iconos y acciones sin tocar la UI.

func configurar_habilidades(
	personaje: CharacterData
) -> void:

	_personaje = personaje

	_reconstruir_iconos_habilidades()


func _tiene_habilidad(id: String) -> bool:

	if _personaje == null:
		return false

	for hab in _personaje.habilidades:

		if hab != null and hab.id == id:
			return true

	return false


func _reconstruir_iconos_habilidades() -> void:

	# Limpiar los iconos del personaje anterior
	for dato in _iconos_habilidades:

		var boton_viejo: TextureButton = dato["boton"]

		if is_instance_valid(boton_viejo):
			boton_viejo.queue_free()

	_iconos_habilidades.clear()

	_habilidad_golpe = null

	_contador_recarga_golpe = null

	if _personaje == null:
		return

	var indice := 0

	for hab in _personaje.habilidades:

		if hab == null or hab.icono == null:
			continue

		var boton := TextureButton.new()

		boton.texture_normal = hab.icono

		boton.ignore_texture_size = true

		boton.stretch_mode = TextureButton.STRETCH_SCALE

		boton.position = Vector2(
			24.0 + indice * 92.0, 500.0
		)

		boton.size = Vector2(84, 84)

		boton.focus_mode = Control.FOCUS_NONE

		# Descripción bonita al pasar el ratón: panel con
		# título dorado, en vez del tooltip gris nativo.
		var hab_actual := hab

		boton.mouse_entered.connect(func() -> void:
			_mostrar_info_habilidad(
				hab_actual.nombre,
				hab_actual.descripcion
			)
		)

		boton.mouse_exited.connect(func() -> void:
			if _tooltip_habilidad != null:
				_tooltip_habilidad.visible = false
				_tooltip_habilidad.text = ""
		)

		boton.pressed.connect(
			_habilidad_pulsada.bind(hab.id)
		)

		_raiz.add_child(boton)

		var contador := _crear_contador_recarga()

		contador.position = Vector2.ZERO

		contador.size = Vector2(84.0, 84.0)

		boton.add_child(contador)

		# El golpe de suelo mantiene su flujo especial de
		# confirmación y recarga; se enlaza a su icono
		# dinámico sea cual sea el personaje que lo tenga.
		if hab.id == "golpe_suelo":

			_habilidad_golpe = boton

			_contador_recarga_golpe = contador

		_iconos_habilidades.append(
			{
				"hab": hab,
				"boton": boton,
				"contador": contador
			}
		)

		indice += 1


func _crear_contador_recarga() -> Label:
	var contador := Label.new()
	contador.text = ""
	contador.position = Vector2(0.0, 31.0)
	contador.size = Vector2(96.0, 34.0)
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contador.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	contador.add_theme_font_size_override("font_size", 22)
	contador.add_theme_color_override("font_color", Color.WHITE)
	contador.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	contador.add_theme_constant_override("shadow_offset_x", 2)
	contador.add_theme_constant_override("shadow_offset_y", 2)
	contador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contador.visible = false
	return contador


func _habilidad_pulsada(id: String) -> void:
	pulsar_habilidad(id)


# ENTRADA ÚNICA DE PULSACIÓN DE HABILIDAD
# La usan los iconos del inventario y los botones
# táctiles de MovementControls. El golpe de suelo
# mantiene aquí su flujo de confirmación y afecta a
# las salas; el resto delega en el jugador.

# MOSTRAR LA DESCRIPCIÓN DE UNA HABILIDAD
# Panel con el nombre en dorado y la descripción
# debajo. Lo usan los iconos al pasar el ratón y los
# avisos de estado del golpe de suelo.

func _mostrar_info_habilidad(titulo: String, texto: String) -> void:

	if _tooltip_habilidad == null:
		return

	# Título dorado + separador + descripción en blanco
	# cálido: mucho más legible que el texto plano.
	_tooltip_habilidad.text = (
		"[color=#f0c96a][font_size=18]" + titulo
		+ "[/font_size][/color]\n"
		+ "[color=#6f7488][font_size=11]"
				+ "------------------------------\n"
		+ "[/font_size][/color]\n"
		+ "[color=#ece7d9][font_size=15]" + texto
		+ "[/font_size][/color]"
	)

	_tooltip_habilidad.visible = true


func _mostrar_info_habilidad_temporal(titulo: String, texto: String) -> void:
	_mensaje_temporal_id += 1
	var id_actual: int = _mensaje_temporal_id
	_mostrar_info_habilidad(titulo, texto)
	await get_tree().create_timer(2.5).timeout
	if id_actual == _mensaje_temporal_id and _tooltip_habilidad != null:
		_tooltip_habilidad.visible = false
		_tooltip_habilidad.text = ""


func pulsar_habilidad(id: String) -> void:
	if id == "golpe_suelo":
		_on_golpe_icon_pulsado()
		return
	if id == "mini_teletransporte":
		_iniciar_mini_teletransporte()
		return
	if id == "teletransporte_objeto":
		_iniciar_teletransporte_objeto()
		return
	var jugador := _jugador_controlado()
	if jugador != null and jugador.has_method("usar_habilidad"):
		jugador.usar_habilidad(id)


# TELETRANSPORTE (CIENTÍFICO TELEPORTADOR)
# Las dos habilidades abren un selector: el
# mini-teletransporte pide la sala destino y el
# teletransporte de objeto pide primero el objeto y
# después la sala. La recarga la gestiona el personaje
# (consumir_recarga_habilidad) al confirmar.

var _selector: Control = null
var _tele_salas: Array[Dictionary] = []
var _tele_item_nombre: String = ""
var _tele_confirmar: Callable = Callable()


func _salas_adyacentes() -> Array[Dictionary]:

	var resultado: Array[Dictionary] = []

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "laboratorio" in main:

		return resultado

	var data: RoomData = (
		main.laboratorio.salas[main.sala_actual]
	)

	for par in [
		["arriba", data.arriba],
		["abajo", data.abajo],
		["izquierda", data.izquierda],
		["derecha", data.derecha]
	]:

		if par[1] >= 0:

			resultado.append({
				"indice": par[1],
				"direccion": par[0]
			})

	return resultado


func _iniciar_mini_teletransporte() -> void:

	var jugador := _jugador_controlado()

	if jugador == null or not jugador.has_method(
		"puede_usar_habilidad"
	):

		return

	if not jugador.puede_usar_habilidad("mini_teletransporte"):

		_mostrar_info_habilidad(
			"Mini-teletransporte",
			"En recarga: la habilidad todavía no está lista."
		)

		return

	var salas := _salas_adyacentes()

	if salas.is_empty():

		_mostrar_info_habilidad(
			"Mini-teletransporte",
			"Esta sala no tiene salas adyacentes."
		)

		return

	_abrir_selector_teletransporte(
		"MINI-TELETRANSPORTE\nElige la sala destino",
		[],
		salas,
		func(_nombre: String, indice: int, direccion: String):

			if jugador.has_method("teleportar_a_sala") \
					and jugador.teleportar_a_sala(
						indice, direccion
					):

				print(
					"🌀 Mini-teletransporte a la sala ",
					indice
				)

			else:

				_mostrar_info_habilidad(
					"Mini-teletransporte",
					"No se pudo teletransportar."
				)
	)


func _iniciar_teletransporte_objeto() -> void:

	var jugador := _jugador_controlado()

	if jugador == null or not jugador.has_method(
		"puede_usar_habilidad"
	):

		return

	if not jugador.puede_usar_habilidad("teletransporte_objeto"):

		_mostrar_info_habilidad(
			"Teletransporte de objeto",
			"En recarga: la habilidad todavía no está lista."
		)

		return

	if items.is_empty():

		_mostrar_info_habilidad(
			"Teletransporte de objeto",
			"No llevas ningún objeto en el inventario."
		)

		return

	var salas := _salas_adyacentes()

	if salas.is_empty():

		_mostrar_info_habilidad(
			"Teletransporte de objeto",
			"Esta sala no tiene salas adyacentes."
		)

		return

	var opciones: Array[Dictionary] = []

	for item in items:

		opciones.append({
			"nombre": item["nombre"],
			"icono": item["icono"]
		})

	_abrir_selector_teletransporte(
		"TELETRANSPORTE DE OBJETO\nElige qué objeto enviar",
		opciones,
		salas,
		func(nombre_item: String, indice: int, direccion: String):

			_confirmar_teletransporte_objeto(
				nombre_item, indice, direccion
			)
	)


func _confirmar_teletransporte_objeto(
	nombre_item: String,
	indice: int,
	direccion: String
) -> void:

	var jugador := _jugador_controlado()

	if jugador == null or not jugador.has_method(
		"teletransportar_objeto_a_sala"
	):

		return

	# Nombre de datos para recrear el objeto en la sala
	var nombre_datos: String = nombre_item

	if DROP_DATOS.has(nombre_item):

		nombre_datos = DROP_DATOS[nombre_item]

	elif nombre_item == "Bateria":

		nombre_datos = "bateria"

	# Textura del objeto (la del inventario)
	var textura: Texture2D = TEXTURA_BATERIA

	for item in items:

		if item["nombre"] == nombre_item:

			textura = item["icono"]

			break

	# RIESGO 20%: el objeto aparece en una sala aleatoria
	var indice_final: int = indice

	var fue_aleatorio := false

	if randf() < 0.2:

		var main := (
			get_tree().get_first_node_in_group("main")
		)

		if main != null and "laboratorio" in main:

			var total: int = main.laboratorio.salas.size()

			if total > 1:

				var elegido := randi() % total

				if elegido == main.sala_actual:

					elegido = (elegido + 1) % total

				indice_final = elegido

				fue_aleatorio = true

	if not jugador.teletransportar_objeto_a_sala(
		nombre_datos,
		nombre_item,
		indice_final,
		direccion,
		textura
	):

		return

	# El objeto sale del inventario
	for i in range(items.size()):

		if items[i]["nombre"] == nombre_item:

			items.remove_at(i)

			break

	_seleccion = -1

	_refrescar_ui()

	if fue_aleatorio:

		_mostrar_info_habilidad(
			"Teletransporte de objeto",
			"¡El portal falló! El objeto apareció en una sala aleatoria."
		)

	else:

		_mostrar_info_habilidad(
			"Teletransporte de objeto",
			"Objeto enviado a la sala destino."
		)


# OVERLAY DEL SELECTOR

func _abrir_selector_teletransporte(
	titulo: String,
	items_opciones: Array[Dictionary],
	salas: Array[Dictionary],
	al_confirmar: Callable
) -> void:

	_cerrar_selector()

	_tele_salas = salas

	_tele_confirmar = al_confirmar

	var jugador := _jugador_controlado()

	if jugador != null:

		jugador.movimiento_bloqueado = true

	if items_opciones.is_empty():

		_pintar_selector(
			titulo, [], false
		)

	else:

		_pintar_selector(
			titulo, items_opciones, true
		)


func _cerrar_selector() -> void:

	if _selector != null:

		_selector.queue_free()

		_selector = null

	_tele_salas.clear()

	_tele_item_nombre = ""

	_tele_confirmar = Callable()

	var jugador := _jugador_controlado()

	if jugador != null:

		jugador.movimiento_bloqueado = false


func _pintar_selector(
	titulo: String,
	items_opciones: Array[Dictionary],
	fase_item: bool
) -> void:

	if _selector != null:

		_selector.queue_free()

	_selector = Control.new()

	_selector.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	_selector.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(_selector)

	var fondo := ColorRect.new()

	fondo.color = Color(0.0, 0.0, 0.0, 0.6)

	fondo.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	fondo.mouse_filter = Control.MOUSE_FILTER_STOP

	_selector.add_child(fondo)

	var panel := PanelContainer.new()

	var estilo := StyleBoxFlat.new()

	estilo.bg_color = Color(0.08, 0.09, 0.13)

	estilo.border_color = Color(0.75, 0.58, 0.28)

	estilo.set_border_width_all(2)

	estilo.set_corner_radius_all(10)

	estilo.content_margin_left = 20.0

	estilo.content_margin_right = 20.0

	estilo.content_margin_top = 14.0

	estilo.content_margin_bottom = 14.0

	panel.add_theme_stylebox_override("panel", estilo)

	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH

	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	panel.set_anchors_preset(Control.PRESET_CENTER)

	_selector.add_child(panel)

	var caja := VBoxContainer.new()

	caja.add_theme_constant_override("separation", 10)

	panel.add_child(caja)

	var lbl := Label.new()

	lbl.text = titulo

	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	lbl.add_theme_font_override("font", FUENTE_UI)

	lbl.add_theme_font_size_override("font_size", 15)

	lbl.add_theme_color_override(
		"font_color", Color(0.94, 0.79, 0.42)
	)

	caja.add_child(lbl)

	if fase_item:

		var fila := HBoxContainer.new()

		fila.alignment = BoxContainer.ALIGNMENT_CENTER

		fila.add_theme_constant_override("separation", 10)

		caja.add_child(fila)

		for opcion in items_opciones:

			var btn := _boton_selector(
				opcion["nombre"]
			)

			var nombre_opcion: String = opcion["nombre"]

			btn.pressed.connect(func():

				_tele_item_nombre = nombre_opcion

				_pintar_selector(
					"Elige la sala destino",
					[],
					false
				)
			)

			fila.add_child(btn)

	else:

		for sala_info in _tele_salas:

			var btn := _boton_selector(
				_texto_sala(sala_info)
			)

			var indice: int = sala_info["indice"]

			var direccion: String = sala_info["direccion"]

			var item_nombre: String = _tele_item_nombre

			var confirmar := _tele_confirmar

			btn.pressed.connect(func():

				_cerrar_selector()

				if confirmar.is_valid():

					confirmar.call(
						item_nombre, indice, direccion
					)
			)

			caja.add_child(btn)

	caja.add_child(_boton_cancelar_selector())


func _boton_selector(texto: String) -> Button:

	var btn := Button.new()

	btn.text = texto

	btn.custom_minimum_size = Vector2(220.0, 42.0)

	btn.add_theme_font_override("font", FUENTE_UI)

	btn.add_theme_font_size_override("font_size", 13)

	btn.focus_mode = Control.FOCUS_NONE

	return btn


func _boton_cancelar_selector() -> Button:

	var btn := _boton_selector("Cancelar")

	btn.pressed.connect(_cerrar_selector)

	return btn


func _texto_sala(sala_info: Dictionary) -> String:

	var nombre_sala: String = ""

	var main := get_tree().get_first_node_in_group("main")

	if main != null and "laboratorio" in main:

		var sala = main.laboratorio.salas[
			sala_info["indice"]
		]

		nombre_sala = RoomData.TipoSala.keys()[sala.tipo]

	return sala_info["direccion"].capitalize() + " - " + nombre_sala


func _on_golpe_icon_pulsado() -> void:
	if _tiempo_recarga_golpe > 0.0:
		_mostrar_info_habilidad(
			"Golpe de suelo",
			"En recarga: quedan %.0f segundos." % _tiempo_recarga_golpe
		)
		return

	if _golpe_visto:
		_usar_golpe_de_suelo()
	else:
		_previsualizar_golpe()


func _previsualizar_golpe() -> void:
	_golpe_visto = true
	_mostrar_info_habilidad(
		"Golpe de suelo",
		"Listo. Pulsa otra vez para confirmar el golpe."
	)


func _usar_golpe_de_suelo() -> void:
	if _tiempo_recarga_golpe > 0.0:
		_mostrar_info_habilidad(
			"Golpe de suelo",
			"En recarga: quedan %.0f segundos." % _tiempo_recarga_golpe
		)
		return

	_golpe_activo = true
	_golpe_visto = false
	_tiempo_recarga_golpe = TIEMPO_RECARCA_GOLPE
	print("[HABILIDAD] Golpe de suelo activado. Recarga: 30 segundos.")
	if _habilidad_golpe != null:
		_habilidad_golpe.disabled = true
		_habilidad_golpe.modulate = Color(0.38, 0.38, 0.38, 0.95)
	if _contador_recarga_golpe != null:
		_contador_recarga_golpe.text = "30"
		_contador_recarga_golpe.visible = true
	_mostrar_info_habilidad(
		"Golpe de suelo",
		"¡Activado! La vibración desordena las piezas de los puzles cercanos."
	)

	var jugador := _jugador_controlado() as Node2D
	if jugador != null:
		if jugador.has_method("activar_animacion_golpe"):
			jugador.activar_animacion_golpe()
		elif jugador.has_method("play"):
			jugador.play("golpe")

	var afectados := _afectar_puzzles_rivales()
	if afectados > 0:
		_mostrar_mensaje_vibracion("Vibración: piezas desordenadas")
	else:
		_mostrar_mensaje_vibracion("Vibración: sin puzles rivales cerca")

	var ga := get_tree().get_first_node_in_group("gestor_audio") as AudioManager
	if ga != null and ga.has_method("reproducir_efecto"):
		ga.reproducir_efecto("habgolpe")


func _afectar_puzzles_rivales() -> int:

	var jugador_actual := _jugador_controlado()
	if jugador_actual == null:
		return 0

	var sala_actual_jugador: int = 0
	if jugador_actual.has_meta("sala_actual_idx"):
		sala_actual_jugador = int(jugador_actual.get_meta("sala_actual_idx"))
	elif jugador_actual.has_method("get"):
		var campo_sala: Variant = jugador_actual.get("sala_actual_idx")
		if typeof(campo_sala) == TYPE_INT:
			sala_actual_jugador = int(campo_sala)

	var main := get_tree().get_first_node_in_group("main") as Node
	var salas_afectadas: Array[int] = [sala_actual_jugador]

	if main != null and main.has_method("obtener_salas_adyacentes_a_actual"):
		salas_afectadas = main.obtener_salas_adyacentes_a_actual()

	var afectados := 0

	# 1. SALA ACTIVA: desordenar puzzles directamente
	var room_actual_node: Node = sala_actual
	if main != null and main.has_method("get_node_or_null"):
		var room_node := main.get_node_or_null("DisplayedRoom")
		if room_node != null and room_node.get_child_count() > 0:
			room_actual_node = room_node.get_child(0)

	if room_actual_node != null:
		var objetos := room_actual_node.get_node_or_null("Objects")
		if objetos != null:
			for hijo in objetos.get_children():
				if hijo.has_method("desordenar_piezas"):
					if hijo is PanelElectrico:
						hijo.desordenar_piezas(false)
					else:
						hijo.desordenar_piezas()
					afectados += 1

	# 2. RIVALES EN SALAS ADYACENTES: desordenar puzzles
	for rival in get_tree().get_nodes_in_group("player"):
		if rival == jugador_actual:
			continue
		var sala_rival: int = 0
		if rival.has_meta("sala_actual_idx"):
			sala_rival = int(rival.get_meta("sala_actual_idx"))
		elif rival.has_method("get"):
			var campo_rival: Variant = rival.get("sala_actual_idx")
			if typeof(campo_rival) == TYPE_INT:
				sala_rival = int(campo_rival)
		if not salas_afectadas.has(sala_rival):
			continue
		if rival.get_parent() != null and rival.get_parent().has_node("Objects"):
			var objetos_rival := rival.get_parent().get_node("Objects")
			for hijo in objetos_rival.get_children():
				if hijo.has_method("desordenar_piezas"):
					if hijo is PanelElectrico:
						hijo.desordenar_piezas(false)
					else:
						hijo.desordenar_piezas()
					afectados += 1

	# 3. SALAS ADYACENTES SIN RIVAL: marcar vibración
	#    pendiente y deshacer resolución de paneles
	#    para que al entrar estén desordenados/cerrados
	if main != null and main.get("laboratorio") != null:
		var salas: Array[RoomData] = main.laboratorio.salas
		for indice in salas_afectadas:
			if indice == sala_actual_jugador:
				continue  # Ya se procesó arriba
			if indice < 0 or indice >= salas.size():
				continue
			var data: RoomData = salas[indice]
			# Marcar vibración pendiente (RoomBuilder desordenará al construir)
			data.vibracion_pendiente = true
			# Deshacer resolución de paneles: la puerta debe nacer cerrada
			if data.panel_resuelto:
				data.panel_resuelto = false
			if data.panel_resuelto_vecina:
				data.panel_resuelto_vecina = false

	return afectados


func _mostrar_mensaje_vibracion(texto: String) -> void:

	if _mensaje_vibracion != null and is_instance_valid(_mensaje_vibracion):
		_mensaje_vibracion.queue_free()

	_mensaje_vibracion = Label.new()
	_mensaje_vibracion.name = "MensajeGolpeVibracion"
	_mensaje_vibracion.text = texto
	_mensaje_vibracion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje_vibracion.position = Vector2(220.0, 70.0)
	_mensaje_vibracion.size = Vector2(400.0, 40.0)
	_mensaje_vibracion.add_theme_font_size_override("font_size", 18)
	_mensaje_vibracion.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	_mensaje_vibracion.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_mensaje_vibracion.z_index = 20
	_raiz.add_child(_mensaje_vibracion)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_mensaje_vibracion, "modulate:a", 0.0, 0.85)
	tween.tween_callback(func() -> void:
		if _mensaje_vibracion != null and is_instance_valid(_mensaje_vibracion):
			_mensaje_vibracion.queue_free()
			_mensaje_vibracion = null
	)


func _crear_boton_accion(
	texto: String,
	pos_x: float,
	pos_y: float
) -> Button:

	var boton := Button.new()

	boton.text = texto

	boton.position = Vector2(pos_x, pos_y)

	boton.size = Vector2(150, 38)

	boton.add_theme_font_size_override("font_size", 18)

	_raiz.add_child(boton)

	return boton


# SELECCIÓN DE RANURA

func _slot_pulsado(indice: int) -> void:

	if indice >= items.size():
		_seleccion = -1
	elif _seleccion == indice:
		_seleccion = -1
	else:
		_seleccion = indice

	_refrescar_ui()


# REFRESCAR LA INTERFAZ

func _refrescar_ui() -> void:

	for i in range(MAX_SLOTS):

		var slot: Dictionary = _slots[i]

		var boton: TextureButton = slot["boton"]

		var icono: TextureRect = slot["icono"]

		var hay_item := i < items.size()

		icono.visible = hay_item

		if hay_item:
			icono.texture = items[i]["icono"]

		# Resaltar la ranura seleccionada
		if hay_item and _seleccion == i:
			boton.self_modulate = Color(1.0, 0.95, 0.45)

		elif hay_item:
			boton.self_modulate = Color.WHITE

		else:
			boton.self_modulate = Color(1, 1, 1, 0.5)


	var hay_seleccion := (
		_seleccion >= 0 and _seleccion < items.size()
	)

	if _btn_usar:
		_btn_usar.visible = hay_seleccion

	if _btn_tirar:
		_btn_tirar.visible = hay_seleccion
