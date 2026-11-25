extends BaseEnemy

@export var spear_damage = 8
@export var spear_speed = 440
@export var spear_damage_after_throw = 18
@export var spear_speed_after_throw = 500
@export var attack_delay_time = 1.0

var attack_range = 170
var can_shoot :bool = true

@onready var attack_delay_timer = %AttackDelayTimer

func _ready():
	sprite = %Sprite
	die_parti_amount = 16
	super._ready()


func chase_behavior(delta):
	if target and target.is_player_died == false :
		var distance = position.distance_to(target.position)
		var direction = \
		to_local(path_finding.get_next_path_position()).normalized()
		if distance > attack_range :
			move(direction,delta)
		else :
			velocity = Vector2.ZERO
			if can_shoot == true :
				attack()
				can_shoot == false
			
		move_and_slide()

func attack():
	var spear = enemy_spear.instantiate()
	get_tree().root.add_child(spear)
	spear.modulate = main_color
	spear.damage = spear_damage
	spear.speed = spear_speed
	spear.position = position
	spear.look_at(target.position)
	spear.direction = (Vector2(
	target.position - position)).normalized()
	spear.attack()
	can_shoot = false
	await get_tree().create_timer(attack_delay_time).timeout
	can_shoot = true


func spawn_die_spear():
	var die_spear = enemy_spear.instantiate()
	get_tree().root.add_child(die_spear)
	die_spear.modulate = main_color
	die_spear.damage_aftr_drop = spear_damage_after_throw
	die_spear.position = position
	die_spear.speed = spear_speed_after_throw
	die_spear.look_at(target.position)
	die_spear.droped = true
	die_spear.direction = (Vector2(
		target.position - position)).normalized()
	
	die_spear.throw_spear()

#func die():
	#spawn_die_spear()
	#super.die()
