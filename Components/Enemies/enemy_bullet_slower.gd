extends Area2D
class_name EnemyBulletSlower

@export var hide_timer = 7.0
@export var bullet_slow_rate = 0.25
@export var can_slow = false
@onready var animation_player: AnimationPlayer = %AnimationPlayer
var player :Player

func _ready() -> void:
	hide()
	var rotate_tween = create_tween()
	rotate_tween.tween_property($coll/Sprite, 'rotation', 18, 15)

func activate(toggle:bool=true):
	#%HideTimer.start()
	#if toggle == true:
		animation_player.play('start')
		visible = true
		can_slow = true
	#else :
		await get_tree().create_timer(hide_timer).timeout
		animation_player.play_backwards('start')

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'start' and can_slow == false:
		hide()
		can_slow = false

func _on_body_entered(body: Node2D) -> void:
	if body is BaseEnemy:
		body.speed /= 2
		body.animation_player.speed_scale /= 2
		body.animation_player.play('slow')

func _on_body_exited(body: Node2D) -> void:
	if body is BaseEnemy:
		body.speed *= 2
		body.animation_player.speed_scale *= 2
		body.animation_player.play_backwards('slow')
