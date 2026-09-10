extends Node


# SESIÓN DE JUEGO (AUTOLOAD)
# Guarda el personaje elegido en la pantalla de
# selección para que Main, la interfaz y los botones
# lo consulten. Persiste entre escenas.

signal personaje_cambiado(id: String)

const ID_POR_DEFECTO := "patosa"

var _personaje_id: String = ""


# PARTIDA MULTIUSUARIO (HOT-SEAT)
# Número de jugadores (1-8) y sus elecciones de
# personaje en orden. Persiste entre escenas.

var numero_jugadores: int = 1

var selecciones: Array = []

var jugador_en_turno: int = 0

var tiempo_inicio_partida_msec: int = 0
var orden_llegada: Array[String] = []


func seleccionar_personaje(id: String) -> void:

	_personaje_id = id

	personaje_cambiado.emit(id)


func personaje_actual() -> CharacterData:

	var datos := CatalogoPersonajes.obtener(
		_personaje_id
	)

	if datos != null:
		return datos

	return CatalogoPersonajes.obtener(ID_POR_DEFECTO)


func hay_seleccion() -> bool:

	return _personaje_id != ""


# CONFIGURAR LA PARTIDA

func configurar_partida(num_jugadores: int) -> void:

	numero_jugadores = clampi(num_jugadores, 1, 8)

	selecciones = []

	jugador_en_turno = 0

	_personaje_id = ""
	tiempo_inicio_partida_msec = Time.get_ticks_msec()
	orden_llegada.clear()


func registrar_llegada(nombre: String) -> void:
	if not orden_llegada.has(nombre):
		orden_llegada.append(nombre)


func tiempo_partida_segundos() -> int:
	if tiempo_inicio_partida_msec <= 0:
		return 0
	return maxi(0, int((Time.get_ticks_msec() - tiempo_inicio_partida_msec) / 1000))


# REGISTRAR LA ELECCIÓN DEL JUGADOR EN TURNO

func registrar_seleccion(id: String) -> void:

	if selecciones.size() < numero_jugadores:

		selecciones.append(id)

	# Compatibilidad con el flujo antiguo de un solo
	# personaje: el último elegido queda como actual.
	seleccionar_personaje(id)


# ¿QUIÉN HA ELEGIDO ESE PERSONAJE?
# Devuelve el número del jugador (1-based) que ya
# eligió ese personaje, o 0 si sigue libre.

func jugador_que_eligio(id: String) -> int:

	return selecciones.find(id) + 1


# PASAR AL SIGUIENTE JUGADOR (SELECCIÓN)

func avanzar_turno_seleccion() -> void:

	jugador_en_turno = mini(
		jugador_en_turno + 1, numero_jugadores
	)


# ¿YA HAN ELEGIDO TODOS?

func seleccion_completa() -> bool:

	return selecciones.size() >= numero_jugadores


# PERSONAJES DE LA PARTIDA (UNO POR JUGADOR, EN ORDEN)

func personajes_en_juego() -> Array:

	var lista: Array = []

	for id in selecciones:

		var datos := CatalogoPersonajes.obtener(id)

		if datos != null:
			lista.append(datos)

	return lista
