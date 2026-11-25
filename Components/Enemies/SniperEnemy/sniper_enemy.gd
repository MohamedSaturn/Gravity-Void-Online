class_name SniperEnemy
extends RangedEnemy

func _ready():
	super._ready()

func activate_ultimate():
	super.activate_ultimate()
	fire_rate *= 0.5
