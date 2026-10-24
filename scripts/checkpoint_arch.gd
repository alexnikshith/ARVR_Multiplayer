extends Area3D
class_name CheckpointArch

signal checkpoint_passed(player_id: int, new_score: int)

@onready var arch_label: Label3D = $ArchLabel
@onready var arch_flash: OmniLight3D = $ArchFlash
@onready var lintel_glow: CSGBox3D = $Pillars/Lintel/GlowStrip

var total_crossings: int = 0

func _ready():
	add_to_group("checkpoint_arches")
	body_entered.connect(_on_body_entered)
	if arch_flash:
		arch_flash.visible = false

func _on_body_entered(body: Node):
	if body.is_in_group("players"):
		# Only locally controlled player triggers the pass to avoid remote ghost triggers
		if body.get("is_locally_controlled") == true:
			if body.has_method("is_carrying") and body.is_carrying():
				if body.has_method("can_trigger_checkpoint") and body.can_trigger_checkpoint():
					if body.has_method("trigger_checkpoint_pass"):
						body.trigger_checkpoint_pass()
					elif body.has_method("on_checkpoint_passed"):
						body.on_checkpoint_passed()

func trigger_network_flash():
	total_crossings += 1
	_trigger_flash()

func _trigger_flash():
	if arch_flash:
		arch_flash.visible = true
		arch_flash.light_energy = 3.5
		var tween = create_tween()
		tween.tween_property(arch_flash, "light_energy", 0.0, 0.5)
		tween.tween_callback(func(): arch_flash.visible = false)
		
	if arch_label:
		arch_label.text = "✅ CHECKPOINT PASSED! (+1 PT)\n⭐ Total Arch Crossings: %d" % total_crossings
		arch_label.modulate = Color(0.3, 1.0, 0.5)
		get_tree().create_timer(1.8).timeout.connect(func():
			if arch_label:
				arch_label.text = "🏁 CHECKPOINT ARCH (TASK 2)\nPass through with a shape for +1 Point!"
				arch_label.modulate = Color(1.0, 0.9, 0.3)
		)

func reset_arch():
	total_crossings = 0
	if arch_label:
		arch_label.text = "🏁 CHECKPOINT ARCH (TASK 2)\nPass through with a shape for +1 Point!"
		arch_label.modulate = Color(1.0, 0.9, 0.3)
	if arch_flash:
		arch_flash.visible = false
