extends Area2D
class_name Sword

var attack_backwards = false
var damage :int = 32
var attack_health :int = 0
var attack_cooldown_time :float = 1
var can_attack = true
var can_damage = false

@export var animation_player: AnimationPlayer 
@export var attack_cooldown: Timer 
@onready var player: Player

func _physics_process(delta: float) -> void:
	if player:
		position = player.position

func attack(sword_damage:int=damage):
	player.can_attack_sword = false
	if attack_cooldown:
		attack_cooldown.wait_time = attack_cooldown_time
	if not can_attack:
		return
	can_attack = false
	can_damage = true
	animation_player.play("attack")
	var ability_active = player.is_ability_active
	%TrailAbi.visible = ability_active
	%heart.visible = ability_active
	if ability_active == true :
		if player.ability_type == 'ss' and player.is_dashing == false:
			player.dash_activated()
	await animation_player.animation_finished
	animation_finished()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemies') and can_damage:
		var enemy :BaseEnemy = body
		enemy.take_damage(damage,'mele')

func animation_finished() -> void:
	if not attack_cooldown:
		return
	attack_cooldown.start()
	can_damage = false
	await attack_cooldown.timeout 
	player.can_attack_sword = true
	queue_free()
