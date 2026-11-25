class_name BaseEnemy
extends CharacterBody2D
signal enemy_died(enemy:BaseEnemy)
signal damaged(amount:int,curr_health:int)

@export var speed = 150
@export var max_health = 90
@export var die_parti_amount = 7
@export var bars_cont_hight = 90
@export var main_color = Color.html('#c41f51')
@export var animation_player :AnimationPlayer
@export var can_spawn_playerhp = true
@export var new_path_cooldown = 1.0
@export_group('Ultimate')
@export var ultimate_color :Color
var ultimate_max_charge = 100
@export var ultimate_charger_points = 4
@export var ultimate_current_charge = 0
@export var can_spawn_fragment = true
var tween_manager : TweenManager
var explode_particles := preload('res://Components/Explosions/ExplodePar.tscn')
var triangle := preload('res://Assets/Sprites/triangle.png')
var explosion := preload('res://Components/Explosions/Explosion.tscn')
var enemy_spear = preload("res://Components/Enemies/SpearEnemy/EnemySpear.tscn")
const ult_fragment = preload("res://Components/PLayer/Items/UltimateFragment.tscn")
var player_hp_node := preload('res://Components/PLayer/Items/PlayerHP.tscn')
var can_move = false
var boss :BaseEnemy
var current_health :float
var target: Player = null
var wall: StaticBody2D = null
var color = Color.INDIAN_RED
var defult_color = Color.WHITE
var defult_speed = 0
var un_slow_time = 3
var stop_the_slow = false
var defult_modulate 
var can_take_damage = true
var is_slowed = false
var is_ultimate_active = false
var start_tween_finished = false
@onready var un_slow_timer = %UnSlowTimer
@onready var path_finding: NavigationAgent2D = $PathFinding
@onready var hp_bar = %HPBar as ProgressBar
@onready var coll = %Coll as CollisionShape2D
@onready var sprite: Node2D = %Sprite

#func play_slow_anim(back_wards):
	#if back_wards == false and is_slowed == false:
		#animation_player.play("get_slowness")
	#if back_wards == true :
		#animation_player.play_backwards("get_slowness")
@onready var new_path_timer: Timer = %NewPathTimer

func _ready():
	ultimate_particles.emitting = false
	ultimate_particles.modulate = ultimate_color
	ultimate_charger.start()
	new_path_timer.wait_time = new_path_cooldown
	defult_modulate = coll.modulate
	defult_speed = speed
	current_health = max_health
	ready_bars()
	spawn_tween()

@onready var bars_container: VBoxContainer = %BarsContainer
@onready var ultimate_bar: ProgressBar = %UltimateBar

func ready_bars():
	ultimate_bar.max_value = ultimate_max_charge
	bars_container.show()
	hp_bar.max_value = max_health
	hp_bar.value = max_health
	var max_size = 200
	var size_x = hp_bar.max_value*0.9+40
	hp_bar.custom_minimum_size.x = size_x if size_x < max_size else max_size
	bars_container.position.x = -(bars_container.size.x/2)
	hp_bar.custom_minimum_size.y = 18
	ultimate_bar.custom_minimum_size.x = ultimate_max_charge
	bars_container.position.y = -bars_cont_hight

var is_ultimate_chrged = false

func charge_ultimate(amount:int):
	if is_ultimate_active == false :
		if ultimate_current_charge < ultimate_max_charge:
			ultimate_current_charge += amount
		else:
			ultimate_current_charge = ultimate_max_charge
			activate_ultimate()
			bar_visible(ultimate_bar,false)
		ultimate_bar.value = ultimate_current_charge

func _physics_process(delta):
	if coll and target:
		coll.look_at(target.global_position)
	if not start_tween_finished:
		return 
	chase_behavior(delta)

func chase_behavior(delta):
	if target and target.is_player_died == false :
		var distance = position.distance_to(target.position)
		var direction = to_local(path_finding.get_next_path_position()).normalized()
		if can_move == true:
			move(direction,delta)
			move_and_slide()

func spawn_tween():
	var tween = create_tween()
	var tween_dur = 0.5
	var org_coll_scale = coll.scale
	coll.scale *= 0.2
	coll.modulate.a = 0.0
	hp_bar.modulate.a = 0.0
	tween.tween_property(coll,'scale',org_coll_scale,tween_dur)
	tween.parallel().tween_property(coll,'modulate:a',1.0,tween_dur)
	tween.parallel().tween_property(hp_bar,'modulate:a',1.0,tween_dur)
	await tween.finished
	start_tween_finished = true
	make_path()

func move(direction,delta):
	velocity = direction * speed

func spawn_player_hp():
	var player_hp :HealthCube = player_hp_node.instantiate()
	if target.is_ability_active:
			player_hp.amount *= max_health*0.1
	player_hp.position = position + get_random_vector()
	player_hp.player = target
	get_parent().add_child(player_hp)

func spawn_ult_fragment():
	var fragment :UltFragment = ult_fragment.instantiate()
	fragment.position = position + get_random_vector()
	fragment.player = target
	get_parent().add_child(fragment)

func add_explosion():
	var explode = explosion.instantiate()
	explode.position = position
	explode.modulate = main_color
	get_parent().add_child(explode)
@onready var ultimate_particles: CPUParticles2D = %UltimateParticles

func activate_ultimate():
	animation_player.play("ultimate_activated")
	is_ultimate_active = true
	ultimate_particles.emitting = true
	main_color = ultimate_color
	spawn_die_parti()
	target.camera_shake()

func make_path():
	path_finding.target_position = target.global_position

func spawn_popup_text(text:String ,color:Color):
	if target.is_player_died == false:
		var popup_text := preload('res://Components/UI/MyWorldUI/NumPopup.tscn')
		var popup := popup_text.instantiate()
		popup.popup(global_position,text,color)
		get_parent().add_child(popup)

func add_health(amount:int):
	var visible_health :int = amount
	var new_health = current_health + amount
	if new_health >= max_health:
		visible_health = new_health - max_health
		current_health = max_health
	else:current_health += amount
	var heal_color = Color.html("#88aa77").darkened(0.3)
	if not visible_health ==0:
		spawn_popup_text(str(visible_health),heal_color)
	update_hpbar()

func bar_visible(bar:ProgressBar,is_visible:bool):
	if is_visible:bar.modulate.a = 1.0
	else:bar.modulate.a = 0.0

func spawn_die_spear():
	var die_spear := enemy_spear.instantiate()
	get_tree().root.add_child(die_spear)
	die_spear.modulate = coll.modulate
	die_spear.damage_aftr_drop 
	die_spear.position = position
	die_spear.look_at(target.position)
	die_spear.droped = true
	die_spear.direction = (Vector2(
		target.position - position)).normalized()
	die_spear.throw_spear()

func take_damage(amount: int,attack_type:String='range'):
	current_health -= amount 
	tween_manager.take_damage_tween(coll)
	emit_signal('damaged',amount,current_health)
	var color_damage :Color = target.popup_enemy_damaged_color
	var color_wow_damake :Color = target.popup_damage_wow_color
	spawn_popup_text(str(amount)if attack_type == 'range'\
	else str(amount)+ '!',color_damage\
	if attack_type == 'range' else color_wow_damake)
	if target.trade_abi_charger in target.active_trades:
		target.charge_ability(1)
	if current_health <= 0:
		die()
	update_hpbar()

func update_hpbar():
	hp_bar.value = current_health

func die():
	bars_container.hide()
	emit_signal('enemy_died',self)
	if target.is_ability_active and can_spawn_playerhp:
		call_deferred("spawn_player_hp")
	elif can_spawn_fragment:
		call_deferred("spawn_ult_fragment")
	spawn_die_parti()
	collision_layer = 0
	collision_mask = 0 #why?
	die_tween()

func get_random_vector(max_distance:float=20) -> Vector2:
	var rand_x = randf_range(-max_distance,max_distance)
	var rand_y = randf_range(-max_distance,max_distance)
	return Vector2(rand_x,rand_y)

func die_tween():
	var tween_time = 0.15
	var die_tween = create_tween()
	die_tween.tween_property(coll,'scale',Vector2(3,3),tween_time)
	die_tween.parallel().tween_property(coll,'modulate',Color.TRANSPARENT,tween_time)
	await die_tween.finished
	call_deferred('queue_free')

func spawn_die_parti():
	var die_par :CPUParticles2D= explode_particles.instantiate()
	die_par.texture = triangle
	die_par.position = position
	die_par.modulate = main_color
	die_par.amount = die_parti_amount+1
	#die_par.speed_scale *= 1
	get_parent().call_deferred('add_child',(die_par)) ##aftor 0.1.2.2
	die_par.emitting = true

func _on_new_path_timer_timeout():
	if path_finding:
		make_path()
@onready var ultimate_charger: Timer = %UltimateCharger

func _on_ultimate_charger_timeout() -> void:
	charge_ultimate(ultimate_charger_points)
	ultimate_charger.start()
	
