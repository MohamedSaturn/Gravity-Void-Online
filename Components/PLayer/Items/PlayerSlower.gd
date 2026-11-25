extends Area2D

@export var des_time = 1
@export var slow_color :Color
@onready var des_timer = $DesTimer
var player :CharacterBody2D = null
var defult_slower_modulate : Color


func slowness(target):
	defult_slower_modulate = target.get_node('collision').modulate
	target.max_speed /= 2
	target.modulate = slow_color


func un_slowness(target):
	target.max_speed = target.defult_max_speed
	target.modulate = target.defult_modulate


func _on_body_entered(body):
	if body.name == 'Player' and body.is_ability_active == false:
		if body.max_speed > 130 :
			slowness(body)


func _on_body_exited(body):
	if body.name == 'Player' and body.is_ability_active == false:
		if body.max_speed < 130 :
			un_slowness(body)


func _on_des_timer_timeout():
	queue_free()
