extends Node


# CATALOGO DE PERSONAJES (autoload "CatalogoPersonajes")
# Fuente unica de datos de los personajes jugables.
# La pantalla de seleccion, el HUD y los iconos se
# generan solos a partir de esta lista: para añadir un
# personaje nuevo basta con añadir una entrada aqui.

const ID_DEFECTO := "patosa"

var _personajes: Array[CharacterData] = []


func _ready() -> void:

	_personajes = [
		_crear_patosa(),
		_crear_teleportador(),
		_crear_forzudo(),
		_crear_nino(),
		_crear_robot(),
		_crear_electricista(),
		_crear_cientifico(),
		_crear_cientifica()
	]


# CONSULTAS

func todos() -> Array[CharacterData]:

	return _personajes


func obtener(id: String) -> CharacterData:

	for p in _personajes:

		if p.id == id:
			return p

	if _personajes.size() > 0:
		return _personajes[0]

	return null


func por_indice(indice: int) -> CharacterData:

	if indice < 0 or indice >= _personajes.size():
		return null

	return _personajes[indice]


# HELPERS DE CONSTRUCCION

func _pers(
	id: String,
	nombre: String,
	descripcion: String,
	ruta_escena: String
) -> CharacterData:

	var c := CharacterData.new()

	c.id = id
	c.nombre = nombre
	c.descripcion = descripcion
	c.escena = load(ruta_escena) as PackedScene

	return c


func _hab(
	id: String,
	nombre: String,
	descripcion: String,
	ruta_icono: String = "",
	cooldown: float = 0.0,
	accion: String = "",
	confirmar: bool = false
) -> HabilidadData:

	var h := HabilidadData.new()

	h.id = id
	h.nombre = nombre
	h.descripcion = descripcion

	if ruta_icono != "":
		h.icono = load(ruta_icono) as Texture2D

	h.cooldown = cooldown
	h.accion_input = accion
	h.requiere_confirmacion = confirmar

	return h


# 4.1 ==================================================
# INGENIERA PATOSA

func _crear_patosa() -> CharacterData:

	var c := _pers(
		"patosa",
		"Ingeniera Patosa",
		"Una técnica brillante... pero extremadamente despistada. Siempre lleva su enorme llave inglesa y un cinturón lleno de herramientas que no recuerda para qué sirven. Su torpeza provoca resultados impredecibles, pero a veces eso juega a su favor.",
		"res://Scenes/Characters/ingeniera_patosa.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"golpe_llave",
			"Golpe con llave inglesa",
			"Puede mover objetos pesados que otros no pueden o descolocar piezas del puzle de otro jugador.",
			"res://Sprites/golpellavelogo.png",
			20.0
		),
		_hab(
			"reparacion_chapucera",
			"Reparación chapucera",
			"Arregla máquinas, puertas o mecanismos rotos. RIESGO: 30% de que la reparación cause un fallo temporal (chispa, humo, bloqueo de puerta...).",
			"res://Sprites/reparacionchapuceralogo.png",
			20.0
		)
	]

	c.habilidades = habs

	return c


# 4.2 ==================================================
# CIENTÍFICO TELEPORTADOR

func _crear_teleportador() -> CharacterData:

	var c := _pers(
		"teleportador",
		"Científico Teleportador",
		"Un genio obsesionado con la física cuántica. Lleva un prototipo de teletransportador portátil que funciona... la mayoría de las veces. Es rápido, calculador y siempre está pensando en atajos.",
		"res://Scenes/Characters/cientifico_teleportador.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"mini_teletransporte",
			"Mini-teletransporte",
			"Se teletransporta a una sala adyacente a elección, apareciendo junto a su puerta.",
			"res://Sprites/Mini_teletransportelogo.png",
			30.0
		),
		_hab(
			"teletransporte_objeto",
			"Teletransporte de objeto",
			"Envía un objeto del inventario a una sala adyacente a elección. RIESGO: 20% de que el objeto aparezca en una sala aleatoria.",
			"res://Sprites/teletransportedeobjetologo.png",
			30.0
		)
	]

	c.habilidades = habs

	return c


# 4.3 ==================================================
# FORZUDO VEGETARIANO

func _crear_forzudo() -> CharacterData:

	var c := _pers(
		"forzudo",
		"Forzudo Vegetariano",
		"Un culturista amante de las verduras y defensor del tofu. Es fuerte, amable y muy literal. Prefiere resolver problemas a la fuerza antes que pensar demasiado.",
		"res://Scenes/Characters/FVegetariano.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"superfuerza",
			"Superfuerza",
			"Empuja grandes objetos, abre puertas atascadas o mueve obstáculos que bloquean el camino.",
			"res://Sprites/empujarlogo.png"
		),
		_hab(
			"golpe_suelo",
			"Golpe de suelo",
			"Provoca una vibración que desordena piezas del puzle de otro jugador en la misma sala o en salas adyacentes.",
			"res://Sprites/golpelogo.png",
			30.0,
			"golpe_suelo",
			true
		)
	]

	c.habilidades = habs

	return c


# 4.4 ==================================================
# NIÑO CIENTÍFICO

func _crear_nino() -> CharacterData:

	var c := _pers(
		"nino",
		"Niño Científico",
		"Un pequeño prodigio del laboratorio. Corretea por todas partes, toca todo lo que no debe y hace preguntas incómodas. Su tamaño y energía lo convierten en un personaje impredecible.",
		"res://Scenes/Characters/Niño.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"pasar_huecos",
			"Pasar por huecos",
			"Puede atravesar conductos, agujeros o espacios estrechos inaccesibles para otros.",
			"res://Sprites/pasarporhuecologo.png",
			20.0
		),
		_hab(
			"accion_impredecible",
			"Acción impredecible",
			"Hay un 80% de probabilidad de que el turno se prolongue 10 segundos. En el 20% restante, el Niño ignora la orden y se mueve en una dirección aleatoria durante 5 segundos.",
			"res://Sprites/accionimpredeciblelogo.png",
			30.0
		)
	]

	c.habilidades = habs

	return c

# 4.5 ==================================================
# ROBOT DEFECTUOSO

func _crear_robot() -> CharacterData:

	var c := _pers(
		"robot",
		"Robot Defectuoso",
		"Un robot experimental que nunca pasó la fase de pruebas. Tiene chispazos, pantallazos azules y un humor extraño. A veces es muy útil... y otras veces se apaga sin motivo.",
		"res://Scenes/Characters/Robot.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"descarga_electrica",
			"Descarga eléctrica",
			"Activa mecanismos eléctricos cercanos: abre puertas cerradas y energiza terminales apagados. Usar una batería del inventario la recarga al instante.",
			"res://Sprites/descargaelectricalogo.png",
			30.0
		),
		_hab(
			"cortocircuito",
			"Cortocircuito",
			"Apaga temporalmente una sala completa (incluyendo luces y mecanismos). RIESGO: 25% de apagarse él mismo durante un turno.",
			"res://Sprites/cortocircuitologo.png",
			30.0
		)
	]

	c.habilidades = habs

	return c


# 4.6 ==================================================
# ELECTRICISTA LOCO

func _crear_electricista() -> CharacterData:

	var c := _pers(
		"electricista",
		"Electricista Loco",
		"Un técnico obsesionado con los cables. Habla solo, mezcla colores sin mirar y asegura que todo funciona mejor si chispea un poco. Es caótico, pero sorprendentemente eficaz.",
		"res://Scenes/Characters/Electricista.tscn"
	)

	var habs: Array[HabilidadData] = [
		_hab(
			"mezcla_cables",
			"Mezcla de cables",
			"Abre una puerta cercana, pero un 50% de las veces cierra otra abierta al azar.",
			"res://Sprites/mezclacableslogo.png",
			30.0
		),
		_hab(
			"sobrecarga",
			"Sobrecarga",
			"Acelera un puzzle eléctrico cercano: mitad de cables conectados o parte de la respuesta del terminal ya escrita.",
			"res://Sprites/sobrecargalogo.png",
			30.0
		)
	]

	c.habilidades = habs

	return c


# CIENTÍFICO

func _crear_cientifico() -> CharacterData:

	var c := _pers(
		"cientifico",
		"Científico",
		"Un científico del laboratorio, metódico y observador. Prefiere analizar los mecanismos antes de actuar y resuelve los puzles con calma y precisión.",
		"res://Scenes/Characters/Cientifico.tscn"
	)

	c.habilidades = []

	return c


# CIENTÍFICA

func _crear_cientifica() -> CharacterData:

	var c := _pers(
		"cientifica",
		"Científica",
		"Una científica del laboratorio, brillante y meticulosa. Está acostumbrada a trabajar en equipo y sabe sacar partido a cualquier situación.",
		"res://Scenes/Characters/Cientifica.tscn"
	)

	c.habilidades = []

	return c
