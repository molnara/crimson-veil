extends Node3D
## Weather particle controller - MUST be manually added as Node3D in editor
## Do NOT use as .tscn - instantiated scenes don't work properly

var rain_particles: GPUParticles3D
var storm_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var blizzard_particles: GPUParticles3D

func _ready():
	print("[WeatherParticles] Initializing...")
	
	# Position at player's starting location
	await get_tree().process_frame  # Wait for player to be ready
	var player = get_tree().get_first_node_in_group("player")
	if player:
		global_position = player.global_position
		print("[WeatherParticles] Positioned at player: ", global_position)
	
	_create_rain()
	_create_storm()
	_create_snow()
	_create_blizzard()
	
	# Register with WeatherManager after a short delay
	await get_tree().create_timer(0.5).timeout
	if WeatherManager:
		WeatherManager.set_rain_particles(rain_particles)
		WeatherManager.set_storm_particles(storm_particles)
		WeatherManager.set_snow_particles(snow_particles)
		WeatherManager.set_blizzard_particles(blizzard_particles)
		print("[WeatherParticles] Registered with WeatherManager")

func _create_rain():
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "Rain"
	add_child(rain_particles)
	
	rain_particles.position = Vector3(0, 50, 0)
	rain_particles.amount = 12000
	rain_particles.lifetime = 3.5
	rain_particles.preprocess = 0.0
	rain_particles.emitting = true
	rain_particles.visible = false
	rain_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(100, 0.1, 100)
	mat.gravity = Vector3(0, -25, 0)
	rain_particles.process_material = mat
	
	# Rain streaks
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.06, 1.8, 0.06)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.6, 0.75, 1.0, 0.5)
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mesh_mat
	rain_particles.draw_pass_1 = mesh
	
	print("[WeatherParticles] Rain created")

func _create_storm():
	storm_particles = GPUParticles3D.new()
	storm_particles.name = "Storm"
	add_child(storm_particles)
	
	storm_particles.position = Vector3(0, 60, 0)
	storm_particles.amount = 20000
	storm_particles.lifetime = 2.5
	storm_particles.preprocess = 0.0
	storm_particles.emitting = true
	storm_particles.visible = false
	storm_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(120, 0.1, 120)
	mat.gravity = Vector3(-5, -40, -3)  # Angled rain for stormy effect
	rain_particles.process_material = mat
	storm_particles.process_material = mat
	
	# Heavy storm rain - thicker and longer
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.08, 2.5, 0.08)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.5, 0.6, 0.8, 0.7)
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mesh_mat
	storm_particles.draw_pass_1 = mesh
	
	print("[WeatherParticles] Storm created")

func _create_snow():
	snow_particles = GPUParticles3D.new()
	snow_particles.name = "Snow"
	add_child(snow_particles)
	
	snow_particles.position = Vector3(0, 50, 0)
	snow_particles.amount = 8000
	snow_particles.lifetime = 20.0
	snow_particles.preprocess = 0.0
	snow_particles.emitting = true
	snow_particles.visible = false
	snow_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(100, 0.1, 100)
	mat.gravity = Vector3(0.5, -3, 0.3)  # Gentle drift
	snow_particles.process_material = mat
	
	# Snow flakes
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 0.2, 0.2)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mesh_mat
	snow_particles.draw_pass_1 = mesh
	
	print("[WeatherParticles] Snow created")

func _create_blizzard():
	blizzard_particles = GPUParticles3D.new()
	blizzard_particles.name = "Blizzard"
	add_child(blizzard_particles)
	
	blizzard_particles.position = Vector3(0, 50, 0)
	blizzard_particles.amount = 18000
	blizzard_particles.lifetime = 10.0
	blizzard_particles.preprocess = 0.0
	blizzard_particles.emitting = true
	blizzard_particles.visible = false
	blizzard_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
	
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(120, 0.1, 120)
	mat.gravity = Vector3(-8, -8, -5)  # Strong horizontal wind
	blizzard_particles.process_material = mat
	
	# Blizzard snow - larger, denser
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.25, 0.25, 0.25)
	var mesh_mat = StandardMaterial3D.new()
	mesh_mat.albedo_color = Color(0.95, 0.95, 1.0, 0.9)
	mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mesh_mat
	blizzard_particles.draw_pass_1 = mesh
	
	print("[WeatherParticles] Blizzard created")

func _process(_delta):
	# Check if player teleported far away - reposition weather if so
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance > 200:
			global_position = player.global_position
			print("[WeatherParticles] Repositioned to player at: ", global_position)
