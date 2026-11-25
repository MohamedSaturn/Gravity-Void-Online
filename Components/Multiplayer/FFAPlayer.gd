extends CharacterBody2D
class_name FFAPlayer
## Player used by the Free-For-All mode.
## - Movement/aim: owned by the player's own peer (replicated by "Sync").
## - Health/death/respawn: decided by the server, announced through RPCs.

const RADIUS := 24.0
const MAX_HEALTH := 100
const MAX_SPEED := 300.0
const ACCEL := 2500.0
const FRICTION := 1700.0
const FIRE_RATE := 0.33
const BULLET_DAMAGE := 12
const BULLET_SPEED := 900.0
const MUZZLE_DISTANCE := 34.0
const DASH_SPEED := 950.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 1.2
const RESPAWN_INVULN := 2.0

const SFX_DASH := preload("res://Assets/Sounds/dash.wav")
const SFX_HURT := preload("res://Assets/Sounds/huh.wav")
const SFX_BOOM := preload("res://Assets/Sounds/Boom.wav")

var peer_id := 0
var player_name := ""
var color := Color.WHITE
var world: FFAWorld

var health := MAX_HEALTH
var alive := true
var invulnerable := false

# Replicated by the owner peer
var net_pos := Vector2.ZERO
var aim_angle := 0.0
var dashing := false:
	set(value):
		if value and not dashing and world != null and is_inside_tree():
			world.play_sfx(SFX_DASH, -8.0)
		dashing = value

var _shoot_cd := 0.0
var _dash_cd := 0.0
var _dash_time := 0.0
var _dash_dir := Vector2.RIGHT
var _last_server_shot := -10.0
var _ignore_net_until := 0.0

@onready var visual: Node2D = $Visual
@onready var core: Polygon2D = $Visual/Core
@onready var back: Polygon2D = $Visual/Back
@onready var name_label: Label = $NameLabel
@onready var sync: MultiplayerSynchronizer = $Sync
@onready var shape: CollisionShape2D = $Shape

func _enter_tree() -> void:
	peer_id = name.to_int()
	# The server owns the player node itself, the owning peer owns the input sync.
	$Sync.set_multiplayer_authority(peer_id)
	var cfg := SceneReplicationConfig.new()
	for prop in [".:net_pos", ".:aim_angle", ".:dashing"]:
		var path := NodePath(prop)
		cfg.add_property(path)
		cfg.property_set_spawn(path, false)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	$Sync.replication_config = cfg

func _ready() -> void:
	player_name = Net.get_player_name(peer_id)
	color = Net.get_player_color(peer_id)
	core.color = color.lightened(0.45)
	back.color = color
	name_label.text = player_name
	name_label.add_theme_color_override("font_color", color.lightened(0.3))
	if net_pos == Vector2.ZERO:
		net_pos = position
	queue_redraw()

func is_local() -> bool:
	return peer_id == multiplayer.get_unique_id()

# ---------------------------------------------------------------- per-frame

func _process(_delta: float) -> void:
	visual.rotation = aim_angle
	var a := 1.0
	if dashing:
		a = 0.45
	elif invulnerable:
		a = 0.4 + 0.4 * absf(sin(Time.get_ticks_msec() / 90.0))
	visual.modulate.a = a

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if is_local():
		_local_control(delta)
		net_pos = position
	else:
		var t := Time.get_ticks_msec() / 1000.0
		if t >= _ignore_net_until:
			if position.distance_to(net_pos) > 250.0:
				position = net_pos
			else:
				position = position.lerp(net_pos, clampf(20.0 * delta, 0.0, 1.0))

func _local_control(delta: float) -> void:
	var can_act := world != null and world.match_active and not world.menu_open
	_shoot_cd = maxf(_shoot_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)

	var move_input := world.get_move_input() if world != null and not world.menu_open else Vector2.ZERO
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_time <= 0.0:
			dashing = false
	else:
		if move_input != Vector2.ZERO:
			velocity = velocity.move_toward(move_input * MAX_SPEED, ACCEL * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

	var want_fire := false
	if world != null and world.touch_mode:
		if world.aim_joystick.is_pressing and world.aim_joystick.pos_vector != Vector2.ZERO:
			aim_angle = world.aim_joystick.pos_vector.angle()
			want_fire = true
	elif world != null and not world.menu_open:
		aim_angle = (get_global_mouse_position() - global_position).angle()
		want_fire = Input.is_action_pressed("attack")

	if can_act:
		if want_fire and _shoot_cd <= 0.0:
			_shoot_cd = FIRE_RATE
			_fire_local()
		var dash_pressed := Input.is_action_just_pressed("gadget") or world.consume_dash_request()
		if dash_pressed and _dash_cd <= 0.0 and _dash_time <= 0.0:
			_dash_dir = move_input if move_input != Vector2.ZERO else Vector2.from_angle(aim_angle)
			_dash_time = DASH_TIME
			_dash_cd = DASH_COOLDOWN
			dashing = true

func get_dash_ratio() -> float:
	return 1.0 - clampf(_dash_cd / DASH_COOLDOWN, 0.0, 1.0)

# ---------------------------------------------------------------- shooting

func _fire_local() -> void:
	if multiplayer.is_server():
		_server_fire(aim_angle)
	else:
		# Show the shot immediately, the server decides whether it really counts.
		var dir := Vector2.from_angle(aim_angle)
		world.spawn_bullet(peer_id, global_position + dir * MUZZLE_DISTANCE, dir)
		request_fire.rpc_id(1, aim_angle)

@rpc("any_peer", "call_remote", "reliable")
func request_fire(angle: float) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	_server_fire(angle)

func _server_fire(angle: float) -> void:
	if not alive or world == null or not world.match_active:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_server_shot < FIRE_RATE * 0.8:
		return
	_last_server_shot = now
	var dir := Vector2.from_angle(angle)
	world.broadcast_bullet.rpc(peer_id, global_position + dir * MUZZLE_DISTANCE, dir)

# ---------------------------------------------------------------- health (server decides)

func server_take_damage(amount: int, attacker: int) -> void:
	if not multiplayer.is_server() or not alive or invulnerable:
		return
	health = maxi(health - amount, 0)
	_damaged.rpc(health, amount)
	if health <= 0:
		alive = false
		world.server_player_died(peer_id, attacker)

@rpc("authority", "call_local", "reliable")
func _damaged(new_health: int, amount: int) -> void:
	health = new_health
	queue_redraw()
	if world != null:
		world.popup_text(global_position, str(amount), Color(0.88, 0.45, 0.45))
		world.play_sfx(SFX_HURT, -10.0)
		if is_local():
			world.shake(14.0)
	var tw := create_tween()
	tw.tween_property(core, "color", Color.WHITE, 0.04)
	tw.tween_property(core, "color", color.lightened(0.45), 0.12)

@rpc("authority", "call_local", "reliable")
func die(_killer: int) -> void:
	alive = false
	health = 0
	dashing = false
	_dash_time = 0.0
	velocity = Vector2.ZERO
	hide()
	shape.set_deferred("disabled", true)
	if world != null:
		world.burst(global_position, color, 20, 1.0)
		world.play_sfx(SFX_BOOM, -6.0)
		world.shake(26.0 if is_local() else 10.0)

@rpc("authority", "call_local", "reliable")
func respawn(pos: Vector2) -> void:
	position = pos
	net_pos = pos
	velocity = Vector2.ZERO
	_ignore_net_until = Time.get_ticks_msec() / 1000.0 + 0.3
	health = MAX_HEALTH
	alive = true
	invulnerable = true
	_shoot_cd = 0.0
	show()
	shape.set_deferred("disabled", false)
	queue_redraw()
	await get_tree().create_timer(RESPAWN_INVULN).timeout
	if is_instance_valid(self):
		invulnerable = false

# ---------------------------------------------------------------- drawing

func _draw() -> void:
	if not alive:
		return
	var w := 90.0
	var h := 11.0
	var rect := Rect2(Vector2(-w / 2.0, -50.0), Vector2(w, h))
	draw_rect(rect.grow(2.0), Color(0, 0, 0, 0.45))
	var ratio := clampf(float(health) / MAX_HEALTH, 0.0, 1.0)
	var fill := Color(0.35, 0.8, 0.45).lerp(Color(0.9, 0.35, 0.35), 1.0 - ratio)
	draw_rect(Rect2(rect.position, Vector2(w * ratio, h)), fill)
