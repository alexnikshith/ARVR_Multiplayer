extends Area3D
class_name PickableShape

@export_enum("Cube", "Sphere", "Cone", "Cuboid", "Star") var shape_type: String = "Cube"
@export var respawn_pos: Vector3 = Vector3.ZERO
@export var shape_color: Color = Color(0.2, 0.8, 1.0)

var is_held: bool = false
var carrier_node: Node3D = null

@onready var mesh_cube = $MeshCube
@onready var mesh_sphere = $MeshSphere
@onready var mesh_cone = $MeshCone
@onready var mesh_cuboid = $MeshCuboid
@onready var mesh_star = get_node_or_null("MeshStar")
@onready var label_prompt = $LabelPrompt
@onready var collision_shape = $CollisionShape3D

var float_offset: float = 0.0
var drop_respawn_timer: float = 0.0
var player_in_range: Node3D = null

func _ready():
	add_to_group("pickable_shapes")
	if respawn_pos == Vector3.ZERO:
		respawn_pos = global_position
		
	_setup_mesh_visibility()
	_update_prompt_text()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _setup_mesh_visibility():
	if mesh_cube: mesh_cube.visible = (shape_type == "Cube")
	if mesh_sphere: mesh_sphere.visible = (shape_type == "Sphere")
	if mesh_cone: mesh_cone.visible = (shape_type == "Cone")
	if mesh_cuboid: mesh_cuboid.visible = (shape_type == "Cuboid")
	if mesh_star: mesh_star.visible = (shape_type == "Star")

func _update_prompt_text():
	if label_prompt:
		if is_held:
			label_prompt.visible = false
		else:
			label_prompt.visible = true
			if player_in_range != null:
				label_prompt.text = "%s\n👉 [E] Pick Up" % shape_type
				label_prompt.modulate = Color(1.0, 0.9, 0.3)
			else:
				label_prompt.text = "%s\n[E] Pick" % shape_type
				label_prompt.modulate = shape_color

func _process(delta):
	if is_held:
		drop_respawn_timer = 0.0
		if carrier_node and is_instance_valid(carrier_node):
			# Smoothly follow player carry anchor
			var carry_anchor = carrier_node.get_node_or_null("CarryAnchor")
			if carry_anchor:
				global_position = global_position.lerp(carry_anchor.global_position, delta * 25.0)
				global_rotation = carry_anchor.global_rotation
			else:
				global_position = carrier_node.global_position + Vector3(0, 1.2, 0)
		else:
			drop_shape()
	else:
		if global_position.distance_to(respawn_pos) > 1.0:
			drop_respawn_timer += delta
			if drop_respawn_timer >= 60.0:
				drop_respawn_timer = 0.0
				respawn()
		else:
			drop_respawn_timer = 0.0
			# Floating gentle bob and spin in depot
			float_offset += delta * 2.5
			position.y = respawn_pos.y + sin(float_offset) * 0.08
			rotate_y(delta * 1.2)

func pick_up(by_player: Node3D):
	if is_held:
		return false
	is_held = true
	carrier_node = by_player
	monitoring = false
	monitorable = false
	if label_prompt:
		label_prompt.visible = false
	return true

func drop_shape():
	is_held = false
	carrier_node = null
	monitoring = true
	monitorable = true
	_update_prompt_text()

func drop_at_position(drop_pos: Vector3):
	is_held = false
	carrier_node = null
	global_position = drop_pos
	rotation = Vector3.ZERO
	monitoring = true
	monitorable = true
	_update_prompt_text()

func respawn():
	is_held = false
	carrier_node = null
	global_position = respawn_pos
	rotation = Vector3.ZERO
	monitoring = true
	monitorable = true
	_update_prompt_text()

func _on_body_entered(body: Node):
	if body.is_in_group("players") and not is_held:
		player_in_range = body
		_update_prompt_text()

func _on_body_exited(body: Node):
	if body == player_in_range:
		player_in_range = null
		_update_prompt_text()
