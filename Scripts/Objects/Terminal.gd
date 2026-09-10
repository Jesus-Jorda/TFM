@tool
extends InteractableObject

class_name Terminal


# CONFIGURACIÓN

const ESCALA := 0.12

# Radio del área donde el jugador puede interactuar.
# Lo reducimos para evitar que el terminal se active
# estando demasiado cerca de la puerta.
const RADIO_INTERACCION := 11.0

# Radio mayor para los terminales laterales, que están
# pegados a la pared y el jugador los alcanza desde
# una celda hacia dentro.
const RADIO_INTERACCION_LATERAL := 18.0


# POSICIÓN DEL ÁREA DE INTERACCIÓN

# Desplazamiento vertical para los terminales
# de arriba y abajo.
const DESPLAZAMIENTO_INTERACCION_VERTICAL := 26.0


# Desplazamiento horizontal para los terminales
# de izquierda y derecha.
const DESPLAZAMIENTO_INTERACCION_HORIZONTAL := 18.0

# El CollisionShape2D de InteractionArea viene desplazado
# en la escena (y = -34.5). Lo compensamos para que el
# área de los laterales quede centrada en el terminal.
const COMPENSACION_VERTICAL_SHAPE := 34.5

# Píxeles extra que adelantamos el área hacia dentro de
# la sala (hacia la celda por donde camina el jugador).
const ALCANCE_EXTRA_LATERAL := 10.0

# DATOS DEL TERMINAL

@export_multiline var pregunta: String = ""

@export var respuesta: String = ""

# ENERGÍA DEL TERMINAL
# Sin energía el terminal no abre la interfaz:
# muestra "POWER FAILURE / BATTERY REQUIRED" y solo
# admite instalar una batería del inventario.

@export var tiene_energia: bool = false

# Apagón temporal (cortocircuito del robot): mientras
# dure, el terminal se comporta como apagado aunque
# tenga batería instalada. instalar_bateria() lo
# reactiva: es la vía de escape del apagón.
var sin_energia_temporal: bool = false

# Sobrecarga del electricista: cuando se abre esta
# interfaz, parte de la respuesta ya aparece escrita
# (solo si la respuesta es un número).
var sobrecargado: bool = false

# Índice en el banco de preguntas (TerminalBanco).
# Lo asigna TerminalGenerator al crear el terminal.
var pregunta_índice: int = -1

# Referencia a los datos de la sala (RoomData) para
# persistir la energía y el resuelto al reconstruir.
var datos_sala: RoomData = null

# Una vez resuelto el acertijo, queda completado.
var resuelto: bool = false

var terminal_direccion_texto: String = ""
var terminal_room: Node = null

# DIRECCIÓN

enum Direccion {
	ARRIBA,
	ABAJO,
	IZQUIERDA,
	DERECHA
}


@export var direccion: Direccion = Direccion.ARRIBA:
	set(valor):

		direccion = valor

		if is_inside_tree():

			_actualizar_sprite()
			_actualizar_colisiones()


# SPRITES

const TERMINAL_ARRIBA: Texture2D = preload(
	"res://Assets/Objects/Computers/terminal_up.png"
)

const TERMINAL_ABAJO: Texture2D = preload(
	"res://Assets/Objects/Computers/terminal_down.png"
)

const TERMINAL_IZQUIERDA: Texture2D = preload(
	"res://Assets/Objects/Computers/terminal_left.png"
)

const TERMINAL_DERECHA: Texture2D = preload(
	"res://Assets/Objects/Computers/terminal_right.png"
)


# READY

func _ready() -> void:

	super._ready()

	object_id = "terminal"

	# RECUPERAR DATOS DE LA SALA
	# El terminal cuelga de "Terminals" dentro de la sala.
	# (term_room = get_parent().get_parent()).
	var room := get_parent().get_parent() as Node2D

	if room:
		datos_sala = room.get_meta("room_data") as RoomData

	if datos_sala:

		var dir_texto := _direccion_a_texto(direccion)

		# Recuperar la energía guardada al reconstruir
		# la sala (para que no se apague).
		tiene_energia = datos_sala.terminal_energia.get(
			dir_texto,
			tiene_energia
		)

		# Recuperar el índice de pregunta fijo si no se lo
		# pasó el generador (nunca cambia).
		if pregunta_índice < 0:
			pregunta_índice = datos_sala.terminal_pregunta_indice.get(
				dir_texto,
				-1
			)

		# Recuperar si ya estaba resuelto (puerta abierta)
		resuelto = datos_sala.terminal_resuelto.get(dir_texto, resuelto)

		# Si ya estaba resuelto, volver a abrir la puerta
		# asociada (la sala se reconstruyó cerrada).
		if resuelto:
			terminal_direccion_texto = dir_texto
			terminal_room = room
			desbloquear_puerta_asociada()

	_actualizar_sprite()
	_actualizar_colisiones()


# SPRITE

func _actualizar_sprite() -> void:

	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return


	sprite.scale = Vector2.ONE * ESCALA


	match direccion:

		Direccion.ARRIBA:

			sprite.texture = TERMINAL_ARRIBA


		Direccion.ABAJO:

			sprite.texture = TERMINAL_ABAJO


		Direccion.IZQUIERDA:

			sprite.texture = TERMINAL_IZQUIERDA


		Direccion.DERECHA:

			sprite.texture = TERMINAL_DERECHA


	# PANTALLA ENCENDIDA / APAGADA
	# Sin energía el sprite se ve apagado (oscuro).

	if energia_disponible():
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color(0.45, 0.5, 0.6)


# INSTALAR BATERÍA

func instalar_bateria() -> void:

	tiene_energia = true

	# Instalar batería reactiva el terminal aunque la
	# sala siga en apagón (vía de escape del robot).
	sin_energia_temporal = false

	# Guardar la energía en los datos de la sala para que
	# no se apague al reconstruir.
	if datos_sala:
		datos_sala.terminal_energia[_direccion_a_texto(direccion)] = true

	_actualizar_sprite()

	var ga := (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto("encender")

	_mostrar_mensaje(
		"> POWER RESTORED\n> SYSTEM ONLINE"
	)

	print("🔋 Batería instalada en el terminal")


# ENERGÍA EFECTIVA
# Tiene energía instalada Y no está en apagón
# temporal (cortocircuito del robot).

func energia_disponible() -> bool:

	return tiene_energia and not sin_energia_temporal


# Apagón (cortocircuito): pierde la energía a efectos
# de uso y de sprite, sin borrar la batería instalada.
func apagar_por_apagon() -> void:

	sin_energia_temporal = true

	_actualizar_sprite()


# Fin del apagón: recupera la energía que tuviera.
func reactivar_tras_apagon() -> void:

	sin_energia_temporal = false

	_actualizar_sprite()


# Sobrecarga (electricista): al abrir el terminal, parte
# de la respuesta se rellena sola si es numérica.
func sobrecargar() -> void:

	if resuelto or sobrecargado:

		return

	sobrecargado = true

	print("⚡ Terminal sobrecargado: respuesta parcial precargada")


# MOSTRAR MENSAJE FLOTANTE

func _mostrar_mensaje(texto: String) -> void:

	var etiqueta := Label.new()

	etiqueta.text = texto

	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	etiqueta.add_theme_font_size_override("font_size", 11)

	etiqueta.position = Vector2(-90, -110)

	etiqueta.size = Vector2(180, 70)

	etiqueta.z_index = 50

	add_child(etiqueta)

	var tween := create_tween()

	tween.tween_interval(1.4)

	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.5)

	tween.tween_callback(etiqueta.queue_free)


# COLISIONES

func _actualizar_colisiones() -> void:

	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D


	var colision_fisica := get_node_or_null(
		"StaticBody2D/CollisionShape2D"
	) as CollisionShape2D


	var colision_interaccion := get_node_or_null(
		"InteractionArea/CollisionShape2D"
	) as CollisionShape2D


	var interaction_node := get_node_or_null(
		"InteractionArea"
	) as Area2D


	if sprite == null:
		return


	if sprite.texture == null:
		return


	# COLISIÓN FÍSICA

	if colision_fisica:

		var forma_fisica := (
			colision_fisica.shape
			as RectangleShape2D
		)


		if forma_fisica:

			var tamano_texture := (
				sprite.texture.get_size()
			)


			var tamano_real := (
				tamano_texture * ESCALA
			)


			# La hacemos más pequeña que el sprite
			# para evitar bloquear demasiado.
			tamano_real *= 0.35


			forma_fisica.size = tamano_real


			# POSICIÓN COLISIÓN FÍSICA

			match direccion:

				Direccion.IZQUIERDA:

					colision_fisica.position = Vector2(
						0,
						15
					)


				Direccion.DERECHA:

					colision_fisica.position = Vector2(
						0,
						15
					)


				_:

					colision_fisica.position = Vector2.ZERO


	# ÁREA DE INTERACCIÓN

	if colision_interaccion:

		var forma_interaccion := (
			colision_interaccion.shape
			as CircleShape2D
		)


		if forma_interaccion == null:

			forma_interaccion = CircleShape2D.new()

			colision_interaccion.shape = (
				forma_interaccion
			)


		# Los laterales usan un radio mayor.
		var es_lateral := (
			direccion == Direccion.IZQUIERDA
			or direccion == Direccion.DERECHA
		)

		forma_interaccion.radius = (
			RADIO_INTERACCION_LATERAL
			if es_lateral
			else RADIO_INTERACCION
		)


	# POSICIÓN DEL ÁREA DE INTERACCIÓN

	if interaction_node:

		match direccion:


			# TERMINAL DE ARRIBA

			Direccion.ARRIBA:

				# Lo bajamos dentro de la sala.
				interaction_node.position = Vector2(
					0,
					DESPLAZAMIENTO_INTERACCION_VERTICAL + 15
				)


			# TERMINAL DE ABAJO

			Direccion.ABAJO:

				# También lo bajamos respecto
				# a su posición anterior.
				interaction_node.position = Vector2(
					0,
					-DESPLAZAMIENTO_INTERACCION_VERTICAL + 40
				)


			# TERMINAL IZQUIERDA

			Direccion.IZQUIERDA:

				interaction_node.position = Vector2(
					DESPLAZAMIENTO_INTERACCION_HORIZONTAL + ALCANCE_EXTRA_LATERAL,
					COMPENSACION_VERTICAL_SHAPE
				)


			# TERMINAL DERECHA

			Direccion.DERECHA:

				interaction_node.position = Vector2(
					-(DESPLAZAMIENTO_INTERACCION_HORIZONTAL + ALCANCE_EXTRA_LATERAL),
					COMPENSACION_VERTICAL_SHAPE
				)


# INTERACTUAR

func interactuar() -> void:

	if not jugador_cerca:
		return


	# SIN ENERGÍA: PASAR A OFFLINE
	# Si el jugador lleva una batería en el inventario,
	# la instala. Si no, avisamos de que falta.

	if not energia_disponible():

		var inv := (
			get_tree().get_first_node_in_group(
				"inventory_manager"
			) as InventoryManager
		)

		if inv and inv.tiene_item("Bateria"):

			inv.quitar_item("Bateria")

			instalar_bateria()

		else:

			var ga := (
				get_tree().get_first_node_in_group("gestor_audio")
				as AudioManager
			)

			if ga:
				ga.reproducir_efecto("apagar")

			_mostrar_mensaje(
				"> TERMINAL OFFLINE\n> POWER FAILURE\n> BATTERY REQUIRED"
			)

			print("🔴 Terminal sin energía: hace falta una batería")

		return


	# YA RESUELTO

	if resuelto:

		_mostrar_mensaje("> TERMINAL COMPLETADO")

		return


	print(
		"🖥️ HAS INTERACTUADO CON EL TERMINAL"
	)

	var pregunta_terminal: String = ""
	var respuesta_terminal: String = ""

	if pregunta_índice >= 0 \
			and pregunta_índice < TerminalBanco.bateria_terminal.size():

		var item: Dictionary = TerminalBanco.bateria_terminal[pregunta_índice]
		pregunta_terminal = item["pregunta"]
		respuesta_terminal = item["respuesta"]

	else:
		# Respaldo si no se asignó índice.
		pregunta_terminal = pregunta.strip_edges()
		respuesta_terminal = respuesta.strip_edges()

	if pregunta_terminal.is_empty() or respuesta_terminal.is_empty():
		push_warning(
			"Terminal sin pregunta/respuesta. Usando pregunta de ejemplo."
		)
		pregunta_terminal = (
			"Este terminal necesita electricidad para funcionar. ¿Qué objeto podrías utilizar para alimentarlo?"
		)
		respuesta_terminal = "bateria"


	# BUSCAR TERMINAL INTERFACE

	var terminal_interface: Node = (
		get_tree().get_first_node_in_group(
			"terminal_interface"
		) as Node
	)


	if terminal_interface == null:

		push_warning(
			"No se encontró TerminalInterface en la escena."
		)

		return

	# CONFIGURAR EL PROPIO TERMINAL

	terminal_direccion_texto = _direccion_a_texto(direccion)
	terminal_room = get_parent().get_parent()

	# CONFIGURAR LA INTERFAZ

	if terminal_interface.has_method("configurar_terminal"):
		terminal_interface.call(
			"configurar_terminal",
			self,
			terminal_direccion_texto,
			terminal_room
		)


	# ABRIR INTERFAZ

	# Sobrecarga del electricista: si la respuesta es un
	# número, parte de él ya aparece escrito.
	var texto_previo := ""

	if sobrecargado:

		texto_previo = _respuesta_parcial(respuesta_terminal)

	if terminal_interface.has_method("abrir_terminal"):
		terminal_interface.call(
			"abrir_terminal",
			pregunta_terminal,
			respuesta_terminal,
			texto_previo
		)


# Mitad de la respuesta escrita (solo si es un número).
func _respuesta_parcial(texto_respuesta: String) -> String:

	var texto := texto_respuesta.strip_edges()

	if texto.is_empty() or not texto.is_valid_int():

		return ""

	var cifras: int = int(ceil(texto.length() / 2.0))

	return texto.substr(0, cifras)


# CONFIGURAR TERMINAL

func configurar_terminal(
	direccion_texto: String,
	room: Node
) -> void:

	terminal_direccion_texto = direccion_texto
	terminal_room = room


# DESBLOQUEAR PUERTA ASOCIADA

func desbloquear_puerta_asociada() -> void:

	# PERSISTIR RESUELTO
	# Marcar resuelto en la sala para que, al reconstruir,
	# el terminal sepa que la puerta ya está abierta.
	if datos_sala:
		datos_sala.terminal_resuelto[_direccion_a_texto(direccion)] = true

	# OBTENER LA SALA

	var room: Node = terminal_room

	if room == null or not is_instance_valid(room):

		# Intentar obtener la sala desde el árbol de nodos
		var parent := get_parent()

		if parent != null:

			room = parent.get_parent()

	if room == null:
		push_warning("No se pudo abrir la puerta: no se encontró la sala.")
		return

	# BUSCAR NODO DE PUERTAS

	var doors := room.get_node_or_null("Doors")
	if doors == null:
		push_warning("No se pudo abrir la puerta: no existe el nodo Doors en la sala.")
		return

	# BUSCAR PUERTA POR DIRECCIÓN

	var puerta: Door = null

	if not terminal_direccion_texto.is_empty():

		var nombre_puerta := "Puerta" + terminal_direccion_texto.capitalize()
		puerta = doors.get_node_or_null(nombre_puerta) as Door

	# FALLBACK: PUERTA MÁS CERCANA

	if puerta == null:

		var puerta_mas_cercana: Door = null
		var distancia_mas_corta := INF

		for hijo in doors.get_children():
			if hijo is Door:
				var puerta_candidata := hijo as Door
				var distancia := global_position.distance_to(puerta_candidata.global_position)

				if distancia < distancia_mas_corta:
					distancia_mas_corta = distancia
					puerta_mas_cercana = puerta_candidata

		puerta = puerta_mas_cercana

	# ABRIR PUERTA

	if puerta:

		resuelto = true

		puerta.abrir()
		print(
			"🔓 Puerta abierta: ",
			puerta.name,
			" -> Sala ",
			puerta.sala_destino
		)
		return

	push_warning("No se encontró ninguna puerta para abrir en la sala.")


# DIRECCIÓN A TEXTO

func _direccion_a_texto(valor: Direccion) -> String:

	match valor:
		Direccion.ARRIBA:
			return "arriba"
		Direccion.ABAJO:
			return "abajo"
		Direccion.IZQUIERDA:
			return "izquierda"
		Direccion.DERECHA:
			return "derecha"

	return ""


# DIRECCIÓN A TEXTO (ESTÁTICO)
# Usado por TerminalGenerator para guardar el estado
# por dirección en RoomData.

static func direccion_a_texto(valor: Direccion) -> String:

	match valor:
		Direccion.ARRIBA:
			return "arriba"
		Direccion.ABAJO:
			return "abajo"
		Direccion.IZQUIERDA:
			return "izquierda"
		Direccion.DERECHA:
			return "derecha"

	return ""
