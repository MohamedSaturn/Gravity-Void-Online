extends Area2D
class_name FFABullet
## Bullets are simulated on every peer, but only the server applies damage.

signal impacted(pos: Vector2, color: Color)

var owner_id := 0
var damage := FFAPlayer.BULLET_DAMAGE
var speed := FFAPlayer.BULLET_SPEED
var direction := Vector2.RIGHT
var color := Color.WHITE
var life := 1.8
var _dead := false

func _ready() -> void:
	rotation = direction.angle()
	$Core.color = color.lightened(0.5)
	$Trail.color = Color(color.r, color.g, color.b, 0.6)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _dead:
		return
	if body is FFAPlayer:
		var target := body as FFAPlayer
		if target.peer_id == owner_id or not target.alive or target.invulnerable:
			return
		if multiplayer.is_server():
			target.server_take_damage(damage, owner_id)
	_impact()

func _impact() -> void:
	_dead = true
	impacted.emit(global_position, color)
	queue_free()
