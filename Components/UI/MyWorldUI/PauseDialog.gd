extends PanelContainer
class_name PauseDialog
signal continue_pressed

func _on_contine_pressed():
	emit_signal('continue_pressed')

var main_menu = "res://Components/UI/MainMenu/MainMenu.tscn"
const MY_WORLD = "res://Components/Modes/MyWorld.tscn"

func _on_back_pressed():
	get_tree().change_scene_to_file(main_menu)
	Engine.time_scale = 1

func _on_quit_pressed():
	get_tree().quit()

@onready var confirm_retry_dia: PanelContainer = %ConfirmRetryDia

func _on_retry_pressed() -> void:
	confirm_retry_dia.show()

func _on_confirm_pressed() -> void:
	get_tree().change_scene_to_file(MY_WORLD)

func _on_cancel_pressed() -> void:
	confirm_retry_dia.hide()

@onready var player: Player = %Player

func _on_hype_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		player.max_health = 100000
		player.add_health(100000)
		player.max_speed = 333
	else:
		player.max_health = 100
		player.current_health = 100
		player.max_speed = player.defult_max_speed

func _on_ult_charge_pressed() -> void:
	player.charge_ability(player.ability_max_charge)
