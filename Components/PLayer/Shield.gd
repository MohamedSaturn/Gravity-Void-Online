extends Area2D

var play_backwards = false
@export var anim_player : AnimationPlayer

func start() -> void:
	anim_player.play('rotate_shield')
	play_backwards = true

func _on_shield_animated_animation_finished(anim_name: StringName) -> void:
	if play_backwards:
		anim_player.play_backwards('rotate_shield')
		play_backwards = false
	else:
		anim_player.play('rotate_shield')
		play_backwards = true

func _on_area_entered(area: Area2D) -> void:
	if area is EnemyBullet:
		area.disable()
