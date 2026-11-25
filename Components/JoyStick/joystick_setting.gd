extends Area2D

@export_enum('move','aim','ult','dash') var joystick_type :String
signal drag_finished(final_position: Vector2)

var is_dragging: bool = false

func _input(event: InputEvent) -> void:
	# Check if the touch has stopped
	if event is InputEventScreenTouch and not event.pressed:
		if is_dragging:
			is_dragging = false
			# 2. Emit the signal and pass the final position as data
			drag_finished.emit(global_position)

	# Update position while dragging
	if is_dragging and event is InputEventScreenDrag:
		global_position = event.position

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		is_dragging = true

func on_drag_finished(final_position: Vector2) -> void:
	match joystick_type:
		'move':Global.controles_data.move = final_position
		'aim':Global.controles_data.aim = final_position
		'ult':Global.controles_data.ult = final_position
		'dash':Global.controles_data.dash = final_position
