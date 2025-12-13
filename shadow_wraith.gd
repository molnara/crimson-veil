extends Enemy
class_name ShadowWraith

## Shadow Wraith - Night-only ethereal enemy
## Behavior: Only spawns at night, floats above terrain, phases through objects
## Stats: 40 HP, 12 DMG, 4.0 speed, 2.0m attack range

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
const ETHEREAL_ALPHA: float = 0.6
var wispy_particles: GPUParticles3D = null

func _ready() -> void:
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
	
	# Setup collision shape before calling super
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.6
		shape.height = 1.5
		collision_shape.shape = shape
		collision_shape.position = Vector3(0, 0.75, 0)
		add_child(collision_shape)
	
	# Call parent _ready to initialize
	super._ready()
	
	# Set collision to phase through terrain AFTER parent init (no terrain collision)
	collision_mask = 0  # Don't collide with anything
	
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
	if not day_night_cycle:
		return
	
	# Verify the cycle has the required method (might be a mock or not fully initialized)
	if not day_night_cycle.has_method("get_time_of_day"):
		return
	
	var current_time = day_night_cycle.get_time_of_day()
	if not is_night_time(current_time):
		# Spawned during day somehow - despawn immediately
		queue_free()

func is_night_time(time: float) -> bool:
	"""Check if current time is night (10 PM to 6 AM)"""
	return time >= NIGHT_START or time < NIGHT_END

func _process(delta: float) -> void:
	"""Monitor time of day for despawn at dawn"""
	if current_state == State.DEATH or is_despawning:
		return
	
	# Check for dawn
	if day_night_cycle and day_night_cycle.has_method("get_time_of_day"):
		var current_time = day_night_cycle.get_time_of_day()
		
		# Despawn at dawn (6 AM)
		if current_time >= NIGHT_END and current_time < 0.5:  # Morning
			despawn_at_dawn()

func _physics_process(delta: float) -> void:
	"""Handle floating behavior"""
	if current_state == State.DEATH or is_despawning:
		return
	
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
		if body and body.material:
			var mat = body.material as StandardMaterial3D
			var tween = create_tween()
			tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
			await tween.finished
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
		if body and body.material:
			var mat = body.material as StandardMaterial3D
			# Increase emission temporarily
			mat.emission_energy_multiplier = 3.0
	
	# TODO (Task 3.1): Play wraith attack whisper sound
	# AudioManager.play_sound("wraith_attack", "enemy", false, false)

func on_attack_execute() -> void:
	"""Play attack sound effect"""
	# Reset emission after attack
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body.material:
			var mat = body.material as StandardMaterial3D
			mat.emission_energy_multiplier = 1.5
	
	# TODO (Task 3.1): Play wraith strike sound
	# AudioManager.play_sound("wraith_strike", "enemy", false, false)

func on_death() -> void:
	"""Play death sound effect and fade out"""
	# TODO (Task 3.1): Play wraith death dissipate sound
	# AudioManager.play_sound("wraith_death", "enemy", false, false)
	
	# Fade out on death
	var visual = get_node_or_null("Visual")
	if visual:
		var body = visual.get_node_or_null("Body")
		if body and body.material:
			var mat = body.material as StandardMaterial3D
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
	
	# Flash brighter (increase emission)
	var mat = body.material as StandardMaterial3D
	if mat:
		var original_emission = mat.emission_energy_multiplier
		mat.emission_energy_multiplier = 4.0
		
		# Restore after 0.1s
		await get_tree().create_timer(0.1).timeout
		if mat:
			mat.emission_energy_multiplier = original_emission

func create_enemy_visual() -> void:
	"""Create CSG ethereal wraith appearance"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	add_child(visual_root)
	
	var shadow_purple = Color(0.3, 0.1, 0.4, ETHEREAL_ALPHA)  # Dark purple, transparent
	var shadow_black = Color(0.1, 0.05, 0.15, ETHEREAL_ALPHA)  # Near black, transparent
	
	# === BODY (CSGCylinder, vertical) ===
	var body = CSGCylinder3D.new()
	body.radius = 0.6
	body.height = 1.5
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
	body.material = body_mat
	
	# === HEAD (CSGSphere, featureless) ===
	var head = CSGSphere3D.new()
	head.radius = 0.4
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
	head.material = head_mat
	
	# === WISPY TRAIL PARTICLES (optional) ===
	wispy_particles = GPUParticles3D.new()
	wispy_particles.name = "WispyTrail"
	wispy_particles.position = Vector3(0, 0.75, 0)
	wispy_particles.amount = 8
	wispy_particles.lifetime = 1.0
	wispy_particles.explosiveness = 0.0
	wispy_particles.randomness = 0.3
	wispy_particles.visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	visual_root.add_child(wispy_particles)
	
	# Create particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = 0.3
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 15.0
	particle_material.initial_velocity_min = 0.2
	particle_material.initial_velocity_max = 0.5
	particle_material.gravity = Vector3(0, -0.5, 0)
	particle_material.scale_min = 0.1
	particle_material.scale_max = 0.3
	particle_material.color = Color(0.2, 0.1, 0.3, 0.4)  # Dark purple wisp
	wispy_particles.process_material = particle_material
	
	# Create particle mesh
	var particle_mesh = QuadMesh.new()
	particle_mesh.size = Vector2(0.2, 0.2)
	
	var particle_mat = StandardMaterial3D.new()
	particle_mat.albedo_color = Color(0.3, 0.1, 0.4, 0.6)
	particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	particle_mesh.material = particle_mat
	
	wispy_particles.draw_pass_1 = particle_mesh
	wispy_particles.emitting = true
