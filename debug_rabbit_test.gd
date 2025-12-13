extends Node3D

## Minimal debug test - just verify rabbit loads

func _ready() -> void:
	print("\n" + "=".repeat(50))
	print("DEBUG TEST STARTING")
	print("=".repeat(50) + "\n")
	
	# Test 1: Can we load the rabbit scene?
	print("Test 1: Loading corrupted_rabbit.tscn...")
	var rabbit_scene = load("res://corrupted_rabbit.tscn")
	if rabbit_scene:
		print("✅ SUCCESS: Rabbit scene loaded!")
	else:
		print("❌ FAILED: Could not load rabbit scene")
		print("Make sure corrupted_rabbit.tscn is in res://")
		return
	
	# Test 2: Can we instantiate it?
	print("\nTest 2: Instantiating rabbit...")
	var rabbit = rabbit_scene.instantiate()
	if rabbit:
		print("✅ SUCCESS: Rabbit instantiated!")
	else:
		print("❌ FAILED: Could not instantiate rabbit")
		return
	
	add_child(rabbit)
	print("✅ SUCCESS: Rabbit added to scene tree")
	
	# Test 3: Check basic properties
	print("\nTest 3: Checking rabbit properties...")
	print("  - Max Health: %d (expected 30)" % rabbit.max_health)
	print("  - Damage: %d (expected 8)" % rabbit.damage)
	print("  - Speed: %.1f (expected 4.5)" % rabbit.move_speed)
	print("  - Attack Range: %.1f (expected 1.5)" % rabbit.attack_range)
	
	# Test 4: Check if visual was created
	print("\nTest 4: Checking visual geometry...")
	var visual = rabbit.get_node_or_null("Visual")
	if visual:
		print("✅ Visual node found!")
		print("  - Visual children: %d" % visual.get_child_count())
	else:
		print("❌ No Visual node found")
	
	# Test 5: Check collision
	print("\nTest 5: Checking collision setup...")
	print("  - Collision Layer: %d (expected 256 = Layer 9)" % rabbit.collision_layer)
	print("  - Collision Mask: %d (expected 1 = Layer 1)" % rabbit.collision_mask)
	print("  - In 'enemies' group: %s" % rabbit.is_in_group("enemies"))
	
	print("\n" + "=".repeat(50))
	print("DEBUG TEST COMPLETE")
	print("=".repeat(50) + "\n")
	
	# Don't auto-quit so you can see the rabbit in the scene
	print("Scene will stay open - press F8 to stop")
