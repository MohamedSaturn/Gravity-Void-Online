extends ColorRect
class_name DeathDialog

const TESTWORLD = "res://Components/Modes/MyWorld.tscn"
const MAIN_MENU = "res://Components/UI/MainMenu/MainMenu.tscn"

func _on_retry_pressed():
	get_tree().change_scene_to_file(TESTWORLD)
	Global

func _on_menu_pressed():
	get_tree().change_scene_to_file(MAIN_MENU)

func play(kills:int=0,time:String=''):
	if kills != 0 :
		%Kills.show()
		%Kills.text = 'You got '+str(kills)+' kills and survived for '+time
	%AnimationPlayerDeath.play("death_anim")
