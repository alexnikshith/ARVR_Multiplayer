extends Area3D
class_name LadderArea

@export var top_height: float = 3.2
@export var bottom_height: float = 0.0
@export var step_forward_direction: Vector3 = Vector3(0, 0, 1)

@onready var prompt_label: Label3D = $PromptLabel

func _ready():
	add_to_group("ladders")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
	if body.is_in_group("players") and body.has_method("enter_ladder"):
		body.enter_ladder(self)
		if prompt_label:
			prompt_label.modulate = Color(0.3, 1.0, 0.6)

func _on_body_exited(body: Node):
	if body.is_in_group("players") and body.has_method("exit_ladder"):
		body.exit_ladder(self)
		if prompt_label:
			prompt_label.modulate = Color(0.2, 0.85, 1.0)
