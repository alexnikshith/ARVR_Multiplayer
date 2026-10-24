extends CharacterBody3D

const HumanoidAvatar = preload("res://scripts/humanoid_avatar.gd")

# --- Movement Parameters ---
const SPEED = 6.0
const SPRINT_SPEED = 9.5
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.003

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# --- All 8 Characters across both asset folders ---
const CHARACTER_PATHS = {
	"Imp": "res://assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Imp.glb",
	"Puglin": "res://assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Puglin.glb",
	"Astronaut": "res://assets/characters/astronaut.glb",
	"Knight": "res://assets/characters/knight.glb",
	"Ninja": "res://assets/characters/ninja.glb",
	"Robot": "res://assets/characters/robot.glb",
	"Archer": "res://assets/characters/archer.glb",
	"Dwarf": "res://assets/characters/dwarf.glb"
}

# --- Network Properties ---
@export var player_nickname: String = "Player"
@export var player_character_name: String = "Imp"
@export var player_color_name: String = "Blue"
@export var player_serial: String = "PC-01"

# Synchronized transform state for remote peers
@export var sync_position: Vector3 = Vector3.ZERO
@export var sync_rotation_y: float = 0.0
@export var sync_velocity: Vector3 = Vector3.ZERO

# --- Ladder State ---
var is_on_ladder: bool = false
var active_ladder: Node = null
const CLIMB_SPEED: float = 3.2

# --- Tasks State (Shapes, Checkpoint & Individual Timer) ---
var carried_shape: Node3D = null
var carried_shape_type: String = ""
var checkpoint_cleared_for_current_shape: bool = false
var individual_timer: float = 0.0
var checkpoint_score: int = 0
var shapes_in_basket: Dictionary = { "Cube": 0, "Sphere": 0, "Cone": 0, "Cuboid": 0, "Star": 0 }
var total_score: int = 0
var _score_sync_timer: float = 0.0

func enter_ladder(ladder_node: Node):
	is_on_ladder = true
	active_ladder = ladder_node

func exit_ladder(ladder_node: Node):
	if active_ladder == ladder_node:
		is_on_ladder = false
		active_ladder = null

# --- Node References ---
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var nameplate: Label3D = $Nameplate
@onready var model_container: Node3D = $ModelContainer
@onready var carry_anchor: Node3D = $CarryAnchor
var avatar_instance: HumanoidAvatar = null

# Color Palette mapping for nameplate / theme
const COLOR_MAP = {
	"Blue": Color(0.2, 0.65, 1.0),
	"Red": Color(1.0, 0.3, 0.3),
	"Green": Color(0.3, 0.95, 0.45),
	"Yellow": Color(1.0, 0.9, 0.2),
	"Purple": Color(0.85, 0.45, 1.0),
	"Orange": Color(1.0, 0.6, 0.2),
	"Cyan": Color(0.2, 0.95, 0.95),
	"White": Color(0.95, 0.95, 0.95)
}

# Local control & animation state
var is_locally_controlled: bool = false
var mouse_captured: bool = true
var _net_sync_timer: float = 0.0

# Procedural animation parameters
var anim_time: float = 0.0
var walk_cycle: float = 0.0



func _enter_tree():
	var peer_id = name.to_int()
	if peer_id != 0:
		set_multiplayer_authority(peer_id)
		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(peer_id)

func _ready():
	_setup_inputs()
	floor_snap_length = 0.35
	floor_stop_on_slope = true
	floor_constant_speed = true
	sync_position = global_position
	
	var peer_id = name.to_int()
	if peer_id != 0:
		set_multiplayer_authority(peer_id)
		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(peer_id)
		var is_my_player = (peer_id == multiplayer.get_unique_id())
		set_locally_controlled(is_my_player)
	else:
		set_locally_controlled(false)
	
	load_character_model(player_character_name)
	update_nameplate_text()

func setup_authority(id: int):
	set_multiplayer_authority(id)
	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(id)
	var is_me = (id == multiplayer.get_unique_id())
	set_locally_controlled(is_me)

func set_locally_controlled(active: bool):
	is_locally_controlled = active
	if camera:
		camera.current = active
	if active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
	else:
		velocity = Vector3.ZERO

func _setup_inputs():
	var actions = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E, KEY_F, KEY_ENTER]
	}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in actions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _input(event):
	if not is_locally_controlled:
		return
	if not DisplayServer.window_is_focused():
		return

	# Interact key (E / F / Enter)
	if event.is_action_pressed("interact"):
		handle_interact_action()

	# Left-click locks mouse into window
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_captured = true

	# ESC key frees mouse cursor to click UI
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		mouse_captured = not mouse_captured
		if mouse_captured:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Mouse look rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func _physics_process(delta):
	if is_locally_controlled:
		_process_authority_movement(delta)
		
		# Individual Stopwatch Timer
		individual_timer += delta
		
		# Update sync variables
		sync_position = global_position
		sync_rotation_y = model_container.rotation.y
		sync_velocity = velocity
		
		# Broadcast transform to other windows (~30 Hz)
		_net_sync_timer += delta
		if _net_sync_timer >= 0.033:
			_net_sync_timer = 0.0
			_send_transform_network()
			
		# Periodic Score & Timer Sync (~2 Hz)
		_score_sync_timer += delta
		if _score_sync_timer >= 0.5:
			_score_sync_timer = 0.0
			_sync_player_score_data()
			
		# Update Action Prompt HUD
		_update_interaction_hud()
	else:
		_process_remote_interpolation(delta)

	_animate_body_and_hands(delta)

	# Keep carry anchor dynamically aligned to player chest and pickup motion
	if carry_anchor and model_container:
		var target_carry_local = Vector3(0, 1.10, -0.48)
		if avatar_instance and is_instance_valid(avatar_instance) and avatar_instance.is_in_pickup():
			var p = avatar_instance.get_pickup_progress()
			if p < 0.45:
				target_carry_local = Vector3(0, 0.55, -0.55)
			else:
				var blend = (p - 0.45) / 0.55
				target_carry_local = Vector3(0, lerp(0.55, 1.10, blend), lerp(-0.55, -0.48, blend))
		carry_anchor.global_position = model_container.global_transform * target_carry_local
		carry_anchor.global_rotation = model_container.global_rotation

func _process_authority_movement(delta):
	# STRICT FOCUS GUARD: If window not focused, stop physical movement!
	if not DisplayServer.window_is_focused():
		velocity.x = move_toward(velocity.x, 0, SPEED * 3.0 * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * 3.0 * delta)
		move_and_slide()
		if is_on_floor() and velocity.y < 0.0:
			velocity.y = 0.0
		if global_position.y > 12.0 or global_position.y < -1.0:
			global_position.y = 0.5
			velocity.y = 0.0
		return

	# Compute directional movement relative to camera orientation
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_vector.y += 1
	if Input.is_action_pressed("move_backward"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	input_vector = input_vector.normalized()

	var move_direction = Vector3.ZERO
	if input_vector != Vector2.ZERO:
		var cam_basis = camera_pivot.global_transform.basis
		var forward = -Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
		var right = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		move_direction = (forward * input_vector.y + right * input_vector.x).normalized()

	# Speed (slightly reduced if carrying a heavy shape)
	var current_speed = SPEED
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED
	if is_carrying():
		current_speed *= 0.9

	if is_on_ladder:
		# Ladder climbing physics
		var climb_input = 0.0
		if Input.is_action_pressed("move_forward") or Input.is_action_pressed("jump"):
			climb_input += 1.0
		if Input.is_action_pressed("move_backward"):
			climb_input -= 1.0
		
		velocity.y = climb_input * CLIMB_SPEED
		velocity.x = move_direction.x * (current_speed * 0.4)
		velocity.z = move_direction.z * (current_speed * 0.4)
		
		# If at top of ladder and climbing up, step forward onto platform
		if active_ladder and is_instance_valid(active_ladder):
			var top_h = active_ladder.get("top_height")
			if top_h != null and global_position.y >= (top_h - 0.25) and climb_input > 0.0:
				velocity.y = 1.8
				var fwd = -active_ladder.global_transform.basis.z.normalized()
				velocity.x = fwd.x * current_speed * 0.8
				velocity.z = fwd.z * current_speed * 0.8
			
			# Face ladder while climbing
			var ladder_face_rot = active_ladder.global_rotation.y
			model_container.rotation.y = lerp_angle(model_container.rotation.y, ladder_face_rot, delta * 14.0)
		
		# Jump off ladder backwards
		if Input.is_action_just_pressed("jump") and Input.is_action_pressed("move_backward"):
			is_on_ladder = false
			velocity.y = JUMP_VELOCITY * 0.8
			if active_ladder and is_instance_valid(active_ladder):
				var push_out = active_ladder.global_transform.basis.z.normalized()
				velocity.x = push_out.x * current_speed
				velocity.z = push_out.z * current_speed
	else:
		# Apply gravity
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			if velocity.y < 0.0:
				velocity.y = 0.0

		# Jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if move_direction != Vector3.ZERO:
			velocity.x = move_direction.x * current_speed
			velocity.z = move_direction.z * current_speed
			var target_rot = atan2(-move_direction.x, -move_direction.z)
			model_container.rotation.y = lerp_angle(model_container.rotation.y, target_rot, delta * 14.0)
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# Absolute anti-air launch fail-safes (safe bound for elevated platforms)
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0
	if global_position.y > 12.0:
		global_position.y = 0.5
		velocity.y = 0.0
	elif global_position.y < -1.0:
		global_position.y = 0.5
		velocity.y = 0.0

# --- Shape Interaction & Carrying System ---
func is_carrying() -> bool:
	return carried_shape != null and is_instance_valid(carried_shape)

func get_carried_shape_type() -> String:
	return carried_shape_type

func can_pick_shape() -> bool:
	return carried_shape == null

func try_pick_shape(shape_node: Node3D):
	if carried_shape != null:
		return
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		network_pick_shape.rpc(shape_node.get_path())
	else:
		network_pick_shape(shape_node.get_path())

@rpc("any_peer", "call_local", "reliable")
func network_pick_shape(shape_path: NodePath):
	var shape_node = get_node_or_null(shape_path)
	if shape_node == null:
		var s_name = String(shape_path).get_file()
		for s in get_tree().get_nodes_in_group("pickable_shapes"):
			if s.name == s_name:
				shape_node = s
				break
	if shape_node and shape_node.has_method("pick_up"):
		shape_node.pick_up(self)
		carried_shape = shape_node
		carried_shape_type = shape_node.shape_type
		checkpoint_cleared_for_current_shape = false
		update_nameplate_text()
		_sync_player_score_data()
		if avatar_instance and is_instance_valid(avatar_instance):
			avatar_instance.trigger_pickup()
		elif model_container:
			for c in model_container.get_children():
				if c is HumanoidAvatar:
					avatar_instance = c
					avatar_instance.trigger_pickup()
					break

func handle_interact_action():
	if not is_locally_controlled:
		return
	
	if is_carrying():
		var basket = get_tree().root.find_child("ShapeBasket", true, false)
		if basket and is_instance_valid(basket):
			var dist = global_position.distance_to(basket.global_position)
			if dist <= 4.2:
				trigger_basket_deposit(carried_shape_type)
				return
		trigger_drop_shape()
		return
	
	_try_interact_nearest_shape()

func _get_nearest_pickable_shape(max_dist: float = 3.2) -> Node3D:
	var shapes = get_tree().get_nodes_in_group("pickable_shapes")
	var closest_shape: Node3D = null
	var min_dist = max_dist
	for s in shapes:
		if is_instance_valid(s) and s is Area3D:
			if s.get("is_held") == true:
				continue
			var d = global_position.distance_to(s.global_position)
			if d < min_dist:
				min_dist = d
				closest_shape = s
	return closest_shape

func _try_interact_nearest_shape():
	var closest_shape = _get_nearest_pickable_shape(3.2)
	if closest_shape:
		try_pick_shape(closest_shape)

func trigger_drop_shape():
	if not is_carrying():
		return
	var s_path = carried_shape.get_path() if carried_shape else NodePath("")
	var drop_dir = -model_container.global_transform.basis.z.normalized()
	if drop_dir.length_squared() < 0.1:
		drop_dir = Vector3.FORWARD
	var drop_pos = global_position + drop_dir * 1.4
	drop_pos.y = max(drop_pos.y, 0.4)
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		network_drop_shape.rpc(s_path, drop_pos)
	else:
		network_drop_shape(s_path, drop_pos)

@rpc("any_peer", "call_local", "reliable")
func network_drop_shape(shape_path: NodePath, drop_pos: Vector3):
	var shape_node = carried_shape
	if (shape_node == null or not is_instance_valid(shape_node)) and shape_path != NodePath(""):
		shape_node = get_node_or_null(shape_path)
		if shape_node == null:
			var s_name = String(shape_path).get_file()
			for s in get_tree().get_nodes_in_group("pickable_shapes"):
				if s.name == s_name:
					shape_node = s
					break
	
	if shape_node and is_instance_valid(shape_node):
		if shape_node.has_method("drop_at_position"):
			shape_node.drop_at_position(drop_pos)
		elif shape_node.has_method("drop_shape"):
			shape_node.global_position = drop_pos
			shape_node.drop_shape()
	
	for s in get_tree().get_nodes_in_group("pickable_shapes"):
		if s.get("carrier_node") == self:
			if s.has_method("drop_at_position"):
				s.drop_at_position(drop_pos)
			else:
				s.drop_shape()

	carried_shape = null
	carried_shape_type = ""
	checkpoint_cleared_for_current_shape = false
	update_nameplate_text()
	if is_locally_controlled:
		_sync_player_score_data()

func _update_interaction_hud():
	if not is_locally_controlled:
		return
	var main_node = get_tree().root.find_child("Main", true, false)
	if not main_node or not main_node.has_method("update_action_prompt"):
		return
	
	if is_on_ladder:
		main_node.update_action_prompt(true, "🪜 [W] CLIMB UP • [S] CLIMB DOWN", Color(0.2, 0.9, 1.0), true)
		return
	
	if is_carrying():
		var basket = get_tree().root.find_child("ShapeBasket", true, false)
		var near_basket = false
		if basket and is_instance_valid(basket):
			if global_position.distance_to(basket.global_position) <= 4.2:
				near_basket = true
		
		if near_basket:
			main_node.update_action_prompt(true, "📥 [E] DEPOSIT %s IN BASKET" % carried_shape_type.to_upper(), Color(0.25, 1.0, 0.65), true)
		else:
			main_node.update_action_prompt(true, "🔻 [E] DROP %s" % carried_shape_type.to_upper(), Color(1.0, 0.75, 0.25), true)
	else:
		var nearest = _get_nearest_pickable_shape(3.2)
		if nearest:
			main_node.update_action_prompt(true, "📦 [E] PICK UP %s" % nearest.shape_type.to_upper(), Color(0.3, 0.85, 1.0), true)
		else:
			main_node.update_action_prompt(true, "🔍 WALK NEAR SHAPE OR BASKET", Color(0.65, 0.72, 0.85, 0.7), false)

func can_trigger_checkpoint() -> bool:
	return is_carrying() and not checkpoint_cleared_for_current_shape

func _get_total_basket_shapes() -> int:
	var total = 0
	for val in shapes_in_basket.values():
		total += val
	return total

func trigger_checkpoint_pass():
	if not can_trigger_checkpoint():
		return
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		network_checkpoint_passed.rpc()
	else:
		network_checkpoint_passed()

@rpc("any_peer", "call_local", "reliable")
func network_checkpoint_passed():
	checkpoint_cleared_for_current_shape = true
	checkpoint_score += 1
	total_score = checkpoint_score + _get_total_basket_shapes()
	update_nameplate_text()
	if is_locally_controlled:
		_sync_player_score_data()
	
	var arch = get_tree().root.find_child("CheckpointArch", true, false)
	if arch and arch.has_method("trigger_network_flash"):
		arch.trigger_network_flash()

func on_checkpoint_passed() -> int:
	trigger_checkpoint_pass()
	return checkpoint_score

func trigger_basket_deposit(s_type: String):
	if not is_carrying():
		return
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		network_deposit_shape.rpc(s_type)
	else:
		network_deposit_shape(s_type)

@rpc("any_peer", "call_local", "reliable")
func network_deposit_shape(s_type: String):
	if carried_shape and is_instance_valid(carried_shape):
		carried_shape.respawn()
		carried_shape = null
	# Fail-safe: ensure ANY shape in depot claiming this carrier is forced to respawn
	for s in get_tree().get_nodes_in_group("pickable_shapes"):
		if s.get("carrier_node") == self:
			s.respawn()
			
	carried_shape = null
	carried_shape_type = ""
	checkpoint_cleared_for_current_shape = false
	
	if not shapes_in_basket.has(s_type):
		shapes_in_basket[s_type] = 0
	shapes_in_basket[s_type] += 1
	
	# Transparent scoring: 1 point per gate pass + 1 point per shape placed in basket
	total_score = checkpoint_score + _get_total_basket_shapes()
	
	update_nameplate_text()
	if is_locally_controlled:
		_sync_player_score_data()
	
	var basket = get_tree().root.find_child("ShapeBasket", true, false)
	if basket and basket.has_method("on_network_deposit"):
		basket.on_network_deposit(name.to_int(), s_type)

func on_shape_deposited_in_basket(s_type: String):
	trigger_basket_deposit(s_type)

func sync_score_and_carrying_state(data: Dictionary):
	# The locally controlled player is authoritative over its own gameplay state!
	if is_locally_controlled:
		return
	total_score = data.get("total_score", total_score)
	checkpoint_score = data.get("checkpoint", checkpoint_score)
	shapes_in_basket = data.get("shapes", shapes_in_basket)
	var remote_carrying = data.get("carrying", "")
	if remote_carrying == "" and carried_shape != null:
		if is_instance_valid(carried_shape):
			carried_shape.respawn()
		carried_shape = null
		carried_shape_type = ""
	elif remote_carrying != carried_shape_type:
		carried_shape_type = remote_carrying
	update_nameplate_text()

func reset_player_score():
	checkpoint_score = 0
	shapes_in_basket = { "Cube": 0, "Sphere": 0, "Cone": 0, "Cuboid": 0, "Star": 0 }
	total_score = 0
	individual_timer = 0.0
	is_on_ladder = false
	active_ladder = null
	checkpoint_cleared_for_current_shape = false
	if carried_shape and is_instance_valid(carried_shape):
		carried_shape.respawn()
	carried_shape = null
	carried_shape_type = ""
	update_nameplate_text()
	if is_locally_controlled:
		_sync_player_score_data()

# --- Transform RPC Network Layer ---
func _send_transform_network():
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
		
	var cur_rot_y = model_container.rotation.y
	var send_pos = global_position
	if send_pos.y > 12.0 or send_pos.y < -1.0:
		send_pos.y = 0.5
		global_position = send_pos
		velocity.y = 0.0

	if multiplayer.is_server():
		relay_transform.rpc(send_pos, cur_rot_y, velocity)
	else:
		client_send_transform.rpc_id(1, send_pos, cur_rot_y, velocity)

@rpc("any_peer", "unreliable")
func client_send_transform(pos: Vector3, rot_y: float, vel: Vector3):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority() and sender_id != name.to_int():
		return
		
	if pos.y > 12.0 or pos.y < -1.0:
		pos.y = 0.5
		vel.y = 0.0

	if not is_locally_controlled:
		sync_position = pos
		sync_rotation_y = rot_y
		sync_velocity = vel

	if multiplayer.is_server():
		relay_transform.rpc(pos, rot_y, vel)

@rpc("any_peer", "unreliable")
func relay_transform(pos: Vector3, rot_y: float, vel: Vector3):
	if pos.y > 12.0 or pos.y < -1.0:
		pos.y = 0.5
		vel.y = 0.0

	if not is_locally_controlled:
		sync_position = pos
		sync_rotation_y = rot_y
		sync_velocity = vel

func _process_remote_interpolation(delta):
	if sync_position != Vector3.ZERO:
		if sync_position.y > 12.0 or sync_position.y < -1.0:
			sync_position.y = 0.5
		var prev_pos = global_position
		global_position = global_position.lerp(sync_position, delta * 18.0)
		model_container.rotation.y = lerp_angle(model_container.rotation.y, sync_rotation_y, delta * 18.0)
		if sync_velocity.length_squared() > 0.05:
			velocity = sync_velocity
		else:
			var computed_vel = (global_position - prev_pos) / max(delta, 0.001)
			velocity = computed_vel

@rpc("authority", "call_local", "reliable")
func teleport_to_position(target_pos: Vector3):
	global_position = target_pos
	sync_position = target_pos
	velocity = Vector3.ZERO

# --- Scoreboard Sync Layer ---
func _sync_player_score_data():
	# ONLY the machine controlling this avatar can report score data!
	if not is_locally_controlled:
		return
		
	var main_node = get_tree().root.get_node_or_null("Main")
	if main_node and main_node.has_method("report_player_score_data"):
		var p_id = name.to_int()
		if p_id == 0: p_id = multiplayer.get_unique_id()
		main_node.report_player_score_data(p_id, {
			"nickname": player_nickname,
			"character": player_character_name,
			"serial": player_serial,
			"color": player_color_name,
			"timer": individual_timer,
			"checkpoint": checkpoint_score,
			"shapes": shapes_in_basket,
			"total_score": total_score,
			"carrying": carried_shape_type
		})

# --- Rich Procedural Humanoid Animation (Hands, Arms, Legs, Head & Carrying) ---
func _animate_body_and_hands(delta: float):
	if avatar_instance == null or not is_instance_valid(avatar_instance):
		var found = model_container.get_node_or_null("HumanoidAvatar") as HumanoidAvatar
		if found and is_instance_valid(found):
			avatar_instance = found
		elif model_container:
			for c in model_container.get_children():
				if c is HumanoidAvatar:
					avatar_instance = c
					break
	
	if avatar_instance and is_instance_valid(avatar_instance):
		var cam_pitch = spring_arm.rotation.x if (is_locally_controlled and spring_arm) else 0.0
		var is_sprint = Input.is_action_pressed("sprint") if is_locally_controlled else (velocity.length() > SPEED + 0.5)
		var on_ground = is_on_floor() or (global_position.y <= 0.85)
		avatar_instance.update_animation(delta, velocity, on_ground, is_carrying(), is_sprint, cam_pitch, is_on_ladder)

# --- Dynamic Character Loading & Nameplate ---
@rpc("any_peer", "call_local", "reliable")
func apply_customization(p_name: String, p_char: String, p_color_name: String, p_serial: String):
	player_nickname = p_name
	player_character_name = p_char
	player_color_name = p_color_name
	player_serial = p_serial
	
	load_character_model(p_char)
	update_nameplate_text()

func load_character_model(char_name: String):
	if not model_container:
		return
		
	for child in model_container.get_children():
		model_container.remove_child(child)
		child.queue_free()
		
	var avatar = HumanoidAvatar.new()
	avatar.name = "HumanoidAvatar"
	model_container.add_child(avatar)
	avatar_instance = avatar
	avatar.build(char_name, player_color_name)
	
	model_container.scale = Vector3.ONE
	model_container.position = Vector3.ZERO
	if nameplate:
		nameplate.position.y = 2.15

func update_nameplate_text():
	if nameplate:
		var col = COLOR_MAP.get(player_color_name, Color.WHITE)
		var carry_str = " • Carrying: " + carried_shape_type if is_carrying() else ""
		var basket_count = _get_total_basket_shapes()
		nameplate.text = "%s\n[%s • %s%s]\n⭐ Score: %d pts | Gate: %d | Basket: %d" % [
			player_nickname,
			player_character_name,
			player_serial,
			carry_str,
			total_score,
			checkpoint_score,
			basket_count
		]
		nameplate.modulate = col
