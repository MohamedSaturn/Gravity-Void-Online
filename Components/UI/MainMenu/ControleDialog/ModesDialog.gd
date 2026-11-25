extends Control
const game_scene = "res://Components/Modes/MyWorld.tscn"
const ffa_lobby = ("res://Components/Multiplayer/FFALobby.tscn")

func _ready() -> void:
	load(game_scene)

func _on_back_pressed():
	hide()

func _on_boss_button_pressed() -> void:
	Global.selected_gamemode = 'boss'
	get_tree().change_scene_to_file(game_scene)

func _on_score_button_pressed() -> void:
	Global.selected_gamemode = 'score'
	get_tree().change_scene_to_file(game_scene)

func _on_trainn_button_pressed() -> void:
	Global.selected_gamemode = 'train'
	get_tree().change_scene_to_file(game_scene)

func _on_ffa_button_pressed() -> void:
	get_tree().change_scene_to_file(ffa_lobby)
