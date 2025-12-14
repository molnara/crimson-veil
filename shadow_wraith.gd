extends Enemy
class_name ShadowWraith

## Shadow Wraith - Night-only ethereal enemy
## Behavior: Only spawns at night, floats above terrain, phases through objects
## Stats: 40 HP, 12 DMG, 4.0 speed, 2.0m attack range

# Ambient sound timer (performance optimization)
var ambient_sound_timer: float = 0.0
var next_ambient_delay: float = 0.0

# Night-only spawning
var day_night_cycle: Node = null  # Can be DayNightCycle or mock Node for testing
const NIGHT_START: float = 0.9167  # 10 PM (22:00)
const NIGHT_END: float = 0.25  # 6 AM (06:00)
var is_despawning: bool = false

# Floating behavior
const FLOAT_HEIGHT: float = 1.5  # Height above terrain
var terrain_check_timer: float = 0.0
const TERRAIN_CHECK_INTERVAL: float = 0.1  # Check every 0.1s

# Ethereal appearance
const ETHEREAL_ALPHA: float = 0.5  # Semi-transparent ethereal appearance
var wispy_particles: GPUParticles3D = null

func _ready() -> void:
	print("[ShadowWraith] _ready() called")
	# Set wraith stats from balance table
	max_health = 40
	damage = 12
	move_speed = 4.0
	attack_range = 2.0
	detection_range = 10.0
	attack_cooldown_duration = 1.5
	attack_telegraph_duration = 0.5
	
	# Configure drop table
	drop_table = [
		{"item": "shadow_essence", "chance": 0.8},  # 80% chance
		{"item": "ectoplasm", "chance": 0.3}  # 30% rare drop
	]
	
	# Call parent _ready to initialize (collision shape in scene file)
	super._ready()
	print("[ShadowWraith] super._ready() completed successfully")
	
	# TEMP: Enable collision to prevent falling through world
	collision_mask = 1  # Collide with terrain (Layer 1)
	print("[ShadowWraith] Collision mask set to 1 (COLLIDES with terrain - testing)")
	
	# Find day/night cycle
	call_deferred("find_day_night_cycle")
	
	# Verify it's night time (wraiths should only spawn at night)
	call_deferred("verify_night_spawn")

func find_day_night_cycle() -> void:
	"""Find DayNightCycle using groups"""
	var cycles = get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.size() > 0:
		day_night_cycle = cycles[0]

func verify_night_spawn() -> void:
	"""Check if spawned during valid night time"""
	# DEBUG: Disabled for testing - allow wraith to spawn anytime
	print("[ShadowWraith] verify_night_spawn() - DISABLED for debug (spawn anytime)")
	return
	
	# ORIGINAL CODE (commented out for testing):
	# if not day_night_cycle:
	# 	return
	# 
	# # Verify the cycle has the required method (might be a mock or not fully initialized)
	# if not day_night_cycle.has_method("get_time_of_day"):
	# 	return
	# 
	# var current_time = day_night_cycle.get_time_of_day()
	# if not is_night_time(current_time):
	# 	# Spawned during day somehow - despawn immediately
	# 	queue_free()

func is_night_time(time: float) -> bool:
	"""Check if current time is night (10 PM to 6 AM)"""
	return time >= NIGHT_START or time < NIGHT_END

func _process(delta: float) -> void:
	"""Monitor time of day for despawn at dawn"""
	if current_state == State.DEATH or is_despawning:
		return
	
	# Play ambient sound (timer-based - every 5-8 seconds)
	ambient_sound_timer += delta
	if ambient_sound_timer >= next_ambient_delay:
		AudioManager.play_sound_3d("wraith_ambient", global_position, "sfx", false, false)
		ambient_sound_timer = 0.0
		next_ambient_delay = randf_range(5.0, 8.0)
	
	# DEBUG: Disabled dawn despawn for testing
	# # Check for dawn
	# if day_night_cycle and day_night_cycle.has_method("get_time_of_day"):
	# 	var current_time = day_night_cycle.get_time_of_day()
	# 	
	# 	# Despawn at dawn (6 AM)
	# 	if current_time >= NIGHT_END and current_time < 0.5:  # Morning
	# 		despawn_at_dawn()


func _physics_process(delta: float) -> void:
	"""Handle floating behavior"""
	if current_state == State.DEATH or is_despawning:
		return
	
	# DEBUG: Log position every second
	if Engine.get_frames_drawn() % 60 == 0:
		print("[ShadowWraith] Position: %.1f, %.1f, %.1f | State: %s" % [
			global_position.x, global_position.y, global_position.z, State.keys()[current_state]
		])
	
	# Call parent physics for AI and movement (but disable gravity)
	super._physics_process(delta)
	
	# Override velocity.y to maintain float (no gravity)
	velocity.y = 0
	
	# Maintain floating height above terrain
	terrain_check_timer += delta
	if terrain_check_timer >= TERRAIN_CHECK_INTERVAL:
		terrain_check_timer = 0.0
		maintain_float_height()

func maintain_float_height() -> void:
	"""Keep wraith floating at constant height above terrain"""
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
	
	# Raycast down to find terrain
	var ray_start = global_position + Vector3(0, 5.0, 0)
	var ray_end = global_position + Vector3(0, -10.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = 1  # Only terrain layer
	
	var result = space_state.intersect_ray(query)
	if result:
		var terrain_y = result.position.y
		var target_y = terrain_y + FLOAT_HEIGHT
		
		# Smoothly adjust to float height
		var current_y = global_position.y
		global_position.y = lerp(current_y, target_y, 0.1)

func despawn_at_dawn() -> void:
	"""Fade out and despawn when dawn arrives"""
	if is_despawning:
		return
	
	is_despawning = true
	
	# Fade out over 1 second
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body is MeshInstance3D:
			var mat = body.get_surface_override_material(0) as StandardMaterial3D
			if mat:
				var tween = create_tween()
				tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
				await tween.finished
			else:
				await get_tree().create_timer(1.0).timeout
		else:
			await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout
	
	# Despawn
	queue_free()

func update_ai(delta: float) -> void:
	"""Override AI for floating ethereal behavior"""
	if not player or current_state == State.DEATH or is_despawning:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	match current_state:
		State.IDLE:
			# Detect player in range
			if distance < detection_range:
				current_state = State.CHASE
		
		State.CHASE:
			# Check if in attack range
			if distance < attack_range:
				current_state = State.ATTACK
				velocity = Vector3.ZERO
			else:
				# Fast, ethereal chase (ignores terrain)
				chase_player_ethereal()
		
		State.ATTACK:
			# Return to chase if player escapes
			if distance > attack_range * 1.5:
				current_state = State.CHASE
			else:
				# Attempt attack if not on cooldown
				if attack_cooldown <= 0 and not is_telegraphing:
					start_attack_telegraph()

func chase_player_ethereal() -> void:
	"""Chase player while maintaining float height"""
	if not player:
		return
	
	# Get direction to player (ignore Y for horizontal movement)
	var to_player = (player.global_position - global_position)
	to_player.y = 0
	to_player = to_player.normalized()
	
	# Move toward player
	velocity.x = to_player.x * move_speed
	velocity.z = to_player.z * move_speed
	velocity.y = 0  # No vertical velocity (maintained by maintain_float_height)
	
	# Face player
	if to_player.length() > 0.01:
		look_at(global_position + to_player, Vector3.UP)

func on_attack_telegraph() -> void:
	"""Visual feedback during attack telegraph"""
	# Pulse brighter during telegraph
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body is MeshInstance3D:
			var mat = body.get_surface_override_material(0) as StandardMaterial3D
			# Increase emission temporarily
			mat.emission_energy_multiplier = 3.0
	
	# Play wraith attack whisper sound
	AudioManager.play_sound_3d("wraith_attack", global_position, "sfx", false, false)

func on_attack_execute() -> void:
	"""Execute attack and reset visuals"""
	# Reset emission after attack
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body is MeshInstance3D:
			var mat = body.get_surface_override_material(0) as StandardMaterial3D
			mat.emission_energy_multiplier = 1.5

func on_death() -> void:
	"""Play death sound effect and fade out"""
	# Play wraith death dissipate sound
	AudioManager.play_sound_3d("wraith_death", global_position, "sfx", false, false)
	
	# Fade out on death
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body is MeshInstance3D:
			var mat = body.get_surface_override_material(0) as StandardMaterial3D
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color:a", 0.0, 0.5)

func flash_white() -> void:
	"""Override damage flash for ethereal appearance"""
	var visual = get_node_or_null("Visual")
	if not visual:
		return
	
	var body = visual.get_node_or_null("Body")
	if not body:
		return
	
	# Play wraith hit sound
	AudioManager.play_sound_3d("wraith_hit", global_position, "sfx", false, false)
	
	# Flash brighter (increase emission)
	var mat = body.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		var original_emission = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 4.0
		
		# Restore after 0.1s
		await get_tree().create_timer(0.1).timeout
		if mat:
			mat.emission_energy_multiplier = original_emission

func create_enemy_visual() -> void:
	"""Create ethereal wraith appearance"""
	print("[ShadowWraith] create_enemy_visual() called")
	
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	
	var shadow_purple = Color(0.3, 0.1, 0.4, ETHEREAL_ALPHA)  # Dark purple
	var shadow_black = Color(0.1, 0.05, 0.15, ETHEREAL_ALPHA)  # Near black
	
	# === BODY (Ethereal purple cylinder) ===
	var body = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.6
	cylinder_mesh.bottom_radius = 0.6
	cylinder_mesh.height = 1.5
	body.mesh = cylinder_mesh
	body.position = Vector3(0, 0.75, 0)
	body.name = "Body"
	visual_root.add_child(body)
	
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = shadow_purple
	body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	body_mat.emission_enabled = true
	body_mat.emission = Color(0.4, 0.2, 0.6)  # Purple glow
	body_mat.emission_energy_multiplier = 1.5
	body_mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Visible from all angles
	body.set_surface_override_material(0, body_mat)
	
	print("[ShadowWraith] Purple ethereal cylinder created")
	
	# === HEAD (Dark ethereal sphere) ===
	var head = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.4
	sphere_mesh.height = 0.8
	head.mesh = sphere_mesh
	head.position = Vector3(0, 1.7, 0)
	head.name = "Head"
	visual_root.add_child(head)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = shadow_black
	head_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	head_mat.emission_enabled = true
	head_mat.emission = Color(0.2, 0.1, 0.3)  # Dim purple glow
	head_mat.emission_energy_multiplier = 1.0
	head_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	head.set_surface_override_material(0, head_mat)
	
	print("[ShadowWraith] Dark ethereal sphere created")
	print("[ShadowWraith] Visual creation complete!")
