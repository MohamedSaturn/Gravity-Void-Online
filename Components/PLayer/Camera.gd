extends Camera2D

@export var random_strength = 30.0
@export var shake_fade = 5.0

var rng = RandomNumberGenerator.new()
var shake_strength = 0.0
const MIN_SHAKE_THRESHOLD = 0.01

func _ready():
	rng.randomize()
	offset = Vector2.ZERO
	#zoom *= 0.85
	

func apply_shake(strength: float = -1.0):
	queue_shake(strength)

func queue_shake(strength: float = -1.0) -> void:
	if strength <= 0.0:
		shake_strength = max(shake_strength, random_strength)
	else:
		shake_strength = max(shake_strength, strength)

func _process(delta: float) -> void:
	if shake_strength > MIN_SHAKE_THRESHOLD:
		shake_strength = lerpf(shake_strength, 0.0, shake_fade * delta)
		offset = _random_offset(shake_strength)
	else:
		shake_strength = 0.0
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO

func _random_offset(strength: float) -> Vector2:
	return Vector2(
		rng.randf_range(-strength, strength),
		rng.randf_range(-strength, strength)
	)
