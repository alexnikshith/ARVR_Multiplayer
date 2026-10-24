extends SceneTree

var step = 0
var host_main: Node3D = null

func _init():
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	step += 1
	if step == 2:
		host_main = root.get_node_or_null("Main")
		host_main.port_input.text = "8944"
		host_main._on_host_pressed()
		return false
		
	elif step == 5:
		var p1 = host_main.players_container.get_node_or_null("1")
		var arena = host_main.get_node_or_null("Arena")
		var depot = arena.get_node_or_null("ShapesDepot")
		var cube1 = depot.get_node_or_null("ShapeCube1")
		var arch = arena.get_node_or_null("CheckpointArch")
		var basket = arena.get_node_or_null("ShapeBasket")
		
		# Test 1: Pick up shape
		print("[TASK 1] Testing pickup...")
		p1.try_pick_shape(cube1)
		print("  -> Carrying: ", p1.is_carrying(), " Shape: ", p1.get_carried_shape_type())
		assert(p1.is_carrying() and p1.get_carried_shape_type() == "Cube", "Failed to carry cube")
		
		# Test 2: Checkpoint pass
		print("[TASK 2] Testing Checkpoint Arch...")
		print("  -> Initial Gate Score: ", p1.checkpoint_score)
		arch._on_body_entered(p1)
		print("  -> After Crossing Gate Score: ", p1.checkpoint_score)
		assert(p1.checkpoint_score == 1, "Failed to increment checkpoint score")
		
		# Shuttle loop: crossing again with the same shape should NOT increment score
		arch._on_body_entered(p1)
		print("  -> Crossing again with same shape: ", p1.checkpoint_score)
		assert(p1.checkpoint_score == 1, "Shuttle loop violated: duplicate gate score awarded!")
		
		# Test 3: Deposit in Basket using button
		print("[TASK 1] Testing Basket Deposit...")
		basket._on_body_entered(p1)
		p1.global_position = basket.global_position
		p1.handle_interact_action()
		print("  -> Basket Counts: ", host_main.global_basket_counts)
		print("  -> Player Score: ", p1.total_score, " Carried after deposit: ", p1.get_carried_shape_type())
		assert(host_main.global_basket_counts["Cube"] == 1, "Basket Cube count should be 1")
		assert(p1.total_score == 2, "Total score should be 1 (arch) + 1 (basket) = 2")
		assert(p1.is_carrying() == false, "Player should no longer be carrying shape")
		
		print("ALL TASKS AND VERIFICATIONS PASSED SUCCESSFULLY!")
		quit(0)
		return true
		
	return false
