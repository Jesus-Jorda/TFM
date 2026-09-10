extends Resource

class_name RoomData


enum TipoSala {
	INICIO,
	LABORATORIO,
	MAQUINAS,
	DESCANSO,
	ALMACEN,
	CONTROL,
	SALIDA
}


# DATOS GENERALES

@export var tipo : TipoSala = TipoSala.LABORATORIO

@export var ancho : int = 12
@export var alto : int = 8

@export var tam_celda : int = 48
@export var seed : int = 0

# POSICIÓN EN EL MAPA LÓGICO

@export var posicion : Vector2i = Vector2i.ZERO


# CONEXIONES

var arriba : int = -1
var abajo : int = -1
var izquierda : int = -1
var derecha : int = -1

# Lista de salas conectadas
var vecinos : Array[int] = []

# Índice de la sala desde la que fue creada
var padre : int = -1
# PUERTAS

@export var puerta_arriba := false
@export var puerta_abajo := false
@export var puerta_izquierda := false
@export var puerta_derecha := false

# Estado físico persistente de cada puerta compartida.
# La misma clave se escribe en las dos salas conectadas.
var puertas_abiertas: Dictionary = {}

@export var terminal_arriba := false
@export var terminal_abajo := false
@export var terminal_izquierda := false
@export var terminal_derecha := false

# Estado persistente de los terminales de la sala.
# Las claves son las direcciones: "arriba", "abajo",
# "izquierda", "derecha".
#  - terminal_energia: true si ya tiene batería instalada
#    (para que no se apague al reconstruir la sala).
#  - terminal_pregunta_indice: índice fijo en el banco
#    de preguntas (TerminalBanco), para que un terminal
#    nunca cambie de pregunta.
var terminal_energia: Dictionary = {}
var terminal_pregunta_indice: Dictionary = {}
var terminal_resuelto: Dictionary = {}

# Dirección de la puerta cerrada por mecanismo que
# abre el panel eléctrico de esta sala ("" = ninguna).
# Ejemplo: "derecha" → PuertaDerecha empieza cerrada
# y se abre resolviendo el puzle de cables.
@export var panel_puerta : String = ""

# Puerta de esta sala cerrada por el panel eléctrico de
# la sala VECINA (misma puerta física vista desde aquí).
@export var panel_puerta_vecina : String = ""

# Mecanismo resuelto: la puerta del panel está abierta.
var panel_resuelto : bool = false
var panel_resuelto_vecina : bool = false

# Dirección de la puerta cerrada por mecanismo que abre el
# puzzle láser de esta sala ("" = ninguna). Ejemplo: "arriba"
# → PuertaArriba empieza cerrada y se abre alineando el haz.
@export var laser_puerta : String = ""

# Puerta de esta sala cerrada por el puzzle láser de la sala
# VECINA (misma puerta física vista desde aquí).
@export var laser_puerta_vecina : String = ""

# Mecanismo láser resuelto: la puerta del láser está abierta.
var laser_resuelto : bool = false
var laser_resuelto_vecina : bool = false

# Estado persistente del puzzle láser de esta sala.
var laser_forma_indice: int = -1
var laser_orientaciones: Array[int] = []
var laser_emisor_encendido: bool = false
var laser_componentes_activos: bool = true

# Progreso persistente de la plataforma de salida.
var salida_piezas_colocadas: int = 0
var salida_completada: bool = false


# ESTADO

@export var visitada := false
# Distancia desde la sala inicial
var distancia_inicio : int = -1
@export var descubierta := false

# Vibración pendiente de aplicar: el "Golpe de suelo" de
# una sala vecina sacudió el laboratorio. Cuando esta sala
# se construya, sus puzzles aparecen desordenados y la
# cámara tiembla al entrar.
var vibracion_pendiente: bool = false


# CONTENIDO

# Lista de objetos de la sala (ObjectData)
var objetos : Array[ObjectData] = []

# Contadores por tipo de objeto
var num_objetos_interactuables : int = 0
var num_objetos_decoracion : int = 0
var num_objetos_obstaculo : int = 0
var num_objetos_powerup : int = 0

var puzzles : Array = []

var enemigos : Array = []

var obstaculos : Array = []

# Si la sala tiene tele en la esquina (de vez en cuando)
var tiene_tele : bool = false

# Identificador del conducto conectado con otra sala.
# -1 significa que esta sala no tiene conducto.
var conducto_conexion_id: int = -1

# Numeros de terminal por direccion (-1 = sin terminal)
var terminal_arriba_numero : int = -1
var terminal_abajo_numero : int = -1
var terminal_izquierda_numero : int = -1
var terminal_derecha_numero : int = -1

# Cuantos terminales tiene la sala en total
var num_terminales : int = 0


# CONTADOR TOTAL DE OBJETOS

func contar_objetos_total() -> int:
	return (
		num_objetos_interactuables
		+ num_objetos_decoracion
		+ num_objetos_obstaculo
		+ num_objetos_powerup
	)


# REGISTRAR TERMINAL
# Guarda el numero asignado a cada terminal y repone
# el contador de la sala.

func registrar_terminal(direccion: String, numero: int) -> void:

	match direccion:

		"arriba":
			terminal_arriba_numero = numero

		"abajo":
			terminal_abajo_numero = numero

		"izquierda":
			terminal_izquierda_numero = numero

		"derecha":
			terminal_derecha_numero = numero

	num_terminales += 1


# OBTENER NUMERO DE TERMINAL POR DIRECCION

func numero_de_terminal(direccion: String) -> int:

	match direccion:

		"arriba":
			return terminal_arriba_numero

		"abajo":
			return terminal_abajo_numero

		"izquierda":
			return terminal_izquierda_numero

		"derecha":
			return terminal_derecha_numero

	return -1


# REGISTRAR PUZZLE RESUELTO
# Guarda una referencia al objeto del puzzle para que
# la sala sepa que ya está completado.

func registrar_puzzle(puzzle: Variant) -> void:

	if not puzzles.has(puzzle):
		puzzles.append(puzzle)


func tiene_puzzle(puzzle: Variant) -> bool:

	return puzzles.has(puzzle)


# AÑADIR OBJETO

func añadir_objeto(objeto: ObjectData) -> void:

	objetos.append(objeto)

	match objeto.tipo:

		ObjectData.TipoObjeto.INTERACTUABLE:
			num_objetos_interactuables += 1

		ObjectData.TipoObjeto.DECORACION:
			num_objetos_decoracion += 1

		ObjectData.TipoObjeto.OBSTACULO:
			num_objetos_obstaculo += 1

		ObjectData.TipoObjeto.POWERUP:
			num_objetos_powerup += 1


# OBTENER OBJETOS POR TIPO

func obtener_objetos_por_tipo(tipo: ObjectData.TipoObjeto) -> Array[ObjectData]:

	var resultado: Array[ObjectData] = []

	for objeto in objetos:

		if objeto.tipo == tipo:
			resultado.append(objeto)

	return resultado


# OBTENER OBJETO POR NOMBRE

func obtener_objeto_por_nombre(nombre_buscar: String) -> ObjectData:

	for objeto in objetos:

		if objeto.nombre == nombre_buscar:
			return objeto

	return null


# LIMPIAR OBJETOS

func limpiar_objetos() -> void:

	objetos.clear()

	num_objetos_interactuables = 0
	num_objetos_decoracion = 0
	num_objetos_obstaculo = 0
	num_objetos_powerup = 0
