class_name CharacterData
extends Resource


# DATOS DE UN PERSONAJE JUGABLE
# Describe el personaje de forma pura (datos): qué
# escena instanciar, qué retrato mostrar y qué
# habilidades tiene. La interfaz y los botones se
# generan dinámicamente a partir de aquí.

# Identificador único del personaje.
@export var id: String = ""

# Nombre visible en la pantalla de selección.
@export var nombre: String = ""

# Descripción corta del personaje.
@export var descripcion: String = ""

# Escena CharacterBody2D que se instancia como jugador.
@export var escena: PackedScene = null

# Retrato para la pantalla de selección.
@export var retrato: Texture2D = null

# Habilidades del personaje (2 normalmente).
@export var habilidades: Array[HabilidadData] = []


# BÚSQUEDA DE UNA HABILIDAD POR ID

func obtener_habilidad(id_habilidad: String) -> HabilidadData:

	for hab in habilidades:

		if hab.id == id_habilidad:
			return hab

	return null
