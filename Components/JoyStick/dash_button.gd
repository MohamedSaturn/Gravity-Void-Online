extends Node2D
class_name DashButton
@onready var dash_pregress_bar: TextureProgressBar = %DashPregressBar

func _ready() -> void:
	dash_pregress_bar.get_parent().global_position = global_position
