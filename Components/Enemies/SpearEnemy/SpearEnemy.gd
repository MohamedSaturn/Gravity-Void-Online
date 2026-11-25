class_name SpearEnemy
extends BaseEnemy

@export var spear_damage = 8
@export var spear_speed = 440
@export var spear_damage_after_throw = 18
@export var spear_speed_after_throw = 500
@export var attack_delay_time = 1.0
@export var attack_range = 170
@export_group('ultimate')
@export var ultiamte_addi_max_health = 25
@export var ultimate_regneration = 2
@export var ultimate_hit_charge = 40

var can_shoot :bool = true

#@onready var attack_delay_timer = %AttackDelayTimer

func _ready():
	sprite = %Sprite
	die_parti_amount = 16
	animation_player.play_backwards('ultimate_activated')
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
	var spear :Spear= enemy_spear.instantiate()
	get_tree().root.add_child(spear)
	spear.modulate = main_color
	spear.damage = spear_damage
	spear.speed = spear_speed
	spear.shooter = self
	spear.position = position
	spear.look_at(target.position)
	spear.direction = (Vector2(
	target.position - position)).normalized()
	spear.attack()
	spear.hits_player.connect(func(shooter:SpearEnemy):
		shooter.charge_ultimate(ultimate_hit_charge))
	can_shoot = false
	await get_tree().create_timer(attack_delay_time).timeout
	can_shoot = true

func activate_ultimate():
	super.activate_ultimate()
	max_health += ultiamte_addi_max_health
	ready_bars()
	add_health(ultiamte_addi_max_health) 
	%UltimateRegneration.start()

func _on_ultimate_regneration_timeout() -> void:
	add_health(ultimate_regneration)
