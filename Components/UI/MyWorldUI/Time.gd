class_name GameTime
extends Label

var second : int = 0
var minute : int = 0
var hour : int = 0
var stop = false

func _ready() -> void:
	_on_timer_timeout()

func _process(delta):
	text =  str(minute) + ":" + str(second)

func _on_timer_timeout():
	if stop == false:
		if minute == 59 :
			minute = 0
			hour += 1

		if second == 59 :
			second = 0
			minute += 1
		else :
			second += 1

func stop_time():
	stop = true

func reset_time():
	second = 0
	minute = 0
	hour = 0
