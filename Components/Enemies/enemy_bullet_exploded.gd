extends EnemyBullet
class_name ExplodedEnemyBullet

@export var EXPLOSION : PackedScene

var can_explode = true
var explosion_scale = 1

func _ready() -> void:
	animation_player = $AnimationPlayer2
	super._ready()

func disable():
	spawn_explosion()
	super.disable()

func spawn_explosion():
	if can_explode == true:
		var explode :Explosion = EXPLOSION.instantiate()
		explode.modulate = coll.modulate
		explode.damage_player = true
		explode.position = position
		explode.player = target
		explode.damage = damage
		if boss_ability_is_active == true:
			%node_marker.scale *= explosion_scale
			explode.scale = Vector2(explosion_scale,explosion_scale)
			explode.boss_ability_is_active = boss_ability_is_active
		explode.modulate = modulate
		get_tree().root.add_child(explode)
		can_explode = false

func _on_animation_player_2_animation_finished(anim_name: StringName) -> void:
	if disabled == false:
		disable()
		%node_marker.hide()
		await get_tree().create_timer(1).timeout
		destroy()
