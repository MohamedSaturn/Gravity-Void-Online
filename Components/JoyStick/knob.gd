extends Sprite2D
class_name Knob
signal joystick_pressed
signal joystick_released
@onready var parent: Joystick = $".."

var pressing :bool = false
var touch_index :int = -1
var touch_positions :Dictionary = {}

@export var maxLength :int = 50
@export var deadzone :int = 5

func _ready():
	set_process_input(true)
	maxLength *= parent.scale.x

func _process(delta):
	parent.is_pressing = pressing
	if pressing:
		var touch_pos := get_touch_position_safe()
		if touch_pos != Vector2.ZERO:
			if touch_pos.distance_to(parent.global_position) <= maxLength:
				global_position = touch_pos
			else:
				var angle := (touch_pos - parent.global_position).angle()
				global_position = parent.global_position + Vector2(cos(angle), sin(angle)) * maxLength
			calculate_vector()
	else:
		global_position = lerp(global_position, parent.global_position, delta * 50)
		parent.pos_vector = Vector2.ZERO

func calculate_vector():
	var dir := global_position - parent.global_position
	if dir.length() >= deadzone:
		parent.pos_vector = dir.normalized()
	else:
		parent.pos_vector = Vector2.ZERO

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_positions[event.index] = event.position
		else:
			if touch_positions.has(event.index):
				touch_positions.erase(event.index)
	elif event is InputEventScreenDrag:
		touch_positions[event.index] = event.position
	if event is InputEventScreenTouch:
		if event.pressed and not pressing:
			if parent.get_global_rect().has_point(event.position):
				pressing = true
				emit_signal('joystick_pressed')
				touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			pressing = false
			emit_signal('joystick_released')
			touch_index = -1

func get_touch_position_safe() -> Vector2:
	if touch_index >= 0 and touch_positions.has(touch_index):
		return touch_positions[touch_index]
	return Vector2.ZERO
