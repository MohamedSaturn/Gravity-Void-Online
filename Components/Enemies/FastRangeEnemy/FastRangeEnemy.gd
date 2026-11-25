extends RangedEnemy

func _ready():
	super._ready()

func activate_ultimate():
	super.activate_ultimate()
	bullet_range*=2
	bullet_scale*=0.5
