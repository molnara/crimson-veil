extends RigidBody3D
class_name LogPiece

"""
LogPiece - Visual log segments from fallen trees

LIFECYCLE:
1. Spawned by HarvestableTree.spawn_log_pieces() on ground impact
2. Scatters with physics (bounce, roll, settle)
3. Despawns after 4 seconds with particle effect

PURPOSE:
- Purely visual/cosmetic
- Wood was already added to inventory when tree was chopped
- These are just satisfying physics debris
"""

@export var lifetime: float = 4.0  # Seconds before despawn

var spawn_time: float = 0.0

func _ready():
	# Read metadata if set by spawner
	if has_meta("lifetime"):
		lifetime = get_meta("lifetime")
	if has_meta("spawn_time"):
		spawn_time = get_meta("spawn_time")
	else:
		spawn_time = Time.get_ticks_msec() / 1000.0

func _process(delta):
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_alive = current_time - spawn_time
	
	# Despawn after lifetime
	if time_alive >= lifetime:
		despawn()

func despawn():
	"""Despawn log with particle effect"""
	# Play despawn sound effect
	AudioManager.play_sound("resource_break", "sfx")
	
	# Save position and tree reference before we queue_free
	var log_position = global_position
	var scene_tree = get_tree()
	queue_free()
	# Spawn particles after freeing (using saved references)
	spawn_wood_particles_at(log_position, scene_tree)

func spawn_wood_particles_at(particle_position: Vector3, scene_tree: SceneTree):
	"""Spawn wood breaking particles at specified position"""
	var particles = CPUParticles3D.new()
	particles.position = particle_position  # Set local position before adding to tree
	scene_tree.root.call_deferred("add_child", particles)
	
	# Create mesh with material
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.15, 0.15, 0.15)
	
	# Create brown material for the mesh
	var wood_material = StandardMaterial3D.new()
	wood_material.albedo_color = Color(0.25, 0.15, 0.1)  # Dark bark brown
	wood_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting needed
	box_mesh.material = wood_material
	
	particles.mesh = box_mesh
	
	# Configure particles
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 16
	particles.lifetime = 1.0
	particles.speed_scale = 1.5
	
	# Emission shape - sphere
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.3
	
	# Movement
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 60.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.initial_velocity_min = 4.0
	particles.initial_velocity_max = 7.0
	
	# Scale
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.0
	
	# Fade out using modulate (alpha fade)
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1.0, 1.0, 1.0, 1.0))  # Full opacity
	grad.add_point(0.7, Color(1.0, 1.0, 1.0, 0.8))
	grad.add_point(1.0, Color(1.0, 1.0, 1.0, 0.0))  # Fade to transparent
	particles.color_ramp = grad
	
	# Auto-cleanup after particles finish
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()
