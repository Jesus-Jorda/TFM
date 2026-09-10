extends Node2D

class_name ConductoVentilacion

var objeto_datos: ObjectData = null

func _ready() -> void:
	add_to_group("conductos_ventilacion")
