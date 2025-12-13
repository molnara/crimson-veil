extends Node3D

## Automated test scene for Stone Golem enemy
## Tests: Stats, ground slam attack, CSG geometry, drops, stone node patrol

var golem: CharacterBody3D
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== STONE GOLEM AUTOMATED TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Load and instantiate golem
	var golem_scene = load("res://stone_golem.tscn")
	if not golem_scene:
		print("❌ FAILED: Could not load stone_golem.tscn")
		return
	
	print("✓ Golem scene loaded")
	
	golem = golem_scene.instantiate()
	add_child(golem)
	golem.global_position = Vector3(0, 0, 0)
	
	print("✓ Golem instantiated at origin")
	
	# Wait for golem to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Manually set player reference for golem
	golem.player = test_player
	
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
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	test_player.add_child(collision)
	
	# Add take_damage method for testing - set script BEFORE adding to tree
	var player_script = GDScript.new()
	player_script.source_code = """
extends CharacterBody3D
var damage_taken: int = 0
func take_damage(amount: int) -> void:
	damage_taken += amount
"""
	player_script.reload()
	test_player.set_script(player_script)
	
	# Set position and add to tree
	test_player.position = Vector3(0, 0, 20)  # Far away initially
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
	await test_ground_slam_telegraph()
	await test_ground_slam_aoe()
	await test_stagger_behavior()
	await test_stone_patrol_setup()

func test_stat_values() -> void:
	"""Test that stats match balance table"""
	test_count += 1
	var expected = {"max_health": 100, "damage": 20, "move_speed": 1.5, "attack_range": 2.5, "detection_range": 10.0}
	var actual = {"max_health": golem.max_health, "damage": golem.damage, 
				  "move_speed": golem.move_speed, "attack_range": golem.attack_range,
				  "detection_range": golem.detection_range}
	
	if actual == expected:
		passed_count += 1
		test_results["stat_values"] = "✅ PASS"
		print("✅ Stats match balance table (100 HP, 20 DMG, 1.5 speed, 2.5m range, 10m detection)")
	else:
		test_results["stat_values"] = "❌ FAIL: Expected %s, got %s" % [expected, actual]
		print("❌ Stats mismatch - Expected: %s, Got: %s" % [expected, actual])

func test_drop_table_configuration() -> void:
	"""Test drop table is configured correctly"""
	test_count += 1
	var drops = golem.drop_table
	
	var has_stone = false
	var has_iron = false
	var has_core = false
	var stone_chance = 0.0
	var iron_chance = 0.0
	var core_chance = 0.0
	
	for drop in drops:
		if drop.get("item") == "stone":
			has_stone = true
			stone_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "iron_ore":
			has_iron = true
			iron_chance = drop.get("chance", 0.0)
		elif drop.get("item") == "stone_core":
			has_core = true
			core_chance = drop.get("chance", 0.0)
	
	if has_stone and stone_chance == 1.0 and has_iron and iron_chance == 0.6 and has_core and core_chance == 0.2:
		passed_count += 1
		test_results["drop_table"] = "✅ PASS"
		print("✅ Drop table configured correctly (stone 100%, iron ore 60%, stone core 20%)")
	else:
		test_results["drop_table"] = "❌ FAIL: Drop table incorrect"
		print("❌ Drop table - Stone: %s (%.1f%%), Iron: %s (%.1f%%), Core: %s (%.1f%%)" % 
			  [has_stone, stone_chance * 100, has_iron, iron_chance * 100, has_core, core_chance * 100])

func test_csg_geometry_created() -> void:
	"""Test CSG primitives are created"""
	test_count += 1
	var visual = golem.get_node_or_null("Visual")
	
	if not visual:
		test_results["csg_geometry"] = "❌ FAIL: No Visual node"
		print("❌ Visual node not found")
		return
	
	var has_body = visual.has_node("Body")
	var has_head = visual.has_node("Head")
	var has_arms = visual.has_node("ArmLeft") and visual.has_node("ArmRight")
	var has_legs = visual.has_node("LegLeft") and visual.has_node("LegRight")
	var has_eyes = visual.has_node("EyeLeft") and visual.has_node("EyeRight")
	
	if has_body and has_head and has_arms and has_legs and has_eyes:
		passed_count += 1
		test_results["csg_geometry"] = "✅ PASS"
		print("✅ CSG geometry created (body, head, arms, legs, eyes)")
	else:
		test_results["csg_geometry"] = "❌ FAIL: Missing parts"
		print("❌ Missing CSG parts - Body:%s Head:%s Arms:%s Legs:%s Eyes:%s" % 
			  [has_body, has_head, has_arms, has_legs, has_eyes])

func test_collision_shape_setup() -> void:
	"""Test collision is configured correctly"""
	test_count += 1
	var collision = golem.collision_shape
	
	if not collision:
		test_results["collision"] = "❌ FAIL: No collision shape"
		print("❌ Collision shape not found")
		return
	
	var layer_correct = golem.collision_layer == (1 << 8)  # Layer 9
	var mask_correct = golem.collision_mask == 1  # Layer 1
	var in_group = golem.is_in_group("enemies")
	
	if layer_correct and mask_correct and in_group:
		passed_count += 1
		test_results["collision"] = "✅ PASS"
		print("✅ Collision setup correct (Layer 9, Mask 1, in 'enemies' group)")
	else:
		test_results["collision"] = "❌ FAIL: Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group]
		print("❌ Collision - Layer:%s Mask:%s Group:%s" % [layer_correct, mask_correct, in_group])

func test_ground_slam_telegraph() -> void:
	"""Test ground slam telegraph exists and raises arms"""
	test_count += 1
	
	# Move player close to trigger attack
	test_player.global_position = Vector3(0, 0, 2)
	golem.current_state = golem.State.ATTACK
	
	# Trigger attack telegraph
	golem.start_ground_slam()
	
	await wait_frames(3)
	
	# Check that slam is in progress
	var has_slam_flag = golem.is_slamming
	var has_telegraph_method = golem.has_method("on_attack_telegraph")
	
	if has_slam_flag and has_telegraph_method:
		passed_count += 1
		test_results["ground_slam_telegraph"] = "✅ PASS"
		print("✅ Ground slam telegraph implemented")
	else:
		test_results["ground_slam_telegraph"] = "❌ FAIL: Slam:%s Method:%s" % [has_slam_flag, has_telegraph_method]
		print("❌ Ground slam - Slamming flag:%s, Telegraph method:%s" % [has_slam_flag, has_telegraph_method])

func test_ground_slam_aoe() -> void:
	"""Test ground slam deals AoE damage"""
	test_count += 1
	
	# Verify player has damage_taken property
	if not "damage_taken" in test_player:
		test_results["ground_slam_aoe"] = "❌ FAIL: Player script not initialized"
		print("❌ Ground slam AoE - Player damage_taken property not found")
		return
	
	# Reset player damage counter
	test_player.damage_taken = 0
	
	# Position player within AoE range (3m)
	test_player.global_position = Vector3(0, 0, 2.5)
	golem.global_position = Vector3(0, 0, 0)
	golem.current_state = golem.State.ATTACK
	
	# Directly call the attack execute to test AoE damage
	# (bypassing telegraph timing for test purposes)
	golem.on_attack_execute()
	
	await get_tree().process_frame
	
	# Check if player took damage
	var damage_dealt = test_player.damage_taken > 0
	
	if damage_dealt:
		passed_count += 1
		test_results["ground_slam_aoe"] = "✅ PASS"
		print("✅ Ground slam AoE damage working (dealt %d damage)" % test_player.damage_taken)
	else:
		test_results["ground_slam_aoe"] = "❌ FAIL: No damage dealt"
		print("❌ Ground slam AoE - No damage dealt to player in range")

func test_stagger_behavior() -> void:
	"""Test golem enters stagger state after slam"""
	test_count += 1
	
	# Reset stagger timer
	golem.stagger_timer = 0.0
	
	# Directly trigger slam execution
	golem.current_state = golem.State.ATTACK
	golem.on_attack_execute()
	
	await get_tree().process_frame
	
	# Check stagger timer is active
	var is_staggered = golem.stagger_timer > 0
	
	if is_staggered:
		passed_count += 1
		test_results["stagger"] = "✅ PASS"
		print("✅ Stagger behavior working (stagger timer: %.1fs)" % golem.stagger_timer)
	else:
		test_results["stagger"] = "❌ FAIL: No stagger after slam"
		print("❌ Stagger - No stagger timer active after ground slam")

func test_stone_patrol_setup() -> void:
	"""Test stone node patrol system exists"""
	test_count += 1
	
	# Check patrol methods and variables exist
	var has_patrol_method = golem.has_method("patrol_stone_nodes")
	var has_patrol_target = "patrol_target" in golem
	var has_find_method = golem.has_method("find_patrol_points")
	
	if has_patrol_method and has_patrol_target and has_find_method:
		passed_count += 1
		test_results["stone_patrol"] = "✅ PASS"
		print("✅ Stone patrol system implemented")
	else:
		test_results["stone_patrol"] = "❌ FAIL: Method:%s Target:%s Find:%s" % [has_patrol_method, has_patrol_target, has_find_method]
		print("❌ Stone patrol - Patrol method:%s, Target var:%s, Find method:%s" % 
			  [has_patrol_method, has_patrol_target, has_find_method])

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
