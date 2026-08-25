# ============================================================
# ROOFERS vs LANDSCAPERS — Network Manager (Autoload Singleton)
# ============================================================
# Handles all multiplayer connectivity: hosting, joining,
# lobby management, and player synchronization.
#
# This uses Godot's built-in ENet multiplayer with the NetFox
# addon layered on top for authoritative netcode (prediction,
# reconciliation, lag compensation). NetFox is optional for
# initial development — this foundation works without it and
# can be upgraded later.
#
# KEY CONCEPT FOR PvP (vs your 2P co-op experience):
# In co-op, you can trust both clients. In PvP, you CANNOT.
# The server is the authority on all game state:
#   - Player positions (server validates movement)
#   - Hit detection (server confirms hits)
#   - Game phase/timer (server is the clock)
#   - Score/KOs (server tracks all scoring)
# Clients send INPUTS (not positions), server simulates,
# and clients predict locally then reconcile with server state.
extends Node

## Emitted when successfully connected to a server
signal connected_to_server()
## Emitted when disconnected from server
signal disconnected_from_server()
## Emitted when a new peer connects
signal player_connected(peer_id: int)
## Emitted when a peer disconnects
signal player_disconnected(peer_id: int)
## Emitted when the lobby roster changes
signal lobby_updated(player_list: Array)
## Emitted when connection fails
signal connection_failed(reason: String)

# --- Configuration ---

const DEFAULT_PORT: int = 7350
const MAX_PLAYERS: int = 8  # 4v4 core, expandable to 8v8

# --- State ---

## Are we the server (host)?
var is_host: bool = false

## Our unique peer ID (1 = server, 2+ = clients)
var my_peer_id: int = 0

## Connected players: { peer_id: { "name": String, "team": Team, "ready": bool } }
var lobby_players: Dictionary = {}

## Server IP/address for clients
var server_address: String = "127.0.0.1"

## The ENet multiplayer peer
var peer: ENetMultiplayerPeer = null


func _ready() -> void:
	# Connect to Godot's built-in multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)


# ================================================================
# PUBLIC API — Hosting & Joining
# ================================================================

## Host a game server. Other players will connect to us.
func host_game(port: int = DEFAULT_PORT, max_clients: int = MAX_PLAYERS) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, max_clients)
	if error != OK:
		connection_failed.emit("Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	is_host = true
	my_peer_id = 1  # Server is always peer 1

	# Add ourselves to the lobby
	_register_player(my_peer_id, _get_local_player_name())

	print("[NetworkManager] Hosting on port %d" % port)
	return OK


## Join an existing game server.
func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> Error:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(address, port)
	if error != OK:
		connection_failed.emit("Failed to connect: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = peer
	server_address = address
	is_host = false

	print("[NetworkManager] Connecting to %s:%d..." % [address, port])
	return OK


## Disconnect from the current game.
func leave_game() -> void:
	if peer:
		multiplayer.multiplayer_peer = null
		peer = null
	lobby_players.clear()
	is_host = false
	my_peer_id = 0
	print("[NetworkManager] Disconnected.")


# ================================================================
# LOBBY MANAGEMENT
# ================================================================

## Register a player in the lobby (called on all peers via RPC)
@rpc("any_peer", "call_local", "reliable")
func register_player(peer_id: int, player_name: String) -> void:
	_register_player(peer_id, player_name)


## Remove a player from the lobby
func _unregister_player(peer_id: int) -> void:
	if peer_id in lobby_players:
		lobby_players.erase(peer_id)
		lobby_updated.emit(_get_player_list())


## Set a player's ready status
@rpc("any_peer", "call_local", "reliable")
func set_player_ready(peer_id: int, ready: bool) -> void:
	if peer_id in lobby_players:
		lobby_players[peer_id]["ready"] = ready
		lobby_updated.emit(_get_player_list())


## Set a player's team preference
@rpc("any_peer", "call_local", "reliable")
func set_player_team(peer_id: int, team: GameManager.Team) -> void:
	if peer_id in lobby_players:
		lobby_players[peer_id]["team"] = team
		lobby_updated.emit(_get_player_list())
		TeamManager.assign_player(peer_id, team)


## Check if all players are ready (server only)
func all_players_ready() -> bool:
	if lobby_players.size() < 2:
		return false  # Need at least 2 players
	for player_data in lobby_players.values():
		if not player_data.get("ready", false):
			return false
	return true


# ================================================================
# RPC PATTERNS — Key Multiplayer Concepts
# ================================================================
# These are the patterns you'll use throughout the game.
# Coming from 2P co-op, the big shift is:
#
# CO-OP:  Both players trusted. Either can change game state.
# PVP:    Only the SERVER changes game state. Clients REQUEST.
#
# Pattern 1: Client → Server REQUEST
#   Client calls: request_action.rpc_id(1, ...)
#   Server validates, then broadcasts result to all
#
# Pattern 2: Server → All Clients BROADCAST
#   Server calls: sync_state.rpc(...)
#   All clients receive the authoritative state
#
# Pattern 3: Client-side PREDICTION
#   Client immediately shows the action locally (feels responsive)
#   Server confirms or corrects (reconciliation)

## Example: Client requests to deal damage (server validates)
@rpc("any_peer", "call_local", "reliable")
func request_damage(target_peer_id: int, damage: float, _weapon_id: String) -> void:
	# Only the server processes damage requests
	if not multiplayer.is_server():
		return

	var attacker_id := multiplayer.get_remote_sender_id()

	# SERVER-SIDE VALIDATION:
	# - Is the attacker alive?
	# - Is the target alive?
	# - Is the attacker's weapon in range of the target?
	# - Is the damage amount valid for this weapon?
	# - Anti-cheat: is this physically possible given positions?
	# (These checks prevent cheating — critical for PvP!)

	# If valid, broadcast the confirmed damage to all clients
	confirm_damage.rpc(attacker_id, target_peer_id, damage)


## Server broadcasts confirmed damage to all clients
@rpc("authority", "call_local", "reliable")
func confirm_damage(attacker_id: int, target_id: int, damage: float) -> void:
	# All clients apply this damage to the target's health display
	# The server has validated it, so we trust it
	print("[Net] Player %d dealt %.1f damage to Player %d" % [attacker_id, damage, target_id])
	# TODO: Route to the actual player character node for health update


# ================================================================
# INPUT SYNCHRONIZATION
# ================================================================
# Instead of syncing POSITIONS (which is what co-op games often do),
# PvP games sync INPUTS. The server runs the simulation.
#
# Each tick:
#   1. Client captures input (WASD, mouse, buttons)
#   2. Client sends input to server AND predicts locally
#   3. Server receives input, simulates, sends back authoritative state
#   4. Client reconciles: if server state != predicted state, correct
#
# This is what NetFox handles automatically. For now, we use
# Godot's built-in MultiplayerSynchronizer for basic sync.


# ================================================================
# INTERNAL — Signal Handlers
# ================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer connected: %d" % peer_id)
	player_connected.emit(peer_id)

	# If we're the server, send the current lobby state to the new player
	if multiplayer.is_server():
		for existing_id in lobby_players:
			var data = lobby_players[existing_id]
			register_player.rpc_id(peer_id, existing_id, data["name"])


func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer disconnected: %d" % peer_id)
	_unregister_player(peer_id)
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	my_peer_id = multiplayer.get_unique_id()
	print("[NetworkManager] Connected! Our peer ID: %d" % my_peer_id)

	# Tell the server (and all peers) our name
	register_player.rpc(my_peer_id, _get_local_player_name())
	connected_to_server.emit()


func _on_server_disconnected() -> void:
	print("[NetworkManager] Server disconnected!")
	leave_game()
	disconnected_from_server.emit()


func _on_connection_failed() -> void:
	print("[NetworkManager] Connection failed!")
	leave_game()
	connection_failed.emit("Could not connect to server")


# ================================================================
# HELPERS
# ================================================================

func _register_player(peer_id: int, player_name: String) -> void:
	lobby_players[peer_id] = {
		"name": player_name,
		"team": GameManager.Team.NONE,
		"ready": false,
	}
	lobby_updated.emit(_get_player_list())


func _get_player_list() -> Array:
	var result := []
	for peer_id in lobby_players:
		var data = lobby_players[peer_id].duplicate()
		data["peer_id"] = peer_id
		result.append(data)
	return result


func _get_local_player_name() -> String:
	# TODO: Pull from settings/profile
	return "Player_%d" % randi_range(1000, 9999)
