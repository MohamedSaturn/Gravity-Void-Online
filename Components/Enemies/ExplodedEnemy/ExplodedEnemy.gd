extends BaseEnemy
class_name ExplodedEnemy
@export var explosion_damage :int = 22
@export var explosion_scale :float = 0.8
@export var explosion_time = 8.0

@onready var explosion_time_bar: ProgressBar = %ExplosionTimeBar
@onready var explosion_timer: Timer = %ExplosionTimer

func _ready():
	bar_visible(ultimate_bar,false)
	explosion_timer.wait_time = explosion_time
	explosion_time_bar.max_value = explosion_time
	explosion_timer.start()
	sprite = %Sprite
	coll = %Coll
	super._ready()

func chase_behavior(delta):
	if target and target.is_player_died == false :
		explosion_time_bar.value = explosion_timer.time_left
		if start_tween_finished:explosion_time_bar.show()
		var distance = position.distance_to(target.position)
		var direction = to_local(path_finding.get_next_path_position()).normalized()
		move(direction,delta)
		move_and_slide()

func die():
	spawn_explosion()
	super.die()

#func activate_ability():
	#%Base.color = boss.ability_color
	#%Back.color = boss.ability_color.lightened(0.15)
	#%Particles.speed_scale *= 1.3
	#scale *= 1.1
	#speed *= 1.5

func spawn_explosion():
	var explode : = explosion.instantiate()
	target.camera_shake()
	explode.damage_player = true
	explode.damage_enemy = false
	explode.position = position
	explode.player = target
	explode.damage = explosion_damage
	explode.modulate = main_color
	#explode.scale = Vector2(explosion_scale,explosion_scale)
	get_parent().call_deferred('add_child',(explode)) #aftor 0.1.2.2

func _on_explosion_area_body_entered(body):
	if body is Player:
		die()

func _on_explosion_timer_timeout() -> void:
	die()
