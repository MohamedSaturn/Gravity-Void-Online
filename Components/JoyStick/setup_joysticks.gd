extends Node2D ##he have to staly Node2D tm make the drag work

@onready var control_node: Control = %Control
@onready var opacity_slider: HSlider = %OpacitySlider
@onready var nodes: Node2D = $nodes
@onready var movement_joy: Area2D = %MovementJoy
@onready var shooting_joy: Area2D = %ShootingJoy
@onready var ultimate_joy: Area2D = %UltimateJoy
@onready var dash_button: Area2D = %DashButton

func _ready() -> void:
	control_node.modulate.a = Global.controles_data.opacity 
	movement_joy.position = Global.controles_data.move
	shooting_joy.position = Global.controles_data.aim
	ultimate_joy.position = Global.controles_data.ult
	dash_button.position = Global.controles_data.dash

func _on_h_slider_drag_ended(value_changed: bool) -> void:
	var final_value :float = opacity_slider.value
	nodes.modulate.a = final_value
	Global.controles_data.opacity = final_value

const MainMenu = "res://Components/UI/MainMenu/MainMenu.tscn"

func _on_save_pressed() -> void:
		get_tree().change_scene_to_file(MainMenu)

func _on_visibility_changed() -> void:
	if control_node == null:return
	control_node.visible = visible
