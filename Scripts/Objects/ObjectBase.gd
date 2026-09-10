extends Node2D

class_name ObjectBase


# IDENTIFICACIÓN

@export var object_id: String = ""


# SUPERFICIE

enum Superficie {
	SUELO,
	PARED_ARRIBA,
	PARED_ABAJO,
	PARED_IZQUIERDA,
	PARED_DERECHA
}

@export var superficie: Superficie = Superficie.SUELO
