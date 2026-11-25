extends TouchScreenButton
@onready var ability_press: AnimationPlayer = %AbilityPress
@onready var swap_press: AnimationPlayer = %SwapPress
@onready var auto_press: AnimationPlayer = %AutoPress
@onready var player: Player = %Player

func _ready() -> void:
	position = get_parent().global_position #this is after 0.1.2.2

func _on_pressed() -> void:
	ability_press.play('ability_press')

func _on_released() -> void:
	ability_press.play_backwards("ability_press")

func _on_swap_touch_button_pressed() -> void:
	swap_press.play("swap_press")

func _on_swap_touch_button_released() -> void:
	swap_press.play_backwards("swap_press")

func _on_auto_aim_btn_pressed() -> void:
	auto_press.play("auto_press")
@onready var auto_aim_btn: TouchScreenButton = %AutoAimBtn

func _on_auto_aim_btn_released() -> void:
	swap_press.play_backwards("auto_press")
	match player.auto_aim:
		true:
			player.auto_aim = false
			auto_aim_btn.modulate.a = 0.5
		_:
			player.auto_aim = true
			auto_aim_btn.modulate.a = 1
