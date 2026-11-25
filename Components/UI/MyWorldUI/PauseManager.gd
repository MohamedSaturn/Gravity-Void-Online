extends ColorRect

var is_game_paused = false
@onready var player: Player = %Player

#func _on_pause_gui_input(event: InputEvent) -> void:
	#if (event is InputEventMouseButton and event.pressed\
	#and event.button_index == MOUSE_BUTTON_LEFT)\
	#or (event is InputEventScreenTouch and event.pressed):
		#pause_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('pause'):
		if not player.is_player_died:
			match is_game_paused:
				true:
					unpause_game()
				false:
					pause_game()

func pause_game():
	%PauseManager.show()
	is_game_paused = true
	Engine.time_scale = 0

func unpause_game():
	%PauseManager.hide()
	is_game_paused = false
	Engine.time_scale = 1

func _on_pause_dialog_continue_pressed() -> void:
	unpause_game()

func _on_pause_btn_pressed() -> void:
	pause_game()
