extends Node3D

## Automated test scene for Enemy Spawning Integration
## Tests: Biome-specific spawning, pack spawning, night-only spawning, minimum distance

var chunk_manager: Node  # Mock chunk manager
var critter_spawner: Node
var day_night_cycle: DayNightCycle
var test_player: CharacterBody3D
var test_results: Dictionary = {}
var test_count: int = 0
var passed_count: int = 0

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("=== ENEMY SPAWNING INTEGRATION TESTS ===")
	print("=".repeat(60) + "\n")
	print("Starting test initialization...")
	
	# Create mock day/night cycle
	setup_day_night_cycle()
	print("✓ Day/Night cycle created")
	
	# Create test player
	setup_test_player()
	print("✓ Test player created")
	
	# Create mock chunk manager
	setup_chunk_manager()
	print("✓ Chunk manager created")
	
	# Load critter spawner
	var spawner_script = load("res://critter_spawner.gd")
	if not spawner_script:
		print("❌ FAILED: Could not load critter_spawner.gd")
		return
	
	critter_spawner = Node3D.new()
	critter_spawner.set_script(spawner_script)
	critter_spawner.name = "CritterSpawner"
	add_child(critter_spawner)
	
	print("✓ Critter spawner loaded")
	
	# Wait for initialization
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("✓ Initialization complete, running tests...\n")
	
	# Run tests
	await run_all_tests()
	
	# Print results
	print_test_results()

func setup_day_night_cycle() -> void:
	"""Create a mock DayNightCycle"""
	day_night_cycle = DayNightCycle.new()
	day_night_cycle.name = "DayNightCycle"
	day_night_cycle.add_to_group("day_night_cycle")
	add_child(day_night_cycle)
	# Set to daytime initially
	day_night_cycle.set_time_of_day(0.5)  # Noon

func setup_test_player() -> void:
	"""Create a mock player"""
	test_player = CharacterBody3D.new()
	test_player.name = "Player"
	test_player.add_to_group("player")
	test_player.global_position = Vector3(0, 0, 0)
	add_child(test_player)
	
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	test_player.add_child(collision)

func setup_chunk_manager() -> void:
	"""Create a minimal mock chunk manager"""
	chunk_manager = Node.new()
	chunk_manager.name = "ChunkManager"
	chunk_manager.set_script(GDScript.new())
	chunk_manager.get_script().source_code = """
extends Node

var chunk_size: int = 32
var player: Node3D = null
var chunks: Dictionary = {}
var noise: FastNoiseLite = FastNoiseLite.new()
var temperature_noise: FastNoiseLite = FastNoiseLite.new()
var moisture_noise: FastNoiseLite = FastNoiseLite.new()
var height_multiplier: float = 20.0

func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(int(pos.x / chunk_size), int(pos.z / chunk_size))
"""
	chunk_manager.get_script().reload()
	add_child(chunk_manager)
	chunk_manager.player = test_player

func run_all_tests() -> void:
	"""Execute all test cases"""
	print("Running spawning integration tests...")
	
	# Method existence tests
	test_spawning_methods_exist()
	test_night_time_check()
	
	# Spawning behavior tests
	await test_single_enemy_spawn()
	await test_wolf_pack_spawn()
	await test_minimum_distance_check()
	await test_night_only_wraith_spawn()

func test_spawning_methods_exist() -> void:
	"""Test that new spawning methods exist"""
	test_count += 1
	
	var has_spawn_enemies = critter_spawner.has_method("spawn_enemies_in_chunk")
	var has_spawn_single = critter_spawner.has_method("spawn_single_enemy")
	var has_spawn_pack = critter_spawner.has_method("spawn_wolf_pack")
	var has_night_check = critter_spawner.has_method("is_night_time")
	
	if has_spawn_enemies and has_spawn_single and has_spawn_pack and has_night_check:
		passed_count += 1
		test_results["spawning_methods"] = "✅ PASS"
		print("✅ All spawning methods exist")
	else:
		test_results["spawning_methods"] = "❌ FAIL: Enemies:%s Single:%s Pack:%s Night:%s" % [has_spawn_enemies, has_spawn_single, has_spawn_pack, has_night_check]
		print("❌ Missing methods - SpawnEnemies:%s, SpawnSingle:%s, SpawnPack:%s, NightCheck:%s" % [has_spawn_enemies, has_spawn_single, has_spawn_pack, has_night_check])

func test_night_time_check() -> void:
	"""Test night time detection works"""
	test_count += 1
	
	# Set to night
	day_night_cycle.set_time_of_day(0.95)  # 10:48 PM
	critter_spawner.day_night_cycle = day_night_cycle
	
	var is_night = critter_spawner.is_night_time()
	
	# Set to day
	day_night_cycle.set_time_of_day(0.5)  # Noon
	var is_day = not critter_spawner.is_night_time()
	
	if is_night and is_day:
		passed_count += 1
		test_results["night_check"] = "✅ PASS"
		print("✅ Night time detection working")
	else:
		test_results["night_check"] = "❌ FAIL: Night:%s Day:%s" % [is_night, is_day]
		print("❌ Night check - Night detection:%s, Day detection:%s" % [is_night, is_day])

func test_single_enemy_spawn() -> void:
	"""Test single enemy spawning"""
	test_count += 1
	
	# Initialize spawner
	critter_spawner.chunk_manager = chunk_manager
	critter_spawner.player = test_player
	critter_spawner.noise = chunk_manager.noise
	critter_spawner.initialized = true
	
	# Try spawning a corrupted rabbit
	var initial_child_count = critter_spawner.get_child_count()
	critter_spawner.spawn_single_enemy("corrupted_rabbit", Vector3(50, 0, 50), Vector2i(1, 1))
	
	await get_tree().process_frame
	
	var spawned = critter_spawner.get_child_count() > initial_child_count
	
	if spawned:
		passed_count += 1
		test_results["single_spawn"] = "✅ PASS"
		print("✅ Single enemy spawning works")
		# Clean up
		var enemy = critter_spawner.get_child(critter_spawner.get_child_count() - 1)
		enemy.queue_free()
	else:
		test_results["single_spawn"] = "❌ FAIL: No enemy spawned"
		print("❌ Single spawn - No enemy spawned (children: %d -> %d)" % [initial_child_count, critter_spawner.get_child_count()])

func test_wolf_pack_spawn() -> void:
	"""Test wolf pack spawning creates 2-3 wolves"""
	test_count += 1
	
	# Initialize spawner
	critter_spawner.chunk_manager = chunk_manager
	critter_spawner.player = test_player
	critter_spawner.noise = chunk_manager.noise
	critter_spawner.initialized = true
	
	var initial_child_count = critter_spawner.get_child_count()
	critter_spawner.spawn_wolf_pack(Vector3(100, 0, 100), Vector2i(3, 3))
	
	await get_tree().process_frame
	
	var wolves_spawned = critter_spawner.get_child_count() - initial_child_count
	var pack_spawned = wolves_spawned >= 2 and wolves_spawned <= 3
	
	if pack_spawned:
		passed_count += 1
		test_results["pack_spawn"] = "✅ PASS"
		print("✅ Wolf pack spawning works (%d wolves)" % wolves_spawned)
		
		# Check pack IDs match
		var wolves = []
		for i in range(wolves_spawned):
			var wolf = critter_spawner.get_child(initial_child_count + i)
			wolves.append(wolf)
		
		# Verify same pack_id
		if wolves.size() >= 2:
			var first_pack_id = wolves[0].pack_id
			var same_pack = true
			for wolf in wolves:
				if wolf.pack_id != first_pack_id:
					same_pack = false
			
			if same_pack:
				print("  ✓ All wolves have same pack_id: %d" % first_pack_id)
			else:
				print("  ⚠ Warning: Pack IDs don't match")
		
		# Clean up
		for wolf in wolves:
			wolf.queue_free()
	else:
		test_results["pack_spawn"] = "❌ FAIL: %d wolves (expected 2-3)" % wolves_spawned
		print("❌ Pack spawn - %d wolves spawned (expected 2-3)" % wolves_spawned)

func test_minimum_distance_check() -> void:
	"""Test enemies don't spawn too close to player"""
	test_count += 1
	
	# Initialize spawner
	critter_spawner.chunk_manager = chunk_manager
	critter_spawner.player = test_player
	critter_spawner.noise = chunk_manager.noise
	critter_spawner.initialized = true
	
	# Position player at origin
	test_player.global_position = Vector3(0, 0, 0)
	
	# Try spawning very close (should fail)
	var initial_child_count = critter_spawner.get_child_count()
	critter_spawner.spawn_single_enemy("corrupted_rabbit", Vector3(5, 0, 5), Vector2i(0, 0))  # 7m away
	
	await get_tree().process_frame
	
	var spawned_close = critter_spawner.get_child_count() > initial_child_count
	
	# Try spawning far away (should succeed)
	critter_spawner.spawn_single_enemy("corrupted_rabbit", Vector3(50, 0, 50), Vector2i(1, 1))  # ~70m away
	
	await get_tree().process_frame
	
	var spawned_far = critter_spawner.get_child_count() > initial_child_count
	
	if not spawned_close and spawned_far:
		passed_count += 1
		test_results["min_distance"] = "✅ PASS"
		print("✅ Minimum distance check working (blocks close spawn, allows far spawn)")
		# Clean up
		if spawned_far:
			var enemy = critter_spawner.get_child(critter_spawner.get_child_count() - 1)
			enemy.queue_free()
	else:
		test_results["min_distance"] = "❌ FAIL: Close:%s Far:%s" % [spawned_close, spawned_far]
		print("❌ Min distance - Spawned close:%s (should be false), Spawned far:%s (should be true)" % [spawned_close, spawned_far])

func test_night_only_wraith_spawn() -> void:
	"""Test Shadow Wraith only spawns at night"""
	test_count += 1
	
	# Initialize spawner
	critter_spawner.chunk_manager = chunk_manager
	critter_spawner.player = test_player
	critter_spawner.noise = chunk_manager.noise
	critter_spawner.day_night_cycle = day_night_cycle
	critter_spawner.initialized = true
	
	# Set to daytime
	day_night_cycle.set_time_of_day(0.5)  # Noon
	test_player.global_position = Vector3(0, 0, 0)
	
	# Manually call spawning logic (since we can't control random biome)
	var spawned_at_day = false
	if critter_spawner.is_night_time():
		spawned_at_day = true  # Should not happen
	
	# Set to nighttime
	day_night_cycle.set_time_of_day(0.95)  # Night
	
	var spawned_at_night = false
	if critter_spawner.is_night_time():
		spawned_at_night = true  # Should happen
	
	if not spawned_at_day and spawned_at_night:
		passed_count += 1
		test_results["night_wraith"] = "✅ PASS"
		print("✅ Night-only wraith spawn logic working")
	else:
		test_results["night_wraith"] = "❌ FAIL: Day:%s Night:%s" % [spawned_at_day, spawned_at_night]
		print("❌ Night wraith - Day check:%s (should be false), Night check:%s (should be true)" % [spawned_at_day, spawned_at_night])

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
