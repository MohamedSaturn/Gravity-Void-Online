extends Node
class_name TweenManager

func shoot_tween(node:Node2D): ## here is where the game is getting FUCKED
	if not node:return
	var tween = create_tween()
	var duration = 0.08
	var def_scale = node.scale.x
	tween.tween_property(node,'position:x',-15,duration)
	tween.parallel().tween_property(node,'scale:x',1.2,duration)
	tween.parallel().tween_property(node,'scale:y',0.8,duration)
	await get_tree().create_timer(duration).timeout
	if not node:return
	var new_tween = create_tween()
	new_tween.tween_property(node,'position:x',0.0,duration)
	new_tween.parallel().tween_property(node,'scale:x',def_scale,duration)
	new_tween.parallel().tween_property(node,'scale:y',def_scale,duration)

func take_damage_tween(node:Node2D):
	if not node:return
	var tween = create_tween() 
	var duration = 0.08
	tween.tween_property(node,'modulate:s',
	0.45,duration)
	if not node:return
	await get_tree().create_timer(duration).timeout
	var new_tween = create_tween()
	new_tween.tween_property(node,'modulate:s',
	0.0,duration)
