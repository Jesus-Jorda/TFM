extends Node

class_name ObjectGenerator


# CONFIGURACIN

const MIN_OBJETOS := 3
const MAX_OBJETOS := 6

const MIN_PARED := 2
const MAX_PARED := 3

# Separacin mnima entre el puzzle lser y los objetos de suelo.
# Se reserva un rea de forma ms equilibrada (diamante), para que el
# centro quede limpio sin vaciar la sala ni generar objetos demasiado
# pegados al mecanismo del puzzle.
const DISTANCIA_PUZZLE_LASER_CELDAS := 2

# Fraccin de tam_celda para la altura de los objetos colgados de la pared superior (subidos para no tocar
# el suelo).
const ALTURA_PARED := 0.35

# Factor para que la colisin sea algo ms pequea que el sprite visible.
const COLISION_FACTOR := 0.7

# La tele solo aparece de vez en cuando en las salas
const PROB_TELE := 0.35

# Las cmaras solo aparecen de vez en cuando
const PROB_CAMARAS := 0.4
const ESCALA_CONDUCTO := 0.24

# Escena de la tele decorativa
static var tele_scene = preload(
	"res://Scenes/Objects/Decorative/Tele.tscn"
)

static var salida_scene = preload(
	"res://Scenes/Objects/Interactable/Salida.tscn"
)

# Las bateras dan energa a los terminales apagados
const PROB_BATERIA := 0.6

# Escala visual de la batera sobre el suelo
# (la textura original mide 482x549 px)
const ESCALA_BATERIA := 0.09

# El panel elctrico abre el puzle de cables
const PROB_PANEL := 0.45

const ESCALA_PANEL := 0.12

static var textura_panel_cables: Texture2D = preload(
	"res://Assets/Objects/Computers/panelelesup.png"
)

# Textura de la batera porttil
static var textura_bateria: Texture2D = preload(
	"res://Assets/Objects/Power/bateriaport.png"
)

static var textura_caja_metal: Texture2D = preload(
	"res://Assets/Objects/Power/cajametal.png"
)

static var textura_conducto: Texture2D = preload(
	"res://Assets/Objects/Power/conductoventilacion.png"
)

# OBJETOS RECOGIBLES DE POWER (VAN AL INVENTARIO)


const MAX_POWER_SALA := 3
const MIN_CONSUMIBLES_SALA := 3
const MAX_CONSUMIBLES_SALA := 6
const MIN_OBJETOS_TOTALES_SALA := 6

static var catalogo_power := [
	{
		"nombre": "barritavege",
		"textura": preload(
			"res://Assets/Objects/Power/barritavege.png"
		),
		"descripcion": "Barrita vegetal"
	},
	{
		"nombre": "cafe",
		"textura": preload(
			"res://Assets/Objects/Power/cafe.png"
		),
		"descripcion": "Cafe"
	},
	{
		"nombre": "caramelos",
		"textura": preload(
			"res://Assets/Objects/Power/caramelos.png"
		),
		"descripcion": "Caramelos"
	},
	{
		"nombre": "cinta",
		"textura": preload(
			"res://Assets/Objects/Power/cinta.png"
		),
		"descripcion": "Cinta aislante"
	},
	{
		"nombre": "fusible",
		"textura": preload(
			"res://Assets/Objects/Power/fusible.png"
		),
		"descripcion": "Fusible"
	}
]


# CATLOGO DE OBJETOS DE SUELO


static var catalogo_suelo := [

	{
		"nombre": "barril",
		"escala": 0.22,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/barril.png")
	},
	{
		"nombre": "barril2",
		"escala": 0.31,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/barril2.png")
	},
	{
		"nombre": "cajacarton",
		"escala": 0.28,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/cajacarton.png")
	},
	{
		"nombre": "cerebro",
		"escala": 0.35,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/cerebro.png")
	},
	{
		"nombre": "cono",
		"escala": 0.36,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/cono.png")
	},
	{
		"nombre": "magua",
		"escala": 0.42,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/magua.png")
	},
	{
		"nombre": "mesa",
		"escala": 0.34,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/mesa.png")
	},
	{
		"nombre": "escritorio",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/escritorio.png")
	},
	{
		"nombre": "microscopio",
		"escala": 0.24,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/microscopio.png")
	},
	{
		"nombre": "mesalaboratorio",
		"escala": 0.32,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/mesalaboratorio.png")
	},
	{
		"nombre": "taquilla",
		"escala": 0.28,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/taquilla.png")
	},
	{
		"nombre": "armariopeq",
		"escala": 0.28,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/armariopeq.png")
	},
	{
		"nombre": "carritocaja",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/carritocaja.png")
	},
	{
		"nombre": "maquina2",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/maquina2.png")
	},
	{
		"nombre": "silla",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/silla.png")
	},
	{
		"nombre": "estanteria",
		"escala": 0.28,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/estanteria.png")
	},
	{
		"nombre": "maquina",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/maquina.png")
	},
	{
		"nombre": "papelera",
		"escala": 0.29,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/papelera.png")
	},
	{
		"nombre": "servidor",
		"escala": 0.27,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/servidor.png")
	},
	{
		"nombre": "planta",
		"escala": 0.30,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Plants/planta.png")
	},
	{
		"nombre": "planta2",
		"escala": 0.26,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Plants/planta2.png")
	}
]

static func _catalogo_suelo_por_tipo(tipo_sala: RoomData.TipoSala) -> Array:
	match tipo_sala:
		RoomData.TipoSala.INICIO:
			return _catalogo_por_nombres(["cajacarton", "escritorio", "silla", "mesa"])
		RoomData.TipoSala.LABORATORIO:
			return _catalogo_por_nombres(["mesalaboratorio", "microscopio", "maquina", "silla", "mesa"])
		RoomData.TipoSala.MAQUINAS:
			return _catalogo_por_nombres(["maquina", "maquina2", "carritocaja", "armariopeq"])
		RoomData.TipoSala.DESCANSO:
			return _catalogo_por_nombres(["silla", "escritorio", "mesa", "papelera"])
		RoomData.TipoSala.ALMACEN:
			return _catalogo_por_nombres(["taquilla", "armariopeq", "estanteria", "carritocaja", "cajacarton"])
		RoomData.TipoSala.CONTROL:
			return _catalogo_por_nombres(["escritorio", "silla", "servidor", "maquina2", "papelera"])
		RoomData.TipoSala.SALIDA:
			return _catalogo_por_nombres(["mesa", "silla", "escritorio", "cajacarton", "servidor"])
		_:
			return catalogo_suelo

	return catalogo_suelo


static func _catalogo_por_nombres(nombres: Array[String]) -> Array:
	var resultado: Array = []
	for nombre in nombres:
		for definicion in catalogo_suelo:
			if definicion["nombre"] == nombre:
				resultado.append(definicion)
				break
	return resultado


# CATLOGO DE OBJETOS DE PARED
# Objetos que cuelgan de las paredes.

static var catalogo_pared := [

	{
		"nombre": "corcho",
		"escala": 0.18,
		"superficie": ObjectBase.Superficie.PARED_ARRIBA,
		"textura": preload("res://Assets/Objects/Decoration/Wall/corcho.png")
	},
	{
		"nombre": "cuadro",
		"escala": 0.20,
		"superficie": ObjectBase.Superficie.PARED_ARRIBA,
		"textura": preload("res://Assets/Objects/Decoration/Wall/cuadro.png")
	},
	{
		"nombre": "posterwarning",
		"escala": 0.22,
		"superficie": ObjectBase.Superficie.PARED_ARRIBA,
		"textura": preload("res://Assets/Objects/Decoration/Wall/posterwarning.png")
	},
	{
		"nombre": "rejilla",
		"escala": 0.15,
		"superficie": ObjectBase.Superficie.PARED_ARRIBA,
		"textura": preload("res://Assets/Objects/Decoration/Wall/rejilla.png")
	}
]


# CATLOGO DE CMARAS DE SEGURIDAD
# Cmaras pegadas a las paredes superior e inferior,
# giradas para apuntar al pasillo. Sin colisin.

static var catalogo_camaras := [

	{
		"nombre": "camara_arriba",
		"escala": 0.25,
		"superficie": ObjectBase.Superficie.PARED_ARRIBA,
		"altura": 0.5,
		"rotacion": deg_to_rad(270.0),
		"flip_aleatorio": false,
		"textura": preload("res://Assets/Objects/Decoration/camera/camarader.png")
	},
	{
		"nombre": "camara_abajo",
		"escala": 0.25,
		"superficie": ObjectBase.Superficie.PARED_ABAJO,
		"altura": 0.8,
		"rotacion": deg_to_rad(270.0),
		"flip_aleatorio": false,
		"textura": preload("res://Assets/Objects/Decoration/camera/camaraizq.png")
	},
	{
		"nombre": "camara_izquierda",
		"escala": 0.25,
		"superficie": ObjectBase.Superficie.PARED_IZQUIERDA,
		"altura": 0.8,
		"rotacion": deg_to_rad(0.0),
		"flip_aleatorio": false,
		"textura": preload("res://Assets/Objects/Decoration/camera/camaraizq.png")
	},
	{
		"nombre": "camara_derecha",
		"escala": 0.25,
		"superficie": ObjectBase.Superficie.PARED_DERECHA,
		"altura": 0.8,
		"rotacion": deg_to_rad(0.0),
		"flip_aleatorio": false,
		"textura": preload("res://Assets/Objects/Decoration/camera/camarader.png")
	}
]


# CATLOGO DE ESCOMBROS


static var catalogo_escombros := [

	{
		"nombre": "escombropiedra",
		"escala": 0.40,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Decoration/Floor/escombropiedra.png")
	},
	{
		"nombre": "escombroarmario",
		"escala": 0.40,
		"superficie": ObjectBase.Superficie.SUELO,
		"textura": preload("res://Assets/Objects/Power/escombroarmario.png")
	}
]


# GENERAR OBJETOS

static func generar(
	parent: Node2D,
	data: RoomData
) -> void:

	# BORRAR OBJETOS VISUALES ANTERIORES

	for hijo in parent.get_children():
		hijo.queue_free()


	# LA SALA RECUERDA SUS OBJETOS INICIALES
	# Solo se generan la primera vez. Si la sala ya
	# tena objetos guardados (data.objetos), se
	# reutilizan siempre los mismos.

	if data.objetos.is_empty():
		_generar_objetos_iniciales(data)

	if data.tipo == RoomData.TipoSala.SALIDA:
		_eliminar_decoracion_suelo_salida(data)

	_asegurar_componentes_laser(data)
	_asegurar_objetos_obligatorios(data)
	_asegurar_baterias_terminales(data)
	_asegurar_consumibles_sala(data)
	_asegurar_minimo_recogibles(data, 3)
	_limpiar_sala_salida(data)
	if data.tipo != RoomData.TipoSala.SALIDA:
		# Esta segunda pasada es intencionada: la limpieza de la sala
		# puede haber eliminado el ultimo sitio valido para un objeto.
		_asegurar_baterias_terminales(data)
		var minimo_recogibles := clampi(
			3,
			6,
			int(data.ancho * data.alto / 25.0)
		)
		_asegurar_recogibles_finales(data, minimo_recogibles)


	# CREAR LOS NODOS VISUALES A PARTIR DE LOS DATOS

	for objeto in data.objetos:

		# Los objetos ya recogidos no se vuelven a crear
		if objeto.recogido:
			continue

		# Los objetos interactivos (bateras) los crea
		# el PowerGenerator con su propio script.
		if objeto.interactuable:
			continue

		_crear_nodo_objeto(parent, objeto)


	# TELE EN LA ESQUINA SUPERIOR DERECHA

	if data.tiene_tele:
		_crear_tele(parent, data)

	if data.tipo == RoomData.TipoSala.SALIDA:
		_crear_salida(parent, data)


static func reponer_objetos_marcados(data: RoomData) -> bool:
	var nombres_reposicion: Array[String] = []
	for objeto in data.objetos:
		if objeto.necesita_reposicion:
			nombres_reposicion.append(objeto.reposicion_nombre)

	if nombres_reposicion.is_empty():
		return false

	var celdas_usadas: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido or objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		celdas_usadas.append(Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		))

	var creados: int = 0
	for nombre in nombres_reposicion:
		var celda: Vector2i = _elegir_celda_libre(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			celda = _liberar_celda_decoracion(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			continue
		celdas_usadas.append(celda)
		var definicion: Dictionary = _definicion_power(nombre)
		data.añadir_objeto(ObjectData.crear(
			definicion["nombre"],
			ObjectData.TipoObjeto.INTERACTUABLE,
			definicion["textura"],
			Vector2((celda.x + 1) * data.tam_celda, (celda.y + 1) * data.tam_celda),
			1.0,
			true,
			definicion["descripcion"]
		))
		creados += 1

	if creados > 0:
		for objeto in data.objetos:
			if objeto.necesita_reposicion:
				objeto.necesita_reposicion = false

	return creados > 0


static func reponer_consumible_sala(
	data: RoomData,
	nombre: String
) -> bool:
	var celda_usada: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido or objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		celda_usada.append(Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		))

	var celda := _elegir_celda_libre(data, celda_usada)
	if celda == Vector2i(-1, -1):
		celda = _liberar_celda_decoracion(data, celda_usada)
	if celda == Vector2i(-1, -1):
		return false

	var definicion := _definicion_power(nombre)
	data.añadir_objeto(ObjectData.crear(
		nombre,
		ObjectData.TipoObjeto.INTERACTUABLE,
		definicion["textura"],
		Vector2((celda.x + 1) * data.tam_celda, (celda.y + 1) * data.tam_celda),
		1.0,
		true,
		definicion["descripcion"]
	))
	return true


static func _definicion_power(nombre: String) -> Dictionary:
	for definicion in catalogo_power:
		if definicion["nombre"] == nombre:
			return definicion
	return catalogo_power.pick_random()


static func _crear_salida(parent: Node2D, data: RoomData) -> void:
	var salida := salida_scene.instantiate() as Node2D
	if salida == null:
		push_error("ObjectGenerator: no se pudo instanciar Salida.tscn")
		return

	salida.name = "SalidaPlataforma"
	salida.position = Vector2(
		(data.ancho * data.tam_celda) / 2.0,
		(data.alto * data.tam_celda) / 2.0
	)
	parent.add_child(salida)


static func _asegurar_objetos_obligatorios(data: RoomData) -> void:
	if data.tipo == RoomData.TipoSala.SALIDA:
		return


static func _asegurar_componentes_laser(data: RoomData) -> void:
	if data.laser_puerta == "":
		return

	var tiene_laser := false
	var tiene_caja := false
	for objeto in data.objetos:
		if objeto.recogido:
			continue
		if objeto.nombre == "laserpuzzle":
			tiene_laser = true
		elif objeto.nombre == "cajametal":
			tiene_caja = true

	var celdas_usadas: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido or objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		celdas_usadas.append(Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		))

	if not tiene_laser:
		var celda_laser := _elegir_celda_libre(data, celdas_usadas)
		if celda_laser == Vector2i(-1, -1):
			celda_laser = Vector2i(data.ancho / 2, data.alto / 2)
		data.añadir_objeto(ObjectData.crear(
			"laserpuzzle",
			ObjectData.TipoObjeto.INTERACTUABLE,
			textura_panel_cables,
			Vector2(
				(celda_laser.x + 1) * data.tam_celda,
				(celda_laser.y + 1) * data.tam_celda
			),
			ESCALA_PANEL,
			true,
			"Alineador laser"
		))
		celdas_usadas.append(celda_laser)

	if not tiene_caja:
		var celda_caja := _elegir_celda_caja_manejable(data, celdas_usadas)
		if celda_caja == Vector2i(-1, -1):
			celda_caja = _liberar_celda_decoracion(data, celdas_usadas)
		if celda_caja == Vector2i(-1, -1):
			var celdas_fallback := _celdas_disponibles(
				data,
				celdas_usadas,
				false
			)
			if not celdas_fallback.is_empty():
				celda_caja = celdas_fallback[0]
		if celda_caja != Vector2i(-1, -1):
			data.añadir_objeto(ObjectData.crear(
				"cajametal",
				ObjectData.TipoObjeto.OBSTACULO,
				textura_caja_metal,
				Vector2(
					(celda_caja.x + 1) * data.tam_celda,
					(celda_caja.y + 1) * data.tam_celda
				),
				0.52,
				false,
				"Caja metalica"
			))


static func _liberar_celda_decoracion(
	data: RoomData,
	_celdas_usadas: Array[Vector2i]
) -> Vector2i:
	for indice in range(data.objetos.size() - 1, -1, -1):
		var objeto: ObjectData = data.objetos[indice]
		if objeto.recogido:
			continue
		if objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		if objeto.tipo != ObjectData.TipoObjeto.DECORACION:
			continue
		var celda := Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		)
		data.objetos.remove_at(indice)
		return celda
	return Vector2i(-1, -1)


static func _asegurar_baterias_terminales(data: RoomData) -> void:
	var terminales: int = int(data.terminal_arriba) \
		+ int(data.terminal_abajo) \
		+ int(data.terminal_izquierda) \
		+ int(data.terminal_derecha)
	terminales = max(terminales, data.num_terminales)
	if terminales <= 0:
		return

	var baterias: int = 0
	var celdas_usadas: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido:
			continue
		if objeto.superficie == ObjectBase.Superficie.SUELO:
			celdas_usadas.append(Vector2i(
				round(objeto.posicion.x / data.tam_celda) - 1,
				round(objeto.posicion.y / data.tam_celda) - 1
			))
		if objeto.nombre == "bateria" and objeto.interactuable:
			baterias += 1

	while baterias < terminales:
		var celda := _elegir_celda_libre(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			var alternativas := _celdas_disponibles(data, celdas_usadas, false)
			if alternativas.is_empty():
				celda = _liberar_celda_decoracion(data, celdas_usadas)
				if celda == Vector2i(-1, -1):
					celda = Vector2i(
						clampi(1 + baterias, 1, data.ancho - 2),
						clampi(1, 1, data.alto - 2)
					)
			else:
				celda = alternativas[0]

		celdas_usadas.append(celda)
		data.añadir_objeto(ObjectData.crear(
			"bateria",
			ObjectData.TipoObjeto.INTERACTUABLE,
			textura_bateria,
			Vector2((celda.x + 1) * data.tam_celda, (celda.y + 1) * data.tam_celda),
			ESCALA_BATERIA,
			true,
			"Bateria portatil"
		))
		baterias += 1


static func _contar_consumibles(data: RoomData) -> int:
	var total: int = 0
	var nombres_consumibles := [
		"barritavege",
		"cafe",
		"caramelos",
		"cinta",
		"fusible"
	]
	for objeto in data.objetos:
		if objeto.recogido:
			continue
		if objeto.interactuable and nombres_consumibles.has(objeto.nombre):
			total += 1
	return total


static func _contar_recogibles_suelo(data: RoomData) -> int:
	var total: int = 0
	for objeto in data.objetos:
		if objeto.recogido:
			continue
		if objeto.interactuable and objeto.superficie == ObjectBase.Superficie.SUELO:
			total += 1
	return total


static func _minimo_total_objetos_sala(data: RoomData) -> int:
	var area: int = max(1, data.ancho * data.alto)
	var minimo: int = max(MIN_OBJETOS_TOTALES_SALA, int(area / 18.0))
	return minimo


static func _eliminar_consumibles_excedentes(data: RoomData, exceso: int) -> void:
	if exceso <= 0:
		return

	var indices: Array[int] = []
	for i in range(data.objetos.size() - 1, -1, -1):
		var objeto := data.objetos[i]
		if objeto.interactuable and [
			"barritavege",
			"cafe",
			"caramelos",
			"cinta",
			"fusible"
		].has(objeto.nombre):
			indices.append(i)
			if indices.size() >= exceso:
				break

	for idx in indices:
		data.objetos.remove_at(idx)


static func _asegurar_consumibles_sala(data: RoomData) -> void:
	var consumibles: int = _contar_consumibles(data)

	var faltantes: int = clampi(MIN_CONSUMIBLES_SALA - consumibles, 0, MAX_CONSUMIBLES_SALA)
	if faltantes > 0:
		var celdas_usadas: Array[Vector2i] = []
		for objeto in data.objetos:
			if objeto.recogido:
				continue
			if objeto.superficie != ObjectBase.Superficie.SUELO:
				continue
			celdas_usadas.append(Vector2i(
				round(objeto.posicion.x / data.tam_celda) - 1,
				round(objeto.posicion.y / data.tam_celda) - 1
			))

		for i in range(faltantes):
			var celda := _elegir_celda_libre(data, celdas_usadas)
			if celda == Vector2i(-1, -1):
				break
			celdas_usadas.append(celda)
			var definicion: Dictionary = catalogo_power.pick_random()
			data.añadir_objeto(ObjectData.crear(
				definicion["nombre"],
				ObjectData.TipoObjeto.INTERACTUABLE,
				definicion["textura"],
				Vector2((celda.x + 1) * data.tam_celda, (celda.y + 1) * data.tam_celda),
				1.0,
				true,
				definicion["descripcion"]
			))

	consumibles = _contar_consumibles(data)
	if consumibles > MAX_CONSUMIBLES_SALA:
		_eliminar_consumibles_excedentes(data, consumibles - MAX_CONSUMIBLES_SALA)

	var elementos_contables := 0
	for objeto in data.objetos:
		if objeto.recogido or objeto.nombre == "bateria":
			continue
		elementos_contables += 1

	var total_objetos_minimo := _minimo_total_objetos_sala(data)
	if elementos_contables < total_objetos_minimo:
		var celdas_usadas: Array[Vector2i] = []
		for objeto in data.objetos:
			if objeto.recogido or objeto.nombre == "bateria":
				continue
			if objeto.superficie != ObjectBase.Superficie.SUELO:
				continue
			celdas_usadas.append(Vector2i(
				round(objeto.posicion.x / data.tam_celda) - 1,
				round(objeto.posicion.y / data.tam_celda) - 1
			))
		for i in range(total_objetos_minimo - elementos_contables):
			var celda := _elegir_celda_libre(data, celdas_usadas)
			if celda == Vector2i(-1, -1):
				break
			celdas_usadas.append(celda)
			var catalogo_tipo := _catalogo_suelo_por_tipo(data.tipo)
			if catalogo_tipo.is_empty():
				catalogo_tipo = catalogo_suelo
			var definicion: Dictionary
			if _contar_recogibles_suelo(data) < 3:
				definicion = catalogo_power.pick_random()
			else:
				definicion = catalogo_tipo.pick_random()
			data.añadir_objeto(ObjectData.crear(
				definicion["nombre"],
				ObjectData.TipoObjeto.INTERACTUABLE if definicion in catalogo_power else ObjectData.TipoObjeto.DECORACION,
				definicion["textura"],
				Vector2((celda.x + 1) * data.tam_celda, (celda.y + 1) * data.tam_celda),
				1.0,
				true,
				definicion.get("descripcion", "Objeto")
			))

static func _asegurar_recogible_visible(data: RoomData) -> void:
	if _contar_consumibles(data) > 0:
		return

	var definicion: Dictionary = catalogo_power.pick_random()
	var posicion := Vector2(
		(data.ancho + 1) * data.tam_celda / 2.0,
		(data.alto + 1) * data.tam_celda / 2.0
	)
	data.añadir_objeto(ObjectData.crear(
		definicion["nombre"],
		ObjectData.TipoObjeto.INTERACTUABLE,
		definicion["textura"],
		posicion,
		1.0,
		true,
		definicion["descripcion"]
	))


static func _eliminar_decoracion_suelo_salida(data: RoomData) -> void:
	for indice in range(data.objetos.size() - 1, -1, -1):
		var objeto: ObjectData = data.objetos[indice]
		if objeto.superficie == ObjectBase.Superficie.SUELO \
				and objeto.tipo == ObjectData.TipoObjeto.DECORACION:
			data.objetos.remove_at(indice)


static func _limpiar_sala_salida(data: RoomData) -> void:
	if data.tipo != RoomData.TipoSala.SALIDA:
		return

	data.laser_puerta = ""
	data.panel_puerta = ""

	for indice in range(data.objetos.size() - 1, -1, -1):
		var objeto: ObjectData = data.objetos[indice]
		if objeto.nombre == "laserpuzzle" \
				or objeto.nombre == "panelcables" \
				or (
					objeto.superficie == ObjectBase.Superficie.SUELO
					and objeto.tipo == ObjectData.TipoObjeto.DECORACION
				):
			data.objetos.remove_at(indice)


static func _asegurar_minimo_recogibles(data: RoomData, minimo: int) -> void:
	var recogibles: int = _contar_recogibles_suelo(data)
	var celdas_usadas: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido or objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		celdas_usadas.append(Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		))

	while recogibles < minimo:
		var celda := _elegir_celda_libre(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			celda = _liberar_celda_decoracion(data, celdas_usadas)
			if celda == Vector2i(-1, -1):
				var disponibles := _celdas_disponibles(data, celdas_usadas, false)
				if disponibles.is_empty():
					break
				celda = disponibles[0]
		celdas_usadas.append(celda)
		var definicion: Dictionary = catalogo_power.pick_random()
		var posicion := Vector2(
			(celda.x + 1) * data.tam_celda,
			(celda.y + 1) * data.tam_celda
		)
		data.añadir_objeto(ObjectData.crear(
			definicion["nombre"],
			ObjectData.TipoObjeto.INTERACTUABLE,
			definicion["textura"],
			posicion,
			1.0,
			true,
			definicion["descripcion"]
		))
		recogibles += 1


static func _asegurar_recogibles_finales(
	data: RoomData,
	minimo: int
) -> void:
	var recogibles := _contar_recogibles_suelo(data)
	if recogibles >= minimo:
		return

	var celdas_usadas: Array[Vector2i] = []
	for objeto in data.objetos:
		if objeto.recogido or objeto.superficie != ObjectBase.Superficie.SUELO:
			continue
		celdas_usadas.append(Vector2i(
			round(objeto.posicion.x / data.tam_celda) - 1,
			round(objeto.posicion.y / data.tam_celda) - 1
		))

	while recogibles < minimo:
		var celda := _elegir_celda_libre(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			celda = _liberar_celda_decoracion(data, celdas_usadas)
		if celda == Vector2i(-1, -1):
			# En salas pequeñas puede no quedar una celda libre.
			# Se reserva una posición interior antes de rendirse.
			celda = Vector2i(
				clampi(2 + recogibles, 1, data.ancho - 2),
				clampi(2, 1, data.alto - 2)
			)

		var definicion: Dictionary = catalogo_power[
			recogibles % catalogo_power.size()
		]
		data.añadir_objeto(ObjectData.crear(
			definicion["nombre"],
			ObjectData.TipoObjeto.INTERACTUABLE,
			definicion["textura"],
			Vector2(
				(celda.x + 1) * data.tam_celda,
				(celda.y + 1) * data.tam_celda
			),
			1.0,
			true,
			definicion["descripcion"]
		))
		celdas_usadas.append(celda)
		recogibles += 1


# GENERAR OBJETOS INICIALES DE LA SALA

static func _generar_objetos_iniciales(data: RoomData) -> void:

	# LA SALA INICIAL ES UNA SALA MS


	# Semilla propia para que la sala tenga siempre
	# el mismo contenido inicial.
	seed(data.seed + 2)

	# La tele aparece de vez en cuando en las salas
	# que no son la de inicio.
	data.tiene_tele = (
		data.tipo != RoomData.TipoSala.INICIO
		and randf() < PROB_TELE
	)

	# OBJETOS DE SUELO

	var cantidad := randi_range(MIN_OBJETOS, MAX_OBJETOS)
	if data.tipo == RoomData.TipoSala.INICIO \
			or data.laser_puerta != "":
		cantidad = max(cantidad, 3)

	var celdas_usadas: Array[Vector2i] = []
	var celda_laser: Vector2i = Vector2i(-1, -1)
	var celda_barrita_reservada := Vector2i(-1, -1)

	# Reservar primero el puesto del lser y su zona de trabajo.
	# As los dems objetos no aparecen pegados al puzzle.
	if data.tipo == RoomData.TipoSala.INICIO \
			or data.laser_puerta != "":
		celda_laser = Vector2i(
			data.ancho / 2,
			data.alto / 2
		)
		_reservar_zona_puzzle(
			data,
			celda_laser,
			celdas_usadas
		)
		if data.tipo == RoomData.TipoSala.INICIO:
			_reservar_zona_spawn(
				data,
				Vector2i(2, data.alto / 2),
				celdas_usadas,
				1
			)
			celda_barrita_reservada = _elegir_celda_libre(data, celdas_usadas)
			if celda_barrita_reservada != Vector2i(-1, -1):
				celdas_usadas.append(celda_barrita_reservada)

	for i in range(cantidad):

		var celda := _elegir_celda_libre(data, celdas_usadas)

		# No hay ms sitio libre
		if celda == Vector2i(-1, -1):
			break

		celdas_usadas.append(celda)

		var catalogo_tipo := _catalogo_suelo_por_tipo(data.tipo)
		var definicion = catalogo_tipo.pick_random()

		var posicion := Vector2(
			(celda.x + 1) * data.tam_celda,
			(celda.y + 1) * data.tam_celda
		)

		_crear_objeto_en(data, definicion, posicion)


	# ESCOMBROS (50% de probabilidad)

	if randf() < 0.5:

		var celda_escombro := _elegir_celda_libre(data, celdas_usadas)

		if celda_escombro != Vector2i(-1, -1):

			celdas_usadas.append(celda_escombro)

			var definicion = catalogo_escombros.pick_random()

			_crear_objeto_en(
				data,
				definicion,
				Vector2(
					(celda_escombro.x + 1) * data.tam_celda,
					(celda_escombro.y + 1) * data.tam_celda
				)
			)

	# GARANTA DE DECORACIN DE SUELO
	# Si la aleatoriedad se queda sin recursos y la sala
	# queda prcticamente vaca, dejamos mnimo 3 piezas
	# de suelo para que no parezca un hueco vaco ni una
	# zona sin decoracin.

	var terminales_sala: int = int(data.terminal_arriba) \
		+ int(data.terminal_abajo) \
		+ int(data.terminal_izquierda) \
		+ int(data.terminal_derecha)
	var minimo_decoracion: int = 1 if terminales_sala > 0 else MIN_OBJETOS
	var decoracion_suelo_actual := 0
	for objeto in data.objetos:
		if objeto.superficie == ObjectBase.Superficie.SUELO and objeto.tipo == ObjectData.TipoObjeto.DECORACION:
			decoracion_suelo_actual += 1

	if decoracion_suelo_actual < minimo_decoracion:
		for celda in _celdas_disponibles(data, celdas_usadas, false):
			if decoracion_suelo_actual >= minimo_decoracion:
				break
			if celdas_usadas.has(celda):
				continue
			celdas_usadas.append(celda)
			var catalogo_tipo := _catalogo_suelo_por_tipo(data.tipo)
			if catalogo_tipo.is_empty():
				catalogo_tipo = catalogo_suelo
			var definicion = catalogo_tipo.pick_random()
			_crear_objeto_en(
				data,
				definicion,
				Vector2(
					(celda.x + 1) * data.tam_celda,
					(celda.y + 1) * data.tam_celda
				)
			)
			decoracion_suelo_actual += 1

	# Refuerzo final: si an no hay decoracin mnima, se fuerza
	# aunque la sala se haya quedado muy tensa por el layout.
	if data.tipo != RoomData.TipoSala.SALIDA:
		var decoracion_final := 0
		for objeto in data.objetos:
			if objeto.superficie == ObjectBase.Superficie.SUELO and objeto.tipo == ObjectData.TipoObjeto.DECORACION:
				decoracion_final += 1
		if decoracion_final < minimo_decoracion:
			for celda in _celdas_disponibles(data, celdas_usadas, false):
				if decoracion_final >= minimo_decoracion:
					break
				var catalogo_tipo := _catalogo_suelo_por_tipo(data.tipo)
				if catalogo_tipo.is_empty():
					catalogo_tipo = catalogo_suelo
				_crear_objeto_en(
					data,
					catalogo_tipo.pick_random(),
					Vector2(
						(celda.x + 1) * data.tam_celda,
						(celda.y + 1) * data.tam_celda
					)
				)
				decoracion_final += 1


	# BATERAS (para dar energa a los terminales)
	# Garanta anti-bloqueo: si la sala tiene terminales,
	# SIEMPRE aparecen tantas bateras como terminales.
	# As nunca te quedas encerrado sin poder abrir la
	# puerta. Si la sala no tiene terminales, de vez en
	# cuando aparece una de reserva para llevarla.

	var terminales_configurados := int(data.terminal_arriba) \
		+ int(data.terminal_abajo) \
		+ int(data.terminal_izquierda) \
		+ int(data.terminal_derecha)
	var baterias_a_colocar := 0

	if max(data.num_terminales, terminales_configurados) > 0:
		baterias_a_colocar = max(data.num_terminales, terminales_configurados)
	elif randf() < PROB_BATERIA:
		baterias_a_colocar = 1

	for i in range(baterias_a_colocar):

		var celda_bateria := _elegir_celda_libre(data, celdas_usadas)

		# Si la sala qued muy apretada, seguimos buscando
		# cualquier celda libre sin forzar la zona de la puerta.
		if celda_bateria == Vector2i(-1, -1):
			var celdas_fallback := _celdas_disponibles(data, celdas_usadas, false)
			if celdas_fallback.is_empty():
				break
			celda_bateria = celdas_fallback[0]

		celdas_usadas.append(celda_bateria)

		var objeto_bateria := ObjectData.crear(
			"bateria",
			ObjectData.TipoObjeto.INTERACTUABLE,
			textura_bateria,
			Vector2(
				(celda_bateria.x + 1) * data.tam_celda,
				(celda_bateria.y + 1) * data.tam_celda
			),
			ESCALA_BATERIA,
			true,
			"Batera porttil"
		)

		data.añadir_objeto(objeto_bateria)


	# PANEL ELCTRICO (PUZLE DE CABLES)
	# En las salas con puerta de mecanismo se coloca el
	# panel que abre el puzle de cables (sigue intacto).

	if data.panel_puerta != "":

		var celda_panel := _elegir_celda_libre(data, celdas_usadas)

		if celda_panel != Vector2i(-1, -1):

			celdas_usadas.append(celda_panel)

			var objeto_panel := ObjectData.crear(
				"panelcables",
				ObjectData.TipoObjeto.INTERACTUABLE,
				textura_panel_cables,
				Vector2(
					(celda_panel.x + 1) * data.tam_celda,
					(celda_panel.y + 1) * data.tam_celda
				),
				ESCALA_PANEL,
				true,
				"Panel elctrico"
			)

			data.añadir_objeto(objeto_panel)


	# PUZLE DE LSERES ASOCIADO A PUERTA
	# Si esta sala tiene una puerta bloqueada por puzzle
	# lser (laser_puerta != ""), se genera el objeto
	# lser para que el jugador pueda abrir la puerta.
	# Si hay lser, siempre hay caja metlica en la sala.

	var hay_laser := data.laser_puerta != ""

	if hay_laser:
		var celda_laser_objeto: Vector2i = celda_laser
		if celda_laser_objeto == Vector2i(-1, -1):
			celda_laser_objeto = _elegir_celda_libre(data, celdas_usadas)
		if celda_laser_objeto == Vector2i(-1, -1):
			celda_laser_objeto = Vector2i(data.ancho / 2, data.alto / 2)
		celdas_usadas.append(celda_laser_objeto)

		var objeto_laser := ObjectData.crear(
			"laserpuzzle",
			ObjectData.TipoObjeto.INTERACTUABLE,
			textura_panel_cables,
			Vector2(
				(celda_laser_objeto.x + 1) * data.tam_celda,
				(celda_laser_objeto.y + 1) * data.tam_celda
			),
			ESCALA_PANEL,
			true,
			"Alineador lser"
		)

		data.añadir_objeto(objeto_laser)


	# La sala del lser siempre tiene una caja metlica.
	# En las dems salas aparece de forma ocasional.
	var debe_generar_caja := hay_laser
	if not debe_generar_caja and randf() < 0.35:
		debe_generar_caja = true

	if debe_generar_caja:
		var celda_caja := _elegir_celda_caja_manejable(
			data,
			celdas_usadas
		)
		if data.tipo == RoomData.TipoSala.INICIO:
			celda_caja = _elegir_celda_caja_inicio(data, celdas_usadas)
		if celda_caja != Vector2i(-1, -1):
			celdas_usadas.append(celda_caja)
			data.añadir_objeto(
				ObjectData.crear(
					"cajametal",
					ObjectData.TipoObjeto.OBSTACULO,
					textura_caja_metal,
					Vector2(
						(celda_caja.x + 1) * data.tam_celda,
						(celda_caja.y + 1) * data.tam_celda
					),
					0.52,
					false,
					"Caja metlica"
				)
			)


	# OBJETOS RECOGIBLES DE POWER (MX 3 POR SALA)
	# Barritas, cafe, fusibles... van directos al
	# inventario al recogerlos. NO cuentan las bateri?as
	# obligatorias de los terminales: este bloque es
	# independiente de aquella garanti?a.

	var extras_power := 1

	if data.tipo == RoomData.TipoSala.INICIO:
		var celda_barrita: Vector2i = celda_barrita_reservada
		if celda_barrita != Vector2i(-1, -1):
			celdas_usadas.append(celda_barrita)
			data.añadir_objeto(
				ObjectData.crear(
					"barritavege",
					ObjectData.TipoObjeto.INTERACTUABLE,
					catalogo_power[0]["textura"],
					Vector2(
						(celda_barrita.x + 1) * data.tam_celda,
						(celda_barrita.y + 1) * data.tam_celda
					),
					1.0,
					true,
					"Barrita vegetal"
				)
			)

	if randf() < 0.7:
		extras_power += 1

	if randf() < 0.45:
		extras_power += 1

	if randf() < 0.25:
		extras_power += 1

	var espacio_consumibles: int = max(
		0,
		MAX_CONSUMIBLES_SALA - _contar_consumibles(data)
	)
	for i in range(mini(extras_power, espacio_consumibles)):

		var celda_power := _elegir_celda_libre(
			data, celdas_usadas
		)

		if celda_power == Vector2i(-1, -1):
			break

		celdas_usadas.append(celda_power)

		var definicion = catalogo_power.pick_random()

		data.añadir_objeto(
			ObjectData.crear(
				definicion["nombre"],
				ObjectData.TipoObjeto.INTERACTUABLE,
				definicion["textura"],
				Vector2(
					(celda_power.x + 1) * data.tam_celda,
					(celda_power.y + 1) * data.tam_celda
				),
				1.0,
				true,
				definicion["descripcion"]
			)
		)


	# OBJETOS DE PARED

	var cantidad_pared := randi_range(MIN_PARED, MAX_PARED)

	var columnas_pared: Array[int] = []

	for i in range(cantidad_pared):

		var definicion = catalogo_pared.pick_random()

		var es_lateral: bool = (
			definicion["superficie"]
			== ObjectBase.Superficie.PARED_IZQUIERDA
			or definicion["superficie"]
			== ObjectBase.Superficie.PARED_DERECHA
		)

		var columna := _elegir_columna_libre(
			data, columnas_pared, es_lateral
		)

		if columna == -1:
			break

		columnas_pared.append(columna)

		_crear_objeto_en(
			data,
			definicion,
			_posicion_pared(data, definicion, columna)
		)

	# Cada sala marcada por LaboratoryGenerator genera un solo
	# conducto; su pareja est guardada en otra sala.
	if data.conducto_conexion_id >= 0:
		_generar_conducto(data)


	# CMARAS DE SEGURIDAD (solo de vez en cuando)

	if randf() < PROB_CAMARAS:

		var paredes: Array[int] = [0, 1, 2, 3]
		paredes.shuffle()

		var num_camaras := randi_range(1, 3)

		for i in range(min(num_camaras, paredes.size())):

			var pared := paredes[i]

			var definicion = _camara_para_pared(pared)

			if definicion == null:
				continue

			var es_lateral := pared >= 2

			var indices_ocupados: Array[int] = []
			if not es_lateral:
				indices_ocupados = columnas_pared

			var indice := _elegir_indice_camara(
				data,
				es_lateral,
				indices_ocupados
			)

			if indice == -1:
				continue

			_crear_objeto_en(
				data,
				definicion,
				_posicion_pared(data, definicion, indice)
			)

			if not es_lateral:
				columnas_pared.append(indice)


# CREAR OBJETO Y GUARDARLO EN LA SALA

static func _crear_objeto_en(
	data: RoomData,
	definicion: Dictionary,
	posicion: Vector2
) -> void:

	var objeto := ObjectData.crear(
		definicion["nombre"],
		ObjectData.TipoObjeto.DECORACION,
		definicion["textura"],
		posicion,
		definicion["escala"]
	)

	objeto.superficie = definicion["superficie"]

	objeto.rotacion = definicion.get("rotacion", 0.0)
	objeto.conducto_conexion_id = definicion.get("conducto_conexion_id", -1)

	# Los objetos de pared se voltean aleatoriamente para
	# que no queden todos mirando igual. Las piezas con
	# "flip_aleatorio": false (cmaras) mantienen su giro.
	if definicion.get("flip_aleatorio", true):
		if objeto.superficie == ObjectBase.Superficie.PARED_ARRIBA \
				or objeto.superficie == ObjectBase.Superficie.PARED_ABAJO:
			objeto.flip_h = randf() < 0.5

	data.añadir_objeto(objeto)


static func asignar_parejas_conductos(salas: Array[RoomData]) -> void:
	var candidatas: Array[RoomData] = []
	for sala in salas:
		sala.conducto_conexion_id = -1
		if sala.tipo != RoomData.TipoSala.INICIO:
			candidatas.append(sala)

	var cantidad_salas: int = mini(6, candidatas.size() - (candidatas.size() % 2))

	candidatas.shuffle()
	for indice in range(0, cantidad_salas, 2):
		var conexion_id: int = indice / 2
		candidatas[indice].conducto_conexion_id = conexion_id
		candidatas[indice + 1].conducto_conexion_id = conexion_id


static func _generar_conducto(data: RoomData) -> void:
	var paredes: Array[ObjectBase.Superficie] = [
		ObjectBase.Superficie.PARED_ARRIBA,
		ObjectBase.Superficie.PARED_ABAJO,
		ObjectBase.Superficie.PARED_IZQUIERDA,
		ObjectBase.Superficie.PARED_DERECHA
	]
	paredes.shuffle()

	for superficie in paredes:
		var es_lateral: bool = (
			superficie == ObjectBase.Superficie.PARED_IZQUIERDA
			or superficie == ObjectBase.Superficie.PARED_DERECHA
		)
		var limite: int = data.alto if es_lateral else data.ancho

		for indice in range(1, limite - 1):
			if _conducto_ocupa_puerta(data, superficie, indice):
				continue

			var definicion := {
				"nombre": "conductoventilacion",
				"escala": ESCALA_CONDUCTO,
				"superficie": superficie,
				"textura": textura_conducto,
				"rotacion": _rotacion_conducto(superficie),
				"flip_aleatorio": false,
				"conducto_conexion_id": data.conducto_conexion_id
			}
			_crear_objeto_en(data, definicion, _posicion_pared(data, definicion, indice))
			return


static func _conducto_ocupa_puerta(
	data: RoomData,
	superficie: ObjectBase.Superficie,
	indice: int
) -> bool:
	var hay_puerta: bool = false
	var centro: int = 0
	if superficie == ObjectBase.Superficie.PARED_ARRIBA:
		hay_puerta = data.puerta_arriba
		centro = data.ancho / 2
	elif superficie == ObjectBase.Superficie.PARED_ABAJO:
		hay_puerta = data.puerta_abajo
		centro = data.ancho / 2
	elif superficie == ObjectBase.Superficie.PARED_IZQUIERDA:
		hay_puerta = data.puerta_izquierda
		centro = data.alto / 2
	else:
		hay_puerta = data.puerta_derecha
		centro = data.alto / 2
	return hay_puerta and abs(indice - centro) <= 2


static func _rotacion_conducto(superficie: ObjectBase.Superficie) -> float:
	match superficie:
		ObjectBase.Superficie.PARED_ARRIBA:
			return 0.0
		ObjectBase.Superficie.PARED_ABAJO:
			return PI
		ObjectBase.Superficie.PARED_IZQUIERDA:
			return -PI / 2.0
		ObjectBase.Superficie.PARED_DERECHA:
			return PI / 2.0
	return 0.0


# POSICIN DE UN OBJETO DE PARED
# Coloca en la pared superior o inferior segn la
# superficie, usando su altura individual si la tiene.

static func _posicion_pared(
	data: RoomData,
	definicion: Dictionary,
	indice: int
) -> Vector2:

	var superficie = definicion["superficie"]

	# PARED SUPERIOR

	if superficie == ObjectBase.Superficie.PARED_ARRIBA:
		return Vector2(
			(indice + 1) * data.tam_celda,
			12.0
		)

	# PARED INFERIOR (altura desde abajo)

	if superficie == ObjectBase.Superficie.PARED_ABAJO:
		return Vector2(
			(indice + 1) * data.tam_celda,
			(data.alto + 1.0) * data.tam_celda - 12.0
		)

	# PARED IZQUIERDA (distancia desde la izquierda)

	if superficie == ObjectBase.Superficie.PARED_IZQUIERDA:
		return Vector2(
			12.0,
			(indice + 1) * data.tam_celda
		)

	# PARED DERECHA (distancia desde la derecha)

	return Vector2(
		(data.ancho + 1.0) * data.tam_celda - 12.0,
		(indice + 1) * data.tam_celda
	)


# ASOCIAR NDICE DE PARED A UNA CMARA DEL CATLOGO
# 0 = ARRIBA, 1 = ABAJO, 2 = IZQUIERDA, 3 = DERECHA

static func _camara_para_pared(pared: int) -> Dictionary:

	match pared:
		0: return catalogo_camaras[0]
		1: return catalogo_camaras[1]
		2: return catalogo_camaras[2]
		3: return catalogo_camaras[3]

	return {}


# ELEGIR NDICE PARA UNA CMARA (LEJOS DE LA PUERTA)
# Para paredes laterales (es_lateral=true) el ndice
# es una fila; para superior/inferior, una columna.
# Evita el centro, donde est la puerta.

static func _elegir_indice_camara(
	data: RoomData,
	es_lateral: bool,
	usados: Array[int]
) -> int:

	var max_indice: int = data.alto if es_lateral else data.ancho
	var puerta: int = max_indice / 2

	var intentos := 0

	while intentos < 50:

		intentos += 1

		var indice := randi_range(1, max(1, max_indice - 2))

		# No acercarse a la puerta (margen de 2 para que
		# el hueco quede bien despejado).
		if abs(indice - puerta) <= 2:
			continue

		if usados.has(indice):
			continue

		return indice

	return -1


# CREAR LA TELE EN LA ESQUINA SUPERIOR DERECHA

static func _crear_tele(parent: Node2D, data: RoomData) -> void:

	var tele := tele_scene.instantiate() as Node2D

	if tele == null:
		return

	tele.name = "Tele"

	tele.position = Vector2(
		data.ancho * data.tam_celda - 3,
		0.3 * data.tam_celda
	)

	tele.scale = Vector2.ONE * 0.22

	# La tele cuelga de la pared: se dibuja por encima
	# del personaje, igual que las cmaras.
	tele.z_index = 10

	# COLISIN FSICA
	# Evita que el jugador se meta debajo de la tele.
	# Las unidades son locales (el nodo escala 0.22 las
	# reduce a ~79x62 px en pantalla).

	var cuerpo_tele := StaticBody2D.new()

	cuerpo_tele.name = "TeleCollision"

	var colision_tele := CollisionShape2D.new()

	var forma_tele := RectangleShape2D.new()

	forma_tele.size = Vector2(260, 210)

	colision_tele.shape = forma_tele

	colision_tele.position = Vector2(0, -10)

	cuerpo_tele.add_child(colision_tele)

	tele.add_child(cuerpo_tele)

	# Asignar el script de interaccin (radio para
	# poder acercarse e interactuar con la tele).
	tele.set_script(preload("res://Scripts/Objects/Tele.gd"))

	parent.add_child(tele)

	# Reproducir la animacin de la tele (la escena no
	# trae autoplay, por eso no se mova).
	var anim := tele.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if anim != null:
		anim.play("default")


# ELEGIR CELDA LIBRE
# Evita las celdas ya ocupadas por otro objeto.

static func _elegir_celda_libre(
	data: RoomData,
	celdas_usadas: Array[Vector2i]
) -> Vector2i:

	var candidatas: Array[Vector2i] = []
	for y in range(1, data.alto - 1):
		for x in range(1, data.ancho - 1):
			var celda := Vector2i(x, y)

			if _cerca_de_puerta(data, x, y):
				continue
			if x == 1 or x == data.ancho - 2:
				continue
			if y == 1 or y == data.alto - 2:
				continue
			if data.tipo == RoomData.TipoSala.INICIO and _dentro_de_zona_puzzle(data, celda):
				continue
			if celdas_usadas.has(celda):
				continue

			candidatas.append(celda)

	if candidatas.is_empty():
		for y in range(1, data.alto - 1):
			for x in range(1, data.ancho - 1):
				var celda := Vector2i(x, y)
				if celdas_usadas.has(celda):
					continue
				if data.tipo == RoomData.TipoSala.INICIO and _dentro_de_zona_puzzle(data, celda):
					continue
				if _cerca_de_puerta(data, x, y):
					continue
				candidatas.append(celda)

	if candidatas.is_empty():
		return Vector2i(-1, -1)

	var mejor: Vector2i = candidatas[0]
	var mejor_score: int = 100000
	for celda in candidatas:
		var score: int = 0
		for usada in celdas_usadas:
			var dx: int = abs(usada.x - celda.x)
			var dy: int = abs(usada.y - celda.y)
			if dx <= 2 and dy <= 2:
				score += 1

		# Penalizar zonas ya saturadas para no amontonar objetos.
		# Las celdas ms centrales y ms separadas de otros objetos se prefieren.
		var centro := Vector2i(data.ancho / 2, data.alto / 2)
		var dist_centro: int = abs(celda.x - centro.x) + abs(celda.y - centro.y)
		score += dist_centro / 6

		if score < mejor_score or (score == mejor_score and randf() < 0.35):
			mejor = celda
			mejor_score = score

	return mejor


static func _celdas_disponibles(
	data: RoomData,
	celdas_usadas: Array[Vector2i],
	respetar_areas_seguras: bool = true
) -> Array[Vector2i]:
	var celdas: Array[Vector2i] = []

	for y in range(1, data.alto - 1):
		for x in range(1, data.ancho - 1):
			var celda := Vector2i(x, y)
			if celdas_usadas.has(celda):
				continue
			if data.tipo == RoomData.TipoSala.INICIO and _dentro_de_zona_puzzle(data, celda):
				continue
			if respetar_areas_seguras:
				if x == 1 or x == data.ancho - 2:
					continue
				if y == 1 or y == data.alto - 2:
					continue

			# Nunca colocar objetos cerca de las puertas:
			# un objeto ah bloqueara el paso o se
			# solapara con la zona de interaccin.
			if _cerca_de_puerta(data, x, y):
				continue

			celdas.append(celda)

	return celdas


# RESERVAR ZONA DEL PUZZLE LSER

static func _reservar_zona_puzzle(
	data: RoomData,
	centro: Vector2i,
	celdas_usadas: Array[Vector2i]
) -> void:

	# Reservamos una zona visualmente ms equilibrada, con forma de
	# rombo alrededor del centro del puzzle. As queda limpio y
	# ordenado, pero sin vaciar la sala ni bloquear los objetos
	# importantes como la caja metlica o el spawn.
	for y in range(
		max(1, centro.y - DISTANCIA_PUZZLE_LASER_CELDAS),
		min(data.alto - 1, centro.y + DISTANCIA_PUZZLE_LASER_CELDAS + 1)
	):
		for x in range(
			max(1, centro.x - DISTANCIA_PUZZLE_LASER_CELDAS),
			min(data.ancho - 1, centro.x + DISTANCIA_PUZZLE_LASER_CELDAS + 1)
		):
			var celda := Vector2i(x, y)
			var dx: int = abs(celda.x - centro.x)
			var dy: int = abs(celda.y - centro.y)
			if dx <= DISTANCIA_PUZZLE_LASER_CELDAS and dy <= DISTANCIA_PUZZLE_LASER_CELDAS and not celdas_usadas.has(celda):
				celdas_usadas.append(celda)


static func _reservar_zona_spawn(
	data: RoomData,
	centro: Vector2i,
	celdas_usadas: Array[Vector2i],
	radio: int = 2
) -> void:

	# rea libre para que el personaje aparezca sin quedar atrapado
	# entre objetos o encima del puzzle/caja al entrar en la sala.
	for y in range(
		max(1, centro.y - radio),
		min(data.alto - 1, centro.y + radio + 1)
	):
		for x in range(
			max(1, centro.x - radio),
			min(data.ancho - 1, centro.x + radio + 1)
		):
			var celda := Vector2i(x, y)
			if not celdas_usadas.has(celda):
				celdas_usadas.append(celda)


# ZONA DEL PUZZLE DE LSER
# Define el centro seguro del puzzle para que ninguna
# decoracin ni caja aparezcan dentro de ese espacio.

static func _dentro_de_zona_puzzle(
	data: RoomData,
	celda: Vector2i,
	radio: int = 2
) -> bool:
	if data.tipo != RoomData.TipoSala.INICIO:
		return false

	var centro := Vector2i(data.ancho / 2, data.alto / 2)
	var dx: int = abs(celda.x - centro.x)
	var dy: int = abs(celda.y - centro.y)
	return dx <= radio and dy <= radio


static func _celdas_seguras_inicio(
	data: RoomData,
	celdas_usadas: Array[Vector2i]
) -> Array[Vector2i]:
	var centro := Vector2i(data.ancho / 2, data.alto / 2)
	var seguros: Array[Vector2i] = []

	for y in range(1, data.alto - 1):
		for x in range(1, data.ancho - 1):
			var celda := Vector2i(x, y)
			if _cerca_de_puerta(data, x, y):
				continue
			if x == 1 or x == data.ancho - 2:
				continue
			if y == 1 or y == data.alto - 2:
				continue
			if abs(x - centro.x) <= 1 and abs(y - centro.y) <= 1:
				continue
			if celdas_usadas.has(celda):
				continue
			seguros.append(celda)

	return seguros


static func _elegir_celda_segura_inicio(
	data: RoomData,
	celdas_usadas: Array[Vector2i]
) -> Vector2i:
	var seguros := _celdas_seguras_inicio(data, celdas_usadas)
	if seguros.is_empty():
		return Vector2i(-1, -1)
	return seguros.pick_random()


static func _elegir_celda_caja_inicio(
	data: RoomData,
	celdas_usadas: Array[Vector2i]
) -> Vector2i:
	var centro := Vector2i(data.ancho / 2, data.alto / 2)
	var candidatas: Array[Vector2i] = []

	for y in range(2, data.alto - 2):
		for x in range(1, max(1, centro.x - 1)):
			var celda := Vector2i(x, y)
			if celdas_usadas.has(celda):
				continue
			if _cerca_de_puerta(data, x, y):
				continue
			if not _tiene_espacio_para_empujar(data, celda, celdas_usadas):
				continue
			candidatas.append(celda)

	if not candidatas.is_empty():
		return candidatas.pick_random()

	return _elegir_celda_caja_manejable(data, celdas_usadas)


static func _elegir_celda_caja_manejable(
	data: RoomData,
	celdas_usadas: Array[Vector2i]
) -> Vector2i:
	var candidatas: Array[Vector2i] = []
	for celda in _celdas_disponibles(data, celdas_usadas):
		if _tiene_espacio_para_empujar(data, celda, celdas_usadas):
			candidatas.append(celda)

	if candidatas.is_empty():
		return Vector2i(-1, -1)
	return candidatas.pick_random()


static func _tiene_espacio_para_empujar(
	data: RoomData,
	celda: Vector2i,
	celdas_usadas: Array[Vector2i]
) -> bool:
	var direcciones := [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN
	]
	for direccion in direcciones:
		var vecina: Vector2i = celda + direccion
		if vecina.x < 1 or vecina.x >= data.ancho - 1:
			continue
		if vecina.y < 1 or vecina.y >= data.alto - 1:
			continue
		if _cerca_de_puerta(data, vecina.x, vecina.y):
			continue
		if not celdas_usadas.has(vecina):
			return true
	return false


# COMPROBAR CERCANA A UNA PUERTA
# Devuelve true si la casilla (x,y) est en la misma
# columna/fila que una puerta (o muy cerca de ella).

static func _cerca_de_puerta(
	data: RoomData,
	x: int,
	y: int,
	margen: int = 2
) -> bool:

	# PUERTA ARRIBA / ABAJO (ejes verticales)
	# Para que el jugador no aparezca lejos, se limpia
	# la banda central (columnas margen) y, como estn
	# pegadas a la pared, tambin las filas del borde
	# superior e inferior (y==1 e y==alto-2), que son
	# las que flanquean el hueco de la puerta.

	if data.puerta_arriba or data.puerta_abajo:

		if abs(x - data.ancho / 2) <= margen:
			return true

		if y <= 1 or y >= data.alto - 2:
			return true

	# PUERTA IZQUIERDA / DERECHA (ejes horizontales)

	if data.puerta_izquierda or data.puerta_derecha:

		if abs(y - data.alto / 2) <= margen:
			return true

		if x <= 1 or x >= data.ancho - 2:
			return true

	return false


# ELEGIR COLUMNA LIBRE (OBJETOS DE PARED)
# Evita columnas ya ocupadas por otro objeto de pared.

static func _elegir_columna_libre(
	data: RoomData,
	columnas_usadas: Array[int],
	es_lateral: bool = false
) -> int:

	# Indice del objeto en la pared: columna (x) para
	# paredes arriba/abajo, fila (y) para las laterales.
	var max_indice: int = data.alto if es_lateral else data.ancho

	var puerta: int = max_indice / 2

	var hay_puerta := (
		(data.puerta_izquierda or data.puerta_derecha)
		if es_lateral
		else (data.puerta_arriba or data.puerta_abajo)
	)

	var intentos := 0

	while intentos < 30:

		intentos += 1

		var columna := randi_range(1, max(1, max_indice - 2))

		# No dejar objetos de pared sobre/pegados a la
		# puerta de esa pared (columna o fila central y
		# sus adyacentes, con un margen de 2 para que
		# quede bien despejado el hueco de la puerta).
		if hay_puerta and abs(columna - puerta) <= 2:
			continue

		if columnas_usadas.has(columna):
			continue

		return columna

	return -1


# CREAR NODO VISUAL DEL OBJETO

static func _crear_nodo_objeto(
	parent: Node2D,
	objeto: ObjectData
) -> void:
	if objeto.nombre == "conductoventilacion":
		var conducto := ConductoVentilacion.new()
		conducto.objeto_datos = objeto
		conducto.position = objeto.posicion
		conducto.z_index = 1
		var desplazamiento_conducto := Vector2.ZERO
		match objeto.superficie:
			ObjectBase.Superficie.PARED_ARRIBA:
				desplazamiento_conducto.y = 18.0
			ObjectBase.Superficie.PARED_ABAJO:
				desplazamiento_conducto.y = -18.0
			ObjectBase.Superficie.PARED_IZQUIERDA:
				desplazamiento_conducto.x = 18.0
			ObjectBase.Superficie.PARED_DERECHA:
				desplazamiento_conducto.x = -18.0
		conducto.position += desplazamiento_conducto
		parent.add_child(conducto)

		var sprite_conducto := Sprite2D.new()
		sprite_conducto.name = "Sprite"
		sprite_conducto.texture = objeto.textura
		sprite_conducto.scale = Vector2.ONE * objeto.escala
		sprite_conducto.rotation = objeto.rotacion
		conducto.add_child(sprite_conducto)
		return

	var sprite := Sprite2D.new()

	sprite.name = objeto.nombre

	sprite.texture = objeto.textura

	sprite.scale = Vector2.ONE * objeto.escala

	sprite.position = objeto.posicion

	sprite.rotation = objeto.rotacion

	sprite.flip_h = objeto.flip_h
	sprite.flip_v = objeto.flip_v

	# Los objetos de pared deben quedar detrs del personaje para que
	# no tape al jugador ni haga que la decoracin quede fatal.
	var es_pared := (
		objeto.superficie == ObjectBase.Superficie.PARED_ARRIBA
		or objeto.superficie == ObjectBase.Superficie.PARED_ABAJO
		or objeto.superficie == ObjectBase.Superficie.PARED_IZQUIERDA
		or objeto.superficie == ObjectBase.Superficie.PARED_DERECHA
	)

	if es_pared:
		sprite.z_index = 0

	parent.add_child(sprite)

	# Los objetos de suelo bloquean el paso.
	# Los de pared cuelgan y no tienen colisin.
	if objeto.superficie == ObjectBase.Superficie.SUELO and objeto.textura:
		var cuerpo := _crear_colision(parent, objeto)
		if objeto.nombre == "cajametal" and cuerpo != null:
			parent.remove_child(sprite)
			cuerpo.add_child(sprite)
			sprite.position = Vector2.ZERO


# CREAR COLISIN DEL OBJETO

static func _crear_colision(
	parent: Node2D,
	objeto: ObjectData
) -> Node2D:

	var cuerpo: Node2D
	if objeto.nombre == "cajametal":
		cuerpo = MetalBox.new()
		(cuerpo as MetalBox).objeto_datos = objeto
	else:
		cuerpo = StaticBody2D.new()

	cuerpo.name = "ObjectCollision"

	cuerpo.position = objeto.posicion

	var nodo_fisico: Node = cuerpo
	if objeto.nombre == "cajametal":
		var fisica := StaticBody2D.new()
		fisica.name = "MetalBoxCollision"
		fisica.collision_layer = 1
		fisica.collision_mask = 1
		cuerpo.add_child(fisica)
		nodo_fisico = fisica

	var collision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	# Usamos SOLO la parte visible del sprite (descartando
	# los bordes transparentes de la imagen) para que la
	# colisin se ajuste al objeto real y no a su caja.
	var imagen := objeto.textura.get_image()

	var rect_visible := imagen.get_used_rect()

	var factor_colision := COLISION_FACTOR
	if objeto.nombre == "cajametal":
		factor_colision = 0.45
	forma.size = rect_visible.size * objeto.escala * factor_colision

	# La parte visible puede no estar centrada en la imagen
	# (sobra transparencia a un lado). Desplazamos la
	# colisin para que quede centrada sobre el sprite visible.
	var centro_visible := Vector2(
		rect_visible.get_center().x,
		rect_visible.get_center().y
	)

	if objeto.nombre == "cajametal":
		collision.position = Vector2.ZERO
	else:
		collision.position = (
			(centro_visible - imagen.get_size() / 2.0)
			* objeto.escala
		)

	collision.shape = forma

	nodo_fisico.add_child(collision)

	parent.add_child(cuerpo)

	return cuerpo
