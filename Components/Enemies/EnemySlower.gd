# SlowArea.gd
extends Area2D

@export var des_time = 2.5
@export var slow_factor = 0.5  # How much to slow enemies (0.5 = 50% speed)
var affected_enemies = []
@onready var des_timer = $DesTimer
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("des")
	des_timer.wait_time = des_time
	# Set up monitoring
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func slowness(body):
	affected_enemies.append(body)
	# Store original speed and apply slow
	body.play_slow_anim(false)
	body.is_slowed = true
	body.set_meta("original_speed", body.speed)
	body.get_node('Coll').modulate = '#89c0ff'
	body.speed *= slow_factor

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		slowness(body)

func _on_body_exited(body: Node2D):
	if body.is_in_group("enemies"):
		affected_enemies.erase(body)
		# Restore original speed
		if body.has_meta("original_speed"):
			unslowness(body)


func unslowness(body):
	body.is_slowed = false
	body.play_slow_anim(true)
	body.speed = body.defult_speed
	body.get_node('Coll').modulate = body.defult_modulate
	body.remove_meta("original_speed")


func destroy():
	# Restore speed of all affected enemies before destroying
	for enemy in affected_enemies:
		if is_instance_valid(enemy) and enemy.has_meta("original_speed"):
			enemy.get_node('Coll').modulate = enemy.modulate
			enemy.speed = enemy.defult_speed
			enemy.remove_meta("original_speed")
	
	queue_free()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == 'des' :
		destroy()
