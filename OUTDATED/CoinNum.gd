extends HBoxContainer

@onready var coin = %Coin
@onready var label = %Label

func _process(delta):
	coin.text = str(Global.current_coin)
	
