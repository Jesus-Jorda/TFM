extends Node

class_name InteractionManager


# JUGADOR

var jugador: Character = null


# OBJETO ACTUAL

var objeto_actual: InteractableObject = null


# OBJETOS CERCANOS (para reevaluar cada frame)
# Lista de objetos que han entrado en el área de interacción.
# Se usa para recalcular el más cercano cada vez que entra o
# sale un objeto, lo que resuelve casos donde hay áreas
# solapadas: si el objeto activo sale del área, el siguiente
# más cercano de la lista pasa a ser el nuevo activo.

var objetos_cercanos: Array[InteractableObject] = []


# UI

var prompt: Button = null


# ESTADO

var interacciones_activas: bool = true


# SALA ACTUAL

# Nodo de la sala mostrada. Lo usa el inventario para
# soltar objetos en el suelo de la sala correcta.
var sala_actual: Node2D = null


# READY

func _ready() -> void:

	add_to_group("interaction_manager")

	if prompt:
		prompt.visible = false


# ASIGNAR JUGADOR

func asignar_jugador(
	nuevo_jugador: Character
) -> void:

	jugador = nuevo_jugador


# ASIGNAR PROMPT

func asignar_prompt(
	nuevo_prompt: Button
) -> void:

	prompt = nuevo_prompt

	if prompt:
		prompt.visible = false

		# El prompt ahora es un botón: al pulsarlo
		# se interactúa con el objeto actual.
		if not prompt.pressed.is_connected(_pulsado_interactuar):
			prompt.pressed.connect(_pulsado_interactuar)


# ACTIVAR / DESACTIVAR INTERACCIONES

func establecer_activo(activo: bool) -> void:
	interacciones_activas = activo

	if not activo:
		objeto_actual = null
		objetos_cercanos.clear()
		ocultar_prompt()


func refrescar_para_jugador(nuevo_jugador: Character) -> void:
	# Desvincular al jugador anterior de todos los objetos para
	# que un prompt no sobreviva al cambio de turno.
	if sala_actual != null:
		var objetos_sala := sala_actual.get_node_or_null("Objects")
		if objetos_sala != null:
			for nodo in objetos_sala.find_children("*", "Node", true, false):
				if nodo is InteractableObject:
					var interactuable := nodo as InteractableObject
					if interactuable.jugador != null:
						interactuable._jugador_sale(interactuable.jugador)

	jugador = nuevo_jugador
	objetos_cercanos.clear()
	objeto_actual = null
	ocultar_prompt()

	if not interacciones_activas or jugador == null:
		return

	var sala := sala_actual
	if sala == null:
		return

	var objetos := sala.get_node_or_null("Objects")
	if objetos == null:
		return

	for nodo in objetos.find_children("*", "Node", true, false):
		if not nodo is InteractableObject:
			continue
		var area := nodo.get_node_or_null("InteractionArea") as Area2D
		if area != null and area.get_overlapping_bodies().has(jugador):
			nodo._jugador_entra(jugador)
			registrar_objeto(nodo as InteractableObject)


# REGISTRAR OBJETO

func registrar_objeto(
	objeto: InteractableObject
) -> void:

	if not interacciones_activas:
		return

	if objeto == null:
		return
	if jugador != null and objeto.has_method("puede_interactuar_con_jugador") \
			and not objeto.puede_interactuar_con_jugador(jugador):
		return

	if not objetos_cercanos.has(objeto):
		objetos_cercanos.append(objeto)

	_actualizar_objeto_actual()


# QUITAR OBJETO

func quitar_objeto(
	objeto: InteractableObject
) -> void:

	if not interacciones_activas:
		return

	objetos_cercanos.erase(objeto)

	if objeto_actual == objeto:
		objeto_actual = null

	_actualizar_objeto_actual()


# RECALCULAR EL OBJETO MÁS CERCANO
# Recorre objetos_cercanos y elige el más próximo al
# jugador como objeto_actual. Se llama cada vez que un
# objeto entra o sale de su área de interacción, así que
# si el activo se va, el vecino más cercano toma el relevo
# sin esperar a un nuevo body_entered.

func _actualizar_objeto_actual() -> void:
	for objeto in objetos_cercanos.duplicate():
		if objeto == null or not is_instance_valid(objeto) \
				or not objeto.jugador_cerca \
				or objeto.jugador != jugador \
				or not objeto.puede_interactuar_con_jugador(jugador):
			objetos_cercanos.erase(objeto)

	if objetos_cercanos.is_empty():
		objeto_actual = null
		ocultar_prompt()
		return

	if jugador == null:
		objeto_actual = objetos_cercanos[0]
		mostrar_prompt(objeto_actual.obtener_texto_prompt())
		return

	var mas_cercano: InteractableObject = objetos_cercanos[0]

	var distancia_min := jugador.global_position.distance_to(
		mas_cercano.global_position
	)

	for o in objetos_cercanos:

		var d := jugador.global_position.distance_to(o.global_position)

		if d < distancia_min:

			distancia_min = d

			mas_cercano = o

	objeto_actual = mas_cercano

	mostrar_prompt(objeto_actual.obtener_texto_prompt())


# MOSTRAR PROMPT

func mostrar_prompt(texto: String = "") -> void:

	if prompt == null:
		return

	if texto.is_empty():
		texto = "[ E ]  INTERACTUAR"

	prompt.text = texto

	prompt.visible = true


# REFRESCAR PROMPT
# Vuelve a pedir el texto del objeto actual por si su
# contexto ha cambiado (p. ej. al coger o instalar una
# batería).

func refrescar_prompt() -> void:

	if objeto_actual == null:
		return

	mostrar_prompt(objeto_actual.obtener_texto_prompt())


# OCULTAR PROMPT

func ocultar_prompt() -> void:

	if prompt == null:
		return

	prompt.visible = false


# PROCESS

func _process(
	_delta: float
) -> void:

	if not interacciones_activas:
		return

	if jugador == null:
		return

	if objeto_actual == null:
		return


	# INTERACTUAR

	if Input.is_action_just_pressed("interactuar"):

		objeto_actual.interactuar()


# BOTÓN INTERACTUAR PULSADO

func _pulsado_interactuar() -> void:

	if not interacciones_activas:
		return

	if objeto_actual == null:
		return

	objeto_actual.interactuar()
