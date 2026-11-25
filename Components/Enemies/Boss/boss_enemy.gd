extends BaseEnemy
signal ability_activated

@export var attack_delay_time :float= 1
@export var attack_stage :int= 1
@export var bullets_color :Color
@export_group('Attack_1')
@export var bullet_scene_1: PackedScene
@export var bullet_attack_1_speed = 30
@export var bullet_attack_1_damage = 10
@export var spread_angle_1 = 15
@export var delay_bet_atts_1 = 0.5
@export var num_of_attakcs_1 = 15
@export var addi_range_1 = 2.0
@export_subgroup('Ability')
@export var ability_attack_1_bullet_scale = 1.3
@export var ability_attack_1_bullet_speed = 1.3
@export var ability_num_of_attakcs_1 = 15
@export_group('Attack_2')
@export var bullet_scene_2: PackedScene
@export var bullet_attack_2_speed = 550
@export var bullet_attack_2_damage = 34
@export var delay_bet_atts_2 = 0.5
@export var num_of_attakcs_2 = 13
@export_subgroup('Ability')
@export var ability_explo_scale = 1.5
@export_group('Attack_3')
@export var bullet_scene_3: PackedScene
@export var bullet_attack_3_speed = 700
@export var bullet_attack_3_damage = 15
@export var bullets_count_3 = 17
@export var attacks_count_3 = 4
@export var bullet_spawn_time_3 = 0.2
@export var attack_delay_time_3 :float= 1
@export var spread_angle_3 = 30
@export_subgroup('Ability')
@export var bullet_spawn_time_3_ability = 0.25
@export var bullets_count_3_ability = 20
@export var bullet_attack_3_speed_ability = 1.25
@export_group('Attack_4')
@export var fast_enemy_scene: PackedScene
@export var fast_enemy_damage = 15
@export var fast_enemy_explosion_scale = 0.75
@export var fast_enemy_max_speed = 300
@export var fast_enemy_health = 10
@export var attack_4_wait_time = 1.0
@export_subgroup('Ability')

@export_group('Ability Stats')
@export var ability_damage :float = 1.5
@export var ability_speed :float = 1.2
@export var ability_color = Color.html('#8f1ef8') 

var is_ability_activated = false

@onready var animation_player_2: AnimationPlayer = $AnimationPlayer2

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	%Armor.rotation += 0.01 if !is_ability_activated else 0.02

func _ready() -> void:
	super._ready()
	%AbilityParticles.emitting = false
	coll = %body
	start_timer()

func spawn_fast_enemy(spawn_position:Vector2,
	fast_enemy_scene:PackedScene=fast_enemy_scene,
	damage:int=fast_enemy_damage,speed:int=fast_enemy_max_speed,
	explosion_scale:int=fast_enemy_explosion_scale):
	var fast_enemy :ExplodedEnemy = fast_enemy_scene.instantiate()
	await get_tree().create_timer(0.3).timeout
	fast_enemy.position = spawn_position
	fast_enemy.explosion_damage = damage
	fast_enemy.explosion_scale  = explosion_scale
	fast_enemy.target = target
	fast_enemy.boss = self
	fast_enemy.is_ability_active = is_ability_activated
	get_parent().add_child(fast_enemy)
	if is_ability_activated:
		fast_enemy.activate_ability()

func spawn_particles(pos:Vector2,amount:int,modul:Color=bullets_color,parti_scale:float=1):
	var explode_part = explode_particles.instantiate()
	explode_part.scale *= Vector2(parti_scale,parti_scale)
	explode_part.position = position
	explode_part.explosiveness = 1
	explode_part.one_shot = true
	explode_part.modulate = modul
	explode_part.amount = amount
	get_parent().add_child(explode_part)
	explode_part.emitting = true


func attack_4():
	spawn_fast_enemy(%Marker1.global_position)
	spawn_fast_enemy(%Marker2.global_position)
	spawn_fast_enemy(%Marker3.global_position)
	spawn_fast_enemy(%Marker4.global_position)
	#if is_ability_activated == true:
		#spawn_fast_enemy(%Marker5.global_position)
		#spawn_fast_enemy(%Marker6.global_position)
		#spawn_fast_enemy(%Marker7.global_position)
		#spawn_fast_enemy(%Marker8.global_position)
	await get_tree().create_timer(attack_4_wait_time).timeout
	start_timer()
	attack_stage = 1

func attack_3(bullet_count:int=bullets_count_3,
	attack_count:int=attacks_count_3):
	if is_ability_activated == true :
		toggle_can_move(false)
		for i in attack_count:
			if target and not target.is_player_died and bullet_scene_3:
				for ii in bullets_count_3_ability if is_ability_activated else bullets_count_3:
					var base_direction = (target.position - position).normalized()
					var random_dir_3 = randi_range(-spread_angle_3, spread_angle_3)
					
					shoot(bullet_scene_3,360+random_dir_3,base_direction,
					bullet_attack_3_damage,
					bullet_attack_3_speed if is_ability_activated else \
					bullet_attack_3_speed*bullet_attack_3_speed_ability,1,0.2)
					
					await get_tree().create_timer(bullet_spawn_time_3 \
					if is_ability_activated else bullet_spawn_time_3_ability).timeout 
				await get_tree().create_timer(attack_delay_time_3).timeout
		start_timer()
		attack_stage = 4
		toggle_can_move(true)
	else:
		attack_4()
		

func attack_2(bullet_count:int=num_of_attakcs_2):
	toggle_can_move(false)
	for i in range(bullet_count):
		var base_direction = (target.position - position).normalized()
		
		shoot(bullet_scene_2,360,base_direction,
		bullet_attack_2_damage,bullet_attack_2_speed,1,
		0.5,'start',1.2)
		await get_tree().create_timer(delay_bet_atts_2).timeout
	start_timer()
	attack_stage = 3
	toggle_can_move(true)

func attack_1(bullet_count:int=num_of_attakcs_1):
	toggle_can_move(false)
	for i in range(bullet_count):
		if target and not target.is_player_died and bullet_scene_1:
			var base_direction = (target.position - position).normalized()
			var random_dir = randi_range(-addi_range_1, addi_range_1)
			var spread_angles = [0+random_dir,
			 -spread_angle_1+random_dir,
			(-spread_angle_1+random_dir)*2,
			 spread_angle_1+random_dir,
			(spread_angle_1+random_dir)*2]
			for angle_deg in spread_angles:
				shoot(bullet_scene_1,angle_deg,base_direction,
				bullet_attack_1_damage,
				bullet_attack_1_speed if is_ability_activated == false \
				else bullet_attack_1_speed*ability_attack_1_bullet_speed,
				1 if is_ability_activated == false else ability_attack_1_bullet_scale,0.2)
			await get_tree().create_timer(delay_bet_atts_1).timeout
	start_timer()
	attack_stage = 2
	toggle_can_move(true)

func shoot(bullet_scene:PackedScene,
	angle_deg,
	target_pos:Vector2,
	damage:int,speed:int,
	bullet_scale:float=1,
	speed_scale:int=0.5,
	anim_name:String='shoot_bullet',
	bullet_speed_scale:float=0.5,
	color:Color=bullets_color):
	
	var direction = target_pos.rotated(deg_to_rad(angle_deg))
	var bullet : EnemyBullet = bullet_scene.instantiate()
	bullet.damage = damage
	bullet.boss_ability_is_active = is_ability_activated
	bullet.target = target
	
	bullet.position = %ShootingPos.global_position
	bullet.speed = speed
	bullet.direction = direction
	var bullet_vec2_scale = Vector2(bullet_scale,bullet_scale)
	bullet.scale = bullet_vec2_scale
	bullet.speed_scale_anim = bullet_speed_scale
	bullet.modulate = color
	if is_ability_activated == true:
		bullet.modulate = ability_color
	if bullet is ExplodedEnemyBullet:
		bullet.explosion_scale = ability_explo_scale
	bullet.look_at(bullet.position + direction)
	get_parent().add_child(bullet)
	bullet.play_anim('shoot_bullet')

func activate_ability():
	emit_signal("ability_activated")
	is_ability_activated = true
	print_rich('[color=red][b]boss ability is active!')
	animation_player_2.play("activate_ability")
	target.camera_shake()
	speed *= ability_speed

func _on_attack_timer_timeout() -> void:
	match attack_stage :
		1:attack_1()
		2:attack_2()
		3:attack_3()
		4:attack_4()
	print_rich('[b]next_attack is : ',attack_stage)

func start_timer(scaled:int=1):
	%AttackTimer.wait_time = attack_delay_time*scaled
	%AttackTimer.start()

func _on_damaged(amount: int, curr_health: int) -> void:
	if current_health <= max_health/2 and is_ability_activated == false:
		activate_ability()

func toggle_can_move(toggle:bool):
	can_move = toggle

func die():
	exp
	target.camera_shake()
	super.die()

func _on_armor_area_entered(area: Area2D) -> void:
	if area is PlayerBullet:
		area.disable_coll()
