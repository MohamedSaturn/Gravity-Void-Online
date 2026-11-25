#@tool
extends CharacterBody2D
class_name Player
signal ability_ends
signal ability_charged
signal dashed
signal fanger_finished

@export var max_speed = 200
@export var max_health = 100
@export var damage_scale :float = 1.0
@export var acceleration = 2000
@export var friction = 1000
@export var damage_time = 0.12
@export var num_popup :PackedScene
@export var particle_scene :PackedScene
@export var start_abi_type = 'ss'
#@export_group('Main Attacks')
@export_enum('range','mele') var attack_type = "range"
@export_group('Shoot')
@export var fire_rate = 0.5
@export var bullet_damage = 10
@export var bullet_speed = 520
@export var bullet_scale = 1.0
@export var bullet_speed_scale = 1.0
@export var bullet_scene :PackedScene
@export var shoot_part :PackedScene
@export_subgroup('sword')
@export var sword_damage = 25
@export var sword_health_attack = 7
@export var sword_attack_cooldown :float = 0.15
@export var sword_scene : PackedScene
@export_group('Dash')
@export var dash_cooldown_time = 0.3
@export var dash_fragment_req = 3
var dash_current_charge = 0
var show_dash_popup = false
@export var dash_speed :int = 500
@export_group('Trades')
@export var active_trades :Array[String]

@export_group('Text Popup Color')
@export var popup_dash_color :Color
@export var popup_damage_color :Color
@export var popup_enemy_damaged_color :Color
@export var popup_damage_wow_color :Color
@export var popup_health_color :Color
@export var popup_ability_charged_color :Color
@export_group('Export')
@export_enum('Android','Windows') var platform_type := 'Windows'
@export var set_platform_name = false
@export_group('Debug')
@export var debug_dash = false
@export_category('Ultimates')
@export var ability_modulate = Color.WHITE
@export var ability_health = 25 as int

@export var ability_max_charge = 100
var auto_chrge_ult = false
@export var ability_type :String = 'oo'
@export var ability_delay_time = 10
var current_ability_charge = 0
@export_group('Multishot "SS"')
@export var max_speed_ability_ss = 1.3
@export var bullet_speed_ability_ss = 1.2
@export var fire_rate_ability_ss = 1.3
@export var spread_angle_ss :int = 10
@export var bullet_damage_main_multi = 30
@export var bullet_damage_spread_multi = 20
@export var bullet_scale_ability_ss = 1.3
@export var bullet_anim_scale_speed_ss = 1.0
@export var dash_ability_damage = 10
@export_group('Mashun "OO"')
@export var max_speed_ability_oo = 1.2
@export var bullet_speed_ability_oo = 2.5
@export var bullet_damage_ability_oo = 3.0
@export var sword_damage_ability_oo = 1.3
@export var fire_rate_ability_oo = 1.6
@export var damage_scale_ability_oo = 1.5
@export var bullet_scale_ability_oo = 1.0
@export var spread_angle_m_oo = 10
@export var bullet_anim_scale_speed_oo = 1.0
@export_group('Slower "HH"')
@export var max_speed_ability_hh = 2.0
@export var bullet_speed_ability_hh = 1.5
@export var bullet_damage_ability_hh = 1.5
@export var fire_rate_ability_hh = 0.3
@export var bullet_scale_ability_hh = 1.5
var fanger_dash_speed :int = 800
var fanger_max_distance = 500
var fanged_enemies := [BaseEnemy]
var max_fanger_hits = 4
var current_fanger_hits = 0
@onready var ultimate_joystick: UltimateJoystick = %UltimateJoystick
@onready var attack_delay_bar: ProgressBar = %AttackDelayBar
#@onready var sword_animator: AnimationPlayer = %SwordAnimator
@onready var shoot_timer = %ShootTimer
@onready var damage_timer = %DamageTimer
@onready var ability_delay_timer = %AbilityDelayTimer
@onready var animation_player = %AnimationPlayer
@onready var health_bar: ProgressBar = %HPBar
@onready var dash_pregress_bar: TextureProgressBar = %DashPregressBar
#@onready var ult_pregress_bar :TextureProgressBar = %UltProgressBar
@onready var collision = %collision
@onready var death_dialog :DeathDialog = %DeathDialog
@onready var camera: Camera2D = $"../Camera"
#@onready var dash_step_cooldown_timer: Timer = %DashCooldownTimer
@onready var dash_cooldown_timer: Timer = %DashCooldownTimer
@onready var time = %Time
@onready var dash_effect = %DashEffect
#@onready var move_joystick: Joystick = %MoveJoystick
#@onready var fanger: Polygon2D = %Fanger
#@onready var boss := %BOSS
#@onready var hp_num = %HPNum
@onready var move_sprite: Sprite2D = %MoveSprite
@onready var aim_sprite: Sprite2D = %AimSprite
@onready var tween_manager: TweenManager = %TweenManager
#@onready var attack_sword_cooldown: Timer = %AttackSwordCooldown
#@onready var rage_bar: ProgressBar = %RageBar
#@onready var ult_visible: Polygon2D = %UltVisible

var auto_aim = false
var player_color : Color
var def_bullet_scale :float = 1
var defult_max_speed = 0
var defult_bullet_speed = 0
var defult_fire_rate = 0
var defult_bullet_damage = 0
var defult_modulate :Color
var def_sword_damage = 25
var def_sword_cooldown
var def_dash_cooldown = 4
var is_ability_charged = false
var input_vector = Vector2.ZERO
var current_health: float
var can_take_damage = true
var shoot_type = 'r'
var is_ability_active = false
var is_player_died :bool = false
var is_dashing = false
var is_fanging = false
var can_dash = true
var dash_dir = Vector2.ZERO
var can_take_explo_damage = true
var direction: Vector2 = Vector2.ZERO
var kills :int = 0
var enemy_damage_multiplier :float = 1.0
var can_attack = true
var is_aim_joy_touching = false
var is_move_joy_touching = false
var trade_adv_dash = 'aaa'
var trade_shield = 'ddd'
var trade_hp_cude = 'hhh'
var trade_revivor = 'rrr'
var trade_abi_charger = 'uuu'
var can_attack_sword = true
var fanger_direction :Vector2
var fanger_start_position :Vector2
@onready var shoot_dir: Line2D = %ShootDir
@onready var ss_spread_angle: Node2D = %SSSpreadAngle
var current_shoot_dire :Node2D = shoot_dir
@onready var shoot_directors: Node2D = %ShootDirectors

func ready_trades():
	#active_trades.append(trade_shield)
	#active_trades.append(trade_adv_dash)
	active_trades.append(trade_hp_cude)
	active_trades.append(trade_revivor)
	#if trade_shield in active_trades:
		#%Shield.start()
	#else:%Shield.queue_free()

func ready_bars_and_timers():
	attack_delay_bar.hide()
	#rage_bar.max_value = rage_cooldown.wait_time
	#dash_step_cooldown_timer.wait_time = dash_step_cooldown
	ability_delay_timer.wait_time = ability_delay_time
	damage_timer.wait_time = damage_time
	#dash_step_cooldown_timer.start()
	health_bar.max_value = max_health
	#%DashBar.max_value = dash_max_charge
	dash_pregress_bar.max_value = dash_cooldown_timer.wait_time
	dash_pregress_bar.value = dash_cooldown_timer.wait_time

func ready_def():
	player_color = %NonCore.modulate
	defult_modulate = collision.modulate
	defult_bullet_damage = bullet_damage
	defult_bullet_speed = bullet_speed
	defult_fire_rate = fire_rate
	defult_max_speed = max_speed
	def_bullet_scale = bullet_scale
	def_sword_damage = sword_damage
	def_sword_cooldown = sword_attack_cooldown

func ready_platform():
	if set_platform_name:
		platform_type = OS.get_name()
	if platform_type == 'Windows':
		%JoystickControl.hide()
		
		%UltBar.show()
		%DashBar.show()
		
		#%JoystickControl.hide()

func ready_sword_and_dash():
	if debug_dash:
		%DebugDash.show()
	dash_effect.hide()
	dash_cooldown_timer.wait_time = dash_cooldown_time
	%Fanger.hide()

#var attack_timer: Timer = attack_sword_cooldown

func process_bars():
	#rage_bar.value = rage_cooldown.time_left
	#attack_delay_bar.max_value = attack_timer.wait_time
	#attack_delay_bar.value = attack_timer.wait_time-attack_timer.time_left
	#%ultpart.emitting = is_ability_active
	#%UltBar.max_value = ult_pregress_bar.max_value
	#if is_ability_active == true :
		#ult_pregress_bar.max_value = ability_delay_timer.wait_time
		#ult_pregress_bar.value = ability_delay_timer.time_left
	#else :
		#ult_pregress_bar.max_value = ability_max_charge
		#ult_pregress_bar.value = current_ability_charge
	health_bar.value = current_health
	if not can_dash:
		dash_pregress_bar.value = dash_cooldown_timer.time_left
	else :
		dash_pregress_bar.value = dash_cooldown_timer.wait_time
	#%UltBar.value = ult_pregress_bar.value
	#%UltBar.max_value = ult_pregress_bar.max_value
	%DashBar.value = dash_pregress_bar.value
	#dash_pregress_bar.max_value = dash_cooldown

func process_debug():
	var n1 = ''' 
	is_dashing : '''+str(is_dashing)
	var n2 = ''' 
	is_fanging : '''+str(is_fanging)
	var n3 = ''' 
	can_dash : '''+str(can_dash)
	var n4 = ''' 
	current_fanger_hits : ''' + str(current_fanger_hits) +'''
	'''
	var mn = '''
	'''
	%DebugDash.text = n1 + n2 + n3 + n4 +\
	#str(dash_current_charge) + '/' + str(dash_max_charge) + mn +\
	str(get_next_fanger()) + mn + str(fanged_enemies)
	#%UltBar.value = ult_pregress_bar.value
	var abi_debug = %DebugAbi
	abi_debug.text = 'abi curr charge:'+str(current_ability_charge)+\
	' ability max charge:'+str(ability_max_charge)

@onready var ultimate_fire: Node2D = %UltimateFire
@onready var directors: Node2D = %Directors


func _ready():
	ultimate_fire.modulate.a = 0.0
	if auto_chrge_ult:
		charge_ability(ability_max_charge)
		is_ability_charged = true
	%AbilityPart.emitting = false
	ready_trades()
	ready_sword_and_dash()
	switch_attack_type()
	ready_platform()
	ready_bars_and_timers()
	ability_type = Global.def_abi_type
	current_health = max_health
	ready_def()
	update_fire_rate()
@onready var hh_director: Line2D = %HHDirector
@onready var aim_joystick: Joystick = %AimJoystick

func _physics_process(delta):
	if is_player_died == false:
		if ultimate_joystick.is_pressing:
			directors.visible = true
			if ability_type == 'hh':hh_director.show()
			else:hh_director.hide()
			hh_director.look_at(global_position+ultimate_joystick.pos_vector)
			shoot_directors.look_at(global_position+aim_joystick.pos_vector)
		else:
			directors.visible = false
		#ult_visible.rotation += 1.5 * delta
		#ult_visible.visible = is_ability_charged
		process_bars()
		#%Fanger.visible = is_fanging
		#if is_fanging and fanger_target != null:
			#can_attack = false
			#%Fanger.look_at(global_position+fanger_direction)
		match platform_type:
			'Windows':windows_process(delta)
			'Android':android_process(delta)
		movement(delta)
		if Input.is_action_pressed("debug_ability"):
			current_ability_charge = ability_max_charge
		if Input.is_action_pressed("use_ability") \
		and current_ability_charge >= ability_max_charge: 
			ActivateAbility()
		#if Input.is_action_just_pressed('attack_type'):
			#switch_attack_type()
		move_and_slide()
		#collision.disabled = is_fanging
		#%UltVisible.modulate = collision.modulate
		process_debug()

func windows_process(delta:float):
	var mouce_pos = get_global_mouse_position()
	#rotate_player(mouce_pos,delta)
	#if is_fanging and fanger_target != null:
	collision.look_at(mouce_pos)
	if Input.is_action_pressed("attack") and can_attack:
		attack()

func attack():
	match attack_type:
		'range':
			shoot()
			attack_delay_bar.show()
		#'mele':attack_sword()

func android_process(delta:float):
	update_aim_from_joystick()
	if direction != Vector2.ZERO:
		if current_shoot_dire:
			current_shoot_dire.visible = true
		aim_sprite.position = global_position+direction
		rotate_player(aim_sprite.position,delta)
		shoot_directors.look_at(aim_sprite.position)
		if is_fanging and fanger_target != null:
			collision.look_at(global_position+fanger_direction)
		attack()
	else:
		if current_shoot_dire:current_shoot_dire.visible = false

func rotate_player(target_pos:Vector2,delta:float):
	var target_angle = (target_pos-global_position).angle()
	var rotation_speed = 17
	collision.rotation = rotate_toward(
	collision.rotation,target_angle,rotation_speed*delta)

func switch_attack_type():
	match attack_type:
		'mele':
			attack_type='range'
			%RangeSprite.show()
			%MeleSprite.hide()
			#attack_timer = shoot_timer
			#rage()
		#'range':
			#attack_type='mele'
			#%RangeSprite.hide()
			#%MeleSprite.show()
			##attack_timer = attack_sword_cooldown
			#dash_manager()

var fanger_target :BaseEnemy
func movement(delta):
	if is_dashing:
		#if is_ability_active and ability_type == 'hh':
			#velocity = dash_dir * fanger_dash_speed
		#else:
		velocity = dash_dir * dash_speed
		if 'aaa' in active_trades:
			can_take_damage = false
		return 
	elif is_fanging:
		if fanger_target == null\
		or fanger_start_position.distance_to(global_position)>fanger_max_distance:
			finish_dash()
			return
		if not fanger_direction==Vector2.ZERO:
			position += fanger_direction*fanger_dash_speed*delta
			velocity = Vector2.ZERO
			print('dir is: ',fanger_direction)
	else:
	#if platform_type == 'Windows' or set_platform_name == true:
		input_vector.x = Input.get_axis("move left", "move right")
		input_vector.y = Input.get_axis("move up", "move down")
		input_vector = input_vector.normalized()
		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		#if velocity != Vector2.ZERO:
			#if is_ability_active and ability_type == 'hh':
				#%FangerDirection.look_at(velocity*100000)
		if platform_type == 'Android':
			var direction = %MoveJoystick.pos_vector
			if direction:
				velocity = direction * max_speed
				move_sprite.position = global_position+velocity
				if not %AimJoystick.is_pressing:
					rotate_player(move_sprite.position,delta)
			else:
				velocity = Vector2.ZERO
			input_vector = direction.normalized()
			#if velocity.length() > 0:
	if Input.is_action_pressed("gadget"):
		dash_manager()

var is_raged = false
var rage_speed = 1.25
var rage_fire_rate = 0.8

#func rage():
	#rage_bar.show()
	#is_raged = true
	#fire_rate *= rage_fire_rate
	#max_speed *= rage_speed
	#rage_cooldown.start()
	#update_fire_rate()
	#if not is_ability_active:
		#collision.modulate = Color.html('#d26b5a')

#@onready var rage_cooldown: Timer = %RageCooldown

#func unrage():
	#rage_bar.hide()
	#fire_rate /= rage_fire_rate
	#max_speed /= rage_speed
	##dash_step_cooldown_timer.start()
	#collision.modulate = Color.WHITE
	#is_raged = false
	#update_fire_rate()
	#print('unraged')

func dash_manager():
	if not can_dash:return
	if velocity == Vector2.ZERO:return
	if is_ability_active:
		activate_dash()
		return
	if current_ability_charge >= dash_fragment_req:
		activate_dash()
		current_ability_charge -= dash_fragment_req
		is_ability_charged = false

func activate_dash(direction:Vector2=input_vector):
	is_dashing = true
	can_dash = false
	%DashAnimation.play("start_dash")
	dash_dir = direction.normalized()
	emit_signal("dashed")
	dash_effect.look_at(global_position+dash_dir)
	%Dashing.playing = true
	#dash_current_charge = 0

func fanger_activated():
	#%FangerArea.monitoring = true
	%DashAnimation.play("start_fanger")
	is_fanging = true
	current_fanger_hits = 0
	fanger_start_position = global_position
	fanger_direction = ultimate_joystick.pos_vector
	fanger_target = get_next_fanger()
	#if fanger_target == null:
		#return
		#print('didnt find enemy')
	print('fanger activated')

func finish_dash():
	is_dashing = false
	is_fanging = false
	can_attack = true
	velocity = Vector2.ZERO
	%DashAnimation.stop()
	fanged_enemies.clear()
	can_take_damage = true
	print_rich('[b][color=green]dash/fanger finished')
	dash_cooldown_timer.start()


func update_aim_from_joystick():
	var joy_vec = Vector2.ZERO
	if has_node("%AimJoystick"):
		joy_vec = %AimJoystick.pos_vector
	if joy_vec.length() < 0.2:
		direction = Vector2.ZERO
		return
	direction = joy_vec.normalized()

func charge_ability(amount:int):
	if is_ability_active == false :
		if current_ability_charge < ability_max_charge:
			current_ability_charge += amount
			if current_ability_charge == ability_max_charge:
				#if is_ability_charged == false:
				current_ability_charge = ability_max_charge
				emit_signal("ability_charged")
				spawn_popup_text('Ultimate Charged',popup_ability_charged_color)
				is_ability_charged = true
		else:return

#func charge_dash(amount:float):
	#if dash_max_charge > dash_current_charge:
		#dash_current_charge += amount
	#else:
		#dash_current_charge = dash_max_charge
		#can_dash = true
		##%DashVisible.show()
		#dash_step_cooldown_timer.stop()
		##if show_dash_popup == false:
			##show_dash_popup = true
			##spawn_popup_text('Dash Charged',popup_dash_color)
	##var time_left = dash_cooldown_timer.time_left
	##var new_time_left = max(time_left-amount,0.0)
	##if not dash_cooldown_timer.is_stopped():
		##dash_cooldown_timer.stop()
		##dash_cooldown_timer.start(new_time_left)
@onready var fire_animator: AnimationPlayer = %FireAnimator

func ActivateAbility():
	max_speed = defult_max_speed
	animation_player.play("activate_ability")
	camera_shake()
	add_health(ability_health)
	is_ability_charged = false
	current_ability_charge = 0
	is_ability_active = true
	explosive_particles(16, ability_modulate)
	ability_delay_timer.start()
	%Ultimate.playing = true
	match ability_type :
		'ss' :ability_ss() ##Multishot
		'oo' :ability_oo() ##Rangeshot
		'hh' :ability_hh() ##Slowmotion

func shoot():
	#shoot_dir.show()
	#ss_spread_angle.show()
	if shoot_timer.is_stopped():
		match shoot_type:
			's':shoot_type_s()
			'r':shoot_type_r()
			#'m':shoot_type_m()
		%Shoting.playing = true
		#%ShootAnimator.play("shoot")
		print('func shoot')
		if not shoot_part:return
		spawn_shoot_part()
@onready var core: Polygon2D = %CORE
@onready var shoot_marker: Marker2D = %ShootMarker

func spawn_shoot_part():
	var particles :CPUParticles2D = shoot_part.instantiate()
	particles.position = shoot_marker.global_position
	particles.modulate = core.color
	get_parent().add_child(particles)
	particles.emitting = true

func camera_shake():
	camera.call_deferred("apply_shake")

#func _input(event):
	#if event.is_action_pressed('mmb_down') :
		#camera.zoom *= 1 - 0.1
	#elif  event.is_action_pressed('mmb_up') :
		#camera.zoom *= 1 + 0.1

func get_nearest_enemy_position():
	var nearest_enemy :Vector2 = Vector2.ZERO
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if not is_instance_valid(enemy) :continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy.position
	return nearest_enemy as Vector2

func shoot_bullet(num_of_bullet:int=1,angle_deg=0,
	bullet_scale:float=bullet_scale,
	bullet_speed_scale:float=bullet_speed_scale):
	var bullet : PlayerBullet = bullet_scene.instantiate()
	var bullet_vec2_scale = Vector2(bullet_scale,bullet_scale)
	var direction:Vector2
	var mouse_pos = get_global_mouse_position()
	direction = (mouse_pos - position).normalized()
	if platform_type == 'Android':
		var joy_vector = %AimJoystick.pos_vector
		direction = joy_vector.normalized()
	var spread_deg_oo = randf_range(-spread_angle_m_oo,spread_angle_m_oo)
	var spread_rad_oo = deg_to_rad(spread_deg_oo)
	if auto_aim:
		direction = (get_nearest_enemy_position()-position).normalized()
	bullet.damage = bullet_damage
	bullet.position = position
	bullet.speed = bullet_speed
	bullet.scale = bullet_vec2_scale
	if is_ability_active and ability_type == 'oo':
		bullet.can_explode = true
	bullet.speed_scale_anim = bullet_speed_scale
	##oo -----> m
	var spread_rad_ss = deg_to_rad(spread_angle_ss)
	#if shoot_type == 'm':
		#direction = direction.rotated(spread_rad_oo)
		#bullet.speed *= 1.0 + (randi() % 7 + 2)/10
	if shoot_type == 's':
		if num_of_bullet == 1:
			bullet.damage = bullet_damage_main_multi
		else:
			bullet.damage = bullet_damage_spread_multi
			#bullet.speed *= 0.9
			#bullet.scale *= 0.9
		match num_of_bullet:
			2:direction = direction.rotated(spread_rad_ss)
			3:direction = direction.rotated(-spread_rad_ss)
			4:direction = direction.rotated(spread_rad_ss*2)
			5:direction = direction.rotated(-spread_rad_ss*2)
	#if is_ability_active and ability_type == 'hh':
		#bullet.destroy_after_collide = false
	bullet.look_at(bullet.position + direction)
	bullet.direction = direction
	bullet.player = self
	if not is_ability_active:
		bullet.get_core().color = %CORE.color
		bullet.get_trail().color = %NonCore.modulate
	bullet.get_particles().modulate = %CORE.color
	get_parent().add_child(bullet)
	print('func shoot bullet')

func shoot_type_r():
	current_shoot_dire = shoot_dir
	ss_spread_angle.hide()
	shoot_dir.show()
	shoot_bullet()
	shoot_timer.start()

func get_coll():
	return %collision

#func attack_sword():
	#if not can_attack_sword:
		#return
	#var sword : Sword = sword_scene.instantiate()
	#get_parent().add_child(sword)
	#sword.damage = sword_damage
	#sword.modulate = collision.modulate
	#sword.player = self
	#sword.position = %SwordMarker.global_position
	#
	#sword.rotation = collision.rotation
	#sword.attack_cooldown_time = sword_attack_cooldown
	##sword.attack_cooldown = attack_sword_cooldown
	#sword.attack_health = sword_health_attack
	#sword.attack()

func shoot_type_s():
	current_shoot_dire = ss_spread_angle
	shoot_dir.hide()
	ss_spread_angle.show()
	shoot_bullet()
	shoot_bullet(2)
	shoot_bullet(3)
	shoot_bullet(4)
	shoot_bullet(5)
	shoot_timer.start()

func add_health(amount:int):
	spawn_popup_text(str(amount),popup_health_color)
	if current_health + amount >= max_health:
		current_health = max_health
	else:
		current_health += amount

#func shoot_type_m():
	##shoot_bullet()
	#shoot_bullet()
	#shoot_timer.start()

func ability_ss():
	shoot_type = 's'
	max_speed *= max_speed_ability_ss
	bullet_speed *= bullet_speed_ability_ss
	fire_rate = fire_rate_ability_ss
	#bullet_damage *= bullet_damage_ability_ss
	bullet_speed_scale *= bullet_anim_scale_speed_ss
	bullet_scale *= bullet_scale_ability_ss
	update_fire_rate()

func ability_oo():
	shoot_type = 'r'
	max_speed *= max_speed_ability_oo
	bullet_speed *= bullet_speed_ability_oo
	bullet_damage *= bullet_damage_ability_oo
	fire_rate = fire_rate_ability_oo
	damage_scale *= damage_scale_ability_oo
	bullet_speed_scale *= bullet_anim_scale_speed_oo
	bullet_scale *= bullet_scale_ability_oo
	sword_damage *= sword_damage_ability_oo
	update_fire_rate()

func ability_bb():
	shoot_type = 'r'
	#max_speed *= max_speed_ability_bb
	#bullet_speed *= bullet_speed_ability_bb
	#bullet_damage *= bullet_damage_ability_bb
	#bullet_scale *= bullet_scale_ability_bb
	update_fire_rate()

func ability_hh():
	shoot_type = 'r'
	max_speed *= max_speed_ability_hh
	bullet_speed *= bullet_speed_ability_hh
	bullet_damage *= bullet_damage_ability_hh
	fire_rate = fire_rate_ability_hh
	bullet_scale *= bullet_scale_ability_hh
	spawn_enemy_slower()
	update_fire_rate()

@export var enemy_bullet_slower: PackedScene

func spawn_enemy_slower():
	var slower: EnemyBulletSlower = enemy_bullet_slower.instantiate()
	slower.player = self
	get_parent().add_child(slower)
	get_parent().move_child(slower,4)
	slower.position = hh_director.to_global(hh_director.get_point_position(1))
	print(slower.position)
	slower.activate()

func spawn_popup_text(text:String ,color:Color):
	if is_player_died == false:
		var popup :PopupText = num_popup.instantiate()
		popup.popup(global_position,text,color)
		get_parent().add_child(popup)

func _on_ability_delay_timer_timeout():
	restore_stats()
	emit_signal("ability_ends")

func restore_stats():
	shoot_type = 'r'
	max_speed = defult_max_speed
	bullet_speed = defult_bullet_speed
	fire_rate = defult_fire_rate
	bullet_damage = defult_bullet_damage
	bullet_scale = def_bullet_scale
	bullet_speed_scale = 1.0
	damage_scale = 1.0
	sword_damage = def_sword_damage
	#dash_cooldown = def_dash_cooldown
	
	update_fire_rate()
	animation_player.play_backwards('activate_ability')
	is_ability_active = false

func _on_damage_timer_timeout():
	can_take_damage = true

func get_player_sprite():
	return %PlayerSprite

func take_damage(amount:int,is_boss_ability_active:bool=false):
	#if is_boss_ability_active == true :
		#amount *= boss.ability_damage
	#amount *= damage_scale
	#amount *= enemy_damage_multiplier
	if can_take_damage:
		spawn_popup_text(str(amount),popup_damage_color)
		tween_manager.take_damage_tween(get_player_sprite())
		current_health -= amount
		can_take_damage = false
		damage_timer.start()
		#%DamagedAnimator.play("damaged")
		if current_health <= 0 and not death_dialog.is_visible_in_tree() :
			can_take_damage = false
			die()
	%Damaged.playing = true

func die():
	#if trade_revivor in active_trades and\
	#ability_max_charge == current_ability_charge:
		#ActivateAbility()
		#add_health(25)
	is_player_died = true
	explosive_particles(20,modulate)
	camera_shake()
	animation_player.play("death")
	await animation_player.animation_finished
	var time : String = %Time.text
	death_dialog.play(kills,time)
	health_bar.hide()


func explosive_particles(amount:int,modul:Color=collision.modulate,parti_scale:float=1):
	const EXPLODE_PAR = preload("res://Components/Explosions/ExplodePar.tscn")
	var explode_par = EXPLODE_PAR.instantiate()
	explode_par.scale *= Vector2(parti_scale,parti_scale)
	explode_par.position = position
	explode_par.modulate = modul
	explode_par.amount = amount
	get_parent().add_child(explode_par)
	explode_par.emitting = true
	await get_tree().create_timer(3).timeout
	explode_par.queue_free()

func update_fire_rate():
	shoot_timer.wait_time = fire_rate

func _on_ability_ends() -> void:
	can_take_damage = true
	

func _on_ability_charged() -> void:
	pass

func _on_ability_touch_button_pressed() -> void:
	if current_ability_charge >= ability_max_charge: 
		ActivateAbility()
		print('ultimate touch button pressed')

func _on_dash_touch_button_pressed() -> void:
	if !is_player_died :
		dash_manager()
		print('dash touch button pressed')

func _on_swipe_attack_touch_btn_pressed() -> void:
	switch_attack_type()

func _on_dash_animation_animation_finished(anim_name: StringName) -> void:
	if anim_name == "start_dash":
		finish_dash()

func _on_fanger_area_body_entered(body: Node2D) -> void:
	if body is BaseEnemy:
		print('fanged enemy')
		if is_fanging:
			body.take_damage(30)
			add_health(15)
			fanged_enemies.append(body)
			current_fanger_hits += 1
			if current_fanger_hits >= max_fanger_hits:
				finish_dash()
			fanger_target = get_next_fanger()
			fanger_direction = \
			(fanger_target.global_position-global_position).normalized()
			if fanger_target == null:
				finish_dash()
			print('got fanged')

func get_next_fanger():
	var nearest_enemy :BaseEnemy = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group('enemies'):
		if not is_instance_valid(enemy) :continue
		if enemy in fanged_enemies:continue
		var distance = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	if nearest_enemy != null \
	and nearest_distance > fanger_max_distance:
		return null
	return nearest_enemy as BaseEnemy

#func _on_dash_step_cooldown_timer_timeout() -> void:
	#charge_dash(dash_step_charge)
	#dash_step_cooldown_timer.start()

func _on_shoot_timer_timeout() -> void:
	attack_delay_bar.hide()

func _on_swap_touch_button_pressed() -> void:
	dash_manager()

#func _on_rage_cooldown_timeout() -> void:
	#unrage()
	#rage_cooldown.stop()

func _on_fire_animator_animation_finished(anim_name: StringName) -> void:
	fire_animator.play("fire_loop")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name=='activate_ability':fire_animator.play("fire_loop")
	elif anim_name =='death':hide()

func _on_native_ult_charge_timeout() -> void:
	charge_ability(1)

func _on_dash_coodown_timeout() -> void:
	can_dash = true
