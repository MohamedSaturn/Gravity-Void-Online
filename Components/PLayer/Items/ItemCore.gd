extends Area2D
class_name DroppedItem
signal about_to_hide
@export var despawn_timer = 10
var coll:Node2D

func _ready(): 
	spawn_tween(coll)
	await get_tree().create_timer(despawn_timer).timeout
	spawn_tween(coll,true)

func des_obj():
	queue_free()

func spawn_tween(coll:Node2D,despawn=false):
	var tween = create_tween()
	var tween_dur = 0.25
	if not despawn:
		coll.scale *= 0.5
		coll.modulate.a = 0.0
	match despawn:
		false:
			tween.tween_property(
				coll,'scale',Vector2(1,1),tween_dur)
			tween.parallel().tween_property(
				coll,'modulate:a',1.0,tween_dur)
			await tween.finished
			set_deferred("monitoring", true)
		true:
			emit_signal('about_to_hide')
			tween.tween_property(
				coll,'scale',Vector2(0.5,0.5),tween_dur)
			tween.parallel().tween_property(
				coll,'modulate:a',0.0,tween_dur)
			await tween.finished
			des_obj()
