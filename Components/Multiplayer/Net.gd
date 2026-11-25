extends Node
## Networking layer for the Free-For-All mode (autoload "Net").
## Listen-server over ENet: one player hosts, the others join by IP.

signal players_changed
signal join_failed(reason: String)
signal connected_to_host
signal disconnected_from_host
signal all_peers_loaded

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 8
const LOBBY_SCENE := "res://Components/Multiplayer/FFALobby.tscn"
const WORLD_SCENE := "res://Components/Multiplayer/FFAWorld.tscn"
const MENU_SCENE := "res://Components/UI/MainMenu/MainMenu.tscn"

const PALETTE: Array[Color] = [
	Color("#e07a7a"), Color("#6fb7e8"), Color("#8fd68f"), Color("#e8c76f"),
	Color("#b58be8"), Color("#e88bc4"), Color("#6fe8d6"), Color("#e8986f"),
]

## peer_id -> {"name": String, "color": int}
var players: Dictionary = {}
var local_name := "Player"
var settings := {"kill_limit": 10, "time_limit": 300}
var in_match := false
var _loaded: Array[int] = []
var _server_world_ready := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func is_online() -> bool:
	return multiplayer.multiplayer_peer != null \
		and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer) \
		and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED

func host_game(port: int = DEFAULT_PORT) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	players = {1: {"name": local_name, "color": 0}}
	players_changed.emit()
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	in_match = false
	_loaded.clear()
	_server_world_ready = false

func get_player_color(peer_id: int) -> Color:
	var info: Dictionary = players.get(peer_id, {})
	return PALETTE[int(info.get("color", 0)) % PALETTE.size()]

func get_player_name(peer_id: int) -> String:
	var info: Dictionary = players.get(peer_id, {})
	return str(info.get("name", "Player"))

# ----- connection events ---------------------------------------------------

func _on_peer_connected(_id: int) -> void:
	pass # clients register themselves once they are connected

func _on_connected_to_server() -> void:
	_register.rpc_id(1, local_name)
	connected_to_host.emit()

func _on_connection_failed() -> void:
	leave()
	join_failed.emit("Could not reach the host")

func _on_server_disconnected() -> void:
	leave()
	disconnected_from_host.emit()
	get_tree().change_scene_to_file(MENU_SCENE)

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	players.erase(id)
	_loaded.erase(id)
	_sync_players.rpc(players)
	players_changed.emit()
	_check_all_loaded()

# ----- lobby ---------------------------------------------------------------

@rpc("any_peer", "reliable")
func _register(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if in_match:
		_rejected.rpc_id(id, "Match already in progress")
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	var used: Array = []
	for info in players.values():
		used.append(info["color"])
	var color_idx := 0
	while used.has(color_idx):
		color_idx += 1
	players[id] = {"name": player_name.strip_edges().left(16), "color": color_idx}
	_sync_players.rpc(players)
	players_changed.emit()

@rpc("authority", "reliable")
func _rejected(reason: String) -> void:
	join_failed.emit(reason)

@rpc("authority", "call_local", "reliable")
func _sync_players(data: Dictionary) -> void:
	players = data
	players_changed.emit()

# ----- match flow ----------------------------------------------------------

func start_match() -> void:
	if not multiplayer.is_server():
		return
	_loaded.clear()
	_server_world_ready = false
	in_match = true
	_load_world.rpc(settings)

@rpc("authority", "call_local", "reliable")
func _load_world(match_settings: Dictionary) -> void:
	settings = match_settings
	in_match = true
	get_tree().change_scene_to_file(WORLD_SCENE)

## Called by every peer's FFAWorld once its scene is ready.
func notify_world_ready() -> void:
	if multiplayer.is_server():
		_server_world_ready = true
		_check_all_loaded()
	else:
		_client_loaded.rpc_id(1)

@rpc("any_peer", "reliable")
func _client_loaded() -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if not _loaded.has(id):
		_loaded.append(id)
	_check_all_loaded()

func _check_all_loaded() -> void:
	if not multiplayer.is_server() or not _server_world_ready or not in_match:
		return
	for id in players.keys():
		if id != 1 and not _loaded.has(id):
			return
	all_peers_loaded.emit()

func return_to_lobby() -> void:
	if multiplayer.is_server():
		_go_lobby.rpc()

@rpc("authority", "call_local", "reliable")
func _go_lobby() -> void:
	in_match = false
	get_tree().change_scene_to_file(LOBBY_SCENE)
