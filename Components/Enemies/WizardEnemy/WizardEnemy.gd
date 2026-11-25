extends RangedEnemy
class_name WizardEnemy

@export_group('health attack')
@export var health_points = 15
@export var health_ultimate_points = 25
@export_group('stunn attack')
@export var stunn_time = 1.0
@export_group('fast enemy attack')
@export var fast_enemy_scene:PackedScene
@export var spawn_points : Array[Marker2D]
@export var fast_enemy_damage = 14
@export var spawn_ultimate_points : Array[Marker2D]

@onready var attack_cooldown_timer: Timer = %AttackCooldownTimer
@onready var warn_animator: AnimationPlayer = %WarnAnimator
@onready var healer_animator: AnimationPlayer = %HealerAnimator
@onready var fast_enemy_cooldown: Timer = %FastEnemyCooldown

func _ready() -> void:
	super._ready()
	fast_enemy_cooldown.wait_time = 10
	fast_enemy_cooldown.start()
	attack_cooldown_timer.wait_time = fire_rate
	attack_cooldown_timer.start()
	attack_animation()

func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true

func attack_animation():
	warn_animator.play("attack")
	await warn_animator.animation_finished
	warn_animator.play_backwards("attack")

func activate_ultimate():
	super.activate_ultimate()
	health_points = health_ultimate_points
	spawn_points = spawn_ultimate_points

func attack():
	if can_attack:
		attack_animation()
		if current_health <= max_health *0.7:
			attack_health()
		else:
			shoot()
			charge_ultimate(10)
		can_attack = false
		attack_cooldown_timer.start()

func attack_fast_enemy():
	attack_animation()
	for mark_position in spawn_points:
		var fast_enemy :ExplodedEnemy = fast_enemy_scene.instantiate()
		fast_enemy.position = mark_position.global_position
		fast_enemy.explosion_damage = fast_enemy_damage
		fast_enemy.explosion_scale  = 1
		fast_enemy.tween_manager = tween_manager
		fast_enemy.target = target
		fast_enemy.can_spawn_fragment = false
		fast_enemy.can_spawn_playerhp = false
		get_parent().add_child(fast_enemy)

func attack_health():
	healer_animator.play("heal")
	if is_ultimate_active:health_points = health_ultimate_points
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if not is_instance_valid(enemy) :continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < bullet_range:
			enemy.add_health(health_points)
	for player in get_tree().get_nodes_in_group("player"):
		player.take_damage(health_points)

func _on_shooted() -> void:
	attack()

func _on_fast_enemy_cooldown_timeout() -> void:
	attack_fast_enemy()
	fast_enemy_cooldown.start()
