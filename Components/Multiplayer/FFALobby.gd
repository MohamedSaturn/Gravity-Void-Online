class_name FFA_LOBBY extends Control
## Lobby for Free-For-All: host a game or join one by IP, then start the match.

const GAME_THEME := preload("res://Assets/Res/GameTheme.tres")
const CONFIG_PATH := "user://ffa.cfg"

var _name_edit: LineEdit
var _ip_edit: LineEdit
var _port_edit: LineEdit
var _status: Label

var _connect_box: VBoxContainer
var _lobby_box: VBoxContainer
var _players_label: RichTextLabel
var _address_label: Label
var _host_options: VBoxContainer
var _kill_spin: SpinBox
var _time_spin: SpinBox
var _start_btn: Button
var _wait_label: Label

func _ready() -> void:
	theme = GAME_THEME
	_build_ui()
	_load_config()
	Net.players_changed.connect(_refresh_players)
	Net.join_failed.connect(_on_join_failed)
	Net.connected_to_host.connect(func(): _set_status("Connected, waiting for the host..."))
	if Net.is_online():
		# Coming back from a finished match
		_show_lobby()
	_refresh_players()

# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(560, 0)
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "FREE FOR ALL"
	title.add_theme_font_size_override("font_size", 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	# ---- before connecting
	_connect_box = VBoxContainer.new()
	_connect_box.z_index=9
	_connect_box.add_theme_constant_override("separation", 12)
	root.add_child(_connect_box)
	_name_edit = _add_field(_connect_box, "Your name", "Player%d" % randi_range(100, 999))
	_name_edit.max_length = 16
	_ip_edit = _add_field(_connect_box, "Host IP address", "127.0.0.1")
	_port_edit = _add_field(_connect_box, "Port", str(Net.DEFAULT_PORT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_connect_box.add_child(row)
	var host_btn := _button("Host game")
	host_btn.pressed.connect(_on_host_pressed)
	row.add_child(host_btn)
	var join_btn := _button("Join game")
	join_btn.pressed.connect(_on_join_pressed)
	row.add_child(join_btn)

	# ---- after connecting
	_lobby_box = VBoxContainer.new()
	_lobby_box.z_index=10
	_lobby_box.add_theme_constant_override("separation", 12)
	_lobby_box.hide()
	root.add_child(_lobby_box)
	_address_label = Label.new()
	_address_label.add_theme_font_size_override("font_size", 22)
	_address_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lobby_box.add_child(_address_label)
	_players_label = RichTextLabel.new()
	_players_label.bbcode_enabled = true
	_players_label.fit_content = true
	_players_label.scroll_active = false
	_players_label.add_theme_font_size_override("normal_font_size", 28)
	_lobby_box.add_child(_players_label)

	_host_options = VBoxContainer.new()
	_host_options.add_theme_constant_override("separation", 10)
	_lobby_box.add_child(_host_options)
	_kill_spin = _add_spin(_host_options, "Kills to win (0 = off)", 0, 50, int(Net.settings["kill_limit"]))
	_time_spin = _add_spin(_host_options, "Time limit, minutes (0 = off)", 0, 30, int(Net.settings["time_limit"]) / 60)
	_start_btn = _button("Start match")
	_start_btn.pressed.connect(_on_start_pressed)
	_host_options.add_child(_start_btn)
	_wait_label = Label.new()
	_wait_label.text = "Waiting for the host to start..."
	_wait_label.add_theme_font_size_override("font_size", 24)
	_lobby_box.add_child(_wait_label)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 22)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)

	var back := _button("Back")
	back.pressed.connect(_on_back_pressed)
	root.add_child(back)

func _add_field(parent: Control, label_text: String, default_text: String) -> LineEdit:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.custom_minimum_size = Vector2(220, 0)
	l.add_theme_font_size_override("font_size", 26)
	row.add_child(l)
	var e := LineEdit.new()
	e.text = default_text
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.add_theme_font_size_override("font_size", 26)
	row.add_child(e)
	return e

func _add_spin(parent: Control, label_text: String, lo: int, hi: int, value: int) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 24)
	row.add_child(l)
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.value = value
	row.add_child(s)
	return s

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(200, 54)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 28)
	return b

func _set_status(text: String) -> void:
	_status.text = text

# ------------------------------------------------------------------ actions

func _apply_name() -> void:
	var n := _name_edit.text.strip_edges()
	Net.local_name = n if n != "" else "Player"

func _port() -> int:
	var p := _port_edit.text.to_int()
	return p if p > 0 and p < 65536 else Net.DEFAULT_PORT

func _on_host_pressed() -> void:
	_apply_name()
	_save_config()
	var err := Net.host_game(_port())
	if err != OK:
		_set_status("Could not host on port %d (error %d). Is it already in use?" % [_port(), err])
		return
	_set_status("")
	_show_lobby()

func _on_join_pressed() -> void:
	_apply_name()
	_save_config()
	var addr := _ip_edit.text.strip_edges()
	if addr == "":
		_set_status("Enter the host's IP address")
		return
	var err := Net.join_game(addr, _port())
	if err != OK:
		_set_status("Could not start connection (error %d)" % err)
		return
	_set_status("Connecting to %s..." % addr)
	_show_lobby()

func _on_start_pressed() -> void:
	Net.settings = {
		"kill_limit": int(_kill_spin.value),
		"time_limit": int(_time_spin.value) * 60,
	}
	if Net.settings["kill_limit"] == 0 and Net.settings["time_limit"] == 0:
		Net.settings["kill_limit"] = 10   # a match needs some way to end
	Net.start_match()

func _on_back_pressed() -> void:
	Net.leave()
	_lobby_box.hide()
	get_tree().change_scene_to_file(Net.MENU_SCENE)

func _on_join_failed(reason: String) -> void:
	_connect_box.show()
	_lobby_box.hide()
	_set_status(reason)

func _show_lobby() -> void:
	_connect_box.hide()
	_lobby_box.show()
	var is_host := multiplayer.is_server()
	_host_options.visible = is_host
	_wait_label.visible = not is_host
	if is_host:
		var ips := PackedStringArray()
		for a in IP.get_local_addresses():
			if a.count(".") == 3 and not a.begins_with("127.") and not a.begins_with("169.254."):
				ips.append(a)
		_address_label.text = "Friends join with one of: %s  (port %d)" % [", ".join(ips), _port()]
	else:
		_address_label.text = "Connected to %s" % _ip_edit.text

func _refresh_players() -> void:
	if _players_label == null:
		return
	var text := ""
	var ids: Array = Net.players.keys()
	ids.sort()
	for id in ids:
		var col := Net.get_player_color(id).to_html(false)
		var tag := "  (host)" if id == 1 else ""
		var you := "  <- you" if id == multiplayer.get_unique_id() else ""
		text += "[color=#%s]%s[/color]%s%s\n" % [col, Net.get_player_name(id).replace("[", "[lb]"), tag, you]
	_players_label.text = ""
	_players_label.append_text(text.strip_edges() if text != "" else "Waiting for players...")
	if _start_btn != null:
		_start_btn.text = "Start match (%d player%s)" % [Net.players.size(), "" if Net.players.size() == 1 else "s"]

# ------------------------------------------------------------------ remember name / IP

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ffa", "name", _name_edit.text)
	cfg.set_value("ffa", "ip", _ip_edit.text)
	cfg.set_value("ffa", "port", _port_edit.text)
	cfg.save(CONFIG_PATH)

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	_name_edit.text = str(cfg.get_value("ffa", "name", _name_edit.text))
	_ip_edit.text = str(cfg.get_value("ffa", "ip", _ip_edit.text))
	_port_edit.text = str(cfg.get_value("ffa", "port", _port_edit.text))
