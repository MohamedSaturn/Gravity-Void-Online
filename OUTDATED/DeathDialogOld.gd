extends ColorRect


const TESTWORLD = "res://Scenes/MyWorld.tscn"
const MAIN_MENU = "res://Scenes/MainMenu.tscn"


func _on_retry_pressed():
	get_tree().change_scene_to_file(TESTWORLD)


func _on_exit_pressed():
	get_tree().change_scene_to_file(MAIN_MENU)
