extends Node
class_name RoundsManager

@export var ranged_enemy_scene : PackedScene
@export var sniper_enemy_scene : PackedScene
@export var spear_enemy_scene : PackedScene
@export var fast_ranged_enemy_scene : PackedScene
@export var wizard_enemy_scene : PackedScene
@export var spawn_points : Array[Marker2D] 
@export var player : Player
@export var rounds_text_anim : AnimationPlayer
@onready var rounds_text: Label = %RoundsText
@export var base_enemy_count = 3

var round_number = 1
var enemy_damage_multiplier = 1.0
var enemy_health_multiplier = 1.0
var active_enemies : Array[BaseEnemy]

func start_round():
	rounds_text_anim.play('start_round')
	print_rich("[b][color=red]Starting round: " + str(round_number))
	var enemy_count = base_enemy_count
	if round_number % 2 == 0: ## add enemy to the count every 4 rounds
		base_enemy_count += 1
		## here we make the cards system 
		enemy_count = base_enemy_count
	if round_number % 4 == 0 and not round_number == 1: ## buff the emeny stats every 2 rounds
		enemy_damage_multiplier += 0.1
		enemy_health_multiplier += 0.1
	for i in range(enemy_count):
		spawn_enemy()
		await get_tree().create_timer(1).timeout
	rounds_text.text = 'Round '+str(round_number)
	#%RoundsNode.position.x = %MAIN.size.x/2-20
	#%RoundsNode.position.y = 150
	for player_hp in get_tree().get_nodes_in_group('player_hp_node') as Array[HealthCube]:
		player_hp.follow_player()
@onready var tween_manager: TweenManager = %TweenManager

var safe_spawn_point :Array[Marker2D]
var last_enemy :BaseEnemy
func spawn_enemy(enemy_scene:PackedScene=get_enemy_by_chance()):
	if spawn_points.is_empty():
		return
	var random_int = randi_range(-25,25)*10
	var random_pos = Vector2(random_int,random_int)
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	if enemy_scene == null:
		return
	var enemy :BaseEnemy = enemy_scene.instantiate()
	enemy.target = player
	enemy.position =\
	spawn_point.position
	print(spawn_point.global_position + random_pos)
	## apply buffs
	player.enemy_damage_multiplier = enemy_damage_multiplier
	enemy.tween_manager = tween_manager
	enemy.max_health *= enemy_health_multiplier
	## start next round if all enemies died
	active_enemies.append(enemy)
	#add_child(enemy)
	call_deferred("add_child",enemy) #aftor 0.1.2.2
	enemy.enemy_died.connect(func(_enemy):
		active_enemies.erase(_enemy)
		if active_enemies.is_empty():
			next_round())
		#if _enemy != %BOSS:
			#player.kills += 1) after 0.1.2.2
		#print_rich("[color=gray]Enemy Killed: " + _enemy.type)
		#)
	#print_rich("[color=pink]Enemy Spawned Type: " + enemy.type)

func get_enemy_by_chance() -> PackedScene:
	var roll = randf() * 100
	if roll < 15:return wizard_enemy_scene
	if roll < 35:return ranged_enemy_scene
	elif roll < 55:return sniper_enemy_scene
	elif roll < 80:return fast_ranged_enemy_scene
	else:return spear_enemy_scene

func next_round():
	round_number += 1
	start_round()
