extends Node

class_name WallGenerator


# CONFIGURACIÓN

const ESCALA := 0.33
const ESCALA_INFERIOR := 0.38
const ESCALA_DANADA := 0.24
const ESCALA_ROTA := 0.18

const SOLAPE := 10

# Altura de dibujo (z_index) de las paredes dañadas y
# rotas: por encima de las paredes normales (z_index 0)
# para que sus grietas no queden tapadas por los solapes
# entre piezas vecinas ni por las esquinas entre paredes.
# El jugador usa z_index 2, así que sigue dibujándose
# por delante de todas las paredes.
const Z_PARED_ESPECIAL := 1

# Grosor de la colisión de las paredes
const GROSOR_COLISION := 16.0


# TEXTURAS

static var pared_superior = preload("res://Sprites/ps.png")
static var pared_inferior = preload("res://Sprites/pinf.png")
static var pared_vertical = preload("res://Sprites/pv.png")

static var pared_superior_danada = preload("res://Sprites/psdañada.png")
static var pared_inferior_danada = preload("res://Sprites/pinfdañada.png")
static var pared_vertical_danada = preload("res://Sprites/pvdañada.png")

static var pared_superior_rota = preload("res://Sprites/psrota.png")
static var pared_inferior_rota = preload("res://Sprites/pinfrota.png")
static var pared_vertical_rota = preload("res://Sprites/pvrota.png")


# REFERENCIA DE LAS PIEZAS ROTAS (PARA RECUPERAR)
# Las piezas rotas se han quitado de la generación: ahora
# las dañadas se convertirán en rotas con la mecánica del
# juego. Para recuperarlas con el MISMO tamaño y
# transformación, estos eran sus valores (los bloques
# eliminados en la última refactorización):
#  HORIZONTAL SUPERIOR (pared_superior_rota):
#    - escala = 0.325 (o 0.175 en el antiguo tamaño
#      pequeño de salas normales)
#    - 1 pieza centrada en un tramo de 3 celdas:
#      x = (tramo[0] + 2.0) * tam_celda  (celdas_tramo + 1 / 2.0)
#      y = SOLAPE + 2.0
#    - ancho de colisión = tam_celda * 0.70
#    - crear_pared_horizontal_especial(..., true, true)
#    - OJO: la escala X recibe +0.04 automáticamente en
#      crear_pared_horizontal_especial (ya conservado).
#  HORIZONTAL INFERIOR (pared_inferior_rota):
#    - escala = 0.39
#    - 1 pieza centrada en un tramo de 3 celdas:
#      x = (tramo[1]) -> usar la celda central del tramo
#      posicion + Vector2(0, 8)
#    - ancho de colisión = tam_celda * 0.70
#    - crear_pared_horizontal_especial(..., true, true)
#    - El resto de celdas del tramo solo colisión
#      (crear_pared_horizontal sin sprite).
#  VERTICAL (pared_vertical_rota):
#    - escala = ESCALA_ROTA (0.18)
#    - patrón de 3 celdas: rota + hueco + rota girada
#      * rota de arriba:   flip_h = invertir_base, pos + (0,8)
#      * hueco central:    sin sprite, solo colisión:
#        _crear_colision_vertical(parent, pos, tam_celda * 0.58)
#      * rota de abajo:    flip_h = not invertir_base,
#        pos + (0,8), rotar_180 = true
#    - ancho de colisión = tam_celda * 0.58
#    - crear_pared_vertical_especial(..., true, true, indice == 2)
#  Ayudantes eliminados que usaban:
#    - _expandir_tramo(): separaba el tramo dañado del roto.
#    - _crear_colision_vertical(): colisión del hueco roto.


# GENERAR TODAS LAS PAREDES

static func generar(
	parent: Node2D,
	data: RoomData
) -> void:

	# Cada sala tendrá siempre las mismas paredes
	seed(data.seed + 1)

	# Borrar paredes anteriores
	for hijo in parent.get_children():
		hijo.queue_free()

	if data.tipo == RoomData.TipoSala.INICIO:
		_generar_paredes_inicio(parent, data)
		return

	# Generar las cuatro paredes
	generar_superior(parent, data)
	generar_inferior(parent, data)

	generar_lateral_izquierda(parent, data)
	generar_lateral_derecha(parent, data)


# PAREDES ESPECIALES DE LA PRIMERA SALA

static func _generar_paredes_inicio(
	parent: Node2D,
	data: RoomData
) -> void:

	# La sala inicial también se conecta con puertas; se
	# excluyen igual que en el resto de salas para que las
	# paredes especiales no lleguen a taparlas.
	var puerta_arriba := int(data.ancho / 2.0) if data.puerta_arriba else -1
	var puerta_abajo := int(data.ancho / 2.0) if data.puerta_abajo else -1
	var puerta_izquierda := int(data.alto / 2.0) if data.puerta_izquierda else -1
	var puerta_derecha := int(data.alto / 2.0) if data.puerta_derecha else -1

	_generar_horizontal_superior(parent, data, puerta_arriba, 0.35, 3)
	_generar_horizontal_inferior(parent, data, puerta_abajo)
	_generar_lateral(parent, data, puerta_izquierda, false)
	_generar_lateral(parent, data, puerta_derecha, true)


# COLOCACIÓN DE TRAMOS DAÑADOS / ROTOS
# Reglas de las paredes especiales:
#  - Un solo tramo dañado y un solo tramo roto por lado.
#  - Nunca cerca de las puertas: mínimo un bloque de
#    separación y, cuando la pared tiene sitio, dos. Así
#    las piezas grandes, que sobresalen un poco del tramo,
#    nunca llegan a tapar el marco de la puerta.
#  - Nunca en las esquinas: el tramo deja libre la
#    primera y la última celda de la pared (las piezas
#    grandes se saldrían por ocupar varias celdas).
#  - En las paredes verticales el tramo dañado son 3
#    piezas seguidas (de tres en tres) y el tramo roto es
#    rota + hueco + rota girada 180 grados, para generar
#    el hueco.

static func _elegir_tramo(
	total: int,
	tamano: int,
	puerta: int,
	celdas_ocupadas: Array
) -> Array[int]:

	if tamano <= 0 or tamano > total:
		return []

	# Se intenta dejar primero 2 celdas libres entre el
	# tramo y la puerta (pensando en el saliente de las
	# piezas grandes); si la pared es pequeña y no hay
	# sitio, se deja al menos 1 celda.
	for margen in [2, 1]:

		var candidatos: Array[int] = []

		# Nunca en las esquinas: el tramo no toca ni la
		# primera ni la última celda de la pared.
		for inicio in range(1, total - tamano):

			var valido := true

			for i in range(inicio, inicio + tamano):

				if celdas_ocupadas.has(i):
					valido = false
					break

				# Separación con la puerta igual al
				# margen actual (2 si hay sitio, sino 1).
				if puerta >= 0 and abs(i - puerta) <= margen:
					valido = false
					break

			if valido:
				candidatos.append(inicio)

		if not candidatos.is_empty():
			var elegido: int = candidatos[randi() % candidatos.size()]

			var tramo: Array[int] = []
			for i in range(tamano):
				tramo.append(elegido + i)

			return tramo

	return []


# COLISIÓN SIN SPRITE (PAREDES ESPECIALES)
# Las piezas dañadas cubren varias celdas: la celda
# central lleva el sprite y las laterales solo colisión
# para que la pared siga siendo sólida.

static func _crear_colision_horizontal(
	parent: Node2D,
	posicion: Vector2,
	tam_celda: float
) -> void:

	var cuerpo := StaticBody2D.new()
	cuerpo.name = "WallCollision"
	cuerpo.position = posicion
	parent.add_child(cuerpo)

	var collision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(tam_celda, GROSOR_COLISION)
	collision.shape = forma
	cuerpo.add_child(collision)


# CREAR PARED DAÑADA INTERACTIVA
# Instancia una ParedDanada (con su zona de interacción
# y el prompt "ROMPER") en lugar del sprite suelto.
# Reproduce el mismo aspecto y colisión que las piezas
# dañadas normales.

static func _crear_pared_danada_interactiva(
	parent: Node2D,
	posicion: Vector2,
	textura: Texture2D,
	escala: float,
	escala_x_extra: bool,
	tamano_colision: Vector2,
	invertir_horizontal: bool
) -> void:

	var pared := ParedDanada.new()

	pared.position = posicion

	pared.textura = textura

	pared.escala = escala

	pared.escala_x_extra = escala_x_extra

	pared.tamano_colision = tamano_colision

	pared.invertir_horizontal = invertir_horizontal

	parent.add_child(pared)


# PARED SUPERIOR (COMPARTIDA)
# Solo piezas dañadas: ocupan 3 celdas de ancho y se
# quitan las paredes normales de debajo, dejando solo
# su colisión. El tramo reserva 3 celdas.
# Más adelante las dañadas podrán convertirse en rotas;
# cuando se añada esa mecánica se recuperará la
# generación de piezas rotas.

static func _generar_horizontal_superior(
	parent: Node2D,
	data: RoomData,
	puerta: int,
	escala_danada: float,
	celdas_tramo: int
) -> void:

	var total := data.ancho

	# Solo puede haber paredes dañadas si hay otra sala
	# conectada al otro lado. Si no hay sala arriba, la
	# pared da hacia "fuera" del laboratorio y se queda
	# limpia.
	var tramo_danada: Array[int] = []
	if data.arriba != -1:
		tramo_danada = _elegir_tramo(
			total, celdas_tramo, puerta, []
		)

	for x in range(total):

		# Si hay puerta arriba, dejamos un hueco
		if puerta >= 0 and x == puerta:
			continue

		var posicion := Vector2(
			(x + 1) * data.tam_celda,
			SOLAPE
		)

		# Tramo dañado: una pieza centrada en el tramo
		if tramo_danada.has(x):
			if x == tramo_danada[0]:
				var centro_danada_x: float = (
					(tramo_danada[0] + (celdas_tramo + 1) / 2.0)
					* data.tam_celda
				)
				_crear_pared_danada_interactiva(
					parent,
					Vector2(centro_danada_x, SOLAPE),
					pared_superior_danada,
					escala_danada,
					true,
					Vector2(data.tam_celda * 0.85, GROSOR_COLISION * 0.75),
					false
				)
			else:
				# Celda cubierta por la pieza dañada: sin
				# sprite, solo colisión.
				_crear_colision_horizontal(
					parent,
					posicion,
					data.tam_celda
				)
			continue

		crear_pared_horizontal_especial(
			parent,
			posicion,
			pared_superior,
			ESCALA,
			data.tam_celda * 0.95,
			false,
			false
		)


# PARED INFERIOR (COMPARTIDA)
# Solo piezas dañadas: son grandes (ocupan 3 celdas de
# ancho), por eso su tramo reserva 3 celdas y se quitan
# las paredes normales de debajo. Las celdas cubiertas
# mantienen la colisión para que la pared siga sólida.

static func _generar_horizontal_inferior(
	parent: Node2D,
	data: RoomData,
	puerta: int
) -> void:

	var total := data.ancho

	# Solo puede haber paredes dañadas si hay otra sala
	# conectada al otro lado (abajo).
	var tramo_danada: Array[int] = []
	if data.abajo != -1:
		tramo_danada = _elegir_tramo(total, 3, puerta, [])

	for x in range(total):

		# Si hay puerta abajo, dejamos un hueco
		if puerta >= 0 and x == puerta:
			continue

		var posicion := Vector2(
			(x + 1) * data.tam_celda,
			(data.alto + 1) * data.tam_celda - SOLAPE
		)

		# Tramo dañado: una pieza centrada en el tramo
		if tramo_danada.has(x):
			if x == tramo_danada[1]:
				_crear_pared_danada_interactiva(
					parent,
					posicion,
					pared_inferior_danada,
					0.38,
					false,
					Vector2(data.tam_celda * 0.85, GROSOR_COLISION * 0.75),
					false
				)
			else:
				# Celda cubierta por la pieza dañada: sin
				# sprite, solo colisión.
				_crear_colision_horizontal(
					parent,
					posicion,
					data.tam_celda
				)
			continue

		crear_pared_horizontal_especial(
			parent,
			posicion,
			pared_inferior,
			ESCALA_INFERIOR,
			data.tam_celda * 0.95,
			false,
			false
		)


# PAREDES VERTICALES (COMPARTIDAS)
# Solo piezas dañadas: el tramo dañado son 3 piezas
# seguidas (de tres en tres).
# invertir_base: la pared derecha usa la textura
# reflejada.

static func _generar_lateral(
	parent: Node2D,
	data: RoomData,
	puerta: int,
	invertir_base: bool
) -> void:

	var total := data.alto

	# Solo puede haber paredes dañadas si hay otra sala
	# conectada al otro lado (izquierda o derecha según
	# la pared que se esté generando).
	var conectada: bool = data.izquierda != -1
	if invertir_base:
		conectada = data.derecha != -1

	var tramo_danada: Array[int] = []
	if conectada:
		tramo_danada = _elegir_tramo(total, 3, puerta, [])

	var posicion_x := (
		(data.ancho + 1) * data.tam_celda - SOLAPE
		if invertir_base
		else SOLAPE
	)

	for y in range(total):

		# Si hay puerta en este lado, dejamos un hueco
		if puerta >= 0 and y == puerta:
			continue

		var posicion := Vector2(
			posicion_x,
			(y + 1) * data.tam_celda
		)

		if tramo_danada.has(y):
			_crear_pared_danada_interactiva(
				parent,
				posicion,
				pared_vertical_danada,
				0.14,
				false,
				Vector2(GROSOR_COLISION * 0.75, data.tam_celda * 0.55),
				invertir_base
			)
			continue

		crear_pared_vertical_especial(
			parent,
			posicion,
			pared_vertical,
			ESCALA,
			data.tam_celda * 0.95,
			invertir_base,
			false
		)


# PARED SUPERIOR

static func generar_superior(
	parent: Node2D,
	data: RoomData
) -> void:

	var puerta := int(data.ancho / 2.0) if data.puerta_arriba else -1

	_generar_horizontal_superior(parent, data, puerta, 0.35, 3)


# PARED INFERIOR

static func generar_inferior(
	parent: Node2D,
	data: RoomData
) -> void:

	var puerta := int(data.ancho / 2.0) if data.puerta_abajo else -1

	_generar_horizontal_inferior(parent, data, puerta)


# PARED IZQUIERDA

static func generar_lateral_izquierda(
	parent: Node2D,
	data: RoomData
) -> void:

	var puerta := int(data.alto / 2.0) if data.puerta_izquierda else -1

	_generar_lateral(parent, data, puerta, false)


# PARED DERECHA

static func generar_lateral_derecha(
	parent: Node2D,
	data: RoomData
) -> void:

	var puerta := int(data.alto / 2.0) if data.puerta_derecha else -1

	_generar_lateral(parent, data, puerta, true)


# CREAR PARED HORIZONTAL ESPECIAL

static func crear_pared_horizontal_especial(
	parent: Node2D,
	posicion: Vector2,
	textura: Texture2D,
	escala: float,
	tam_celda: float,
	usar_colision_pequena: bool,
	usar_modulacion_rota: bool
) -> void:

	var sprite := Sprite2D.new()

	sprite.texture = textura
	if textura == pared_superior_danada or textura == pared_superior_rota:
		sprite.scale = Vector2(escala + 0.04, escala)
	else:
		sprite.scale = Vector2.ONE * escala
	sprite.position = posicion

	if usar_modulacion_rota:
		sprite.modulate = Color(0.9, 0.82, 0.76, 1.0)

		# Dañada o rota: dibujar por encima de las paredes
		# normales para que las grietas siempre se vean.
		sprite.z_index = Z_PARED_ESPECIAL

	parent.add_child(sprite)

	if usar_colision_pequena:
		var cuerpo := StaticBody2D.new()
		cuerpo.name = "WallCollision"
		cuerpo.position = posicion
		parent.add_child(cuerpo)

		var collision := CollisionShape2D.new()
		var forma := RectangleShape2D.new()
		forma.size = Vector2(tam_celda, GROSOR_COLISION * 0.75)
		collision.shape = forma
		cuerpo.add_child(collision)
		return

	var cuerpo_base := StaticBody2D.new()
	cuerpo_base.name = "WallCollision"
	cuerpo_base.position = posicion
	parent.add_child(cuerpo_base)

	var collision_base := CollisionShape2D.new()
	var forma_base := RectangleShape2D.new()
	forma_base.size = Vector2(tam_celda, GROSOR_COLISION)
	collision_base.shape = forma_base
	cuerpo_base.add_child(collision_base)


# CREAR PARED HORIZONTAL

static func crear_pared_horizontal(
	parent: Node2D,
	posicion: Vector2,
	textura: Texture2D,
	escala: float,
	tam_celda: float
) -> void:

	# SPRITE

	var sprite := Sprite2D.new()

	sprite.texture = textura
	sprite.scale = Vector2.ONE * escala
	sprite.position = posicion

	parent.add_child(sprite)


	# COLISIÓN

	var cuerpo := StaticBody2D.new()

	cuerpo.name = "WallCollision"

	cuerpo.position = posicion

	parent.add_child(cuerpo)


	var collision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	forma.size = Vector2(
		tam_celda,
		GROSOR_COLISION
	)

	collision.shape = forma

	cuerpo.add_child(collision)


# CREAR PARED VERTICAL ESPECIAL

static func crear_pared_vertical_especial(
	parent: Node2D,
	posicion: Vector2,
	textura: Texture2D,
	escala: float,
	tam_celda: float,
	invertir_horizontal: bool,
	usar_modulacion_rota: bool,
	rotar_180: bool = false
) -> void:

	var sprite := Sprite2D.new()

	sprite.texture = textura
	sprite.scale = Vector2.ONE * escala
	sprite.flip_h = invertir_horizontal
	sprite.position = posicion

	if rotar_180:
		# La rota de debajo del hueco se gira 180 grados
		# para que su borde roto mire hacia el hueco.
		sprite.rotation = PI

	if usar_modulacion_rota:
		sprite.modulate = Color(0.9, 0.82, 0.76, 1.0)

		# Dañada o rota: dibujar por encima de las paredes
		# normales para que las grietas siempre se vean.
		sprite.z_index = Z_PARED_ESPECIAL

	parent.add_child(sprite)

	var cuerpo := StaticBody2D.new()
	cuerpo.name = "WallCollision"
	cuerpo.position = posicion
	parent.add_child(cuerpo)

	var collision := CollisionShape2D.new()
	var forma := RectangleShape2D.new()
	forma.size = Vector2(GROSOR_COLISION * 0.75, tam_celda)
	collision.shape = forma
	cuerpo.add_child(collision)


# CREAR PARED VERTICAL

static func crear_pared_vertical(
	parent: Node2D,
	posicion: Vector2,
	textura: Texture2D,
	escala: float,
	invertir_horizontal: bool,
	tam_celda: float
) -> void:

	# SPRITE

	var sprite := Sprite2D.new()

	sprite.texture = textura
	sprite.scale = Vector2.ONE * escala

	# Reflejar la textura para la derecha
	sprite.flip_h = invertir_horizontal

	sprite.position = posicion

	parent.add_child(sprite)


	# COLISIÓN

	var cuerpo := StaticBody2D.new()

	cuerpo.name = "WallCollision"

	cuerpo.position = posicion

	parent.add_child(cuerpo)


	var collision := CollisionShape2D.new()

	var forma := RectangleShape2D.new()

	forma.size = Vector2(
		GROSOR_COLISION,
		tam_celda
	)

	collision.shape = forma

	cuerpo.add_child(collision)
