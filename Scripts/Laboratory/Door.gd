extends Area2D

class_name Door


# DATOS

var direccion: String = ""
var sala_destino: int = -1
var textura_abierta: Texture2D = null
var textura_cerrada: Texture2D = null

var blocker_body: StaticBody2D = null
var blocker_shape: CollisionShape2D = null


# ESTADO

# Indica si la puerta está cerrada.
# Si está cerrada, el jugador no puede atravesarla.
var cerrada: bool = false

# Indica si la puerta está bloqueada por algún sistema.
# Más adelante podremos usarlo para sabotajes, fusibles, etc.
var bloqueada: bool = false


# READY

func _ready() -> void:

	monitoring = true
	monitorable = true

	# Detectar al jugador
	collision_layer = 0
	collision_mask = 1

	_actualizar_estado_fisico()


# COMPROBAR SI SE PUEDE ATRAVESAR

func puede_pasar() -> bool:

	if bloqueada:
		return false

	if cerrada:
		return false

	if sala_destino == -1:
		return false

	return true


# INTERACCIÓN

func interactuar() -> int:

	if not puede_pasar():
		return -1

	return sala_destino


# ABRIR PUERTA

func abrir() -> void:

	cerrada = false
	_sincronizar_estado(true)
	_actualizar_estado_fisico()
	_actualizar_sprite()


# CERRAR

func cerrar() -> void:

	cerrada = true
	_sincronizar_estado(false)
	_actualizar_estado_fisico()
	_actualizar_sprite()


func _sincronizar_estado(abierta: bool) -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not "laboratorio" in main:
		return

	var indice: int = int(main.sala_actual)
	if indice < 0 or indice >= main.laboratorio.salas.size():
		return

	var sala: RoomData = main.laboratorio.salas[indice]
	sala.puertas_abiertas[direccion] = abierta

	if sala_destino < 0 or sala_destino >= main.laboratorio.salas.size():
		return

	var opuesta: String = {
		"arriba": "abajo",
		"abajo": "arriba",
		"izquierda": "derecha",
		"derecha": "izquierda"
	}.get(direccion, "")
	if opuesta != "":
		main.laboratorio.salas[sala_destino].puertas_abiertas[opuesta] = abierta


# ACTUALIZAR SPRITE

func _actualizar_sprite() -> void:

	var sprite := get_node_or_null("Sprite") as Sprite2D

	if sprite == null:
		return

	if cerrada and textura_cerrada:
		sprite.texture = textura_cerrada
	elif textura_abierta:
		sprite.texture = textura_abierta


# ACTUALIZAR ESTADO FÍSICO

func _actualizar_estado_fisico() -> void:

	if blocker_body:
		blocker_body.collision_layer = 1
		blocker_body.collision_mask = 0

	if blocker_shape:
		blocker_shape.disabled = not cerrada
