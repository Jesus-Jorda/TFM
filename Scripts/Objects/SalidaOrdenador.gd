extends InteractableObject

class_name SalidaOrdenador

# ORDENADOR DE REPARACIÓN DE LA SALIDA
# Base para un panel interactivo donde el jugador va
# introduciendo piezas de reparación en el orden correcto.
# Reglas de diseño acordadas:
# - 4 fases visibles de la salida
# - piezas reales: batería + 2 fusibles + 2 cintas
# - la plataforma solo se activa cuando llega a la fase final

const RADIO_INTERACCION := 48.0
const SECUENCIA := [
	"Bateria",
	"Fusible",
	"Fusible",
	"Cinta",
	"Cinta"
]

var plataforma: SalidaPlataforma = null
var inventario: InventoryManager = null
var fase_actual: int = 0
var piezas_usadas: int = 0
var panel_abierto: bool = false

var estado_label: Label = null
var texto_instruccion: Label = null
var panel_reparacion: Panel = null
var botones_piezas: Array[Button] = []
var capa_interfaz: CanvasLayer = null
var fondo_interfaz: ColorRect = null


func _ready() -> void:
	interaction_area = get_node_or_null(".") as Area2D
	super._ready()
	object_id = "salida_ordenador"
	_crear_panel_visual()
	_actualizar_estado()


func _crear_area_interaccion() -> void:
	interaction_area = get_node_or_null(".") as Area2D


func _crear_panel_visual() -> void:
	if get_node_or_null("PanelVisual") != null:
		return

	capa_interfaz = CanvasLayer.new()
	capa_interfaz.name = "InterfazSalida"
	capa_interfaz.layer = 20
	add_child(capa_interfaz)

	fondo_interfaz = ColorRect.new()
	fondo_interfaz.color = Color(0.01, 0.03, 0.02, 0.82)
	fondo_interfaz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo_interfaz.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo_interfaz.visible = false
	capa_interfaz.add_child(fondo_interfaz)

	panel_reparacion = Panel.new()
	panel_reparacion.name = "PanelReparacion"
	panel_reparacion.set_anchors_preset(Control.PRESET_CENTER)
	panel_reparacion.position = Vector2(-360, -210)
	panel_reparacion.size = Vector2(720, 420)
	panel_reparacion.visible = false
	capa_interfaz.add_child(panel_reparacion)

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.03, 0.12, 0.06, 1.0)
	estilo.border_color = Color(0.35, 1.0, 0.45, 0.9)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(8)
	panel_reparacion.add_theme_stylebox_override("panel", estilo)

	var titulo := Label.new()
	titulo.text = "SISTEMA DE REPARACION DE LA SALIDA"
	titulo.position = Vector2(34, 28)
	titulo.size = Vector2(650, 38)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	panel_reparacion.add_child(titulo)

	texto_instruccion = Label.new()
	texto_instruccion.name = "TextoInstruccion"
	texto_instruccion.text = "Repara la salida"
	texto_instruccion.position = Vector2(45, 90)
	texto_instruccion.size = Vector2(630, 42)
	texto_instruccion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto_instruccion.add_theme_font_size_override("font_size", 20)
	texto_instruccion.add_theme_color_override("font_color", Color(0.72, 1.0, 0.75))
	panel_reparacion.add_child(texto_instruccion)

	estado_label = Label.new()
	estado_label.name = "Estado"
	estado_label.text = "PIEZAS INSTALADAS: 0/5"
	estado_label.position = Vector2(45, 145)
	estado_label.size = Vector2(630, 32)
	estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado_label.add_theme_font_size_override("font_size", 16)
	estado_label.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	panel_reparacion.add_child(estado_label)

	var etiqueta_piezas := Label.new()
	etiqueta_piezas.text = "SELECCIONA UNA PIEZA DEL INVENTARIO"
	etiqueta_piezas.position = Vector2(45, 200)
	etiqueta_piezas.size = Vector2(630, 30)
	etiqueta_piezas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta_piezas.add_theme_font_size_override("font_size", 14)
	etiqueta_piezas.add_theme_color_override("font_color", Color(0.55, 0.85, 0.6))
	panel_reparacion.add_child(etiqueta_piezas)

	for datos in [["Bateria", "BATERIA"], ["Fusible", "FUSIBLE"], ["Cinta", "CINTA"]]:
		var boton := Button.new()
		boton.text = datos[1]
		boton.position = Vector2(45 + botones_piezas.size() * 210, 250)
		boton.size = Vector2(190, 52)
		boton.add_theme_font_size_override("font_size", 16)
		boton.pressed.connect(_pieza_pulsada.bind(datos[0]))
		panel_reparacion.add_child(boton)
		botones_piezas.append(boton)

	var cerrar := Button.new()
	cerrar.text = "CERRAR"
	cerrar.position = Vector2(285, 340)
	cerrar.size = Vector2(150, 42)
	cerrar.add_theme_font_size_override("font_size", 16)
	cerrar.pressed.connect(_cerrar_panel)
	panel_reparacion.add_child(cerrar)


func interactuar() -> void:
	if not jugador_cerca:
		return

	if plataforma == null:
		plataforma = _buscar_plataforma_salidas()
	if plataforma != null:
		_sincronizar_con_plataforma()

	if plataforma != null and plataforma.completada:
		print("[Salida] La plataforma ya está reparada")
		return

	if inventario == null:
		inventario = get_tree().get_first_node_in_group("inventory_manager") as InventoryManager

	if inventario == null:
		print("[Salida] No hay inventario disponible")
		return

	panel_abierto = true
	_mostrar_estado_panel()
	if panel_reparacion != null:
		panel_reparacion.visible = true
	if fondo_interfaz != null:
		fondo_interfaz.visible = true
	print("[Salida] Ordenador abierto: requiere piezas de reparación")


func _buscar_plataforma_salidas() -> SalidaPlataforma:
	var plataforma_padre := get_parent() as SalidaPlataforma
	if plataforma_padre != null:
		return plataforma_padre

	var raiz := get_tree().current_scene
	if raiz == null:
		return null

	for nodo in raiz.get_children():
		if nodo is SalidaPlataforma:
			return nodo

	var displayed_room := raiz.get_node_or_null("DisplayedRoom")
	if displayed_room != null:
		for nodo in displayed_room.find_children("SalidaPlataforma", "SalidaPlataforma", true, false):
			return nodo as SalidaPlataforma

	return null


func _mostrar_estado_panel() -> void:
	if texto_instruccion == null:
		return

	texto_instruccion.text = _texto_instruccion_actual()
	if estado_label != null:
		estado_label.text = "PIEZAS INSTALADAS: %d/5" % piezas_usadas
	for boton in botones_piezas:
		var nombre_boton: String = _nombre_pieza_boton(boton)
		var pieza_esperada: String = ""
		if fase_actual < SECUENCIA.size():
			pieza_esperada = String(SECUENCIA[fase_actual])
		boton.disabled = (
			inventario == null
			or nombre_boton != pieza_esperada
			or not inventario.tiene_item(nombre_boton)
		)


func _sincronizar_con_plataforma() -> void:
	if plataforma == null:
		return

	fase_actual = plataforma.piezas_colocadas
	piezas_usadas = plataforma.piezas_colocadas
	if plataforma.completada:
		fase_actual = SECUENCIA.size()


func _nombre_pieza_boton(boton: Button) -> String:
	match boton.text:
		"BATERIA":
			return "Bateria"
		"FUSIBLE":
			return "Fusible"
		"CINTA":
			return "Cinta"
	return ""


func _pieza_pulsada(nombre_pieza: String) -> void:
	if intentar_insertar_pieza(nombre_pieza):
		_mostrar_estado_panel()


func _cerrar_panel() -> void:
	panel_abierto = false
	if panel_reparacion != null:
		panel_reparacion.visible = false
	if fondo_interfaz != null:
		fondo_interfaz.visible = false


func _texto_instruccion_actual() -> String:
	if fase_actual >= SECUENCIA.size():
		return "SALIDA COMPLETA: ya puedes escapar"

	match SECUENCIA[fase_actual]:
		"Bateria":
			return "SIGUIENTE: BATERIA (1 unidad)"
		"Fusible":
			return "SIGUIENTE: FUSIBLES (%d/2)" % max(0, fase_actual - 1)
		"Cinta":
			return "SIGUIENTE: CINTAS (%d/2)" % max(0, fase_actual - 3)
		_:
			return "Repara la salida"


func intentar_insertar_pieza(nombre_pieza: String) -> bool:
	if inventario == null:
		return false

	if fase_actual >= SECUENCIA.size():
		return false

	var pieza_esperada: String = String(SECUENCIA[fase_actual])
	if nombre_pieza != pieza_esperada:
		print("[Salida] Esperaba: ", pieza_esperada, " pero recibiste: ", nombre_pieza)
		return false

	if not inventario.tiene_item(nombre_pieza):
		print("[Salida] No tienes esa pieza: ", nombre_pieza)
		return false

	inventario.quitar_item(nombre_pieza)
	fase_actual += 1
	piezas_usadas += 1

	if plataforma != null:
		plataforma.registrar_pieza_colocada()
	else:
		plataforma = _buscar_plataforma_salidas()
		if plataforma != null:
			plataforma.registrar_pieza_colocada()

	_actualizar_estado()
	return true


func _actualizar_estado() -> void:
	if estado_label != null:
		estado_label.text = "%d/5" % piezas_usadas

	if fase_actual >= SECUENCIA.size() and plataforma != null:
		plataforma.completar_plataforma()
		texto_instruccion.text = "Salida operativa"
		if interaction_manager != null:
			interaction_manager.refrescar_prompt()


func puede_interactuar_con_jugador(_jugador: Character) -> bool:
	if plataforma == null:
		plataforma = _buscar_plataforma_salidas()
	return plataforma == null or not plataforma.completada


func obtener_texto_prompt() -> String:
	return "Reparar salida"
