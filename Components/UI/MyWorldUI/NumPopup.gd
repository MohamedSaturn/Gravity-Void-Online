extends Node2D
class_name PopupText
signal popup_show

@onready var label = $Label
@export var position_range :int = 66
@export var tween_duration :float = 1
@export var y_direction :int = -75
@export var max_scaled :float = 0.25

func popup(spawn_position:Vector2,text:String,color:Color):
	var rangee =\
	Vector2(randi_range(-position_range,position_range),
	randi_range(-position_range,position_range*5))
	position = spawn_position + rangee
	set_text(text)
	set_color(color)
	emit_signal('popup_show')

func _ready():
	modulate.a = 0.0
	var tween :Tween = create_tween()
	tween.tween_property(self, "position",
	 position + Vector2(0, y_direction), tween_duration)
	tween.parallel().tween_property(self, "modulate:a", 1.0, tween_duration/2)
	await tween.finished
	var hide_tween = create_tween()
	var hide_tween_dur = 0.15
	hide_tween.tween_property(self,
	 "scale", Vector2(max_scaled,max_scaled), hide_tween_dur)
	hide_tween.parallel().tween_property(self,
	 "modulate:a", 0.0, hide_tween_dur)

func set_text(text:String):
	$Label.text = text

func set_color(color:Color):
	$Label.add_theme_color_override("font_color",color)
