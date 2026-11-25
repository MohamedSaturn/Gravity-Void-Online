extends ProgressBar

func _on_value_changed(value: int) -> void:
	%Label.text = str(value)
