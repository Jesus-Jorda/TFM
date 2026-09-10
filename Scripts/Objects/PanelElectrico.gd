extends InteractableObject

class_name PanelElectrico


# CONFIGURACIÓN

const RADIO_INTERACCION := 46.0


# SPRITES DEL PANEL EN LA SALA

# Vista lateral (puertas de la derecha o izquierda)
const TEXTURA_LATERAL: Texture2D = preload(
	"res://Assets/Objects/Computers/paneleleder.png"
)

# Vista frontal (puertas de arriba o abajo)
const TEXTURA_FRONTAL: Texture2D = preload(
	"res://Assets/Objects/Computers/panelelesup.png"
)

# Escala para que ambos paneles midan ~45-55 x ~84 px
const ESCALA_VISUAL := 0.19


# DATOS Y ESTADO

var objeto_datos: ObjectData = null

var datos_sala: RoomData = null

var resuelto: bool = false

# Sobrecarga del electricista: al abrir el puzzle, la
# mitad de los cables ya están conectados.
var sobrecargado: bool = false

var _puzzle_abierto: bool = false

# Puerta cerrada por mecanismo que abre este panel
var direccion_puerta: String = ""

# Nodo de la sala donde está el panel
var sala_nodo: Node2D = null


# READY

func _ready() -> void:
	add_to_group("paneles_electricos")

	# ÁREA DE INTERACCIÓN

	if interaction_area == null:

		var area := Area2D.new()

		area.name = "InteractionArea"

		var collision := CollisionShape2D.new()

		var forma := CircleShape2D.new()

		forma.radius = RADIO_INTERACCION

		collision.shape = forma

		area.add_child(collision)

		add_child(area)

		interaction_area = area

	# SPRITE (usa el panel metálico como carcasa)

	if get_node_or_null("Sprite2D") == null:

		var sprite := Sprite2D.new()

		sprite.name = "Sprite2D"

		sprite.texture = _textura_panel()

		sprite.scale = Vector2.ONE * ESCALA_VISUAL

		add_child(sprite)

	# COLISIÓN FÍSICA (mueble sólido)

	var cuerpo := StaticBody2D.new()

	cuerpo.name = "PanelCollision"

	var colision := CollisionShape2D.new()

	var forma_col := RectangleShape2D.new()

	forma_col.size = Vector2(44, 72)

	colision.shape = forma_col

	colision.position = Vector2(0, 6)

	cuerpo.add_child(colision)

	add_child(cuerpo)


	super._ready()

	object_id = "panel_electrico"


# INTERACTUAR

func interactuar() -> void:
	var jugador_activo := jugador
	if jugador_activo == null:
		jugador_activo = get_tree().get_first_node_in_group("jugador_activo") as Character
	if jugador_activo == null:
		var gestor := get_tree().get_first_node_in_group(
			"interaction_manager"
		) as InteractionManager
		if gestor != null:
			jugador_activo = gestor.jugador
	if jugador_activo == null:
		return

	if not jugador_cerca:
		if global_position.distance_to(jugador_activo.global_position) > RADIO_INTERACCION:
			return
		jugador = jugador_activo
		jugador_cerca = true

	if resuelto:
		_reiniciar_puzzle_cables()
		return

	if _puzzle_abierto:
		var puzzle_existente := get_node_or_null("PuzzleCables")
		if puzzle_existente != null:
			return
		_puzzle_abierto = false

	# APAGÓN (CORTOCIRCUITO DEL ROBOT)
	# Sin energía el panel no se puede manipular: los
	# cables están muertos hasta que acabe el apagón.
	if _sala_en_apagon():

		print("⚡ Apagón: el panel de cables está sin energía")

		_mostrar_mensaje_pantalla(
			"Sin energía... los cables no responden"
		)

		return

	# El forzudo no sabe hacer funcionar los cables: solo puede
	# mover objetos pesados. Los paneles de cables son para
	# personajes más manitas.
	if jugador != null and jugador.es_forzudo:

		print("🦾 El forzudo no puede arreglar los cables")
		_mostrar_mensaje_pantalla("Mmm... no entiendes esos cables")

		return

	call_deferred("_abrir_puzzle")


# EL JUGADOR ACTUAL ES EL FORZUDO

func _es_jugador_forzudo() -> bool:

	if jugador == null:
		return false

	return jugador.es_forzudo


# ¿La sala mostrada está en apagón (cortocircuito)?
func _sala_en_apagon() -> bool:

	var main := get_tree().get_first_node_in_group("main")

	if main == null or not main.has_method(
		"sala_actual_en_apagon"
	):

		return false

	return main.sala_actual_en_apagon()


# Sobrecarga (electricista): el puzzle se abrirá con la
# mitad de los cables ya conectados y correctos.
func sobrecargar() -> void:

	if resuelto or sobrecargado:

		return

	sobrecargado = true

	print("⚡ Panel de cables sobrecargado: cables precargados")




# TEXTO DEL PROMPT
# Si el forzudo se acerca al panel se le informa de que
# no puede usarlo; sin no, se invita a arreglar los cables.

func obtener_texto_prompt() -> String:

	if _es_jugador_forzudo():

		return "Mmm... no entiendes esos cables"

	if resuelto:
		return "Cortar cables"

	return "Arreglar cables"


func _reiniciar_puzzle_cables() -> void:
	resuelto = false
	sobrecargado = false
	if datos_sala != null:
		datos_sala.panel_resuelto = false
		if objeto_datos != null:
			datos_sala.puzzles.erase(objeto_datos)
	_marcar_vecina_resuelta(false)
	_cerrar_puerta_mecanica()
	_mostrar_mensaje_pantalla("Cables cortados: el puzzle se ha reiniciado")
	_abrir_puzzle()


func _mostrar_mensaje_pantalla(texto: String) -> void:

	for hijo in get_children():
		if hijo is Label and hijo.name == "MensajePanel":
			hijo.queue_free()

	var etiqueta := Label.new()
	etiqueta.name = "MensajePanel"
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.position = Vector2(-100, -80)
	etiqueta.size = Vector2(200, 50)
	etiqueta.add_theme_font_size_override("font_size", 12)
	etiqueta.add_theme_color_override("font_color", Color(1.0, 0.75, 0.45))
	etiqueta.z_index = 50
	add_child(etiqueta)

	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.4)
	tween.tween_callback(etiqueta.queue_free)


# ELEGIR SPRITE SEGÚN LA PUERTA DEL MECANISMO
# Vista lateral si bloquea una puerta izquierda o
# derecha; vista frontal si es de arriba o abajo.

func _textura_panel() -> Texture2D:

	if direccion_puerta == "izquierda" \
			or direccion_puerta == "derecha":
		return TEXTURA_LATERAL

	return TEXTURA_FRONTAL


# VIBRACIÓN DEL GOLPE DE SUELO
# Desordena el puzle de cables abierto y, si el panel ya
# estaba resuelto, lo deshace y vuelve a cerrar la puerta
# que abrió (igual que hace el puzzle de láser).

func desordenar_piezas(abrir_interfaz: bool = true) -> void:
	if _puzzle_abierto:
		var puzzle := get_node_or_null("PuzzleCables") as PuzzleCables
		if puzzle != null:
			puzzle.queue_free()
		_puzzle_abierto = false

	if resuelto:
		resuelto = false
		if datos_sala:
			datos_sala.panel_resuelto = false
			if objeto_datos:
				datos_sala.puzzles.erase(objeto_datos)
		_marcar_vecina_resuelta(false)
		_cerrar_puerta_mecanica()
	else:
		# Una habilidad puede haber abierto esta puerta sin
		# resolver el panel: la vibración también debe cerrarla.
		if datos_sala:
			datos_sala.panel_resuelto = false
		_marcar_vecina_resuelta(false)
		_cerrar_puerta_mecanica()

	if abrir_interfaz:
		_abrir_puzzle()

	_mostrar_mensaje_pantalla("Vibración: los cables se han desordenado")


# CERRAR LA PUERTA DEL MECANISMO (vibración)

func _cerrar_puerta_mecanica() -> void:

	if direccion_puerta.is_empty():
		return

	if sala_nodo == null or not is_instance_valid(sala_nodo):

		var padre := get_parent()

		if padre != null:
			sala_nodo = padre.get_parent()

	if sala_nodo == null:
		return

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors == null:
		return

	var nombre_puerta := "Puerta" + direccion_puerta.capitalize()

	var puerta := doors.get_node_or_null(nombre_puerta) as Door

	if puerta:
		puerta.cerrar()


# MARCAR LA PUERTA DE LA SALA VECINA
# La puerta del mecanismo existe en las DOS salas que
# conecta (es la misma puerta física). Al resolverse el
# panel, la puerta de la sala vecina también debe nacer
# abierta; si la vibración lo deshace, cerrada de nuevo.

func _marcar_vecina_resuelta(resuelta: bool) -> void:

	if datos_sala == null or direccion_puerta.is_empty():
		return

	# Índice y dirección de la sala vecina al otro lado
	# de la puerta del mecanismo.
	var vecina_indice: int = -1
	var direccion_vecina: String = ""

	match direccion_puerta:
		"arriba":
			vecina_indice = datos_sala.arriba
			direccion_vecina = "abajo"
		"abajo":
			vecina_indice = datos_sala.abajo
			direccion_vecina = "arriba"
		"izquierda":
			vecina_indice = datos_sala.izquierda
			direccion_vecina = "derecha"
		"derecha":
			vecina_indice = datos_sala.derecha
			direccion_vecina = "izquierda"

	if vecina_indice < 0 or direccion_vecina.is_empty():
		return

	# Acceder al laboratorio para actualizar el RoomData
	# de la sala vecina.
	var main := get_tree().get_first_node_in_group("main")

	if main == null or not "laboratorio" in main:
		return

	var salas = main.laboratorio.salas

	if vecina_indice >= salas.size():
		return

	salas[vecina_indice].panel_resuelto_vecina = resuelta


func _abrir_puzzle() -> void:
	if _puzzle_abierto:
		return

	var puzzle := (
		preload("res://Scripts/UI/PuzzleCables.gd").new()
		as PuzzleCables
	)

	if puzzle == null:
		return

	_puzzle_abierto = true

	puzzle.name = "PuzzleCables"
	puzzle.resuelto.connect(_puzzle_resuelto)
	if puzzle.has_signal("cerrado"):
		puzzle.connect("cerrado", _puzzle_cerrado)

	# Sobrecarga del electricista: cables precargados.
	puzzle.sobrecargado = sobrecargado

	add_child(puzzle)

	puzzle.abrir()


func _puzzle_cerrado() -> void:
	_puzzle_abierto = false
	var puzzle := get_node_or_null("PuzzleCables")
	if puzzle != null:
		puzzle.queue_free()
	var gestor := get_tree().get_first_node_in_group(
		"interaction_manager"
	) as InteractionManager
	if gestor != null and jugador != null:
		gestor.establecer_activo(true)
		gestor.refrescar_para_jugador(jugador)


func cerrar_puzzle_por_turno() -> void:
	_puzzle_abierto = false
	var puzzle := get_node_or_null("PuzzleCables") as PuzzleCables
	if puzzle != null and puzzle.abierto:
		puzzle.cerrar()


func _puzzle_resuelto() -> void:

	_puzzle_abierto = false

	resuelto = true

	# PERSISTIR EL ESTADO DEL MECANISMO
	# La puerta de esta sala y la de la vecina nacen
	# abiertas al reconstruir las salas.
	if datos_sala:
		datos_sala.panel_resuelto = true

	_marcar_vecina_resuelta(true)

	# Registrar en la sala que este puzzle está hecho
	if datos_sala and objeto_datos:
		datos_sala.registrar_puzzle(objeto_datos)

	# Activar el mecanismo: abre la puerta asociada
	_abrir_puerta_mecanica()

	print("🧩 Panel eléctrico resuelto")


# ACTIVAR EL MECANISMO
# Abre la puerta de la sala que estaba cerrada por
# este panel (misma lógica que los terminales).
# Más adelante, aquí se conectarán también máquinas:
# bastaría con buscar el nodo del mecanismo por su
# nombre y llamar a su activación.

func _abrir_puerta_mecanica() -> void:

	if direccion_puerta.is_empty():
		return

	if sala_nodo == null or not is_instance_valid(sala_nodo):

		# Respaldo: obtener la sala desde el árbol
		var padre := get_parent()

		if padre != null:
			sala_nodo = padre.get_parent()

	if sala_nodo == null:
		push_warning("Panel: no se encontró la sala para abrir la puerta.")
		return

	var doors := sala_nodo.get_node_or_null("Doors")

	if doors == null:
		return

	var nombre_puerta := "Puerta" + direccion_puerta.capitalize()

	var puerta := doors.get_node_or_null(nombre_puerta) as Door

	if puerta:

		puerta.abrir()

		print(
			"⚡ Mecanismo activado: ",
			puerta.name,
			" abierta por el panel eléctrico"
		)
	else:
		push_warning(
			"Panel: no se encontró la puerta " + nombre_puerta
		)


func ga_reproducir(efecto: String) -> void:

	var ga: AudioManager = (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto(efecto)


func ga_reproducir_corto(efecto: String) -> void:
	var ga: AudioManager = (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto_corto(efecto, 0.8, -8.0)
