extends Area3D
class_name ShapeBasket

signal shape_deposited(player_id: int, shape_type: String, new_counts: Dictionary)

# Live count of shapes placed in this basket
var basket_counts = {
	"Cube": 0,
	"Sphere": 0,
	"Cone": 0,
	"Cuboid": 0,
	"Star": 0
}

@onready var billboard_label: Label3D = $BillboardLabel
@onready var deposit_flash: OmniLight3D = $DepositFlash

func _ready():
	add_to_group("baskets")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_billboard()
	if deposit_flash:
		deposit_flash.visible = false

var player_in_basket: Node3D = null

func _on_body_entered(body: Node):
	if body.is_in_group("players"):
		if body.get("is_locally_controlled") == true:
			player_in_basket = body
			_update_billboard()

func _on_body_exited(body: Node):
	if body == player_in_basket:
		player_in_basket = null
		_update_billboard()

func on_network_deposit(player_id: int, s_type: String):
	if not basket_counts.has(s_type):
		basket_counts[s_type] = 0
	basket_counts[s_type] += 1
	_update_billboard()
	_trigger_deposit_effect(s_type)
	shape_deposited.emit(player_id, s_type, basket_counts)

func deposit_shape_from_player(player_node: Node3D, s_type: String, p_id: int):
	on_network_deposit(p_id, s_type)

func _update_billboard():
	if billboard_label:
		var total = 0
		for val in basket_counts.values():
			total += val
		var base_text = "📥 SHAPE COLLECTION BASKET\n" + \
			"📦 %d Cube | 🟡 %d Sphere | 🔺 %d Cone | 🟩 %d Cuboid | ⭐ %d Star\n" % [
				basket_counts.get("Cube", 0),
				basket_counts.get("Sphere", 0),
				basket_counts.get("Cone", 0),
				basket_counts.get("Cuboid", 0),
				basket_counts.get("Star", 0)
			] + \
			"⭐ Total Shapes in Basket: %d" % total
		
		if player_in_basket and is_instance_valid(player_in_basket):
			if player_in_basket.has_method("is_carrying") and player_in_basket.is_carrying():
				base_text += "\n👉 PRESS [E] OR CLICK HUD BUTTON TO DEPOSIT %s!" % player_in_basket.get_carried_shape_type().to_upper()
		
		billboard_label.text = base_text

func _trigger_deposit_effect(s_type: String):
	if deposit_flash:
		deposit_flash.visible = true
		deposit_flash.light_energy = 3.0
		var tween = create_tween()
		tween.tween_property(deposit_flash, "light_energy", 0.0, 0.45)
		tween.tween_callback(func(): deposit_flash.visible = false)

@rpc("any_peer", "call_local", "reliable")
func sync_basket_state(new_counts: Dictionary):
	basket_counts = new_counts
	_update_billboard()

func reset_basket():
	basket_counts = {
		"Cube": 0,
		"Sphere": 0,
		"Cone": 0,
		"Cuboid": 0,
		"Star": 0
	}
	player_in_basket = null
	_update_billboard()
	if deposit_flash:
		deposit_flash.visible = false
