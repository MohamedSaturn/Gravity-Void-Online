extends Area2D
class_name EnemyBullet
signal hits_player(shooter:BaseEnemy)
@export_enum('normal','exploded') var type = 'normal'
@export var speed = 700
@export var damage = 20
@export var destroy_time = 1
@export var hide_time = 1
@export var speed_scale_anim = 0.25

var disabled = false
var is_slowed = false
var target : Player
var direction = Vector2.ZERO
var boss_ability_is_active = false
var can_deal_damage = true
var shooter :RangedEnemy
@onready var particles = $Particles
@onready var hide_timer = $HideTimer
@onready var animation_player = $AnimationPlayer
@onready var coll = %Coll
@onready var destroy_timer = $DestroyTimer

func _ready():
	animation_player.speed_scale = speed_scale_anim
	destroy_timer.wait_time = destroy_time
	hide_timer.wait_time = hide_time
	destroy_timer.start()
	hide_timer.start()

func play_anim(anim:String):
	animation_player.play(anim)

func _physics_process(delta):
	position += direction  * speed * delta

func _on_bullet_body_entered(body):
	if body.is_in_group('player') :
		if type == 'normal' and can_deal_damage == true:
			emit_signal('hits_player',shooter)
			body.take_damage(damage,boss_ability_is_active)
		disable()
	elif body.is_in_group('collisions'):
		disable()

func get_coll():
	return coll

func disable():
	particles.emitting = false
	direction = Vector2.ZERO
	coll.visible = false
	#coll.disabled = true
	#disabled = true
	can_deal_damage = false

func destroy():
	queue_free()

func _on_destroy_time_timeout():
	destroy()

func _on_animation_player_animation_finished(anim_name):
	disable()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group('enemy_bullet_slower') and is_slowed == false:
		slow_bullet(area,true)
@onready var animation_player_two: AnimationPlayer = %AnimationPlayerTwo

func slow_bullet(bullet_slower:EnemyBulletSlower,toggle:bool):
	var slow_rate = bullet_slower.bullet_slow_rate
	if self:
		if bullet_slower.can_slow == true:
			if toggle == true:
				speed *= slow_rate
				animation_player.speed_scale *= slow_rate
				#animation_player_two.play("slow")
			if toggle == false:
				speed /= slow_rate
				animation_player.speed_scale /= slow_rate
				#animation_player_two.play_backwards("slow")
		is_slowed = toggle

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group('enemy_bullet_slower'):
		slow_bullet(area,false)
