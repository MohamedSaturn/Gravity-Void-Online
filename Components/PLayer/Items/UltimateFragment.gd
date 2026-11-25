extends DroppedItem
class_name UltFragment

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = %Collision
var player : Player
@export var charge_amount = 8
@export var heal_amount = 12

func _ready() -> void:
	coll = collision
	super._ready()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	animation_player.play("move")

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		#if body.is_ability_active:
			#body.add_health(heal_amount)
		if body.current_ability_charge < body.ability_max_charge:
			body.charge_ability(charge_amount)
			body.spawn_popup_text(
									'+'+str(charge_amount)+ ' Fragment!',
									body.popup_ability_charged_color.lightened(0.35))
		spawn_tween(coll,true)
