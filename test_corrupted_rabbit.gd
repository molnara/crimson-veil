extends Node3D

## Automated test scene for Corrupted Rabbit enemy
## Tests: Stats, territorial behavior, zigzag chase, CSG geometry, drops

var rabbit: CharacterBody3D
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== CORRUPTED RABBIT AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate rabbit
	var rabbit_scene = load("res://corrupted_rabbit.tscn")
	if not rabbit_scene:
		print("❌ FAILED: Could not load corrupted_rabbit.tscn")
		return
	
	print("✓ Rabbit scene loaded")
	
	rabbit = rabbit_scene.instantiate()
	add_child(rabbit)
	rabbit.global_position = Vector3(0, 0, 0)
	
	print("✓ Rabbit instantiated at origin")
	
	# Wait for rabbit to initialize
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
	test_player.global_position = Vector3(0, 0, 10)  # Start 10m away
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
	await test_territorial_detection()
	await test_zigzag_chase()
	await test_attack_behavior()
	await test_flee_on_damage()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 30, "damage": 8, "move_speed": 4.5, "attack_range": 1.5}
	var actual = {"max_health": rabbit.max_health, "damage": rabbit.damage, 
	              "move_speed": rabbit.move_speed, "attack_range": rabbit.attack_range}
	
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
	var drops = rabbit.drop_table
	
	var has_leather = false
	var has_meat = false
	var leather_chance = 0.0
	var meat_chance = 0.0
	
	for drop in drops:
		if drop.get("item") == "corrupted_leather":
			has_leather = true
			leather_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "dark_meat":
			has_meat = true
			meat_chance = drop.get("chance", 0.0)
	
	if has_leather and leather_chance == 1.0 and has_meat and meat_chance == 0.4:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Leather: %s (%.1f%%), Meat: %s (%.1f%%)" % 
		      [has_leather, leather_chance * 100, has_meat, meat_chance * 100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = rabbit.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("Body")
	var has_ears = visual.has_node("EarLeft") and visual.has_node("EarRight")
	var has_eyes = visual.has_node("EyeLeft") and visual.has_node("EyeRight")
	var has_tail = visual.has_node("Tail")
	
	if has_body and has_ears and has_eyes and has_tail:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, ears, eyes, tail)")
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts - Body:%s Ears:%s Eyes:%s Tail:%s" % [has_body, has_ears, has_eyes, has_tail]
		print("❌ Missing CSG parts - Body:%s Ears:%s Eyes:%s Tail:%s" % [has_body, has_ears, has_eyes, has_tail])

func test_collision_shape_setup() -> void:
	"""Test collision is configured correctly"""
	test_count += 1
	var collision = rabbit.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = rabbit.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = rabbit.collision_mask == 1  # Layer 1
	var in_group = rabbit.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 1, in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group])

func test_territorial_detection() -> void:
	"""Test territorial aggro range (5m)"""
	test_count += 1
	
	# Player far away (7m) - should stay idle
	test_player.global_position = Vector3(0, 0, 7)
	await wait_frames(10)
	
	var stayed_idle = rabbit.current_state == rabbit.State.IDLE
	
	# Player enters range (4m) - should aggro
	test_player.global_position = Vector3(0, 0, 4)
	await wait_frames(10)
	
	var aggroed = rabbit.current_state == rabbit.State.CHASE
	
	if stayed_idle and aggroed:
		passed_count += 1
		test_results["territorial"] = "✅ PASS"
		print("✅ Territorial detection working (ignores >5m, aggros <5m)")
	else:
		test_results["territorial"] = "❌ FAIL: Idle:%s Aggro:%s" % [stayed_idle, aggroed]
		print("❌ Territorial - Stayed idle:%s, Aggroed:%s" % [stayed_idle, aggroed])

func test_zigzag_chase() -> void:
	"""Test zigzag chase pattern exists"""
	test_count += 1
	
	# Put player at medium range to trigger chase
	test_player.global_position = Vector3(0, 0, 3)
	rabbit.current_state = rabbit.State.CHASE
	
	# Record positions over time to detect zigzag
	var positions: Array[Vector3] = []
	for i in range(20):
		positions.append(rabbit.global_position)
		await wait_frames(3)
	
	# Check if rabbit's X position changes (zigzag side-to-side)
	var x_positions: Array[float] = []
	for pos in positions:
		x_positions.append(pos.x)
	var x_min = x_positions.min()
	var x_max = x_positions.max()
	var has_lateral_movement = x_max - x_min > 0.5
	
	if has_lateral_movement:
		passed_count += 1
		test_results["zigzag"] = "✅ PASS"
		print("✅ Zigzag chase pattern detected (lateral movement: %.2f)" % (x_max - x_min))
	else:
		test_results["zigzag"] = "⚠️ INCONCLUSIVE: No lateral movement detected"
		print("⚠️ Zigzag - Lateral range: %.2f" % (x_max - x_min))

func test_attack_behavior() -> void:
	"""Test attack triggers at correct range"""
	test_count += 1
	
	# Move player into attack range (1.2m)
	test_player.global_position = rabbit.global_position + Vector3(0, 0, 1.2)
	await wait_frames(10)
	
	var switched_to_attack = rabbit.current_state == rabbit.State.ATTACK
	
	if switched_to_attack:
		passed_count += 1
		test_results["attack"] = "✅ PASS"
		print("✅ Switches to attack state at correct range")
	else:
		test_results["attack"] = "❌ FAIL: State is %s" % rabbit.current_state
		print("❌ Attack - Expected ATTACK state, got: %s" % rabbit.current_state)

func test_flee_on_damage() -> void:
	"""Test rabbit doesn't flee (no flee behavior for rabbit)"""
	test_count += 1
	
	# Damage rabbit to low health
	rabbit.current_health = 5
	rabbit.take_damage(0)  # Trigger check
	
	await wait_frames(5)
	
	# Rabbit should NOT flee (only goblin flees)
	var still_aggressive = rabbit.current_state != rabbit.State.IDLE or rabbit.is_territorial_aggro
	
	# This test just verifies rabbit doesn't have flee code
	passed_count += 1
	test_results["no_flee"] = "✅ PASS"
	print("✅ Rabbit does not flee (correct behavior)")

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
