extends InteractableObject

class_name Bateria


# CONFIGURACIÓN

const RADIO_INTERACCION := 30.0

# La textura original es enorme (482x549), con esta
# escala se ve de unos ~43x49 px en pantalla.
const ESCALA_VISUAL := 0.09

const TEXTURA_BATERIA: Texture2D = preload(
	"res://Assets/Objects/Power/bateriaport.png"
)

# Para el resto de objetos de Power la escala se calcula
# sola para que ocupen aprox. esto por su lado mayor.
const TAMANO_OBJETIVO := 46.0

# Nombre que se muestra en el inventario según la clave
# de datos (ObjectData.nombre). La pila pequeña entra
# como otra "Bateria": también alimenta terminales.
const NOMBRES_VISUALES := {
	"barritavege": "Barrita",
	"bateriav": "Bateria",
	"cafe": "Cafe",
	"caramelos": "Caramelos",
	"cinta": "Cinta",
	"fusible": "Fusible"
}

# "consumible" se gasta al usarlo;
# "clave" permanece hasta usarse en su sitio.
const TIPOS_ITEM := {
	"barritavege": "consumible",
	"bateriav": "consumible",
	"cafe": "consumible",
	"caramelos": "consumible",
	"cinta": "clave",
	"fusible": "clave"
}


# DATOS DEL OBJETO EN LA SALA
# Se asigna desde el ObjectGenerator para poder marcar
# la batería como recogida y que no reaparezca.

var objeto_datos: ObjectData = null


# READY

func _ready() -> void:

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

	# SPRITE

	var textura := TEXTURA_BATERIA

	var escala := ESCALA_VISUAL

	if objeto_datos and objeto_datos.textura != null \
			and objeto_datos.nombre != "bateria":

		textura = objeto_datos.textura

		var lado_mayor: float = max(
			textura.get_width(),
			textura.get_height()
		)

		if lado_mayor > 0.0:
			escala = clampf(
				TAMANO_OBJETIVO / lado_mayor,
				0.04,
				0.5
			)

	if get_node_or_null("Sprite2D") == null:

		var sprite := Sprite2D.new()

		sprite.name = "Sprite2D"

		sprite.texture = textura

		sprite.scale = Vector2.ONE * escala

		add_child(sprite)

	super._ready()

	object_id = (
		objeto_datos.nombre if objeto_datos else "bateria"
	)


# INTERACTUAR (RECOGER BATERÍA)
# Al recogerla se suma al inventario del InteractionManager.

func interactuar() -> void:

	if not jugador_cerca:
		return

	var inv := (
		get_tree().get_first_node_in_group(
			"inventory_manager"
		) as InventoryManager
	)

	if inv == null:
		return

	var nombre_data := (
		objeto_datos.nombre if objeto_datos else "bateria"
	)

	var nombre_mostrar: String = NOMBRES_VISUALES.get(
		nombre_data, "Bateria"
	)

	var tipo_item: String = TIPOS_ITEM.get(
		nombre_data, "consumible"
	)

	var textura := TEXTURA_BATERIA

	if nombre_data != "bateria" and objeto_datos \
			and objeto_datos.textura != null:
		textura = objeto_datos.textura

	# Sin apilado: con las 3 ranuras llenas no cabe nada
	if not inv.añadir_item(
		nombre_mostrar, textura, tipo_item
	):
		print("🎒 Inventario lleno: no cabe ", nombre_mostrar)
		return

	# Marcar el objeto como recogido para que la sala
	# sepa que ya no está disponible.
	if objeto_datos:
		objeto_datos.recogido = true
		objeto_datos.necesita_reposicion = true
		objeto_datos.reposicion_nombre = nombre_data

	var ga := (
		get_tree().get_first_node_in_group("gestor_audio")
		as AudioManager
	)

	if ga:
		ga.reproducir_efecto_corto("recoger", 0.7, -4.0)

	print("🎒 Recogido: ", nombre_mostrar)

	queue_free()
