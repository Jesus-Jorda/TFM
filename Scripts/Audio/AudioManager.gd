extends Node

class_name AudioManager


# STREAMS

const MUSICA_FONDO: AudioStream = preload(
	"res://Audio/Music/Quantum Jelly Lab.mp3"
)

const SONIDO_PUERTAS := [
	preload("res://Audio/Doors/puerta1.mp3"),
	preload("res://Audio/Doors/puerta2.mp3"),
	preload("res://Audio/Doors/puerta3.mp3")
]

# Efectos del juego (se llaman por nombre)
const EFECTOS := {
	"encender": preload("res://Audio/encender.mp3"),
	"apagar": preload("res://Audio/apagar.mp3"),
	"coger": preload("res://Audio/coger.mp3"),
	"clic": preload("res://Audio/clic.mp3"),
	"recoger": preload("res://Audio/recoger2.mp3"),
	"consumir": preload("res://Audio/consumirobjeto.mp3"),
	"comer": preload("res://Audio/comerobjeto.mp3"),
	"soltar": preload("res://Audio/soltar.mp3"),
	"reparar": preload("res://Audio/reparar.mp3"),
	"romper": preload("res://Audio/romper.mp3"),
	"habgolpe": preload("res://Audio/habgolpe.mp3"),
	"arrastrarcaja": preload("res://Audio/arrastrarcaja.mp3"),
	"finturno": preload("res://Audio/finturno.mp3"),
	"victoriaindividual": preload("res://Audio/victoriaindividual.mp3"),
	"puertaabierta": preload("res://Audio/puertaabierta.mp3"),
	"respuestacorrecta": preload("res://Audio/respuestacorrecta.mp3"),
	"respuestaincorrecta": preload("res://Audio/respuestaincorrecta.mp3"),
	"cableresuelto": preload("res://Audio/cableresuelto.mp3"),
	"laserresuelto": preload("res://Audio/laserresuelto.mp3"),
	"errorinteraccion": preload("res://Audio/errorinteraccion.mp3"),
	"conductoventilacion": preload("res://Audio/conductoventilacion.mp3"),
	"cerrarpuerta": preload("res://Audio/cerrarpuerta.mp3")
}

const VOLUMENES_EFECTOS := {
	"arrastrarcaja": -14.0,
	"finturno": -10.0,
	"victoriaindividual": -7.0,
	"laserresuelto": -12.0,
	"cableresuelto": -10.0,
	"conductoventilacion": -10.0,
	"respuestacorrecta": -10.0,
	"respuestaincorrecta": -12.0,
	"errorinteraccion": -12.0
}


# REPRODUCTORES

var musica_player: AudioStreamPlayer

var efectos_players: Array[AudioStreamPlayer] = []

var efecto_actual: int = 0


# READY

func _ready() -> void:

	add_to_group("gestor_audio")

	_configurar_buses()

	_crear_musica()


	for i in range(4):

		var player := AudioStreamPlayer.new()

		player.bus = "Efectos"

		add_child(player)

		efectos_players.append(player)


	set_volumen_musica(0.01)

	set_volumen_efectos(1.0)


# BUSES DE AUDIO

func _configurar_buses() -> void:

	if AudioServer.get_bus_index("Musica") == -1:

		AudioServer.add_bus()

		AudioServer.set_bus_name(
			AudioServer.bus_count - 1,
			"Musica"
		)

	if AudioServer.get_bus_index("Efectos") == -1:

		AudioServer.add_bus()

		AudioServer.set_bus_name(
			AudioServer.bus_count - 1,
			"Efectos"
		)


# MÚSICA DE FONDO

func _crear_musica() -> void:

	musica_player = AudioStreamPlayer.new()

	musica_player.name = "MusicaFondo"

	musica_player.bus = "Musica"

	var stream := MUSICA_FONDO as AudioStreamMP3

	if stream:
		stream.loop = true

	musica_player.stream = stream

	add_child(musica_player)

	musica_player.play()


# REPRODUCIR EFECTO POR NOMBRE
# Nombres: encender, apagar, coger, soltar,
# reparar, romper, desbloqueo, habgolpe.

func reproducir_efecto(nombre: String) -> void:

	if not EFECTOS.has(nombre):
		return

	if efectos_players.is_empty():
		return

	var player: AudioStreamPlayer = efectos_players[efecto_actual]

	efecto_actual = (efecto_actual + 1) % efectos_players.size()

	player.stream = EFECTOS[nombre]
	player.volume_db = float(VOLUMENES_EFECTOS.get(nombre, -8.0))
	player.play()


func reproducir_efecto_corto(nombre: String, duracion: float = 0.8, volumen_db: float = -8.0) -> void:
	if not EFECTOS.has(nombre) or efectos_players.is_empty():
		return

	var player: AudioStreamPlayer = efectos_players[efecto_actual]
	efecto_actual = (efecto_actual + 1) % efectos_players.size()
	player.stream = EFECTOS[nombre]
	player.volume_db = volumen_db + float(VOLUMENES_EFECTOS.get(nombre, 0.0))
	player.play()
	get_tree().create_timer(duracion).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.stop()
			player.volume_db = 0.0
	)


func reproducir_habilidad(nombre_archivo: String, duracion: float = 0.0) -> void:
	var ruta := "res://Audio/" + nombre_archivo + ".mp3"
	if not ResourceLoader.exists(ruta) or efectos_players.is_empty():
		return

	var player: AudioStreamPlayer = efectos_players[efecto_actual]
	efecto_actual = (efecto_actual + 1) % efectos_players.size()
	player.stream = load(ruta) as AudioStream
	player.volume_db = -8.0
	player.play()

	if duracion > 0.0:
		get_tree().create_timer(duracion).timeout.connect(func() -> void:
			if is_instance_valid(player):
				player.stop()
				player.volume_db = 0.0
		)


# SONIDO ALEATORIO DE PUERTA

func reproducir_puerta() -> void:

	if SONIDO_PUERTAS.is_empty() or efectos_players.is_empty():
		return

	var player: AudioStreamPlayer = efectos_players[efecto_actual]

	efecto_actual = (efecto_actual + 1) % efectos_players.size()

	player.stream = SONIDO_PUERTAS.pick_random()

	player.play()


# VOLÚMENES (0.0 - 1.0)

func set_volumen_musica(valor: float) -> void:

	var idx := AudioServer.get_bus_index("Musica")

	if idx == -1:
		return

	AudioServer.set_bus_volume_db(
		idx,
		linear_to_db(clampf(valor, 0.0, 1.0))
	)


func set_volumen_efectos(valor: float) -> void:

	var idx := AudioServer.get_bus_index("Efectos")

	if idx == -1:
		return

	AudioServer.set_bus_volume_db(
		idx,
		linear_to_db(clampf(valor, 0.0, 1.0))
	)


func get_volumen_musica() -> float:

	var idx := AudioServer.get_bus_index("Musica")

	if idx == -1:
		return 1.0

	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func get_volumen_efectos() -> float:

	var idx := AudioServer.get_bus_index("Efectos")

	if idx == -1:
		return 1.0

	return db_to_linear(AudioServer.get_bus_volume_db(idx))


# SILENCIAR MÚSICA / EFECTOS
# Silencia el bus completo sin perder el volumen
# configurado en los sliders.

func set_silencio_musica(silencio: bool) -> void:

	var idx := AudioServer.get_bus_index("Musica")

	if idx != -1:
		AudioServer.set_bus_mute(idx, silencio)


func esta_musica_silenciada() -> bool:

	var idx := AudioServer.get_bus_index("Musica")

	return idx != -1 and AudioServer.is_bus_mute(idx)


func set_silencio_efectos(silencio: bool) -> void:

	var idx := AudioServer.get_bus_index("Efectos")

	if idx != -1:
		AudioServer.set_bus_mute(idx, silencio)


func esta_efectos_silenciado() -> bool:

	var idx := AudioServer.get_bus_index("Efectos")

	return idx != -1 and AudioServer.is_bus_mute(idx)
