extends Node2D
class_name World
@onready var player = %Player
@onready var spawn_timer = %SpawnTimer
@onready var spawn_point_1 = %SpawnPoint1
@onready var spawn_point_2 = %SpawnPoint2
@onready var spawn_point_3 = %SpawnPoint3
@onready var spawn_point_4 = %SpawnPoint4
@onready var rounds_manager: RoundsManager = %RoundsManager

@export var fast_enemy :PackedScene
@export var ranged_enemy :PackedScene
@export var sniper_enemy :PackedScene
@export var tank_enemy :PackedScene
@export var new_wizard_enemy: PackedScene

@export var power_control :PackedScene

var active_enemies = []
var last_spowned_enemy :BaseEnemy
var is_game_paused = false
@export var spawn_delay_time = 6.0
@export var spawn_enemies = false
@export var spawn_boss = true
@export_enum('train','boss','score','round') var game_type = 'boss'





func set_target_for_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is BaseEnemy:
			enemy.target = player
			enemy.wall = %Wall
			active_enemies.append(enemy)
			enemy.make_path()

@onready var joystick_control: Control = %JoystickControl
@onready var move_joystick: Joystick = %MoveJoystick
@onready var aim_joystick: Joystick = %AimJoystick
@onready var ultimate_joystick: UltimateJoystick = %UltimateJoystick
@onready var dash_button: DashButton = %DashButton

func _ready():
	joystick_control.modulate.a = Global.controles_data.opacity 
	move_joystick.position = Global.controles_data.move
	aim_joystick.position = Global.controles_data.aim
	ultimate_joystick.position = Global.controles_data.ult
	dash_button.position = Global.controles_data.dash
	rounds_manager.start_round()
	spawn_boss = false
	spawn_enemies = false
	##game_type = Global.selected_gamemode
	#match game_type :
		#'boss':
			#spawn_boss = true
			#spawn_enemies = false
		#'score':
			#spawn_boss = false
			#spawn_enemies = true
			#spawn_random_enemy()
		#'train':
			#spawn_boss = false
			#spawn_enemies = false
		#'round':
	#if game_type != 'boss':
		#%BOSS.queue_free()
	%WallColor.polygon = %WallCollision.polygon
	%WallColor.rotation = %WallCollision.rotation
	%WallCollision.position = Vector2.ZERO
	%WallColor.position = Vector2.ZERO
	%DeathDialog.hide()
	set_target_for_enemy()
	Engine.time_scale = 1
	if spawn_enemies:
		spawn_timer.wait_time = spawn_delay_time
		spawn_timer.connect("timeout", _on_spawn_timer_timeout)
		spawn_timer.start()

func _process(_delta):
	var fps :int = Engine.get_frames_per_second()
	%Fps.text = 'FPS : '+str(fps)

func spawn_random_enemy():
	var enemy_types = ["tank", "ranged", "sniper"]
	var random_type = enemy_types[randi() % enemy_types.size()]
	var spawn_pos = get_random_spawn_position()
	spawn_enemy(random_type, spawn_pos)

func get_random_spawn_position() -> Vector2:
	var pos = Vector2()
	var edge = randi() % 4 + 1
	match edge:
		1:pos = spawn_point_1.global_position
		2:pos = spawn_point_2.global_position
		3:pos = spawn_point_3.global_position
		4:pos = spawn_point_4.global_position
	return pos

func spawn_enemy(type: String, pos: Vector2):
	var enemy
	match type.to_lower():
		"tank":enemy = tank_enemy.instantiate()
		"ranged":enemy = ranged_enemy.instantiate()
		"sniper":enemy = sniper_enemy.instantiate()
		_:return
	enemy.position = pos
	enemy.target = player
	last_spowned_enemy = enemy
	add_child(enemy)
	active_enemies.append(enemy)
	enemy.tree_exiting.connect(func(): 
		active_enemies.erase(enemy)
		if enemy != %BOSS:
			player.kills += 1
		)

func _on_spawn_timer_timeout():
	if player.is_player_died == false :
		spawn_random_enemy()

#func pause_game():
	#%PauseManager.show()
	#Engine.time_scale = 0
	#is_game_paused = true

#func unpause_game():
	#Engine.time_scale = 1
	#is_game_paused = false
	#%PauseManager.hide()


#func _on_pause_dialog_continue_pressed() -> void:
	#unpause_game()

func _on_harder_timer_timeout() -> void:
	spawn_timer.wait_time *= 0.9
