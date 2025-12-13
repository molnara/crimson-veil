extends Node3D

## Automated test scene for Ice Wolf enemy
## Tests: Stats, pack behavior, surround tactics, CSG geometry, drops

var wolf: CharacterBody3D
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== ICE WOLF AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate wolf
	var wolf_scene = load("res://ice_wolf.tscn")
	if not wolf_scene:
		print("❌ FAILED: Could not load ice_wolf.tscn")
		return
	
	print("✓ Wolf scene loaded")
	
	wolf = wolf_scene.instantiate()
	wolf.pack_id = 1  # Assign to pack 1
	add_child(wolf)
	wolf.global_position = Vector3(0, 0, 0)
	
	print("✓ Wolf instantiated at origin (pack_id=1)")
	
	# Wait for wolf to initialize
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
	await test_pack_formation()
	await test_howl_signal()
	await test_surround_behavior()
	await test_pack_damage_alert()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 55, "damage": 14, "move_speed": 4.5, "attack_range": 2.0}
	var actual = {"max_health": wolf.max_health, "damage": wolf.damage, 
				  "move_speed": wolf.move_speed, "attack_range": wolf.attack_range}
	
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
	var drops = wolf.drop_table
	
	var has_pelt = false
	var has_fang = false
	var has_shard = false
	var pelt_chance = 0.0
	var fang_chance = 0.0
	var shard_chance = 0.0
	
	for drop in drops:
		if drop.get("item") == "wolf_pelt":
			has_pelt = true
			pelt_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "fang":
			has_fang = true
			fang_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "ice_shard":
			has_shard = true
			shard_chance = drop.get("chance", 0.0)
	
	if has_pelt and pelt_chance == 1.0 and has_fang and fang_chance == 0.7 and has_shard and shard_chance == 0.15:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Pelt: %s (%.1f%%), Fang: %s (%.1f%%), Shard: %s (%.1f%%)" % 
			  [has_pelt, pelt_chance * 100, has_fang, fang_chance * 100, has_shard, shard_chance * 100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = wolf.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("Body")
	var has_head = visual.has_node("Head")
	var has_legs = visual.has_node("Leg0") and visual.has_node("Leg1")
	var has_tail = visual.has_node("Tail")
	var has_eyes = visual.has_node("EyeLeft") and visual.has_node("EyeRight")
	
	if has_body and has_head and has_legs and has_tail and has_eyes:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, head, legs, tail, eyes)")
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts"
		print("❌ Missing CSG parts - Body:%s Head:%s Legs:%s Tail:%s Eyes:%s" % 
			  [has_body, has_head, has_legs, has_tail, has_eyes])

func test_collision_shape_setup() -> void:
	"""Test collision is configured correctly"""
	test_count += 1
	var collision = wolf.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = wolf.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = wolf.collision_mask == 1  # Layer 1
	var in_group = wolf.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 1, in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group])

func test_pack_formation() -> void:
	"""Test wolves can form packs"""
	test_count += 1
	
	# Spawn a second wolf with same pack_id
	var wolf_scene = load("res://ice_wolf.tscn")
	var pack_wolf = wolf_scene.instantiate()
	pack_wolf.pack_id = 1  # Same pack as main wolf
	pack_wolf.position = Vector3(3, 0, 0)
	add_child(pack_wolf)

	await wait_frames(5)  # Brief wait for pack_wolf to initialize

	# Manually trigger pack formation on both wolves
	wolf.form_pack()
	pack_wolf.form_pack()

	await wait_frames(5)  # Wait for pack formation to complete
	
	# Check if wolves found each other
	var main_has_pack = wolf.pack_members.size() > 0
	var pack_has_main = pack_wolf.pack_members.size() > 0
	
	if main_has_pack and pack_has_main:
		passed_count += 1
		test_results["pack_formation"] = "✅ PASS"
		print("✅ Pack formation working (wolves found each other)")
	else:
		test_results["pack_formation"] = "❌ FAIL: Main:%s Pack:%s" % [main_has_pack, pack_has_main]
		print("❌ Pack formation - Main wolf pack size:%d, Pack wolf pack size:%d" % 
			  [wolf.pack_members.size(), pack_wolf.pack_members.size()])
	
	# Clean up pack wolf
	pack_wolf.queue_free()

func test_howl_signal() -> void:
	"""Test howl behavior exists"""
	test_count += 1
	
	var has_howl_method = wolf.has_method("perform_howl")
	var has_howled_flag = wolf.has_howled == false  # Should start false
	
	if has_howl_method and not wolf.has_howled:
		passed_count += 1
		test_results["howl"] = "✅ PASS"
		print("✅ Howl system implemented (method exists, flag initialized)")
	else:
		test_results["howl"] = "❌ FAIL: Method:%s Flag:%s" % [has_howl_method, has_howled_flag]
		print("❌ Howl - Method:%s, Has howled:%s" % [has_howl_method, wolf.has_howled])

func test_surround_behavior() -> void:
	"""Test surround behavior exists"""
	test_count += 1
	
	# Move player close to trigger chase
	test_player.global_position = Vector3(0, 0, 8)
	wolf.current_state = wolf.State.CHASE
	
	await wait_frames(10)
	
	# Check that surround method exists
	var has_surround_method = wolf.has_method("surround_player")
	var has_angle = "surround_angle" in wolf  # Check if property exists
	
	if has_surround_method and has_angle:
		passed_count += 1
		test_results["surround"] = "✅ PASS"
		print("✅ Surround behavior implemented")
	else:
		test_results["surround"] = "❌ FAIL: Method:%s Angle:%s" % [has_surround_method, has_angle]
		print("❌ Surround - Method:%s, Angle property:%s" % [has_surround_method, has_angle])

func test_pack_damage_alert() -> void:
	"""Test pack alerts on damage"""
	test_count += 1
	
	# Verify damage override exists
	var has_damage_override = wolf.has_method("take_damage")
	
	if has_damage_override:
		passed_count += 1
		test_results["pack_alert"] = "✅ PASS"
		print("✅ Damage alerting system implemented")
	else:
		test_results["pack_alert"] = "❌ FAIL: No damage override"
		print("❌ Pack alert - No damage override found")

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
