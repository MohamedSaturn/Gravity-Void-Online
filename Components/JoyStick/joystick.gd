extends Node2D
class_name Joystick

var pos_vector: Vector2
@export_enum('move','aim','ult') var joy_type = 'move' 
var touch_index := -1
var is_pressing = false
@onready var knob: Sprite2D = %Knob

func get_global_rect() -> Rect2:
	return Rect2(global_position - Vector2(75, 75), Vector2(150, 150))
