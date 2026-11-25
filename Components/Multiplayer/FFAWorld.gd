extends Node2D
class_name FFAWorld
## Free-For-All arena. Built mostly from code so the scene file stays trivial.
##
## Authority model
##   * Every peer moves/aims its own player (replicated by FFAPlayer/Sync).
##   * The server validates shots, applies damage, counts kills, respawns
##     players, runs the clock and decides when the match ends.

const PLAYER_SCENE := preload("res://Components/Multiplayer/FFAPlayer.tscn")
const BULLET_SCENE := preload("res://Components/Multiplayer/FFABullet.tscn")
const EXPLODE_PAR := preload("res://Components/Explosions/ExplodePar.tscn")
const SHOOT_PART := preload("res://Components/Explosions/shoot_part.tscn")
const NUM_POPUP := preload("res://Components/UI/MyWorldUI/NumPopup.tscn")
const JOYSTICK := preload("res://Components/JoyStick/joystick.tscn")
const CAMERA_SCRIPT := preload("res://Components/PLayer/Camera.gd")
const GAME_THEME := preload("res://Assets/Res/GameTheme.tres")
const SFX_SHOOT := preload("res://Assets/Sounds/Shoot25.wav")

const ARENA := Rect2(-1408, -608, 2816, 1216)
const SPAWN_POINTS: Array[Vector2] = [
	Vector2(-1150, -450), Vector2(1150, -450), Vector2(-1150, 450), Vector2(1150, 450),
	Vector2(0, -480), Vector2(0, 480), Vector2(-1150, 0), Vector2(1150, 0),
]
const RESPAWN_TIME := 3.0
const COUNTDOWN := 3

var match_active := false
var ended := false
var menu_open := false
var touch_mode := false

var kill_limit := 10
var time_limit := 300
var scores: Dictionary = {}   # peer_id -> {"kills": int, "deaths": int}

var players_node: Node2D
var bullets_node: Node2D
var spawner: MultiplayerSpawner
var camera: Camera2D
var move_joystick: Joystick
var aim_joystick: Joystick

var _time_display := -1
var _last_time_sent := -1
var _time_left := 0.0
var _dash_requested := false

# HUD
var _timer_label: Label
var _banner: Label
var _respawn_label: Label
var _board: RichTextLabel
var _feed: VBoxContainer
var _health_bar: ProgressBar
var _dash_bar: ProgressBar
var _menu_panel: PanelContainer
var _results_panel: PanelContainer
var _results_title: Label
var _results_board: RichTextLabel
var _results_host_box: HBoxContainer
var _results_wait: Label

# ------------------------------------------------------------------ setup

func _ready() -> void:
	Engine.time_scale = 1.0
	touch_mode = OS.has_feature("mobile")
	# Allows pressing F6 on this scene in the editor for a quick solo test.
	if not Net.is_online():
		Net.host_game()
		Net.in_match = true
	kill_limit = int(Net.settings.get("kill_limit", 10))
	time_limit = int(Net.settings.get("time_limit", 300))

	_build_environment()
	_build_camera()
	_build_arena()
	_build_networking()
	_build_hud()
	if touch_mode:
		_build_touch_controls()

	multiplayer.peer_disconnected.connect(_on_peer_left)
	if multiplayer.is_server():
		Net.all_peers_loaded.connect(_begin_match, CONNECT_ONE_SHOT)
	Net.notify_world_ready()

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_normalized = true
	env.set_glow_level(1, 2.3)
	env.set_glow_level(2, 5.0)
	env.set_glow_level(3, 11.0)
	env.set_glow_level(4, 0.0)
	env.glow_intensity = 2.04
	env.glow_strength = 0.66
	env.glow_bloom = 0.58
	env.glow_hdr_threshold = 1.08
	env.glow_hdr_scale = 1.54
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)

func _build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.set_script(CAMERA_SCRIPT)
	camera.zoom = Vector2(0.55, 0.55)   # whole arena is visible, like the original map
	add_child(camera)

func _build_arena() -> void:
	var outside := Polygon2D.new()
	outside.color = Color(0.0703, 0.08626, 0.19)
	outside.z_index = -12
	outside.polygon = PackedVector2Array([Vector2(-6000, -6000), Vector2(6000, -6000),
		Vector2(6000, 6000), Vector2(-6000, 6000)])
	add_child(outside)

	var floor_poly := Polygon2D.new()
	floor_poly.color = Color(0.0862745, 0.105882, 0.231373)
	floor_poly.z_index = -10
	floor_poly.polygon = PackedVector2Array([ARENA.position, Vector2(ARENA.end.x, ARENA.position.y),
		ARENA.end, Vector2(ARENA.position.x, ARENA.end.y)])
	add_child(floor_poly)

	var t := 300.0
	_add_wall(Rect2(ARENA.position.x - t, ARENA.position.y - t, ARENA.size.x + t * 2.0, t))
	_add_wall(Rect2(ARENA.position.x - t, ARENA.end.y, ARENA.size.x + t * 2.0, t))
	_add_wall(Rect2(ARENA.position.x - t, ARENA.position.y, t, ARENA.size.y))
	_add_wall(Rect2(ARENA.end.x, ARENA.position.y, t, ARENA.size.y))

	# Cover in the middle of the arena
	_add_pillar(Vector2.ZERO, Vector2(170, 170))
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			_add_pillar(Vector2(520.0 * sx, 240.0 * sy), Vector2(140, 140))
	queue_redraw()

func _add_wall(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = rect.get_center()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	body.add_child(cs)
	add_child(body)
	return body

func _add_pillar(center: Vector2, size: Vector2) -> void:
	var body := _add_wall(Rect2(center - size / 2.0, size))
	var h := size / 2.0
	var pts := PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	var fill := Polygon2D.new()
	fill.polygon = pts
	fill.color = Color(0.16, 0.19, 0.38)
	fill.z_index = -5
	body.add_child(fill)
	var outline := Line2D.new()
	outline.points = pts
	outline.closed = true
	outline.width = 5.0
	outline.default_color = Color(0.42, 0.47, 0.95, 0.8)
	outline.z_index = -4
	body.add_child(outline)

func _draw() -> void:
	var grid := Color(1, 1, 1, 0.035)
	var step := 176.0
	var x := ARENA.position.x
	while x <= ARENA.end.x:
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), grid, 2.0)
		x += step
	var y := ARENA.position.y
	while y <= ARENA.end.y:
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), grid, 2.0)
		y += step
	draw_rect(ARENA, Color(0.45, 0.5, 1.0, 0.85), false, 6.0)

func _build_networking() -> void:
	players_node = Node2D.new()
	players_node.name = "Players"
	add_child(players_node)
	bullets_node = Node2D.new()
	bullets_node.name = "Bullets"
	add_child(bullets_node)
	spawner = MultiplayerSpawner.new()
	spawner.name = "Spawner"
	add_child(spawner)
	spawner.spawn_path = spawner.get_path_to(players_node)
	spawner.spawn_function = _spawn_player

## Runs on every peer whenever the server spawns a player.
func _spawn_player(data: Variant) -> Node:
	var p: FFAPlayer = PLAYER_SCENE.instantiate()
	p.name = str(int(data["id"]))
	p.position = data["pos"]
	p.net_pos = data["pos"]
	p.world = self
	return p

func get_player(id: int) -> FFAPlayer:
	return players_node.get_node_or_null(str(id)) as FFAPlayer

func get_local_player() -> FFAPlayer:
	return get_player(multiplayer.get_unique_id())

# ------------------------------------------------------------------ input helpers

func get_move_input() -> Vector2:
	if touch_mode and move_joystick != null:
		return move_joystick.pos_vector
	return Input.get_vector("move left", "move right", "move up", "move down")

func consume_dash_request() -> bool:
	var r := _dash_requested
	_dash_requested = false
	return r

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not ended:
		_set_menu(not menu_open)

func _set_menu(open: bool) -> void:
	menu_open = open
	_menu_panel.visible = open

# ------------------------------------------------------------------ effects

func play_sfx(stream: AudioStream, volume_db: float = -6.0) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func burst(pos: Vector2, color: Color, amount: int, s: float) -> void:
	var p: CPUParticles2D = EXPLODE_PAR.instantiate()
	p.position = pos
	p.modulate = color
	p.amount = amount
	p.scale = Vector2(s, s)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(3.0).timeout.connect(p.queue_free)

func popup_text(pos: Vector2, text: String, color: Color) -> void:
	var pop: PopupText = NUM_POPUP.instantiate()
	pop.popup(pos, text, color)
	add_child(pop)

func shake(strength: float) -> void:
	if camera != null and camera.has_method("apply_shake"):
		camera.call("apply_shake", strength)

# ------------------------------------------------------------------ bullets

func spawn_bullet(owner_id: int, pos: Vector2, dir: Vector2) -> void:
	var b: FFABullet = BULLET_SCENE.instantiate()
	b.owner_id = owner_id
	b.position = pos
	b.direction = dir
	b.color = Net.get_player_color(owner_id)
	b.impacted.connect(_on_bullet_impact)
	bullets_node.add_child(b)
	var sp: CPUParticles2D = SHOOT_PART.instantiate()
	sp.position = pos
	sp.modulate = b.color
	add_child(sp)
	sp.emitting = true
	get_tree().create_timer(2.0).timeout.connect(sp.queue_free)
	play_sfx(SFX_SHOOT, -14.0)

func _on_bullet_impact(pos: Vector2, color: Color) -> void:
	burst(pos, color, 4, 0.45)

@rpc("authority", "call_local", "reliable")
func broadcast_bullet(owner_id: int, pos: Vector2, dir: Vector2) -> void:
	# The shooter's own client already showed this shot immediately.
	if owner_id == multiplayer.get_unique_id() and not multiplayer.is_server():
		return
	spawn_bullet(owner_id, pos, dir)

# ------------------------------------------------------------------ match flow (server)

func _begin_match() -> void:
	var ids: Array = Net.players.keys()
	ids.sort()
	var spots: Array[Vector2] = SPAWN_POINTS.duplicate()
	spots.shuffle()
	scores.clear()
	for i in ids.size():
		var id: int = ids[i]
		scores[id] = {"kills": 0, "deaths": 0}
		spawner.spawn({"id": id, "pos": spots[i % spots.size()]})
	_sync_scores.rpc(scores)
	_time_left = float(time_limit)
	_last_time_sent = -1
	_sync_time.rpc(time_limit if time_limit > 0 else -1)
	for i in range(COUNTDOWN, 0, -1):
		_show_banner.rpc(str(i), 0.9)
		await get_tree().create_timer(1.0).timeout
	_show_banner.rpc("FIGHT!", 1.0)
	_set_active.rpc(true)

func server_player_died(victim: int, killer: int) -> void:
	if ended:
		return
	if scores.has(victim):
		scores[victim]["deaths"] = int(scores[victim]["deaths"]) + 1
	if killer != victim and scores.has(killer):
		scores[killer]["kills"] = int(scores[killer]["kills"]) + 1
	_sync_scores.rpc(scores)
	_announce_kill.rpc(killer, victim)
	var p := get_player(victim)
	if p != null:
		p.die.rpc(killer)
	if kill_limit > 0 and scores.has(killer) and int(scores[killer]["kills"]) >= kill_limit:
		_finish_match()
		return
	await get_tree().create_timer(RESPAWN_TIME).timeout
	if ended:
		return
	p = get_player(victim)
	if p != null:
		p.respawn.rpc(_pick_spawn())

func _pick_spawn() -> Vector2:
	var candidates: Array = []
	for sp in SPAWN_POINTS:
		var nearest := INF
		for child in players_node.get_children():
			var other := child as FFAPlayer
			if other != null and other.alive:
				nearest = minf(nearest, sp.distance_to(other.position))
		candidates.append([nearest, sp])
	candidates.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var pick: Array = candidates[randi() % mini(3, candidates.size())]
	return pick[1]

func _leader() -> int:
	var best := -1
	var best_k := -1
	var best_d := 0
	var tie := false
	for id in scores.keys():
		var k := int(scores[id]["kills"])
		var d := int(scores[id]["deaths"])
		if k > best_k or (k == best_k and d < best_d):
			best = id
			best_k = k
			best_d = d
			tie = false
		elif k == best_k and d == best_d:
			tie = true
	return -1 if tie else best

func _finish_match() -> void:
	if ended:
		return
	ended = true
	_end_match.rpc(_leader(), scores)

func _on_peer_left(id: int) -> void:
	if not multiplayer.is_server():
		return
	var p := get_player(id)
	if p != null:
		p.queue_free()
	scores.erase(id)
	_sync_scores.rpc(scores)

func _process(delta: float) -> void:
	if multiplayer.is_server() and match_active and not ended and time_limit > 0:
		_time_left -= delta
		var secs := int(ceil(maxf(_time_left, 0.0)))
		if secs != _last_time_sent:
			_last_time_sent = secs
			_sync_time.rpc(secs)
		if _time_left <= 0.0:
			_finish_match()
	_update_hud()

# ------------------------------------------------------------------ match flow (RPCs)

@rpc("authority", "call_local", "reliable")
func _sync_scores(data: Dictionary) -> void:
	scores = data
	_board.text = ""
	_board.append_text(_board_bbcode(scores))

@rpc("authority", "call_local", "unreliable")
func _sync_time(seconds: int) -> void:
	_time_display = seconds

@rpc("authority", "call_local", "reliable")
func _set_active(value: bool) -> void:
	match_active = value

@rpc("authority", "call_local", "reliable")
func _show_banner(text: String, seconds: float) -> void:
	_banner.text = text
	_banner.show()
	_banner.modulate.a = 1.0
	_banner.pivot_offset = _banner.size / 2.0
	_banner.scale = Vector2(1.6, 1.6)
	var tw := create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(maxf(seconds - 0.5, 0.1))
	tw.tween_property(_banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(_banner.hide)

@rpc("authority", "call_local", "reliable")
func _announce_kill(killer: int, victim: int) -> void:
	var line := RichTextLabel.new()
	line.bbcode_enabled = true
	line.fit_content = true
	line.scroll_active = false
	line.custom_minimum_size = Vector2(380, 0)
	line.add_theme_font_size_override("normal_font_size", 24)
	if killer == victim:
		line.append_text("%s [color=#aaaaaa]self-destructed[/color]" % _colored_name(victim))
	else:
		line.append_text("%s [color=#aaaaaa]eliminated[/color] %s" % [_colored_name(killer), _colored_name(victim)])
	_feed.add_child(line)
	while _feed.get_child_count() > 5:
		_feed.get_child(0).queue_free()
		_feed.remove_child(_feed.get_child(0))
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(line, "modulate:a", 0.0, 0.5)
	tw.tween_callback(line.queue_free)

@rpc("authority", "call_local", "reliable")
func _end_match(winner: int, data: Dictionary) -> void:
	ended = true
	match_active = false
	scores = data
	_set_menu(false)
	if winner == -1:
		_results_title.text = "DRAW"
		_results_title.remove_theme_color_override("font_color")
	else:
		_results_title.text = "%s WINS!" % Net.get_player_name(winner).to_upper()
		_results_title.add_theme_color_override("font_color", Net.get_player_color(winner).lightened(0.3))
	_results_board.text = ""
	_results_board.append_text(_board_bbcode(scores))
	_results_host_box.visible = multiplayer.is_server()
	_results_wait.visible = not multiplayer.is_server()
	_results_panel.show()

# ------------------------------------------------------------------ HUD

func _colored_name(id: int) -> String:
	return "[color=#%s]%s[/color]" % [Net.get_player_color(id).to_html(false),
		Net.get_player_name(id).replace("[", "[lb]")]

func _board_bbcode(data: Dictionary) -> String:
	var ids: Array = data.keys()
	ids.sort_custom(func(a: int, b: int) -> bool:
		var ka := int(data[a]["kills"])
		var kb := int(data[b]["kills"])
		if ka != kb:
			return ka > kb
		return int(data[a]["deaths"]) < int(data[b]["deaths"]))
	var out := ""
	for id in ids:
		var me: bool = id == multiplayer.get_unique_id()
		var line: String = "%s   %d kills / %d deaths" % [_colored_name(id), int(data[id]["kills"]), int(data[id]["deaths"])]
		out += ("[b]%s[/b]" % line if me else line) + "\n"
	return out.strip_edges()

func _make_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.theme = GAME_THEME
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_timer_label = _make_label(34)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_timer_label)
	_timer_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_timer_label.custom_minimum_size = Vector2(500, 0)
	_timer_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_timer_label.offset_top = 10

	_banner = _make_label(130)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.hide()
	root.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.custom_minimum_size = Vector2(700, 200)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_BOTH

	_respawn_label = _make_label(40)
	_respawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_respawn_label.hide()
	root.add_child(_respawn_label)
	_respawn_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_respawn_label.custom_minimum_size = Vector2(700, 0)
	_respawn_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_respawn_label.offset_top = 110

	_board = RichTextLabel.new()
	_board.bbcode_enabled = true
	_board.fit_content = true
	_board.scroll_active = false
	_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board.add_theme_font_size_override("normal_font_size", 24)
	_board.add_theme_font_size_override("bold_font_size", 24)
	root.add_child(_board)
	_board.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_board.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_board.offset_left = -420
	_board.offset_right = -14
	_board.offset_top = 12

	_feed = VBoxContainer.new()
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_feed)
	_feed.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_feed.offset_left = 14
	_feed.offset_top = 52

	var bars := VBoxContainer.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bars)
	bars.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bars.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bars.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bars.offset_bottom = -18
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(380, 26)
	_health_bar.max_value = FFAPlayer.MAX_HEALTH
	_health_bar.show_percentage = false
	_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.add_child(_health_bar)
	_dash_bar = ProgressBar.new()
	_dash_bar.custom_minimum_size = Vector2(380, 12)
	_dash_bar.max_value = 1.0
	_dash_bar.show_percentage = false
	_dash_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.add_child(_dash_bar)

	_menu_panel = _make_panel(root)
	var mv := _menu_panel.get_child(0) as VBoxContainer
	mv.add_child(_title_label("Paused menu"))
	mv.add_child(_make_button("Resume", func(): _set_menu(false)))
	mv.add_child(_make_button("Leave match", _leave))

	_results_panel = _make_panel(root)
	var rv := _results_panel.get_child(0) as VBoxContainer
	_results_title = _title_label("")
	rv.add_child(_results_title)
	_results_board = RichTextLabel.new()
	_results_board.bbcode_enabled = true
	_results_board.fit_content = true
	_results_board.scroll_active = false
	_results_board.custom_minimum_size = Vector2(520, 0)
	_results_board.add_theme_font_size_override("normal_font_size", 26)
	rv.add_child(_results_board)
	_results_host_box = HBoxContainer.new()
	_results_host_box.add_theme_constant_override("separation", 12)
	_results_host_box.add_child(_make_button("Rematch", Net.start_match))
	_results_host_box.add_child(_make_button("Back to lobby", Net.return_to_lobby))
	rv.add_child(_results_host_box)
	_results_wait = _make_label(24)
	_results_wait.text = "Waiting for the host..."
	_results_wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(_results_wait)
	rv.add_child(_make_button("Leave", _leave))

func _make_panel(root: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.hide()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var margin_box := VBoxContainer.new()
	margin_box.add_theme_constant_override("separation", 14)
	panel.add_child(margin_box)
	return panel

func _title_label(text: String) -> Label:
	var l := _make_label(48)
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _make_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 56)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(callback)
	return b

func _update_hud() -> void:
	if _time_display >= 0:
		var t := "%d:%02d" % [_time_display / 60, _time_display % 60]
		_timer_label.text = t + ("   |   First to %d" % kill_limit if kill_limit > 0 else "")
	else:
		_timer_label.text = "First to %d" % kill_limit if kill_limit > 0 else ""
	var me := get_local_player()
	_health_bar.visible = me != null
	_dash_bar.visible = me != null
	_respawn_label.visible = false
	if me != null:
		_health_bar.value = me.health
		_dash_bar.value = me.get_dash_ratio()
		if not me.alive and not ended:
			_respawn_label.text = "Eliminated - respawning..."
			_respawn_label.visible = true

func _leave() -> void:
	Net.leave()
	get_tree().change_scene_to_file(Net.MENU_SCENE)

func _build_touch_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	move_joystick = JOYSTICK.instantiate()
	move_joystick.modulate = Color(0.463749, 0.716895, 0.861328, 1)
	move_joystick.position = Global.controles_data.move
	layer.add_child(move_joystick)
	aim_joystick = JOYSTICK.instantiate()
	aim_joystick.joy_type = "aim"
	aim_joystick.modulate = Color(0.8, 0.397978, 0.376471, 1)
	aim_joystick.position = Global.controles_data.aim
	layer.add_child(aim_joystick)
	var dash := Button.new()
	dash.text = "DASH"
	dash.custom_minimum_size = Vector2(120, 120)
	dash.position = Global.controles_data.dash - Vector2(60, 60)
	dash.modulate.a = 0.7
	dash.button_down.connect(func(): _dash_requested = true)
	layer.add_child(dash)
