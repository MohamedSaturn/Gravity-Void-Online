extends Node

var def_abi_type = 'ss'
var def_gad_type = 'dash'
var selected_game_mode
var selected_score_map = 1
var is_opend_1st_time = false
var current_coin = 100
var is_ss_buy = true
var is_oo_buy = false
var is_hh_buy = false
var is_bb_buy = false
var is_dash_buy = true
var is_slow_buy = false
var is_flip_buy = false
var is_heal_buy = false
var current_gad = 'dash'
var current_abi = 'ss'
var hard_mode = false
var start_intro = true

var ult_1_stats = {}
var ult_2_stats = {}
var ult_3_stats = {}
var sword_stats = {}
var range_stats = {}

var active_trades = []
var def_trades = []

var selected_gamemode = 'boss'
var controles_data :Dictionary = {
	'opacity':1.0,
	'move':Vector2(180,530),
	'aim':Vector2(1415,530),
	'ult':Vector2(1141,375),
	'dash':Vector2(1384,310)
}
