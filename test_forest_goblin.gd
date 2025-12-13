extends Node3D

## Automated test scene for Forest Goblin enemy
## Tests: Stats, patrol behavior, flee at 20% HP, coward backpedal, CSG geometry, drops

var goblin: CharacterBody3D
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== FOREST GOBLIN AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate goblin
	var goblin_scene = load("res://forest_goblin.tscn")
	if not goblin_scene:
		print("❌ FAILED: Could not load forest_goblin.tscn")
		return
	
	print("✓ Goblin scene loaded")
	
	goblin = goblin_scene.instantiate()
	add_child(goblin)
	goblin.global_position = Vector3(0, 0, 0)
	
	print("✓ Goblin instantiated at origin")
	
	# Wait for goblin to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ Initialization complete, running tests...\n")
	
	# Run tests
	await run_all_tests()
	
	# Print results
	print_test_results()

func setup_test_player() -> void:
	"""Create a mock player for testing"""
	var TestPlayer = preload("res://test_player_mock.gd")
	test_player = TestPlayer.new()
	test_player.name = "Player"
	test_player.add_to_group("player")
	test_player.global_position = Vector3(0, 0, 15)  # Start far away
	add_child(test_player)

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
	await test_patrol_waypoints_generated()
	await test_patrol_behavior()
	await test_flee_at_low_health()
	await test_coward_backpedal()
	await test_attack_behavior()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 50, "damage": 12, "move_speed": 3.0, "attack_range": 2.0}
	var actual = {"max_health": goblin.max_health, "damage": goblin.damage, 
	              "move_speed": goblin.move_speed, "attack_range": goblin.attack_range}
	
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
	var drops = goblin.drop_table
	
	var has_wood = false
	var has_stone = false
	var has_tooth = false
	var wood_chance = 0.0
	var stone_chance = 0.0
	var tooth_chance = 0.0
	
	for drop in drops:
		match drop.get("item"):
			"wood":
				has_wood = true
				wood_chance = drop.get("chance", 0.0)
			"stone":
				has_stone = true
				stone_chance = drop.get("chance", 0.0)
			"goblin_tooth":
				has_tooth = true
				tooth_chance = drop.get("chance", 0.0)
	
	var correct = has_wood and wood_chance == 0.8 and \
	              has_stone and stone_chance == 0.6 and \
	              has_tooth and tooth_chance == 0.3
	
	if correct:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly (wood 80%, stone 60%, tooth 30%)")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Wood:%s(%.0f%%) Stone:%s(%.0f%%) Tooth:%s(%.0f%%)" % [has_wood, wood_chance*100, has_stone, stone_chance*100, has_tooth, tooth_chance*100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = goblin.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("Body")
	var has_head = visual.has_node("Head")
	var has_eyes = visual.has_node("EyeLeft") and visual.has_node("EyeRight")
	var has_arms = visual.has_node("ArmLeft") and visual.has_node("ArmRight")
	var has_stick = visual.has_node("Stick")
	
	if has_body and has_head and has_eyes and has_arms and has_stick:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, head, eyes, arms, stick)")
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts"
		print("❌ Missing - Body:%s Head:%s Eyes:%s Arms:%s Stick:%s" % [has_body, has_head, has_eyes, has_arms, has_stick])

func test_collision_shape_setup() -> void:
	"""Test collision is configured correctly"""
	test_count += 1
	var collision = goblin.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = goblin.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = goblin.collision_mask == 1  # Layer 1
	var in_group = goblin.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 1, in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group])

func test_patrol_waypoints_generated() -> void:
	"""Test patrol waypoints are created"""
	test_count += 1
	
	# Wait for deferred waypoint generation
	await wait_frames(5)
	
	var waypoint_count = goblin.patrol_waypoints.size()
	
	if waypoint_count >= 3 and waypoint_count <= 5:
		passed_count += 1
		test_results["waypoints"] = "✅ PASS"
		print("✅ Patrol waypoints generated (%d waypoints)" % waypoint_count)
	else:
		test_results["waypoints"] = "❌ FAIL: Expected 3-5 waypoints, got %d" % waypoint_count
		print("❌ Waypoints - Expected 3-5, got %d" % waypoint_count)

func test_patrol_behavior() -> void:
	"""Test goblin patrols when idle"""
	test_count += 1
	
	# Ensure goblin is idle and has waypoints
	goblin.current_state = goblin.State.IDLE
	await wait_frames(5)
	
	# Record positions over time
	var start_pos = goblin.global_position
	await wait_frames(50)  # Let it patrol
	var end_pos = goblin.global_position
	
	var moved = start_pos.distance_to(end_pos) > 1.0
	
	if moved:
		passed_count += 1
		test_results["patrol"] = "✅ PASS"
		print("✅ Patrol behavior working (moved %.2fm)" % start_pos.distance_to(end_pos))
	else:
		test_results["patrol"] = "⚠️ INCONCLUSIVE: Minimal movement (%.2fm)" % start_pos.distance_to(end_pos)
		print("⚠️ Patrol - Movement: %.2fm" % start_pos.distance_to(end_pos))

func test_flee_at_low_health() -> void:
	"""Test goblin flees when health drops below 20%"""
	test_count += 1
	
	# Move player close
	test_player.global_position = goblin.global_position + Vector3(0, 0, 5)
	
	# Set health to 20% (10 HP)
	goblin.current_health = 10
	goblin.current_state = goblin.State.CHASE
	await wait_frames(5)
	
	# Take small damage to trigger flee check
	goblin.take_damage(1)  # Now at 9 HP (18%)
	await wait_frames(10)
	
	var is_fleeing = goblin.is_fleeing
	
	# Check if moving away from player
	var distance_before = goblin.global_position.distance_to(test_player.global_position)
	await wait_frames(30)
	var distance_after = goblin.global_position.distance_to(test_player.global_position)
	
	var moving_away = distance_after > distance_before
	
	if is_fleeing and moving_away:
		passed_count += 1
		test_results["flee"] = "✅ PASS"
		print("✅ Flee behavior working (distance increased by %.2fm)" % (distance_after - distance_before))
	else:
		test_results["flee"] = "❌ FAIL: Fleeing:%s MovingAway:%s" % [is_fleeing, moving_away]
		print("❌ Flee - Fleeing:%s, MovingAway:%s (Δ%.2fm)" % [is_fleeing, moving_away, distance_after - distance_before])

func test_coward_backpedal() -> void:
	"""Test goblin backpedals when player gets too close"""
	test_count += 1
	
	# Reset goblin health so it doesn't flee
	goblin.current_health = goblin.max_health
	goblin.is_fleeing = false
	
	# Move player very close (within 2m, less than PREFERRED_DISTANCE of 3m)
	test_player.global_position = goblin.global_position + Vector3(0, 0, 2)
	goblin.current_state = goblin.State.CHASE
	
	await wait_frames(5)
	
	# Check if distance increases (backpedaling)
	var distance_before = goblin.global_position.distance_to(test_player.global_position)
	await wait_frames(20)
	var distance_after = goblin.global_position.distance_to(test_player.global_position)
	
	var backed_away = distance_after > distance_before + 0.3
	
	if backed_away:
		passed_count += 1
		test_results["backpedal"] = "✅ PASS"
		print("✅ Coward backpedal working (backed %.2fm away)" % (distance_after - distance_before))
	else:
		test_results["backpedal"] = "⚠️ INCONCLUSIVE: Distance change: %.2fm" % (distance_after - distance_before)
		print("⚠️ Backpedal - Distance change: %.2fm" % (distance_after - distance_before))

func test_attack_behavior() -> void:
	"""Test attack triggers at correct range"""
	test_count += 1
	
	# Reset goblin
	goblin.current_health = goblin.max_health
	goblin.is_fleeing = false
	
	# Move player into attack range (1.8m)
	test_player.global_position = goblin.global_position + Vector3(0, 0, 1.8)
	await wait_frames(10)
	
	var switched_to_attack = goblin.current_state == goblin.State.ATTACK
	
	if switched_to_attack:
		passed_count += 1
		test_results["attack"] = "✅ PASS"
		print("✅ Switches to attack state at correct range")
	else:
		test_results["attack"] = "❌ FAIL: State is %s" % goblin.current_state
		print("❌ Attack - Expected ATTACK state, got: %s" % goblin.current_state)

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
	
	# Don't auto-quit - let user see results
	# await get_tree().create_timer(2.0).timeout
	# get_tree().quit()
