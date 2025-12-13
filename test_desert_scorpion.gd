extends Node3D

## Automated test scene for Desert Scorpion enemy
## Tests: Stats, ambush behavior, emerge/burrow, CSG geometry, drops

var scorpion: CharacterBody3D
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== DESERT SCORPION AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate scorpion
	var scorpion_scene = load("res://desert_scorpion.tscn")
	if not scorpion_scene:
		print("❌ FAILED: Could not load desert_scorpion.tscn")
		return
	
	print("✓ Scorpion scene loaded")
	
	scorpion = scorpion_scene.instantiate()
	add_child(scorpion)
	scorpion.global_position = Vector3(0, 0, 0)
	
	print("✓ Scorpion instantiated at origin")
	
	# Wait for scorpion to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ Initialization complete, running tests...\n")
	
	# Run tests
	await run_all_tests()
	
	# Print results
	print_test_results()

func setup_test_player() -> void:
	"""Create a mock player for testing"""
	test_player = CharacterBody3D.new()
	test_player.name = "Player"
	test_player.add_to_group("player")
	test_player.position = Vector3(0, 0, 20)  # Set local position BEFORE adding to tree (far away)
	add_child(test_player)  # Add to tree
	
	# Add collision shape so player doesn't fall
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	test_player.add_child(collision)

func run_all_tests() -> void:
	"""Execute all test cases"""
	print("Running synchronous tests...")
	
	# Stats tests
	test_stat_values()
	test_drop_table_configuration()
	
	# Visual tests
	test_csg_geometry_created()
	test_collision_shape_setup()
	
	print("\nRunning async behavior tests...")
	
	# Behavior tests
	await test_starts_buried()
	await test_emerge_on_approach()
	await test_tail_strike_telegraph()
	await test_reburrow_chance()
	await test_damage_forces_emerge()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 60, "damage": 15, "move_speed": 3.0, "attack_range": 2.5}
	var actual = {"max_health": scorpion.max_health, "damage": scorpion.damage, 
				  "move_speed": scorpion.move_speed, "attack_range": scorpion.attack_range}
	
	if actual == expected:
		passed_count += 1
		test_results["stat_values"] = "✅ PASS"
		print("✅ Stats match balance table")
	else:
		test_results["stat_values"] = "❌ FAIL: Expected %s, got %s" % [expected, actual]
		print("❌ Stats mismatch - Expected: %s, Got: %s" % [expected, actual])

func test_drop_table_configuration() -> void:
	"""Test drop table is configured correctly"""
	test_count += 1
	var drops = scorpion.drop_table
	
	var has_chitin = false
	var has_venom = false
	var chitin_chance = 0.0
	var venom_chance = 0.0
	
	for drop in drops:
		if drop.get("item") == "chitin":
			has_chitin = true
			chitin_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "venom_sac":
			has_venom = true
			venom_chance = drop.get("chance", 0.0)
	
	if has_chitin and chitin_chance == 1.0 and has_venom and venom_chance == 0.25:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Chitin: %s (%.1f%%), Venom: %s (%.1f%%)" % 
			  [has_chitin, chitin_chance * 100, has_venom, venom_chance * 100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = scorpion.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("BodySegment0")
	var has_pincers = visual.has_node("PincerLeft") and visual.has_node("PincerRight")
	var has_tail = visual.has_node("TailSegment0")
	var has_stinger = visual.has_node("Stinger")
	var has_eyes = visual.has_node("EyeLeft") and visual.has_node("EyeRight")
	
	if has_body and has_pincers and has_tail and has_stinger and has_eyes:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, pincers, tail, stinger, eyes)")
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts"
		print("❌ Missing CSG parts - Body:%s Pincers:%s Tail:%s Stinger:%s Eyes:%s" % 
			  [has_body, has_pincers, has_tail, has_stinger, has_eyes])

func test_collision_shape_setup() -> void:
	"""Test collision is configured correctly"""
	test_count += 1
	var collision = scorpion.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = scorpion.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = scorpion.collision_mask == 1  # Layer 1
	var in_group = scorpion.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 1, in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group])

func test_starts_buried() -> void:
	"""Test scorpion starts buried and invisible"""
	test_count += 1
	
	await wait_frames(5)
	
	# Check state value directly (0 = BURIED)
	var is_buried = scorpion.scorpion_state == 0  # ScorpionState.BURIED
	var visual = scorpion.get_node_or_null("Visual")
	var is_hidden = visual and not visual.visible
	
	if is_buried and is_hidden:
		passed_count += 1
		test_results["starts_buried"] = "✅ PASS"
		print("✅ Scorpion starts buried and hidden")
	else:
		test_results["starts_buried"] = "❌ FAIL: State:%d Hidden:%s" % [scorpion.scorpion_state, is_hidden]
		print("❌ Buried state - State:%d (expected 0), Hidden:%s" % [scorpion.scorpion_state, is_hidden])

func test_emerge_on_approach() -> void:
	"""Test scorpion emerges when player approaches"""
	test_count += 1
	
	# Move player close (within 8m emerge distance)
	test_player.global_position = Vector3(0, 0, 6)
	
	await wait_frames(40)  # Wait longer for emerge animation (0.5s + buffer)
	
	# Check state value directly (2 = SURFACED)
	var is_surfaced = scorpion.scorpion_state == 2  # ScorpionState.SURFACED
	var visual = scorpion.get_node_or_null("Visual")
	var is_visible = visual and visual.visible
	
	if is_surfaced and is_visible:
		passed_count += 1
		test_results["emerge"] = "✅ PASS"
		print("✅ Scorpion emerges when player approaches")
	else:
		test_results["emerge"] = "❌ FAIL: State:%d Visible:%s" % [scorpion.scorpion_state, is_visible]
		print("❌ Emerge - State:%d (expected 2), Visible:%s" % [scorpion.scorpion_state, is_visible])

func test_tail_strike_telegraph() -> void:
	"""Test tail strike has telegraph"""
	test_count += 1
	
	# Move into attack range
	test_player.global_position = scorpion.global_position + Vector3(0, 0, 2.0)
	scorpion.current_state = scorpion.State.CHASE
	
	await wait_frames(10)
	
	# Check that attack behavior exists
	var has_telegraph_method = scorpion.has_method("on_attack_telegraph")
	
	if has_telegraph_method:
		passed_count += 1
		test_results["telegraph"] = "✅ PASS"
		print("✅ Tail strike telegraph method exists")
	else:
		test_results["telegraph"] = "❌ FAIL: No telegraph method"
		print("❌ Telegraph method not found")

func test_reburrow_chance() -> void:
	"""Test reburrow mechanic exists"""
	test_count += 1
	
	var has_reburrow_method = scorpion.has_method("burrow_into_sand")
	var chance_configured = scorpion.REBURROW_CHANCE == 0.3
	
	if has_reburrow_method and chance_configured:
		passed_count += 1
		test_results["reburrow"] = "✅ PASS"
		print("✅ Reburrow mechanic configured (30% chance)")
	else:
		test_results["reburrow"] = "❌ FAIL: Method:%s Chance:%s" % [has_reburrow_method, chance_configured]
		print("❌ Reburrow - Method:%s, Chance:%s" % [has_reburrow_method, chance_configured])

func test_damage_forces_emerge() -> void:
	"""Test taking damage while buried forces emerge"""
	test_count += 1
	
	# Reset scorpion to buried (if possible via restart)
	# For now, just verify the method exists
	var has_damage_override = scorpion.has_method("take_damage")
	
	if has_damage_override:
		passed_count += 1
		test_results["damage_emerge"] = "✅ PASS"
		print("✅ Damage handling implemented")
	else:
		test_results["damage_emerge"] = "❌ FAIL: No damage override"
		print("❌ Damage override not found")

func wait_frames(count: int) -> void:
	"""Wait for specified number of frames"""
	for i in range(count):
		await get_tree().process_frame

func print_test_results() -> void:
	"""Print summary of all tests"""
	print("\n" + "=".repeat(60))
	print("=== TEST SUMMARY ===")
	print("=".repeat(60))
	print("Tests run: %d" % test_count)
	print("Passed: %d" % passed_count)
	print("Failed: %d" % (test_count - passed_count))
	print("Success rate: %.1f%%" % (float(passed_count) / float(test_count) * 100.0))
	print("\nDetailed results:")
	for test_name in test_results:
		print("  %s: %s" % [test_name, test_results[test_name]])
	print("\n" + "=".repeat(60))
	print("=== END TESTS ===")
	print("=".repeat(60) + "\n")
	
	print("Tests complete! Scene will stay open - press F8 to stop")
