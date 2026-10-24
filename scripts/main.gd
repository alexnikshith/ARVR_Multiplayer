extends Node3D

const PORT = 8910
const MAX_CLIENTS = 16
const PLAYER_SCENE = preload("res://scenes/player.tscn")

# Stored info for all connected peers: peer_id -> { "name": ..., "character": ..., "color": ..., "serial": ... }
var players_info = {}

# Live global scoreboard and task state
var scoreboard_registry: Dictionary = {}
var global_basket_counts: Dictionary = { "Cube": 0, "Sphere": 0, "Cone": 0, "Cuboid": 0, "Star": 0 }

# Match timer running from game start
var game_match_timer: float = 0.0
var game_timer_running: bool = false
var _scoreboard_refresh_timer: float = 0.0

# Local player configuration
var local_nickname: String = "player1"
var local_character_name: String = "Cyber Runner"
var local_skin_color: String = "Blue"
var local_serial_no: String = "PC-01"

var enet_peer: ENetMultiplayerPeer = null

# Node references
@onready var lobby_ui = $CanvasLayer/LobbyUI
@onready var hud_ui = $CanvasLayer/HUD
@onready var status_label = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/StatusLabel
@onready var name_input = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/NameInput
@onready var char_option = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/CharacterOption
@onready var skin_option = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/SkinOption
@onready var serial_input = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/SerialInput
@onready var ip_input = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/IPInput
@onready var port_input = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/GridContainer/PortInput
@onready var host_button = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/HBoxButtons/HostButton
@onready var join_button = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/HBoxButtons/JoinButton
@onready var players_container = $PlayersContainer
@onready var multiplayer_spawner = $MultiplayerSpawner
@onready var arena = $Arena
@onready var spawn_points = $Arena/SpawnPoints

# HUD elements
@onready var hud_player_info = $CanvasLayer/HUD/TopBar/PlayerInfoBadge
@onready var hud_timer_badge = $CanvasLayer/HUD/TopBar/TimerBadge
@onready var hud_score_badge = $CanvasLayer/HUD/TopBar/ScoreBadge
@onready var hud_online_count = $CanvasLayer/HUD/TopBar/OnlineCountBadge
@onready var scoreboard_toggle_btn = $CanvasLayer/HUD/TopBar/ScoreboardToggleBtn
@onready var hud_fullscreen_btn = $CanvasLayer/HUD/TopBar/FullscreenButton
@onready var hud_launch_window_2_btn = $CanvasLayer/HUD/TopBar/HudLaunchWindow2Btn
@onready var hud_launch_window_3_btn = $CanvasLayer/HUD/TopBar/HudLaunchWindow3Btn
@onready var hud_disconnect_btn = $CanvasLayer/HUD/TopBar/DisconnectButton

# Scoreboard & Basket UI elements
@onready var basket_ticker_label = $CanvasLayer/HUD/LiveBasketTicker/BasketTickerLabel
@onready var scoreboard_panel = $CanvasLayer/HUD/ScoreboardPanel
@onready var global_basket_label = $CanvasLayer/HUD/ScoreboardPanel/Margin/VBox/GlobalBasketBox/GlobalBasketLabel
@onready var table_rows = $CanvasLayer/HUD/ScoreboardPanel/Margin/VBox/ScrollContainer/TableRows

# Action Button HUD elements
@onready var action_prompt_panel = $CanvasLayer/HUD/ActionPromptPanel
@onready var action_button = $CanvasLayer/HUD/ActionPromptPanel/ActionButton

# Lobby tools
@onready var lobby_fullscreen_btn = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/ToolsHBox/LobbyFullscreenBtn
@onready var launch_window_2_btn = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/ToolsHBox/LaunchWindow2Btn
@onready var launch_window_3_btn = $CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/ToolsHBox/LaunchWindow3Btn

func _ready():
	_setup_character_options()
	_setup_skin_options()
	_connect_ui_signals()
	_setup_multiplayer_signals()
	
	# Configure MultiplayerSpawner
	multiplayer_spawner.spawn_path = NodePath("../PlayersContainer")
	multiplayer_spawner.add_spawnable_scene("res://scenes/player.tscn")
	multiplayer_spawner.spawned.connect(_on_node_spawned)

	# Set Fullscreen mode
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Wire up basket signals from arena
	var basket = arena.get_node_or_null("ShapeBasket")
	if basket and basket.has_signal("shape_deposited"):
		basket.shape_deposited.connect(_on_basket_shape_deposited)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	lobby_ui.visible = true
	hud_ui.visible = false
	if scoreboard_panel:
		scoreboard_panel.visible = false
	
	_reset_game_state_to_zero()
	_check_cmdline_auto_start()

func _process(delta):
	if game_timer_running and hud_ui.visible:
		game_match_timer += delta
		var total_sec = int(game_match_timer)
		var mins = total_sec / 60
		var secs = total_sec % 60
		var tenths = int((game_match_timer - total_sec) * 10)
		if hud_timer_badge:
			hud_timer_badge.text = "⏱️ %02d:%02d.%d" % [mins, secs, tenths]
		
		# If scoreboard is open, update row timers smoothly (~5 Hz)
		if scoreboard_panel and scoreboard_panel.visible:
			_scoreboard_refresh_timer += delta
			if _scoreboard_refresh_timer >= 0.2:
				_scoreboard_refresh_timer = 0.0
				_refresh_scoreboard_ui()

func _setup_character_options():
	char_option.clear()
	var chars = [
		"Cyber Runner",
		"Knight Paladin",
		"Ninja Shadow",
		"Cosmic Astronaut",
		"Urban Brawler",
		"Tech Scientist",
		"Ranger Scout",
		"Mystic Mage"
	]
	for c in chars:
		char_option.add_item(c)
	char_option.select(0) # Default: Cyber Runner

func _setup_skin_options():
	skin_option.clear()
	var skins = ["Blue", "Red", "Green", "Yellow", "Purple", "Orange", "Cyan", "White"]
	for s in skins:
		skin_option.add_item(s)
	skin_option.select(0)

func _connect_ui_signals():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	hud_disconnect_btn.pressed.connect(_on_disconnect_pressed)
	lobby_fullscreen_btn.pressed.connect(toggle_fullscreen)
	hud_fullscreen_btn.pressed.connect(toggle_fullscreen)
	scoreboard_toggle_btn.pressed.connect(toggle_scoreboard)
	
	launch_window_2_btn.pressed.connect(_launch_player2_instance)
	hud_launch_window_2_btn.pressed.connect(_launch_player2_instance)
	launch_window_3_btn.pressed.connect(_launch_player3_instance)
	hud_launch_window_3_btn.pressed.connect(_launch_player3_instance)
	
	if action_button:
		action_button.pressed.connect(_on_action_button_pressed)
	
	$CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/PresetsHBox/Preset1Btn.pressed.connect(func():
		name_input.text = "player1"
		char_option.select(0) # Cyber Runner
		skin_option.select(0) # Blue
		serial_input.text = "PC-01"
		ip_input.text = "127.0.0.1"
	)
	
	$CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/PresetsHBox/Preset2Btn.pressed.connect(func():
		name_input.text = "player2"
		char_option.select(1) # Knight Paladin
		skin_option.select(1) # Red
		serial_input.text = "PC-02"
		ip_input.text = "127.0.0.1"
	)
	
	$CanvasLayer/LobbyUI/MainPanel/MarginContainer/VBoxContainer/PresetsHBox/Preset3Btn.pressed.connect(func():
		name_input.text = "player3"
		char_option.select(2) # Ninja Shadow
		skin_option.select(2) # Green
		serial_input.text = "PC-03"
		ip_input.text = "127.0.0.1"
	)

func _setup_multiplayer_signals():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _read_user_inputs():
	local_nickname = name_input.text.strip_edges()
	if local_nickname.is_empty():
		local_nickname = "Player" + str(randi_range(100, 999))
		
	if char_option and char_option.item_count > 0:
		local_character_name = char_option.get_item_text(char_option.selected)
		
	local_skin_color = skin_option.get_item_text(skin_option.selected)
	
	local_serial_no = serial_input.text.strip_edges()
	if local_serial_no.is_empty():
		local_serial_no = "PC-" + str(randi_range(1, 20)).pad_zeros(2)

# --- Host Action ---
func _on_host_pressed():
	_read_user_inputs()
	var port = port_input.text.to_int()
	if port <= 0:
		port = PORT
		
	status_label.text = "Starting Host Server on port %d..." % port
	
	_reset_game_state_to_zero()
	
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		status_label.text = "Error starting server: %s" % error_string(error)
		return
		
	multiplayer.multiplayer_peer = enet_peer
	status_label.text = "Host server running! Spawning host player..."
	
	players_info[1] = {
		"name": local_nickname,
		"character": local_character_name,
		"color": local_skin_color,
		"serial": local_serial_no
	}
	
	_spawn_player(1)
	_show_in_game_hud("Host (Server)")

# --- Join Action ---
func _on_join_pressed():
	_read_user_inputs()
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
		
	var port = port_input.text.to_int()
	if port <= 0:
		port = PORT
		
	status_label.text = "Connecting to %s:%d..." % [ip, port]
	host_button.disabled = true
	join_button.disabled = true
	
	_reset_game_state_to_zero()
	
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_client(ip, port)
	if error != OK:
		status_label.text = "Error creating client: %s" % error_string(error)
		host_button.disabled = false
		join_button.disabled = false
		return
		
	multiplayer.multiplayer_peer = enet_peer

# --- Multiplayer Callbacks ---
func _on_peer_connected(id: int):
	print("Peer connected with id: ", id)
	if multiplayer.is_server():
		_spawn_player(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected with id: ", id)
	if players_info.has(id):
		players_info.erase(id)
	if scoreboard_registry.has(id):
		scoreboard_registry.erase(id)
		
	if multiplayer.is_server():
		var p_node = players_container.get_node_or_null(str(id))
		if p_node:
			p_node.queue_free()
		_broadcast_players_registry.rpc(players_info)
		_broadcast_scoreboard_registry.rpc(scoreboard_registry)
		
	_update_hud_player_count()
	_refresh_scoreboard_ui()

func _on_connected_to_server():
	var my_id = multiplayer.get_unique_id()
	status_label.text = "Connected! Joined as peer %d" % my_id
	_show_in_game_hud("Client (Peer %d)" % my_id)
	_send_player_info_to_server.rpc_id(1, local_nickname, local_character_name, local_skin_color, local_serial_no)

func _on_connection_failed():
	status_label.text = "❌ Cannot connect to %s:%s!\n👉 Window 1 must click 'HOST GAME' first." % [ip_input.text, port_input.text]
	status_label.modulate = Color(1.0, 0.35, 0.35)
	host_button.disabled = false
	join_button.disabled = false
	multiplayer.multiplayer_peer = null

func _check_cmdline_auto_start():
	var args = OS.get_cmdline_args()
	for arg in args:
		if arg == "--auto-join" or arg == "--auto-join-p2":
			name_input.text = "player2"
			if char_option and char_option.item_count > 1:
				char_option.select(1) # Puglin
			skin_option.select(1) # Red
			serial_input.text = "PC-02"
			ip_input.text = "127.0.0.1"
			get_tree().create_timer(0.4).timeout.connect(_on_join_pressed)
			return
		elif arg == "--auto-join-p3":
			name_input.text = "player3"
			if char_option and char_option.item_count > 2:
				char_option.select(2) # Astronaut
			skin_option.select(2) # Green
			serial_input.text = "PC-03"
			ip_input.text = "127.0.0.1"
			get_tree().create_timer(0.7).timeout.connect(_on_join_pressed)
			return
		elif arg == "--auto-host":
			get_tree().create_timer(0.2).timeout.connect(_on_host_pressed)
			return

func _on_server_disconnected():
	status_label.text = "Disconnected from host server."
	_reset_to_lobby()

# --- Spawning Logic ---
func _spawn_player(peer_id: int):
	if not multiplayer.is_server():
		return
		
	if players_container.has_node(str(peer_id)):
		return

	var player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	
	var spawn_pos = _get_spawn_position(peer_id)
	player.position = spawn_pos
	player.sync_position = spawn_pos
	
	players_container.add_child(player, true)
	if player.has_method("setup_authority"):
		player.setup_authority(peer_id)
	if player.has_method("reset_player_score"):
		player.reset_player_score()
	if player.has_method("teleport_to_position"):
		player.teleport_to_position.rpc(spawn_pos)
	
	if peer_id == 1 and players_info.has(1):
		var info = players_info[1]
		var char_name = info.get("character", "Imp (Dungeon Monsters Kit)")
		player.apply_customization(info.name, char_name, info.color, info.serial)
		_broadcast_players_registry.rpc(players_info)

func _on_node_spawned(node: Node):
	var peer_id = node.name.to_int()
	var spawn_pos = _get_spawn_position(peer_id)
	node.global_position = spawn_pos
	node.sync_position = spawn_pos
	if node.has_method("setup_authority"):
		node.setup_authority(peer_id)
	if node.has_method("reset_player_score"):
		node.reset_player_score()
	if players_info.has(peer_id):
		var info = players_info[peer_id]
		if node.has_method("apply_customization"):
			var char_name = info.get("character", "Imp (Dungeon Monsters Kit)")
			node.apply_customization(info.name, char_name, info.color, info.serial)

func _get_spawn_position(peer_id: int) -> Vector3:
	if spawn_points and spawn_points.get_child_count() > 0:
		var index = (peer_id - 1) % spawn_points.get_child_count()
		if index < 0:
			index = 0
		var marker = spawn_points.get_child(index) as Marker3D
		if marker:
			return marker.global_position
	return Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4))

# --- RPCs for Customization & Network Sync ---
@rpc("any_peer", "call_remote", "reliable")
func _send_player_info_to_server(p_name: String, p_char: String, p_color: String, p_serial: String):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	players_info[sender_id] = {
		"name": p_name,
		"character": p_char,
		"color": p_color,
		"serial": p_serial
	}
	
	var p_node = players_container.get_node_or_null(str(sender_id))
	if p_node and p_node.has_method("apply_customization"):
		p_node.apply_customization(p_name, p_char, p_color, p_serial)
		
	_broadcast_players_registry.rpc(players_info)

@rpc("authority", "call_local", "reliable")
func _broadcast_players_registry(all_players: Dictionary):
	players_info = all_players
	for id_key in players_info.keys():
		var id = int(id_key)
		var info = players_info[id_key]
		var p_node = players_container.get_node_or_null(str(id))
		if p_node and p_node.has_method("apply_customization"):
			var char_name = info.get("character", "Imp (Dungeon Monsters Kit)")
			p_node.apply_customization(info.name, char_name, info.color, info.serial)
	_update_hud_player_count()

# --- Live Scoreboard & Basket Tasks RPC Layer ---
func report_player_score_data(peer_id: int, data: Dictionary):
	if multiplayer.multiplayer_peer == null:
		scoreboard_registry[1] = data
		_refresh_scoreboard_ui()
		return
		
	if multiplayer.is_server():
		scoreboard_registry[peer_id] = data
		_broadcast_scoreboard_registry.rpc(scoreboard_registry)
	else:
		_send_score_data_to_server.rpc_id(1, peer_id, data)

@rpc("any_peer", "call_remote", "unreliable")
func _send_score_data_to_server(reported_id: int, data: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	# Strict validation: peer can only report its own score data
	if sender_id != reported_id:
		return
	scoreboard_registry[sender_id] = data
	_broadcast_scoreboard_registry.rpc(scoreboard_registry)

@rpc("authority", "call_local", "unreliable")
func _broadcast_scoreboard_registry(all_scores: Dictionary):
	scoreboard_registry = all_scores
	_refresh_scoreboard_ui()
	# Ensure 3D nameplates and carrying state match authoritative registry on all peers
	for id_key in scoreboard_registry.keys():
		var p_node = players_container.get_node_or_null(str(id_key))
		if p_node and p_node.has_method("sync_score_and_carrying_state"):
			p_node.sync_score_and_carrying_state(scoreboard_registry[id_key])

func _on_basket_shape_deposited(player_id: int, s_type: String, new_counts: Dictionary):
	global_basket_counts = new_counts
	_refresh_basket_ticker()

func _reset_game_state_to_zero():
	scoreboard_registry.clear()
	global_basket_counts = { "Cube": 0, "Sphere": 0, "Cone": 0, "Cuboid": 0, "Star": 0 }
	game_match_timer = 0.0
	_refresh_basket_ticker()
	_refresh_scoreboard_ui()
	
	if arena:
		var basket = arena.get_node_or_null("ShapeBasket")
		if basket and basket.has_method("reset_basket"):
			basket.reset_basket()
			
		var arch = arena.get_node_or_null("CheckpointArch")
		if arch and arch.has_method("reset_arch"):
			arch.reset_arch()
			
	for s in get_tree().get_nodes_in_group("pickable_shapes"):
		if s.has_method("respawn"):
			s.respawn()
			
	if players_container:
		for p in players_container.get_children():
			if p.has_method("reset_player_score"):
				p.reset_player_score()

func _refresh_basket_ticker():
	var total = 0
	for val in global_basket_counts.values():
		total += val
	var text_str = "📥 BASKET INVENTORY: 📦 %d Cube(s) | 🟡 %d Sphere(s) | 🔺 %d Cone(s) | 🟩 %d Cuboid(s) | ⭐ %d Star(s) (Total: %d)" % [
		global_basket_counts.get("Cube", 0),
		global_basket_counts.get("Sphere", 0),
		global_basket_counts.get("Cone", 0),
		global_basket_counts.get("Cuboid", 0),
		global_basket_counts.get("Star", 0),
		total
	]
	if basket_ticker_label:
		basket_ticker_label.text = text_str
	if global_basket_label:
		global_basket_label.text = text_str

func _refresh_scoreboard_ui():
	var my_id = multiplayer.get_unique_id()
	
	# Update TopBar badges for local player with live timer and score
	var total_sec = int(game_match_timer)
	var mins = total_sec / 60
	var secs = total_sec % 60
	var tenths = int((game_match_timer - total_sec) * 10)
	hud_timer_badge.text = "⏱️ %02d:%02d.%d" % [mins, secs, tenths]
	if scoreboard_registry.has(my_id):
		var my_data = scoreboard_registry[my_id]
		hud_score_badge.text = "⭐ %d pts" % my_data.get("total_score", 0)
		
	_refresh_basket_ticker()
	
	if scoreboard_panel and scoreboard_panel.visible:
		var sub_lbl = scoreboard_panel.find_child("Subtitle", true, false) as Label
		if sub_lbl:
			sub_lbl.text = "⏱️ MATCH TIME RECORDED: %02d:%02d.%d • Real-Time Shapes, Timer & Checkpoints Tracker" % [mins, secs, tenths]
	
	if table_rows == null:
		return
		
	# Clear existing rows
	for child in table_rows.get_children():
		child.queue_free()
		
	# Header Row
	var header_panel = PanelContainer.new()
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.18, 0.24, 0.35, 0.9)
	h_style.corner_radius_top_left = 6
	h_style.corner_radius_top_right = 6
	h_style.corner_radius_bottom_right = 6
	h_style.corner_radius_bottom_left = 6
	header_panel.add_theme_stylebox_override("panel", h_style)
	
	var h_margin = MarginContainer.new()
	h_margin.add_theme_constant_override("margin_left", 12)
	h_margin.add_theme_constant_override("margin_right", 12)
	h_margin.add_theme_constant_override("margin_top", 6)
	h_margin.add_theme_constant_override("margin_bottom", 6)
	
	var h_box = HBoxContainer.new()
	h_box.add_theme_constant_override("separation", 14)
	
	var col_player = Label.new()
	col_player.text = "PLAYER [SERIAL]"
	col_player.custom_minimum_size = Vector2(170, 0)
	col_player.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	col_player.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_player)
	
	var col_avatar = Label.new()
	col_avatar.text = "AVATAR"
	col_avatar.custom_minimum_size = Vector2(110, 0)
	col_avatar.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	col_avatar.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_avatar)
	
	var col_time = Label.new()
	col_time.text = "RECORDED TIME"
	col_time.custom_minimum_size = Vector2(110, 0)
	col_time.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	col_time.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_time)
	
	var col_gate = Label.new()
	col_gate.text = "GATE PTS"
	col_gate.custom_minimum_size = Vector2(85, 0)
	col_gate.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	col_gate.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_gate)
	
	var col_basket = Label.new()
	col_basket.text = "SHAPES IN BASKET"
	col_basket.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_basket.add_theme_color_override("font_color", Color(0.3, 0.95, 0.85))
	col_basket.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_basket)
	
	var col_score = Label.new()
	col_score.text = "TOTAL SCORE"
	col_score.custom_minimum_size = Vector2(120, 0)
	col_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col_score.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
	col_score.add_theme_font_size_override("font_size", 14)
	h_box.add_child(col_score)
	
	h_margin.add_child(h_box)
	header_panel.add_child(h_margin)
	table_rows.add_child(header_panel)
	
	# Player Data Rows
	for peer_id in scoreboard_registry.keys():
		var p_data = scoreboard_registry[peer_id]
		var row_panel = PanelContainer.new()
		var r_style = StyleBoxFlat.new()
		var is_me = (int(peer_id) == my_id)
		r_style.bg_color = Color(0.14, 0.22, 0.32, 0.85) if is_me else Color(0.1, 0.13, 0.18, 0.75)
		r_style.corner_radius_top_left = 6
		r_style.corner_radius_top_right = 6
		r_style.corner_radius_bottom_right = 6
		r_style.corner_radius_bottom_left = 6
		if is_me:
			r_style.border_width_left = 3
			r_style.border_color = Color(0.3, 0.85, 1.0)
		row_panel.add_theme_stylebox_override("panel", r_style)
		
		var r_margin = MarginContainer.new()
		r_margin.add_theme_constant_override("margin_left", 12)
		r_margin.add_theme_constant_override("margin_right", 12)
		r_margin.add_theme_constant_override("margin_top", 6)
		r_margin.add_theme_constant_override("margin_bottom", 6)
		
		var r_box = HBoxContainer.new()
		r_box.add_theme_constant_override("separation", 14)
		
		var p_label = Label.new()
		p_label.text = "%s [%s]%s" % [p_data.get("nickname", "Player"), p_data.get("serial", "PC-01"), " (YOU)" if is_me else ""]
		p_label.custom_minimum_size = Vector2(170, 0)
		p_label.add_theme_font_size_override("font_size", 14)
		r_box.add_child(p_label)
		
		var a_label = Label.new()
		a_label.text = p_data.get("character", "Imp")
		a_label.custom_minimum_size = Vector2(110, 0)
		a_label.add_theme_font_size_override("font_size", 14)
		r_box.add_child(a_label)
		
		var t_val = p_data.get("timer", 0.0)
		if is_me:
			t_val = max(t_val, game_match_timer)
		var t_secs = int(t_val)
		var t_tenths = int((t_val - t_secs) * 10)
		var t_label = Label.new()
		t_label.text = "%02d:%02d.%d" % [t_secs / 60, t_secs % 60, t_tenths]
		t_label.custom_minimum_size = Vector2(110, 0)
		t_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		t_label.add_theme_font_size_override("font_size", 15)
		r_box.add_child(t_label)
		
		var g_label = Label.new()
		g_label.text = "%d pts" % p_data.get("checkpoint", 0)
		g_label.custom_minimum_size = Vector2(85, 0)
		g_label.add_theme_font_size_override("font_size", 15)
		r_box.add_child(g_label)
		
		var shapes_dict = p_data.get("shapes", {})
		var s_text = "📦 %d Cubes | 🟡 %d Spheres | 🔺 %d Cones | 🟩 %d Cuboids | ⭐ %d Stars" % [
			shapes_dict.get("Cube", 0),
			shapes_dict.get("Sphere", 0),
			shapes_dict.get("Cone", 0),
			shapes_dict.get("Cuboid", 0),
			shapes_dict.get("Star", 0)
		]
		var carrying = p_data.get("carrying", "")
		if carrying != "":
			s_text += " [Carrying: %s]" % carrying
		var b_label = Label.new()
		b_label.text = s_text
		b_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b_label.add_theme_color_override("font_color", Color(0.8, 0.92, 1.0))
		b_label.add_theme_font_size_override("font_size", 14)
		r_box.add_child(b_label)
		
		var s_label = Label.new()
		s_label.text = "⭐ %d pts" % p_data.get("total_score", 0)
		s_label.custom_minimum_size = Vector2(120, 0)
		s_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		s_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
		s_label.add_theme_font_size_override("font_size", 16)
		r_box.add_child(s_label)
		
		r_margin.add_child(r_box)
		row_panel.add_child(r_margin)
		table_rows.add_child(row_panel)

func toggle_scoreboard():
	if scoreboard_panel:
		scoreboard_panel.visible = not scoreboard_panel.visible
		if scoreboard_panel.visible:
			_refresh_scoreboard_ui()

# --- UI and HUD Management ---
func _show_in_game_hud(role_str: String):
	lobby_ui.visible = false
	hud_ui.visible = true
	hud_player_info.text = "👤 %s [%s] | %s" % [local_nickname, local_serial_no, role_str]
	game_match_timer = 0.0
	game_timer_running = true
	_update_hud_player_count()
	_refresh_basket_ticker()

func update_action_prompt(btn_visible: bool, text_str: String, accent_color: Color, can_interact: bool):
	if action_prompt_panel:
		action_prompt_panel.visible = btn_visible
	if action_button:
		action_button.text = text_str
		action_button.disabled = not can_interact
		action_button.modulate = accent_color

func _on_action_button_pressed():
	var my_id = multiplayer.get_unique_id()
	var my_player = players_container.get_node_or_null(str(my_id))
	if my_player and my_player.has_method("handle_interact_action"):
		my_player.handle_interact_action()

func _update_hud_player_count():
	var count = players_container.get_child_count()
	if count == 0 and enet_peer != null:
		count = 1
	hud_online_count.text = "👥 %d Online" % count

func _on_disconnect_pressed():
	_reset_to_lobby()

func _reset_to_lobby():
	if enet_peer != null:
		enet_peer.close()
		enet_peer = null
	multiplayer.multiplayer_peer = null
	
	for child in players_container.get_children():
		child.queue_free()
		
	players_info.clear()
	_reset_game_state_to_zero()
	game_timer_running = false
	game_match_timer = 0.0
	
	lobby_ui.visible = true
	hud_ui.visible = false
	if scoreboard_panel:
		scoreboard_panel.visible = false
	host_button.disabled = false
	join_button.disabled = false
	status_label.text = "Disconnected. Ready to Host or Join."
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_F11 or (event.physical_keycode == KEY_ENTER and event.alt_pressed):
			toggle_fullscreen()
		elif event.physical_keycode == KEY_TAB:
			if hud_ui.visible:
				toggle_scoreboard()
				get_viewport().set_input_as_handled()

func toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _launch_player2_instance():
	if enet_peer == null:
		_on_host_pressed()
	
	var exe_path = OS.get_executable_path()
	var proj_path = ProjectSettings.globalize_path("res://")
	var pid = OS.create_process(exe_path, ["--path", proj_path, "--auto-join-p2"])
	print("Launched Player 2 instance with PID: ", pid)
	status_label.text = "Host active! Window 2 launched (player2 / Knight Paladin)."

func _launch_player3_instance():
	if enet_peer == null:
		_on_host_pressed()
	
	var exe_path = OS.get_executable_path()
	var proj_path = ProjectSettings.globalize_path("res://")
	var pid = OS.create_process(exe_path, ["--path", proj_path, "--auto-join-p3"])
	print("Launched Player 3 instance with PID: ", pid)
	status_label.text = "Host active! Window 3 launched (player3 / Ninja Shadow)."
