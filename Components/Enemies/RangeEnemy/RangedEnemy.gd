class_name RangedEnemy
extends BaseEnemy
signal shooted

@export var move_back_speed_ratio = 0.22
@export var move_back_range_ratio = 0.8
@export var fire_rate = 0.2
@export var ultimate_shoot_charge_rate = 20
@export var shoot_point : Marker2D
@export_enum('ranged' ,'sniper' ,'fast_range' ,'wizard') var ranged_type :String
@export_category('bullet stats')
@export var bullet_scene :PackedScene
@export var bullet_speed = 830
@export var bullet_damage = 16
@export var bullet_range = 400
@export var bullet_scale = 2.0

var is_collide_with_wall : bool
var can_attack = false

func _ready():
	set_fire_rate(fire_rate)
	super._ready()

func chase_behavior(delta):
	if target:
		var distance = position.distance_to(target.position)
		var direction = \
		to_local(path_finding.get_next_path_position()).normalized()
		if distance > bullet_range :move(direction,delta)
		else :
			if is_collide_with_wall == true:move(direction,delta)
			else:
				if can_attack :emit_signal('shooted')
				if distance > bullet_range * 0.8 :velocity = Vector2.ZERO
				else :move(-direction * move_back_speed_ratio ,delta)
		move_and_slide()

func move(direction,delta):
	velocity = direction * speed

@onready var collision = %Coll

func shoot():
	if target and not target.is_player_died and bullet_scene:
		var bullet :EnemyBullet= bullet_scene.instantiate()
		bullet.damage = bullet_damage
		bullet.target = target
		bullet.position = shoot_point.global_position
		bullet.modulate = main_color
		bullet.speed = bullet_speed
		bullet.direction = (Vector2(target.position - position)).normalized()
		if ranged_type == 'sniper' :
			bullet.scale *= 1.2
			bullet.scale.x *= 1.2
			bullet.scale.y *= 0.9
		elif ranged_type == 'fast_range':
			bullet.scale *= 0.85
		bullet.speed_scale_anim = bullet_scale
		bullet.shooter = self
		get_parent().add_child(bullet)
		bullet.look_at(target.position)
		bullet.play_anim('shoot_bullet')
		can_attack = false
		bullet.hits_player.connect(bullet_hits_player)
		if is_ultimate_active:bullet.scale*=1.1
		if not ranged_type == 'wizard': 
			set_fire_rate(fire_rate)
			tween_manager.shoot_tween(sprite)

func bullet_hits_player(shooter:RangedEnemy):
	if not shooter:return
	charge_ultimate(ultimate_shoot_charge_rate)
	if not shooter.ranged_type == 'ranged':return
	if not shooter.is_ultimate_active:return
	var additinal_damage = 2
	var heal = 4
	shooter.bullet_damage += additinal_damage
	shooter.add_health(heal)
	shooter.spawn_popup_text('Level up!',ultimate_color)

func set_fire_rate(firerate:float):
	await get_tree().create_timer(firerate).timeout
	can_attack = true

#func activate_ability():
	#fire_rate = fire_rate_abi
	#bullet_damage = bullet_damage_abi
	#bullet_speed *= bullet_speed_abi
	#super.activate_ability()

func _on_move_range_body_entered(body):
	if body.is_in_group('collisions'):
		is_collide_with_wall = true

func _on_move_range_body_exited(body):
	if body.is_in_group('collisions'):
		is_collide_with_wall = false

func _on_shooted() -> void:
	shoot()
