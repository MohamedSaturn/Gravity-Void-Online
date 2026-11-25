extends Area2D
class_name Explosion

@onready var explo_part = $ExploPart
@onready var animation_player = $AnimationPlayer
@onready var des_timer = $DesTimer
@onready var coll = %Coll

@export var damage = 33
@export var des_time = 2
@export var auto_explode = true

var boss_ability_is_active = false
var damage_player = true
var damage_enemy = true
var player :Player

func _ready():
	explode()
	damage_player = true

func explode():
	damage_player = true
	explo_part.lifetime = des_time
	des_timer.wait_time = des_time / explo_part.speed_scale
	animation_player.play("explode")
	des_timer.start()
	coll.show()
	if player:
		player.call_deferred("camera_shake")

func _on_body_entered(body :Node2D):
	if body == player:
		if player.can_take_explo_damage == true and damage_player == true \
		and body and player:
			body.take_damage(damage,boss_ability_is_active)
			coll.call_deferred('disabled',true)
			damage_player = false
			player.can_take_explo_damage = false
			await get_tree().create_timer(0.1).timeout
			player.can_take_explo_damage = true
	elif body is BaseEnemy:
		if not damage_enemy:return
		body.take_damage(damage)

func des_obj():
	queue_free()

func _on_des_timer_timeout():
	des_obj()
