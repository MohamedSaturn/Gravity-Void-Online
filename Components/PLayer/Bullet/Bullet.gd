extends Area2D
class_name PlayerBullet

@export var speed = 400
@export var damage = 15
@export var destroy_time :float = 3
@export var hide_time :float = 1
@export var bullet_damage_afte = 0.5
@export var speed_scale = 1

@onready var coll = %Coll
@onready var animation_player :AnimationPlayer= $AnimationPlayer
@onready var destroy_timer = %DestroyTimer
@onready var hide_timer = %HideTimer
@onready var particles = %Particles

var player :Player
var direction = Vector2.ZERO
var can_damaging = true
var player_ability_activaded = false
var speed_scale_anim = 1
var destroy_after_collide = true
var can_explode = false

func _ready():
	animation_player.speed_scale = speed_scale_anim
	player_ability_activaded = player.is_ability_active
	animation_player.play("bullet_move")
	z_index = -1
	destroy_timer.wait_time = destroy_time
	hide_timer.wait_time = hide_time
	destroy_timer.start()
	hide_timer.start()
	match player_ability_activaded:
		true:
			%TrailAbi.show()
			%Heart.show()
		_:%TrailDef.show()

func _physics_process(delta):
	position += direction * speed * delta

const ENEMY_SLOWER = preload("res://Components/Enemies/EnemySlower.tscn")

func get_core():
	return %Core as Polygon2D

func get_trail():
	return %TrailDef as Polygon2D

func get_particles():
	return %Particles as CPUParticles2D

func spawn_slower():
	var slower = ENEMY_SLOWER.instantiate()
	slower.position = position
	slower.modulate = modulate 
	get_parent().call_deferred('add_child',slower) #aftor 0.1.2.2
	

func destroy():
	queue_free()

func disable_coll():
	animation_player.stop()
	coll.hide()
	can_damaging = false
	particles.emitting = false
	#coll.disabled = true
	if can_explode:
		spawn_explosion()
		can_explode = false
	#call_deferred()
	#set_deferred()

func _on_body_entered(body):
	if body == null:return
	elif body is BaseEnemy:
		if can_damaging == true :
			var enemy :BaseEnemy = body
			enemy.take_damage(damage)
			disable_coll()
			#if destroy_after_collide == true:
	elif body.is_in_group('collisions') :
		disable_coll()
	elif body.is_in_group('boss_armor') \
	and player_ability_activaded == false:
		disable_coll()

const EXPLOSION = preload("res://Components/Explosions/Explosion.tscn")

func spawn_explosion():
		var explode = EXPLOSION.instantiate() as Explosion
		explode.position = position
		explode.modulate = get_core().color
		explode.damage_player = false
		explode.damage_enemy = true
		get_parent().call_deferred('add_child',explode) #aftor 0.1.2.2

func _on_destroy_timer_timeout():
	destroy()
#
#func _on_hide_timer_timeout(): ##idk why its comment
	#disable_coll()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == 'bullet_move':
		disable_coll()
