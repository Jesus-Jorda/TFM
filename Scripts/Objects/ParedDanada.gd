extends InteractableObject

class_name ParedDanada


# PARED DAÑADA INTERACTIVA
# Una pieza de pared dañada que se puede "romper". Es
# como las piezas dañadas que ya creaba WallGenerator
# (mismo sprite, color y colisión) pero además lleva una
# zona de interacción para que el botón de interactuar
# muestre "ROMPER".
# Los valores de cada pieza (textura, escala, colisión,
# volteo) los asigna WallGenerator antes de añadirla a la
# sala, igual que hacía con los sprites sueltos.

# Radio del área de interacción (el jugador se acerca a
# la pared y aparece el botón).
const RADIO_INTERACCION := 42.0

# Misma altura de dibujo que las piezas dañadas de
# WallGenerator: por encima de las paredes normales.
const Z_PARED_ESPECIAL := 1

# Color marrón/grieta de las piezas dañadas.
const COLOR_DANADA := Color(0.9, 0.82, 0.76, 1.0)


# CONFIGURACIÓN DE LA PIEZA (la asigna WallGenerator)

var textura: Texture2D = null

var escala: float = 1.0

# La pared superior usa una escala X un poco mayor para
# que la grieta no deje hueco entre piezas (igual que las
# dañadas normales superiores).
var escala_x_extra: bool = false

# Volteo horizontal (pared derecha / izquierda).
var invertir_horizontal: bool = false

# Tamaño de la colisión de la pared (la misma que ponía
# WallGenerator a cada pieza dañada).
var tamano_colision: Vector2 = Vector2(48.0, 12.0)


# READY

func _ready() -> void:

	# SPRITE

	if get_node_or_null("Sprite2D") == null:

		var sprite := Sprite2D.new()

		sprite.name = "Sprite2D"

		sprite.texture = textura

		if escala_x_extra:
			sprite.scale = Vector2(escala + 0.04, escala)
		else:
			sprite.scale = Vector2.ONE * escala

		sprite.flip_h = invertir_horizontal

		sprite.modulate = COLOR_DANADA

		# Por encima de las paredes normales (z_index 0)
		# para que la grieta siempre se vea.
		sprite.z_index = Z_PARED_ESPECIAL

		add_child(sprite)

	# COLISIÓN DE LA PARED (sólida)

	var cuerpo := StaticBody2D.new()

	cuerpo.name = "WallCollision"

	add_child(cuerpo)

	var collision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	forma.size = tamano_colision

	collision.shape = forma

	cuerpo.add_child(collision)

	# ÁREA DE INTERACCIÓN

	if interaction_area == null:

		var area := Area2D.new()

		area.name = "InteractionArea"

		var colision_area := CollisionShape2D.new()

		var forma_area := CircleShape2D.new()

		forma_area.radius = RADIO_INTERACCION

		colision_area.shape = forma_area

		area.add_child(colision_area)

		add_child(area)

		interaction_area = area

	add_to_group("pared_danada")

	super._ready()

	object_id = "pared_danada"


# TEXTO DEL PROMPT
# El botón de interactuar muestra "ROMPER" cuando el
# jugador se acerca a la pared dañada.

func obtener_texto_prompt() -> String:

	return "ROMPER"


func puede_interactuar_con_jugador(personaje: Character) -> bool:
	return personaje != null and personaje.es_forzudo


# INTERACTUAR
# De momento solo avisa y suena: la mecánica que
# convierte la dañada en rota (recuperando los valores
# guardados en la referencia de WallGenerator) se añadirá
# en el siguiente paso.

func interactuar() -> void:

	if not jugador_cerca or jugador == null or not jugador.es_forzudo:
		return

	var ga := (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto("romper")

	print("🔧 Pared dañada: lista para romper (mecánica pendiente)")
