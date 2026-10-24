extends Node3D
class_name HumanoidAvatar

# --- Joint Node References ---
var root_pelvis: Node3D = null
var torso_joint: Node3D = null
var neck_joint: Node3D = null
var head_joint: Node3D = null

var left_shoulder: Node3D = null
var left_elbow: Node3D = null
var left_wrist: Node3D = null

var right_shoulder: Node3D = null
var right_elbow: Node3D = null
var right_wrist: Node3D = null

var left_hip: Node3D = null
var left_knee: Node3D = null
var left_ankle: Node3D = null

var right_hip: Node3D = null
var right_knee: Node3D = null
var right_ankle: Node3D = null

# Materials
var mat_primary: StandardMaterial3D = null
var mat_secondary: StandardMaterial3D = null
var mat_skin: StandardMaterial3D = null
var mat_pants: StandardMaterial3D = null
var mat_shoes: StandardMaterial3D = null
var mat_glow: StandardMaterial3D = null
var mat_hair: StandardMaterial3D = null
var mat_eyes: StandardMaterial3D = null

# Animation parameters
var anim_time: float = 0.0
var walk_phase: float = 0.0
var current_style: String = "Cyber Runner"
var pickup_anim_timer: float = 0.0
const PICKUP_DURATION: float = 0.42

func trigger_pickup():
	pickup_anim_timer = PICKUP_DURATION

func is_in_pickup() -> bool:
	return pickup_anim_timer > 0.0

func get_pickup_progress() -> float:
	if pickup_anim_timer <= 0.0:
		return 1.0
	return clamp(1.0 - (pickup_anim_timer / PICKUP_DURATION), 0.0, 1.0)

const COLOR_MAP = {
	"Blue": Color(0.2, 0.65, 1.0),
	"Red": Color(1.0, 0.28, 0.28),
	"Green": Color(0.25, 0.95, 0.45),
	"Yellow": Color(1.0, 0.88, 0.2),
	"Purple": Color(0.85, 0.4, 1.0),
	"Orange": Color(1.0, 0.58, 0.15),
	"Cyan": Color(0.15, 0.95, 0.95),
	"White": Color(0.95, 0.95, 0.95)
}

func _ready():
	pass

# Helper to create MeshInstance3D with mesh and material
func _create_mesh_box(parent: Node, size: Vector3, mat: Material, offset: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = offset
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _create_mesh_capsule(parent: Node, radius: float, height: float, mat: Material, offset: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = radius
	cap.height = height
	cap.material = mat
	mi.mesh = cap
	mi.position = offset
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _create_mesh_sphere(parent: Node, radius: float, mat: Material, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.material = mat
	mi.mesh = sph
	mi.position = offset
	parent.add_child(mi)
	return mi

func _create_mesh_cylinder(parent: Node, top_r: float, bot_r: float, height: float, mat: Material, offset: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.material = mat
	mi.mesh = cyl
	mi.position = offset
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _setup_materials(color_name: String, style: String):
	var base_col = COLOR_MAP.get(color_name, Color(0.2, 0.65, 1.0))
	
	mat_primary = StandardMaterial3D.new()
	mat_primary.albedo_color = base_col
	mat_primary.roughness = 0.4
	mat_primary.metallic = 0.15
	
	mat_secondary = StandardMaterial3D.new()
	mat_secondary.albedo_color = Color(0.12, 0.14, 0.18)
	mat_secondary.roughness = 0.5
	mat_secondary.metallic = 0.3
	
	mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.96, 0.78, 0.66)
	mat_skin.roughness = 0.6
	
	mat_pants = StandardMaterial3D.new()
	mat_pants.albedo_color = Color(0.16, 0.19, 0.26)
	mat_pants.roughness = 0.55
	
	mat_shoes = StandardMaterial3D.new()
	mat_shoes.albedo_color = Color(0.92, 0.94, 0.98)
	mat_shoes.roughness = 0.35
	
	mat_glow = StandardMaterial3D.new()
	mat_glow.albedo_color = base_col
	mat_glow.emission_enabled = true
	mat_glow.emission = base_col
	mat_glow.emission_energy_multiplier = 2.0
	
	mat_hair = StandardMaterial3D.new()
	mat_hair.albedo_color = Color(0.18, 0.14, 0.12)
	mat_hair.roughness = 0.5
	
	mat_eyes = StandardMaterial3D.new()
	mat_eyes.albedo_color = Color(0.08, 0.08, 0.1)
	mat_eyes.roughness = 0.1
	
	# Character-specific material tweaks
	if "knight" in style.to_lower():
		mat_primary.metallic = 0.8
		mat_primary.roughness = 0.25
		mat_secondary.metallic = 0.85
		mat_secondary.albedo_color = Color(0.75, 0.8, 0.85)
	elif "ninja" in style.to_lower():
		mat_pants.albedo_color = Color(0.08, 0.08, 0.1)
		mat_secondary.albedo_color = Color(0.06, 0.06, 0.08)
	elif "astronaut" in style.to_lower():
		mat_pants.albedo_color = Color(0.92, 0.94, 0.96)
		mat_primary.roughness = 0.3
	elif "scientist" in style.to_lower():
		mat_secondary.albedo_color = Color(0.96, 0.96, 0.98)
	elif "mage" in style.to_lower():
		mat_secondary.albedo_color = Color(0.18, 0.1, 0.25)

func build(char_name: String, color_name: String):
	for child in get_children():
		child.queue_free()
		
	current_style = _normalize_style_name(char_name)
	_setup_materials(color_name, current_style)
	
	# 1. Root & Pelvis (Anatomical hip pivot at y = 0.95m)
	root_pelvis = Node3D.new()
	root_pelvis.name = "RootPelvis"
	root_pelvis.position = Vector3(0, 0.95, 0)
	add_child(root_pelvis)
	
	_create_mesh_box(root_pelvis, Vector3(0.36, 0.16, 0.22), mat_pants, Vector3(0, 0, 0))
	# Belt / Sash
	_create_mesh_box(root_pelvis, Vector3(0.38, 0.05, 0.23), mat_secondary, Vector3(0, 0.07, 0))
	_create_mesh_box(root_pelvis, Vector3(0.09, 0.06, 0.03), mat_glow, Vector3(0, 0.07, -0.115))
	
	# 2. Torso (Pivot at waist / y = 0.08m from pelvis)
	torso_joint = Node3D.new()
	torso_joint.name = "TorsoJoint"
	torso_joint.position = Vector3(0, 0.08, 0)
	root_pelvis.add_child(torso_joint)
	
	# Lower Torso & Upper Chest
	_create_mesh_box(torso_joint, Vector3(0.34, 0.18, 0.21), mat_primary, Vector3(0, 0.09, 0))
	_create_mesh_box(torso_joint, Vector3(0.40, 0.22, 0.25), mat_primary, Vector3(0, 0.25, 0))
	# Chest accent / Jacket zipper / Armor plate (Front chest only at Z = -0.125)
	_create_mesh_box(torso_joint, Vector3(0.12, 0.32, 0.03), mat_secondary, Vector3(0, 0.18, -0.12))
	_create_mesh_box(torso_joint, Vector3(0.04, 0.28, 0.03), mat_glow, Vector3(0, 0.18, -0.126))
	
	# Character back item (Backpack / Oxygen Tank / Cape / Scabbard)
	_build_back_accessory(torso_joint)
	
	# 3. Neck & Head
	neck_joint = Node3D.new()
	neck_joint.name = "NeckJoint"
	neck_joint.position = Vector3(0, 0.38, 0)
	torso_joint.add_child(neck_joint)
	_create_mesh_cylinder(neck_joint, 0.07, 0.08, 0.08, mat_skin, Vector3(0, 0.04, 0))
	
	head_joint = Node3D.new()
	head_joint.name = "HeadJoint"
	head_joint.position = Vector3(0, 0.08, 0)
	neck_joint.add_child(head_joint)
	
	# Stylized Head
	_create_mesh_box(head_joint, Vector3(0.25, 0.26, 0.24), mat_skin, Vector3(0, 0.12, 0))
	# Face & Headwear according to character style
	_build_head_and_face(head_joint)
	
	# 4. Arms & Hands (Left & Right)
	# Left Arm
	left_shoulder = Node3D.new()
	left_shoulder.name = "LeftShoulder"
	left_shoulder.position = Vector3(-0.25, 0.30, 0)
	torso_joint.add_child(left_shoulder)
	_create_mesh_sphere(left_shoulder, 0.08, mat_primary, Vector3(0, 0, 0))
	_create_mesh_capsule(left_shoulder, 0.065, 0.22, mat_primary, Vector3(0, -0.11, 0))
	
	left_elbow = Node3D.new()
	left_elbow.name = "LeftElbow"
	left_elbow.position = Vector3(0, -0.22, 0)
	left_shoulder.add_child(left_elbow)
	_create_mesh_sphere(left_elbow, 0.06, mat_secondary, Vector3(0, 0, 0))
	_create_mesh_capsule(left_elbow, 0.055, 0.20, mat_skin, Vector3(0, -0.10, 0))
	
	left_wrist = Node3D.new()
	left_wrist.name = "LeftWrist"
	left_wrist.position = Vector3(0, -0.20, 0)
	left_elbow.add_child(left_wrist)
	# Hand / Glove
	_create_mesh_box(left_wrist, Vector3(0.08, 0.11, 0.07), mat_secondary, Vector3(0, -0.05, 0))
	_create_mesh_box(left_wrist, Vector3(0.035, 0.05, 0.04), mat_skin, Vector3(0.04, -0.03, -0.02)) # Thumb
	
	# Right Arm
	right_shoulder = Node3D.new()
	right_shoulder.name = "RightShoulder"
	right_shoulder.position = Vector3(0.25, 0.30, 0)
	torso_joint.add_child(right_shoulder)
	_create_mesh_sphere(right_shoulder, 0.08, mat_primary, Vector3(0, 0, 0))
	_create_mesh_capsule(right_shoulder, 0.065, 0.22, mat_primary, Vector3(0, -0.11, 0))
	
	right_elbow = Node3D.new()
	right_elbow.name = "RightElbow"
	right_elbow.position = Vector3(0, -0.22, 0)
	right_shoulder.add_child(right_elbow)
	_create_mesh_sphere(right_elbow, 0.06, mat_secondary, Vector3(0, 0, 0))
	_create_mesh_capsule(right_elbow, 0.055, 0.20, mat_skin, Vector3(0, -0.10, 0))
	
	right_wrist = Node3D.new()
	right_wrist.name = "RightWrist"
	right_wrist.position = Vector3(0, -0.20, 0)
	right_elbow.add_child(right_wrist)
	_create_mesh_box(right_wrist, Vector3(0.08, 0.11, 0.07), mat_secondary, Vector3(0, -0.05, 0))
	_create_mesh_box(right_wrist, Vector3(0.035, 0.05, 0.04), mat_skin, Vector3(-0.04, -0.03, -0.02)) # Thumb
	
	# 5. Hips, Legs & Feet (Left & Right)
	# Left Leg
	left_hip = Node3D.new()
	left_hip.name = "LeftHip"
	left_hip.position = Vector3(-0.12, -0.05, 0)
	root_pelvis.add_child(left_hip)
	_create_mesh_sphere(left_hip, 0.085, mat_pants, Vector3(0, 0, 0))
	_create_mesh_capsule(left_hip, 0.08, 0.38, mat_pants, Vector3(0, -0.19, 0))
	
	left_knee = Node3D.new()
	left_knee.name = "LeftKnee"
	left_knee.position = Vector3(0, -0.38, 0)
	left_hip.add_child(left_knee)
	_create_mesh_sphere(left_knee, 0.075, mat_secondary, Vector3(0, 0, 0))
	_create_mesh_capsule(left_knee, 0.07, 0.36, mat_pants, Vector3(0, -0.18, 0))
	
	left_ankle = Node3D.new()
	left_ankle.name = "LeftAnkle"
	left_ankle.position = Vector3(0, -0.36, 0)
	left_knee.add_child(left_ankle)
	# Shoe / Sneaker (forward offset)
	_create_mesh_box(left_ankle, Vector3(0.12, 0.09, 0.23), mat_shoes, Vector3(0, -0.04, -0.05))
	_create_mesh_box(left_ankle, Vector3(0.13, 0.03, 0.24), mat_primary, Vector3(0, -0.07, -0.05)) # Sole
	
	# Right Leg
	right_hip = Node3D.new()
	right_hip.name = "RightHip"
	right_hip.position = Vector3(0.12, -0.05, 0)
	root_pelvis.add_child(right_hip)
	_create_mesh_sphere(right_hip, 0.085, mat_pants, Vector3(0, 0, 0))
	_create_mesh_capsule(right_hip, 0.08, 0.38, mat_pants, Vector3(0, -0.19, 0))
	
	right_knee = Node3D.new()
	right_knee.name = "RightKnee"
	right_knee.position = Vector3(0, -0.38, 0)
	right_hip.add_child(right_knee)
	_create_mesh_sphere(right_knee, 0.075, mat_secondary, Vector3(0, 0, 0))
	_create_mesh_capsule(right_knee, 0.07, 0.36, mat_pants, Vector3(0, -0.18, 0))
	
	right_ankle = Node3D.new()
	right_ankle.name = "RightAnkle"
	right_ankle.position = Vector3(0, -0.36, 0)
	right_knee.add_child(right_ankle)
	_create_mesh_box(right_ankle, Vector3(0.12, 0.09, 0.23), mat_shoes, Vector3(0, -0.04, -0.05))
	_create_mesh_box(right_ankle, Vector3(0.13, 0.03, 0.24), mat_primary, Vector3(0, -0.07, -0.05)) # Sole

func _build_head_and_face(parent: Node3D):
	if "astronaut" in current_style.to_lower():
		# Space helmet with curved tinted visor
		_create_mesh_sphere(parent, 0.21, mat_secondary, Vector3(0, 0.12, 0))
		_create_mesh_box(parent, Vector3(0.24, 0.15, 0.16), mat_glow, Vector3(0, 0.13, -0.10))
		_create_mesh_cylinder(parent, 0.06, 0.06, 0.18, mat_secondary, Vector3(0.20, 0.12, 0), Vector3(0, 0, deg_to_rad(90)))
	elif "knight" in style_lower():
		# Knight helmet with visor slit & crest
		_create_mesh_box(parent, Vector3(0.27, 0.28, 0.26), mat_secondary, Vector3(0, 0.13, 0))
		_create_mesh_box(parent, Vector3(0.22, 0.04, 0.27), mat_glow, Vector3(0, 0.14, 0.02)) # Visor eye slot
		_create_mesh_box(parent, Vector3(0.06, 0.14, 0.30), mat_primary, Vector3(0, 0.28, 0)) # Helmet crest
	elif "ninja" in style_lower():
		# Shinobi mask + forehead protector + headband tails
		_create_mesh_box(parent, Vector3(0.26, 0.14, 0.25), mat_secondary, Vector3(0, 0.07, 0)) # Mouth cowl
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(-0.06, 0.15, -0.12)) # Eyes
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(0.06, 0.15, -0.12))
		_create_mesh_box(parent, Vector3(0.27, 0.06, 0.25), mat_primary, Vector3(0, 0.20, 0)) # Headband
		_create_mesh_box(parent, Vector3(0.12, 0.05, 0.26), mat_glow, Vector3(0, 0.20, -0.01)) # Metal plate
		_create_mesh_box(parent, Vector3(0.06, 0.22, 0.03), mat_primary, Vector3(0, 0.10, 0.16), Vector3(-deg_to_rad(20), 0, 0)) # Ribbons
	elif "scientist" in style_lower():
		# Smart Tech Goggles & slick hair
		_create_mesh_box(parent, Vector3(0.26, 0.09, 0.25), mat_hair, Vector3(0, 0.24, 0))
		_create_mesh_box(parent, Vector3(0.24, 0.07, 0.10), mat_secondary, Vector3(0, 0.14, -0.10)) # Goggles frame
		_create_mesh_sphere(parent, 0.035, mat_glow, Vector3(-0.06, 0.14, -0.14)) # Lenses
		_create_mesh_sphere(parent, 0.035, mat_glow, Vector3(0.06, 0.14, -0.14))
	elif "mage" in style_lower():
		# Wizard pointed hat
		_create_mesh_cylinder(parent, 0.24, 0.24, 0.03, mat_primary, Vector3(0, 0.25, 0)) # Brim
		_create_mesh_cylinder(parent, 0.02, 0.16, 0.28, mat_secondary, Vector3(0, 0.38, 0)) # Cone
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(-0.06, 0.13, -0.12))
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(0.06, 0.13, -0.12))
	elif "ranger" in style_lower():
		# Explorer hat with brim
		_create_mesh_cylinder(parent, 0.22, 0.22, 0.03, mat_secondary, Vector3(0, 0.24, 0)) # Hat brim
		_create_mesh_cylinder(parent, 0.14, 0.15, 0.12, mat_secondary, Vector3(0, 0.30, 0)) # Hat crown
		_create_mesh_box(parent, Vector3(0.30, 0.03, 0.30), mat_primary, Vector3(0, 0.26, 0)) # Hat band
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(-0.06, 0.13, -0.12))
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(0.06, 0.13, -0.12))
	elif "brawler" in style_lower():
		# Spiky hair + headband
		_create_mesh_box(parent, Vector3(0.26, 0.12, 0.25), mat_hair, Vector3(0, 0.24, 0))
		_create_mesh_box(parent, Vector3(0.08, 0.14, 0.08), mat_hair, Vector3(0, 0.32, -0.04), Vector3(deg_to_rad(15), 0, 0)) # Front spike
		_create_mesh_box(parent, Vector3(0.27, 0.05, 0.25), mat_primary, Vector3(0, 0.19, 0)) # Headband
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(-0.06, 0.13, -0.12))
		_create_mesh_sphere(parent, 0.025, mat_eyes, Vector3(0.06, 0.13, -0.12))
	else:
		# Cyber Runner: Tech visor glasses + wireless headphones + stylish hair
		_create_mesh_box(parent, Vector3(0.26, 0.08, 0.25), mat_hair, Vector3(0, 0.24, 0)) # Top hair
		_create_mesh_box(parent, Vector3(0.25, 0.18, 0.06), mat_hair, Vector3(0, 0.14, 0.10)) # Back hair
		_create_mesh_box(parent, Vector3(0.22, 0.05, 0.08), mat_glow, Vector3(0, 0.14, -0.11)) # Cyber Visor
		# Headphones
		_create_mesh_cylinder(parent, 0.05, 0.05, 0.05, mat_secondary, Vector3(-0.14, 0.13, 0), Vector3(0, 0, deg_to_rad(90)))
		_create_mesh_cylinder(parent, 0.05, 0.05, 0.05, mat_secondary, Vector3(0.14, 0.13, 0), Vector3(0, 0, deg_to_rad(90)))
		_create_mesh_cylinder(parent, 0.15, 0.15, 0.03, mat_secondary, Vector3(0, 0.26, 0), Vector3(deg_to_rad(90), 0, 0)) # Headband

func _build_back_accessory(parent: Node3D):
	if "astronaut" in current_style.to_lower():
		# Life-support backpack
		_create_mesh_box(parent, Vector3(0.30, 0.34, 0.16), mat_secondary, Vector3(0, 0.22, 0.18))
		_create_mesh_box(parent, Vector3(0.08, 0.12, 0.04), mat_glow, Vector3(0, 0.28, 0.26))
	elif "knight" in style_lower():
		# Sword scabbard / shield mount
		_create_mesh_box(parent, Vector3(0.06, 0.65, 0.04), mat_secondary, Vector3(-0.08, 0.20, 0.16), Vector3(0, 0, deg_to_rad(25)))
		_create_mesh_box(parent, Vector3(0.14, 0.05, 0.06), mat_primary, Vector3(-0.08, 0.48, 0.16), Vector3(0, 0, deg_to_rad(25))) # Hilt
	elif "ranger" in style_lower():
		# Quiver of arrows
		_create_mesh_cylinder(parent, 0.07, 0.06, 0.45, mat_secondary, Vector3(0.10, 0.24, 0.16), Vector3(0, 0, -deg_to_rad(20)))
	elif "cyber" in style_lower() or "runner" in style_lower():
		# Cyber battery unit
		_create_mesh_box(parent, Vector3(0.16, 0.22, 0.08), mat_secondary, Vector3(0, 0.20, 0.16))
		_create_mesh_box(parent, Vector3(0.06, 0.16, 0.02), mat_glow, Vector3(0, 0.20, 0.20))

func style_lower() -> String:
	return current_style.to_lower()

func _normalize_style_name(raw_name: String) -> String:
	var l = raw_name.to_lower()
	if "knight" in l: return "Knight Paladin"
	if "ninja" in l: return "Ninja Shadow"
	if "astronaut" in l: return "Cosmic Astronaut"
	if "scientist" in l or "dwarf" in l: return "Tech Scientist"
	if "ranger" in l or "archer" in l or "puglin" in l: return "Ranger Scout"
	if "mage" in l or "wizard" in l: return "Mystic Mage"
	if "brawler" in l or "imp" in l: return "Urban Brawler"
	return "Cyber Runner"

# --- Natural Human Kinematics Animation Engine ---
func update_animation(delta: float, velocity: Vector3, is_on_floor: bool, is_carrying: bool, is_sprinting: bool, camera_pitch: float, is_on_ladder: bool = false):
	if root_pelvis == null or torso_joint == null:
		return
		
	anim_time += delta
	if pickup_anim_timer > 0.0:
		pickup_anim_timer = max(0.0, pickup_anim_timer - delta)
		
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = (horizontal_speed > 0.35 and (is_on_floor or abs(velocity.y) < 2.0)) or (is_on_ladder and abs(velocity.y) > 0.15)
	
	# 1. LOCOMOTION GAIT PHASE
	if is_on_ladder:
		if abs(velocity.y) > 0.15:
			walk_phase += delta * 6.5 * clamp(abs(velocity.y) / 2.5, 0.7, 1.6)
		else:
			walk_phase = lerp_angle(walk_phase, 0.0, delta * 8.0)
	elif is_moving:
		var step_rate = 7.0 if is_sprinting else 5.2
		walk_phase += delta * step_rate * clamp(horizontal_speed / 4.0, 0.6, 1.8)
	else:
		walk_phase = lerp_angle(walk_phase, 0.0, delta * 10.0)

	var in_pickup = pickup_anim_timer > 0.0
	var pickup_prog = get_pickup_progress()
	# Pickup reach weight (bell curve peaking at prog 0.45)
	var pickup_reach_weight = sin(pickup_prog * PI) if in_pickup else 0.0

	# 2. NATURAL HUMAN LEGS & KNEES (Knees bend backward with negative X rotation!)
	if is_moving:
		var stride_amp = 0.68 if is_sprinting else 0.50
		
		# --- LEFT LEG ---
		var l_sin = sin(walk_phase)
		var l_hip_pitch = l_sin * stride_amp
		left_hip.rotation.x = l_hip_pitch
		left_hip.rotation.y = 0.0
		left_hip.rotation.z = -0.02
		
		if l_sin > 0.0:
			# Forward reach: knee bends backward (-X) to lift foot cleanly off ground
			var reach_bend = sin(l_sin * PI * 0.5) * 0.65
			left_knee.rotation.x = -reach_bend - 0.04
			left_ankle.rotation.x = -l_hip_pitch * 0.5 + reach_bend * 0.3
		else:
			# Backward push / toe-off: knee flexes backward at toe-off
			var push_power = -l_sin
			var toe_off_bend = pow(push_power, 1.8) * 0.90
			left_knee.rotation.x = -toe_off_bend - 0.04
			left_ankle.rotation.x = push_power * 0.35
			
		# --- RIGHT LEG (pi phase offset) ---
		var r_sin = sin(walk_phase + PI)
		var r_hip_pitch = r_sin * stride_amp
		right_hip.rotation.x = r_hip_pitch
		right_hip.rotation.y = 0.0
		right_hip.rotation.z = 0.02
		
		if r_sin > 0.0:
			var reach_bend_r = sin(r_sin * PI * 0.5) * 0.65
			right_knee.rotation.x = -reach_bend_r - 0.04
			right_ankle.rotation.x = -r_hip_pitch * 0.5 + reach_bend_r * 0.3
		else:
			var push_power_r = -r_sin
			var toe_off_bend_r = pow(push_power_r, 1.8) * 0.90
			right_knee.rotation.x = -toe_off_bend_r - 0.04
			right_ankle.rotation.x = push_power_r * 0.35
			
	elif in_pickup:
		# Pickup crouching stance: knees bent backward into slight crouch
		var knee_crouch = -0.40 * pickup_reach_weight
		left_hip.rotation.x = lerp_angle(left_hip.rotation.x, 0.16 * pickup_reach_weight, clamp(delta * 14.0, 0.0, 1.0))
		left_hip.rotation.z = -0.02
		left_knee.rotation.x = lerp_angle(left_knee.rotation.x, knee_crouch, clamp(delta * 14.0, 0.0, 1.0))
		left_ankle.rotation.x = lerp_angle(left_ankle.rotation.x, 0.0, clamp(delta * 10.0, 0.0, 1.0))
		
		right_hip.rotation.x = lerp_angle(right_hip.rotation.x, 0.16 * pickup_reach_weight, clamp(delta * 14.0, 0.0, 1.0))
		right_hip.rotation.z = 0.02
		right_knee.rotation.x = lerp_angle(right_knee.rotation.x, knee_crouch, clamp(delta * 14.0, 0.0, 1.0))
		right_ankle.rotation.x = lerp_angle(right_ankle.rotation.x, 0.0, clamp(delta * 10.0, 0.0, 1.0))
	elif is_on_ladder:
		# Ladder climbing legs
		var step_l = sin(walk_phase)
		left_hip.rotation.x = step_l * 0.45
		left_hip.rotation.z = -0.02
		left_knee.rotation.x = -abs(step_l) * 0.7 - 0.05
		left_ankle.rotation.x = step_l * 0.2
		
		var step_r = -step_l
		right_hip.rotation.x = step_r * 0.45
		right_hip.rotation.z = 0.02
		right_knee.rotation.x = -abs(step_r) * 0.7 - 0.05
		right_ankle.rotation.x = step_r * 0.2
	elif not is_on_floor:
		# Jump / Airborne Pose: knees bent backward naturally, feet pointing down
		left_hip.rotation.x = lerp_angle(left_hip.rotation.x, deg_to_rad(22.0), clamp(delta * 12.0, 0.0, 1.0))
		left_knee.rotation.x = lerp_angle(left_knee.rotation.x, -deg_to_rad(38.0), clamp(delta * 12.0, 0.0, 1.0))
		left_ankle.rotation.x = lerp_angle(left_ankle.rotation.x, -deg_to_rad(15.0), clamp(delta * 12.0, 0.0, 1.0))
		
		right_hip.rotation.x = lerp_angle(right_hip.rotation.x, deg_to_rad(16.0), clamp(delta * 12.0, 0.0, 1.0))
		right_knee.rotation.x = lerp_angle(right_knee.rotation.x, -deg_to_rad(30.0), clamp(delta * 12.0, 0.0, 1.0))
		right_ankle.rotation.x = lerp_angle(right_ankle.rotation.x, -deg_to_rad(15.0), clamp(delta * 12.0, 0.0, 1.0))
	else:
		# Idle Standing Stance
		var idle_shift = sin(anim_time * 1.5) * 0.02
		left_hip.rotation.x = lerp_angle(left_hip.rotation.x, idle_shift, clamp(delta * 8.0, 0.0, 1.0))
		left_hip.rotation.z = -0.03
		left_knee.rotation.x = lerp_angle(left_knee.rotation.x, -0.04, clamp(delta * 8.0, 0.0, 1.0))
		left_ankle.rotation.x = lerp_angle(left_ankle.rotation.x, 0.0, clamp(delta * 8.0, 0.0, 1.0))
		
		right_hip.rotation.x = lerp_angle(right_hip.rotation.x, -idle_shift, clamp(delta * 8.0, 0.0, 1.0))
		right_hip.rotation.z = 0.03
		right_knee.rotation.x = lerp_angle(right_knee.rotation.x, -0.04, clamp(delta * 8.0, 0.0, 1.0))
		right_ankle.rotation.x = lerp_angle(right_ankle.rotation.x, 0.0, clamp(delta * 8.0, 0.0, 1.0))

	# 3. PELVIS BOUNCE & TORSO DYNAMICS
	var base_pelvis_y = 0.95 - (0.14 * pickup_reach_weight)
	if in_pickup:
		root_pelvis.position.y = lerp(root_pelvis.position.y, base_pelvis_y, clamp(delta * 14.0, 0.0, 1.0))
		var torso_x = -0.52 * pickup_reach_weight
		torso_joint.rotation.x = lerp_angle(torso_joint.rotation.x, torso_x, clamp(delta * 16.0, 0.0, 1.0))
		torso_joint.rotation.z = lerp_angle(torso_joint.rotation.z, 0.0, clamp(delta * 12.0, 0.0, 1.0))
		torso_joint.rotation.y = lerp_angle(torso_joint.rotation.y, 0.0, clamp(delta * 12.0, 0.0, 1.0))
	elif is_moving:
		var step_bob = abs(sin(walk_phase)) * (0.045 if is_sprinting else 0.032)
		root_pelvis.position.y = base_pelvis_y + step_bob
		var sway = sin(walk_phase) * (0.04 if is_sprinting else 0.028)
		torso_joint.rotation.z = lerp_angle(torso_joint.rotation.z, sway, clamp(delta * 14.0, 0.0, 1.0))
		var forward_lean = -0.16 if is_sprinting else -0.08
		torso_joint.rotation.x = lerp_angle(torso_joint.rotation.x, forward_lean, clamp(delta * 14.0, 0.0, 1.0))
		torso_joint.rotation.y = lerp_angle(torso_joint.rotation.y, -sin(walk_phase) * 0.08, clamp(delta * 12.0, 0.0, 1.0))
	elif not is_on_floor:
		root_pelvis.position.y = lerp(root_pelvis.position.y, 0.96, clamp(delta * 8.0, 0.0, 1.0))
		torso_joint.rotation.x = lerp_angle(torso_joint.rotation.x, 0.05, clamp(delta * 8.0, 0.0, 1.0))
		torso_joint.rotation.z = lerp_angle(torso_joint.rotation.z, 0.0, clamp(delta * 8.0, 0.0, 1.0))
		torso_joint.rotation.y = lerp_angle(torso_joint.rotation.y, 0.0, clamp(delta * 8.0, 0.0, 1.0))
	else:
		var breath = sin(anim_time * 2.2)
		root_pelvis.position.y = lerp(root_pelvis.position.y, base_pelvis_y + breath * 0.008, clamp(delta * 12.0, 0.0, 1.0))
		var torso_x = breath * 0.02
		torso_joint.rotation.x = lerp_angle(torso_joint.rotation.x, torso_x, clamp(delta * 14.0, 0.0, 1.0))
		torso_joint.rotation.z = lerp_angle(torso_joint.rotation.z, sin(anim_time * 1.2) * 0.012, clamp(delta * 8.0, 0.0, 1.0))
		torso_joint.rotation.y = lerp_angle(torso_joint.rotation.y, 0.0, clamp(delta * 8.0, 0.0, 1.0))

	# 4. NATURAL HUMAN ARMS & ELBOWS (Pickup, Carry, Walking, Idle)
	if in_pickup:
		var blend_fast = clamp(delta * 18.0, 0.0, 1.0)
		var blend_lift = clamp(delta * 16.0, 0.0, 1.0)
		if pickup_prog < 0.45:
			# Reach down & grasp towards the object on floor
			var reach_l_sh = Vector3(deg_to_rad(75.0), deg_to_rad(14.0), -deg_to_rad(10.0))
			var reach_l_el = Vector3(deg_to_rad(28.0), deg_to_rad(8.0), 0)
			var reach_l_wr = Vector3(deg_to_rad(30.0), deg_to_rad(25.0), deg_to_rad(10.0))
			
			var reach_r_sh = Vector3(deg_to_rad(75.0), -deg_to_rad(14.0), deg_to_rad(10.0))
			var reach_r_el = Vector3(deg_to_rad(28.0), -deg_to_rad(8.0), 0)
			var reach_r_wr = Vector3(deg_to_rad(30.0), -deg_to_rad(25.0), -deg_to_rad(10.0))
			
			left_shoulder.rotation = left_shoulder.rotation.lerp(reach_l_sh, blend_fast)
			left_elbow.rotation = left_elbow.rotation.lerp(reach_l_el, blend_fast)
			left_wrist.rotation = left_wrist.rotation.lerp(reach_l_wr, blend_fast)
			
			right_shoulder.rotation = right_shoulder.rotation.lerp(reach_r_sh, blend_fast)
			right_elbow.rotation = right_elbow.rotation.lerp(reach_r_el, blend_fast)
			right_wrist.rotation = right_wrist.rotation.lerp(reach_r_wr, blend_fast)
		else:
			# Lift & scoop up into chest carry posture
			var target_l_sh = Vector3(deg_to_rad(50.0), deg_to_rad(22.0), -deg_to_rad(12.0))
			var target_l_el = Vector3(deg_to_rad(76.0), deg_to_rad(12.0), 0)
			var target_l_wr = Vector3(deg_to_rad(15.0), deg_to_rad(20.0), deg_to_rad(10.0))
			
			var target_r_sh = Vector3(deg_to_rad(50.0), -deg_to_rad(22.0), deg_to_rad(12.0))
			var target_r_el = Vector3(deg_to_rad(76.0), -deg_to_rad(12.0), 0)
			var target_r_wr = Vector3(deg_to_rad(15.0), -deg_to_rad(20.0), -deg_to_rad(10.0))
			
			left_shoulder.rotation = left_shoulder.rotation.lerp(target_l_sh, blend_lift)
			left_elbow.rotation = left_elbow.rotation.lerp(target_l_el, blend_lift)
			left_wrist.rotation = left_wrist.rotation.lerp(target_l_wr, blend_lift)
			
			right_shoulder.rotation = right_shoulder.rotation.lerp(target_r_sh, blend_lift)
			right_elbow.rotation = right_elbow.rotation.lerp(target_r_el, blend_lift)
			right_wrist.rotation = right_wrist.rotation.lerp(target_r_wr, blend_lift)
			
	elif is_carrying:
		# Two-handed carry posture: holding shape right at chest level in front of player
		var carry_bob = sin(anim_time * 3.5) * 0.02
		var carry_walk_comp = sin(walk_phase) * 0.035 if is_moving else 0.0
		var blend_c = clamp(delta * 15.0, 0.0, 1.0)
		
		# Left Arm: raised forward (+X) and angled inward (+Y)
		var target_l_shoulder = Vector3(deg_to_rad(50.0) + carry_bob, deg_to_rad(22.0), -deg_to_rad(12.0) + carry_walk_comp)
		var target_l_elbow = Vector3(deg_to_rad(76.0), deg_to_rad(12.0), 0)
		var target_l_wrist = Vector3(deg_to_rad(15.0), deg_to_rad(20.0), deg_to_rad(10.0))
		
		left_shoulder.rotation = left_shoulder.rotation.lerp(target_l_shoulder, blend_c)
		left_elbow.rotation = left_elbow.rotation.lerp(target_l_elbow, blend_c)
		left_wrist.rotation = left_wrist.rotation.lerp(target_l_wrist, blend_c)
		
		# Right Arm: raised forward (+X) and angled inward (-Y)
		var target_r_shoulder = Vector3(deg_to_rad(50.0) - carry_bob, -deg_to_rad(22.0), deg_to_rad(12.0) - carry_walk_comp)
		var target_r_elbow = Vector3(deg_to_rad(76.0), -deg_to_rad(12.0), 0)
		var target_r_wrist = Vector3(deg_to_rad(15.0), -deg_to_rad(20.0), -deg_to_rad(10.0))
		
		right_shoulder.rotation = right_shoulder.rotation.lerp(target_r_shoulder, blend_c)
		right_elbow.rotation = right_elbow.rotation.lerp(target_r_elbow, blend_c)
		right_wrist.rotation = right_wrist.rotation.lerp(target_r_wrist, blend_c)
		
	elif is_moving:
		# Walking / Running Arm Swing (opposite to same-side leg)
		var arm_amp = 0.65 if is_sprinting else 0.48
		
		# Left Arm (matches Right Leg, opposes Left Leg)
		var l_arm_swing = sin(walk_phase + PI) * arm_amp
		left_shoulder.rotation.x = l_arm_swing
		left_shoulder.rotation.y = deg_to_rad(6.0)
		left_shoulder.rotation.z = -deg_to_rad(8.0)
		var l_elbow_flex = deg_to_rad(18.0) + max(0.0, l_arm_swing) * 0.90
		left_elbow.rotation.x = l_elbow_flex
		left_wrist.rotation.x = l_arm_swing * 0.28
		
		# Right Arm (matches Left Leg, opposes Right Leg)
		var r_arm_swing = sin(walk_phase) * arm_amp
		right_shoulder.rotation.x = r_arm_swing
		right_shoulder.rotation.y = -deg_to_rad(6.0)
		right_shoulder.rotation.z = deg_to_rad(8.0)
		var r_elbow_flex = deg_to_rad(18.0) + max(0.0, r_arm_swing) * 0.90
		right_elbow.rotation.x = r_elbow_flex
		right_wrist.rotation.x = r_arm_swing * 0.28
		
	elif is_on_ladder:
		# Ladder Climbing Hand-over-Hand Pose
		var l_reach = sin(walk_phase) * deg_to_rad(28.0)
		var r_reach = -sin(walk_phase) * deg_to_rad(28.0)
		var target_l_arm = Vector3(deg_to_rad(65.0) + l_reach, deg_to_rad(8.0), -deg_to_rad(10.0))
		var target_l_el = Vector3(deg_to_rad(45.0) + l_reach * 0.5, 0, 0)
		var target_r_arm = Vector3(deg_to_rad(65.0) + r_reach, -deg_to_rad(8.0), deg_to_rad(10.0))
		var target_r_el = Vector3(deg_to_rad(45.0) + r_reach * 0.5, 0, 0)
		var blend_lad = clamp(delta * 14.0, 0.0, 1.0)
		left_shoulder.rotation = left_shoulder.rotation.lerp(target_l_arm, blend_lad)
		left_elbow.rotation = left_elbow.rotation.lerp(target_l_el, blend_lad)
		right_shoulder.rotation = right_shoulder.rotation.lerp(target_r_arm, blend_lad)
		right_elbow.rotation = right_elbow.rotation.lerp(target_r_el, blend_lad)
	elif not is_on_floor:
		# Jump Balance Pose: arms raised slightly outward for balance
		var target_jump_l = Vector3(-deg_to_rad(10.0), deg_to_rad(8.0), -deg_to_rad(26.0))
		var target_jump_r = Vector3(-deg_to_rad(10.0), -deg_to_rad(8.0), deg_to_rad(26.0))
		var blend_j = clamp(delta * 10.0, 0.0, 1.0)
		left_shoulder.rotation = left_shoulder.rotation.lerp(target_jump_l, blend_j)
		left_elbow.rotation = left_elbow.rotation.lerp(Vector3(deg_to_rad(30.0), 0, 0), blend_j)
		right_shoulder.rotation = right_shoulder.rotation.lerp(target_jump_r, blend_j)
		right_elbow.rotation = right_elbow.rotation.lerp(Vector3(deg_to_rad(30.0), 0, 0), blend_j)
	else:
		# Natural Relaxed Human Idle Arms: resting at sides with slight forward elbow bend (~18°)
		var breath = sin(anim_time * 2.2) * 0.03
		var idle_sway = cos(anim_time * 1.6) * 0.02
		var blend_i = clamp(delta * 8.0, 0.0, 1.0)
		
		var target_l_arm = Vector3(-deg_to_rad(5.0) + breath, deg_to_rad(4.0), -deg_to_rad(8.0))
		var target_l_elbow = Vector3(deg_to_rad(18.0) + breath * 0.5, 0, 0)
		left_shoulder.rotation = left_shoulder.rotation.lerp(target_l_arm, blend_i)
		left_elbow.rotation = left_elbow.rotation.lerp(target_l_elbow, blend_i)
		left_wrist.rotation = left_wrist.rotation.lerp(Vector3(idle_sway, 0, 0), blend_i)
		
		var target_r_arm = Vector3(-deg_to_rad(5.0) + breath, -deg_to_rad(4.0), deg_to_rad(8.0))
		var target_r_elbow = Vector3(deg_to_rad(18.0) + breath * 0.5, 0, 0)
		right_shoulder.rotation = right_shoulder.rotation.lerp(target_r_arm, blend_i)
		right_elbow.rotation = right_elbow.rotation.lerp(target_r_elbow, blend_i)
		right_wrist.rotation = right_wrist.rotation.lerp(Vector3(-idle_sway, 0, 0), blend_i)

	# 5. HEAD TRACKING & LOOK
	var pitch_target = clamp(camera_pitch * 0.75, -deg_to_rad(45.0), deg_to_rad(45.0))
	if in_pickup:
		pitch_target += 0.25 * pickup_reach_weight
	var idle_yaw = 0.0
	var idle_tilt = 0.0
	if not is_moving and is_on_floor:
		idle_yaw = sin(anim_time * 0.6) * 0.08
		idle_tilt = cos(anim_time * 0.8) * 0.03
		
	head_joint.rotation.x = lerp_angle(head_joint.rotation.x, pitch_target, delta * 14.0)
	head_joint.rotation.y = lerp_angle(head_joint.rotation.y, idle_yaw, delta * 8.0)
	head_joint.rotation.z = lerp_angle(head_joint.rotation.z, idle_tilt - torso_joint.rotation.z * 0.7, delta * 10.0)
