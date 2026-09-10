extends Resource

class_name ObjectData


# TIPOS DE OBJETO

enum TipoObjeto {
	INTERACTUABLE,   # Objetos que el jugador puede recoger/usar
	DECORACION,      # Objetos decorativos (plantas, mesas, etc.)
	OBSTACULO,       # Objetos que bloquean el paso
	POWERUP          # Objetos que dan energía/acciones
}


# DATOS DEL OBJETO

@export var nombre: String = ""
@export var tipo: TipoObjeto = TipoObjeto.DECORACION
@export var textura: Texture2D = null
@export var posicion: Vector2 = Vector2.ZERO
@export var escala: float = 1.0
@export var rotacion: float = 0.0
@export var flip_h: bool = false
@export var flip_v: bool = false

# Para objetos interactuables
@export var interactuable: bool = false
@export var descripcion: String = ""

# Para obstáculos
@export var bloquea_paso: bool = false

# Superficie donde se apoya/cuelga el objeto
@export var superficie: ObjectBase.Superficie = ObjectBase.Superficie.SUELO

# Objetos ya recogidos (no se vuelven a crear al
# reconstruir la sala, pero siguen contando).
var recogido: bool = false

# Si el objeto se recoge o se mueve durante un turno,
# se crea una reposición al comenzar el siguiente.
var necesita_reposicion: bool = false

# Tipo exacto que debe reaparecer cuando se repone un objeto recogido.
var reposicion_nombre: String = ""

# Conexión de teletransporte de los conductos (-1 si no aplica).
var conducto_conexion_id: int = -1


# CONSTRUCTOR RÁPIDO

static func crear(
	p_nombre: String,
	p_tipo: TipoObjeto,
	p_textura: Texture2D,
	p_posicion: Vector2,
	p_escala: float = 1.0,
	p_interactuable: bool = false,
	p_descripcion: String = ""
) -> ObjectData:

	var objeto := ObjectData.new()

	objeto.nombre = p_nombre
	objeto.tipo = p_tipo
	objeto.textura = p_textura
	objeto.posicion = p_posicion
	objeto.escala = p_escala
	objeto.interactuable = p_interactuable
	objeto.descripcion = p_descripcion

	return objeto
