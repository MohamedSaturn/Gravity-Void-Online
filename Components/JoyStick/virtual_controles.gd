extends CanvasLayer
class_name VirtualControls

@onready var aim_joystick: Node2D = %JoystickAim
@onready var move_joystick: Node2D = %JoystickMove
@onready var dash_button: TouchScreenButton = %DashBtn

var move_vector := Vector2.ZERO
var aim_vector := Vector2.ZERO
signal dash_pressed

func _ready():
	dash_button.pressed.connect(func(): emit_signal("dash_pressed"))

func _process(_delta):
	move_vector = get_stick_vector(move_joystick)
	aim_vector = get_stick_vector(aim_joystick)

func get_stick_vector(joystick_node: Node2D) -> Vector2:
	var base = joystick_node.get_node("Base")
	var knob = joystick_node.get_node("Knob")

	if Input.is_action_pressed("ui_touch"):
		# If you later want touch dragging detection per joystick, add logic here.
		pass

	# This will be filled when we add drag input detection
	return Vector2.ZERO
