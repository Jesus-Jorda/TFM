extends Node

class_name LaboratoryTypeGenerator


static func calcular_distancias(salas : Array[RoomData]) -> void:

	# Reiniciar
	for sala in salas:
		sala.distancia_inicio = -1

	var cola : Array[int] = []

	# La sala inicial siempre es la 0
	salas[0].distancia_inicio = 0

	cola.append(0)

	while !cola.is_empty():

		var indice = cola.pop_front()

		var sala = salas[indice]

		for vecino in sala.vecinos:

			if salas[vecino].distancia_inicio == -1:

				salas[vecino].distancia_inicio = sala.distancia_inicio + 1

				cola.append(vecino)
