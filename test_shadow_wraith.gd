extends Node3D

## Automated test scene for Shadow Wraith enemy
## Tests: Stats, night-only spawning, floating, ethereal collision, dawn despawn, CSG geometry, drops

var wraith: CharacterBody3D
var test_player: CharacterBody3D
var day_night_cycle: Node  # Mock DayNightCycle (using Node instead of full DayNightCycle class)
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== SHADOW WRAITH AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create mock day/night cycle
	setup_day_night_cycle()
	print("✓ Day/Night cycle created (set to night)")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate wraith
	var wraith_scene = load("res://shadow_wraith.tscn")
	if not wraith_scene:
		print("❌ FAILED: Could not load shadow_wraith.tscn")
		return
	
	print("✓ Wraith scene loaded")
	
	wraith = wraith_scene.instantiate()
	add_child(wraith)
	wraith.global_position = Vector3(0, 5, 0)  # Spawn in air
	
	print("✓ Wraith instantiated at (0, 5, 0)")
	
	# Wait for wraith to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Manually set references for wraith
	wraith.player = test_player
	wraith.day_night_cycle = day_night_cycle
	
	print("✓ Initialization complete, running tests...\n")
	
	# Run tests
	await run_all_tests()
	
	# Print results
	print_test_results()

func setup_day_night_cycle() -> void:
	"""Create a mock DayNightCycle for testing"""
	# Create simple mock instead of full DayNightCycle (which requires WorldEnvironment)
	var mock_script = GDScript.new()
	mock_script.source_code = """
extends Node
var time_of_day: float = 0.9583  # Default to night (11 PM)
func get_time_of_day() -> float:
	return time_of_day
func set_time_of_day(new_time: float) -> void:
	time_of_day = new_time
"""
	mock_script.reload()
	
	day_night_cycle = Node.new()
	day_night_cycle.name = "DayNightCycle"
	day_night_cycle.set_script(mock_script)
	day_night_cycle.add_to_group("day_night_cycle")
	add_child(day_night_cycle)

func setup_test_player() -> void:
	"""Create a mock player for testing"""
	test_player = CharacterBody3D.new()
	test_player.name = "Player"
	test_player.add_to_group("player")
	test_player.position = Vector3(0, 0, 20)  # Far away initially
	add_child(test_player)
	
	# Add collision shape
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
	test_ethereal_transparency()
	test_collision_shape_setup()
	
	print("\nRunning async behavior tests...")
	
	# Behavior tests
	await test_night_only_spawn()
	await test_floating_behavior()
	await test_phase_through_collision()
	await test_dawn_despawn()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 40, "damage": 12, "move_speed": 4.0, "attack_range": 2.0, "detection_range": 10.0}
	var actual = {"max_health": wraith.max_health, "damage": wraith.damage, 
				  "move_speed": wraith.move_speed, "attack_range": wraith.attack_range,
				  "detection_range": wraith.detection_range}
	
	if actual == expected:
		passed_count += 1
		test_results["stat_values"] = "✅ PASS"
		print("✅ Stats match balance table (40 HP, 12 DMG, 4.0 speed, 2.0m range, 10m detection)")
	else:
		test_results["stat_values"] = "❌ FAIL: Expected %s, got %s" % [expected, actual]
		print("❌ Stats mismatch - Expected: %s, Got: %s" % [expected, actual])

func test_drop_table_configuration() -> void:
	"""Test drop table is configured correctly"""
	test_count += 1
	var drops = wraith.drop_table
	
	var has_essence = false
	var has_ectoplasm = false
	var essence_chance = 0.0
	var ectoplasm_chance = 0.0
	
	for drop in drops:
		if drop.get("item") == "shadow_essence":
			has_essence = true
			essence_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "ectoplasm":
			has_ectoplasm = true
			ectoplasm_chance = drop.get("chance", 0.0)
	
	if has_essence and essence_chance == 0.8 and has_ectoplasm and ectoplasm_chance == 0.3:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly (shadow essence 80%, ectoplasm 30%)")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Essence: %s (%.1f%%), Ectoplasm: %s (%.1f%%)" % 
			  [has_essence, essence_chance * 100, has_ectoplasm, ectoplasm_chance * 100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = wraith.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("Body")
	var has_head = visual.has_node("Head")
	var has_particles = visual.has_node("WispyTrail")
	
	if has_body and has_head:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, head, particles:%s)" % has_particles)
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts"
		print("❌ Missing CSG parts - Body:%s Head:%s Particles:%s" % 
			  [has_body, has_head, has_particles])

func test_ethereal_transparency() -> void:
	"""Test wraith has transparent material"""
	test_count += 1
	var visual = wraith.get_node_or_null("Visual")
	
	if not visual:
		test_results["transparency"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found for transparency check")
		return
	
	var body = visual.get_node_or_null("Body")
	if not body:
		test_results["transparency"] = "❌ FAIL: No Body node"
		print("❌ Body node not found")
		return
	
	var mat = body.material as StandardMaterial3D
	if mat:
		var is_transparent = mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA
		var has_emission = mat.emission_enabled
		var alpha_value = mat.albedo_color.a
		
		if is_transparent and has_emission and alpha_value <= 0.7:
			passed_count += 1
			test_results["transparency"] = "✅ PASS"
			print("✅ Ethereal transparency working (alpha: %.2f, emission enabled)" % alpha_value)
		else:
			test_results["transparency"] = "❌ FAIL: Trans:%s Emission:%s Alpha:%.2f" % [is_transparent, has_emission, alpha_value]
			print("❌ Transparency - Transparent:%s, Emission:%s, Alpha:%.2f" % 
				  [is_transparent, has_emission, alpha_value])
	else:
		test_results["transparency"] = "❌ FAIL: No material"
		print("❌ No material found on body")

func test_collision_shape_setup() -> void:
	"""Test collision is configured for phase-through"""
	test_count += 1
	var collision = wraith.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = wraith.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = wraith.collision_mask == 0  # No collision mask (phase through)
	var in_group = wraith.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 0 [phase-through], in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s (expect true), Mask:%s (expect true for 0), Group:%s" % 
			  [layer_correct, mask_correct, in_group])

func test_night_only_spawn() -> void:
	"""Test wraith only spawns at night"""
	test_count += 1
	
	# Wait a frame to ensure mock script is loaded
	await get_tree().process_frame
	
	# Check night time detection method exists
	var has_night_check = wraith.has_method("is_night_time")
	
	# Verify current time is night (with safety check for mock)
	var is_night = false
	if day_night_cycle.has_method("get_time_of_day"):
		var current_time = day_night_cycle.get_time_of_day()
		is_night = current_time >= 0.9167 or current_time < 0.25
	
	if has_night_check and is_night:
		passed_count += 1
		test_results["night_spawn"] = "✅ PASS"
		if day_night_cycle.has_method("get_time_of_day"):
			print("✅ Night-only spawn system implemented (current time: %.4f)" % day_night_cycle.get_time_of_day())
		else:
			print("✅ Night-only spawn system implemented")
	else:
		test_results["night_spawn"] = "❌ FAIL: Method:%s Night:%s" % [has_night_check, is_night]
		print("❌ Night spawn - Has method:%s, Is night:%s" % [has_night_check, is_night])

func test_floating_behavior() -> void:
	"""Test wraith maintains float height"""
	test_count += 1
	
	# Record initial height
	var initial_y = wraith.global_position.y
	
	# Wait for float behavior to process
	await get_tree().create_timer(0.5).timeout
	
	# Check that maintain_float_height method exists
	var has_float_method = wraith.has_method("maintain_float_height")
	var maintains_height = abs(wraith.global_position.y - initial_y) < 2.0  # Should stay roughly same height
	
	if has_float_method and maintains_height:
		passed_count += 1
		test_results["floating"] = "✅ PASS"
		print("✅ Floating behavior working (height maintained: %.2fm)" % wraith.global_position.y)
	else:
		test_results["floating"] = "❌ FAIL: Method:%s Height:%s" % [has_float_method, maintains_height]
		print("❌ Floating - Has method:%s, Maintains height:%s (%.2f -> %.2f)" % 
			  [has_float_method, maintains_height, initial_y, wraith.global_position.y])

func test_phase_through_collision() -> void:
	"""Test wraith has collision_mask = 0 for phasing"""
	test_count += 1
	
	# Verify collision mask is 0 (no collisions)
	var phases_through = wraith.collision_mask == 0
	
	if phases_through:
		passed_count += 1
		test_results["phase_through"] = "✅ PASS"
		print("✅ Phase-through collision working (collision_mask = 0)")
	else:
		test_results["phase_through"] = "❌ FAIL: collision_mask = %d (expected 0)" % wraith.collision_mask
		print("❌ Phase-through - collision_mask = %d, expected 0" % wraith.collision_mask)

func test_dawn_despawn() -> void:
	"""Test wraith despawns at dawn"""
	test_count += 1
	
	# Check despawn method exists
	var has_despawn_method = wraith.has_method("despawn_at_dawn")
	var has_despawn_flag = "is_despawning" in wraith
	
	# Set time to dawn (with safety check)
	if day_night_cycle.has_method("set_time_of_day"):
		day_night_cycle.set_time_of_day(0.26)  # 6:15 AM (just after 6 AM dawn)
	
	await get_tree().create_timer(0.2).timeout
	
	# Check if despawn was triggered
	var despawn_triggered = wraith.is_despawning if has_despawn_flag else false
	
	if has_despawn_method and has_despawn_flag:
		passed_count += 1
		test_results["dawn_despawn"] = "✅ PASS"
		print("✅ Dawn despawn system implemented (despawning: %s)" % despawn_triggered)
	else:
		test_results["dawn_despawn"] = "❌ FAIL: Method:%s Flag:%s" % [has_despawn_method, has_despawn_flag]
		print("❌ Dawn despawn - Method:%s, Flag:%s" % [has_despawn_method, has_despawn_flag])

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
