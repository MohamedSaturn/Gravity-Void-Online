class_name Spear
extends Area2D
signal attack_ended
signal hits_player(shooter:SpearEnemy)
var direction 
var shooter:SpearEnemy
@export var damage = 9
@export var damage_aftr_drop = 18
@export var speed = 440
@onready var animation_player = %AnimationPlayer
@export var droped = false


func _physics_process(delta):
	position += direction * speed * delta


func _on_body_entered(body):
	if body.has_method("collisions") :
		destroy()
	elif body.is_in_group('player') :
		body.take_damage(damage)
		emit_signal('hits_player',shooter)


func throw_spear():
	damage = damage_aftr_drop
	animation_player.play("throw_spear")


func attack():
	animation_player.play("attack")


func destroy():
	await get_tree().create_timer(0.5).timeout
	queue_free()
