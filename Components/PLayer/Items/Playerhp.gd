extends DroppedItem
class_name HealthCube

@export var amount = 10
var max_speed = 200
var is_follow = false
var can_start_follow = true
var direction :Vector2
var player :Player

@onready var animation_player = $AnimationPlayer
@onready var collision: CollisionShape2D = %Coll

func _ready(): 
	coll = collision
	animation_player.play("start")
	spawn_tween(collision)
	await get_tree().create_timer(despawn_timer).timeout
	if is_follow:
		return
	spawn_tween(collision,true)

func _physics_process(delta: float) -> void:
	if  is_follow:
		direction = (player.global_position-global_position).normalized()
		position += direction*max_speed*delta
		#rotate_preti(player.global_position,delta)

func start_follow_tween():
	if is_follow:
		return
	var tween = create_tween()
	var tween_dur = 0.22
	tween.tween_property(
		coll,'scale:x',coll.scale.x*1.1,tween_dur)
	tween.parallel().tween_property(
		coll,'scale:y',coll.scale.y*0.8,tween_dur)

func tween_speed():
	var tween = create_tween()
	var duration = 0.7
	var max_tween_speed = 1500
	tween.tween_property(self,'max_speed',max_tween_speed,duration)

func rotate_preti(target_pos:Vector2,delta:float):
	var target_angle = (target_pos-global_position).angle()
	var rotation_speed = 2.0
	rotation = rotate_toward(rotation,target_angle,rotation_speed*delta)

func _on_body_entered(body):
	if body is Player:
		#if body.current_health < 100:
			body.add_health(amount)
			spawn_tween(coll,true)

func follow_player():
	if not can_start_follow:return
	tween_speed()
	if not is_follow:
		is_follow = true
#func _on_area_entered(area: Area2D) -> void:
	#if area is PlayerBullet:
		#if not area.can_damaging:
			#return
		#start_follow_tween()
		#tween_speed()
		#if not is_follow:
			#is_follow = true
			#area.disable_coll()
func _on_about_to_hide() -> void:
	can_start_follow = false
