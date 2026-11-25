extends Joystick
class_name UltimateJoystick

#@export var ult_btn : TouchScreenButton #aftor 0.1.2.2

var distant:float

@onready var player               :Player = %Player
@onready var ability_touch_button :TouchScreenButton = %AbilityTouchButton
@onready var ult_pregress_bar     :TextureProgressBar = %UltProgressBar

func _process(delta: float) -> void:
	distant = knob.position.distance_to(Vector2.ZERO)
	$Label.text = str(distant)
	ability_touch_button.global_position = knob.global_position
	if player.is_ability_active == true :
		ult_pregress_bar.max_value = player.ability_delay_timer.wait_time
		ult_pregress_bar.value = player.ability_delay_timer.time_left
	else :
		ult_pregress_bar.max_value = player.ability_max_charge
		ult_pregress_bar.value = player.current_ability_charge
	#%UltBar.value = ult_pregress_bar.value
	#%UltBar.max_value = ult_pregress_bar.max_value

func _on_knob_joystick_released() -> void:
	if distant > 17.5:
		if not player.current_ability_charge >= player.ability_max_charge:return
		player.ActivateAbility()
