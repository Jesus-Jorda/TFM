extends Node

class_name TerminalBanco


# BATERÍA DE PREGUNTAS
# Banco compartido de preguntas/respuestas de los
# terminales. Cada terminal de la partida recibe un
# índice fijo (asignado por TerminalGenerator.dar_terminal),
# de modo que un NUNCA cambia de pregunta.

static var bateria_terminal: Array[Dictionary] = [
	{
		"pregunta": "Calcula: 2 + 3",
		"respuesta": "5"
	},
	{
		"pregunta": "Calcula: 9 - 4",
		"respuesta": "5"
	},
	{
		"pregunta": "Calcula: 3 × 4",
		"respuesta": "12"
	},
	{
		"pregunta": "Calcula: 15 ÷ 3",
		"respuesta": "5"
	},
	{
		"pregunta": "¿Qué personaje activa electricidad?",
		"respuesta": "robot"
	},
	{
		"pregunta": "¿Qué personaje pasa por huecos?",
		"respuesta": "nino"
	},
	{
		"pregunta": "¿Qué objeto da fuerza al forzudo?",
		"respuesta": "barrita"
	},
	{
		"pregunta": "¿Qué objeto da energía rápida?",
		"respuesta": "cafe"
	},
	{
		"pregunta": "¿Qué objeto necesitas para encender un terminal apagado?",
		"respuesta": "bateria"
	},
	{
		"pregunta": "¿Qué personaje puede mover una caja metálica pesada?",
		"respuesta": "forzudo"
	},
	{
		"pregunta": "¿Qué personaje puede teletransportarse cerca para esquivar obstáculos?",
		"respuesta": "cientifico"
	},
	{
		"pregunta": "¿Qué personaje puede reparar un mecanismo averiado?",
		"respuesta": "ingeniera"
	},
	{
		"pregunta": "¿Qué objeto sirve para arreglar temporalmente un cable suelto?",
		"respuesta": "cinta"
	},
	{
		"pregunta": "¿Qué personaje está especializado en cables y circuitos?",
		"respuesta": "electricista"
	},
]
