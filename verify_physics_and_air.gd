extends SceneTree

var step = 0
var host_main: Node3D = null
var client2_tree: SceneTree = null
var max_y_recorded = 0.0

func _init():
	change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> bool:
	step += 1
	if step == 2:
		host_main = root.get_node_or_null("Main")
		if host_main == null:
			printerr("Cannot find Main!")
			quit(1)
			return true
		host_main.port_input.text = "8933"
		host_main._on_host_pressed()
		print("[TEST] Host started on port 8933")
		return false
		
	elif step == 5:
		var p1 = host_main.players_container.get_node_or_null("1")
		if p1:
			print("[TEST] P1 Spawned at: ", p1.global_position, " Y-vel: ", p1.velocity.y)
			# Simulate second player joining directly
			host_main._on_peer_connected(2)
			host_main.players_info[2] = {
				"name": "player2",
				"character": "Puglin (Dungeon Monsters Kit)",
				"color": "Red",
				"serial": "PC-02"
			}
			# Simulate third player joining
			host_main._on_peer_connected(3)
			host_main.players_info[3] = {
				"name": "player3",
				"character": "Astronaut (Characters Kit)",
				"color": "Green",
				"serial": "PC-03"
			}
		return false
		
	elif step == 10:
		var p1 = host_main.players_container.get_node_or_null("1")
		var p2 = host_main.players_container.get_node_or_null("2")
		var p3 = host_main.players_container.get_node_or_null("3")
		print("[TEST] After spawn -> P1 pos: ", p1.global_position if p1 else "null")
		print("[TEST] After spawn -> P2 pos: ", p2.global_position if p2 else "null")
		print("[TEST] After spawn -> P3 pos: ", p3.global_position if p3 else "null")
		return false
		
	elif step > 10 and step <= 90:
		for id in ["1", "2", "3"]:
			var p = host_main.players_container.get_node_or_null(id)
			if p:
				# Move p towards center to test proximity collision
				p.global_position = p.global_position.move_toward(Vector3.ZERO, delta * 3.0)
				if p.global_position.y > max_y_recorded:
					max_y_recorded = p.global_position.y
		if step % 20 == 0:
			var p1 = host_main.players_container.get_node_or_null("1")
			var p2 = host_main.players_container.get_node_or_null("2")
			print("Frame ", step, " -> P1 Y: ", p1.global_position.y if p1 else 0, " P2 Y: ", p2.global_position.y if p2 else 0)
		return false
		
	elif step > 90:
		print("[TEST RESULT] Max Y recorded across all 3 players: ", max_y_recorded)
		if max_y_recorded > 3.0:
			printerr("FAIL: Players went into the air! Max Y: ", max_y_recorded)
			quit(1)
		else:
			print("SUCCESS: Players remained grounded and never went into the air!")
			quit(0)
		return true
		
	return false
