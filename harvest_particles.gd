extends Node3D

"""
Creates Minecraft-style pixel "poof" particles when resources are harvested.
Spawns small cubes that fly outward and fade away.
Static utility class - no need for class_name.
"""

static func create_break_particles(position: Vector3, resource_type: String, parent: Node) -> void:
	"""Create particle explosion at the given position"""
	var particle_count = 15 + randi() % 10  # 15-24 particles (increased from 8-12)
	
	for i in range(particle_count):
		# Generate a NEW random color for each particle based on resource type
		var particle_color: Color
		match resource_type:
			"stone", "ore":
				particle_color = get_rock_particle_color()
			"wood":
				particle_color = get_wood_particle_color()
			"foliage":
				particle_color = get_foliage_particle_color()
			_:
				particle_color = get_rock_particle_color()
		
		var particle = create_particle(particle_color)
		parent.add_child(particle)
		# Set position AFTER adding to tree
		particle.global_position = position

static func create_particle(color: Color) -> MeshInstance3D:
	"""Create a single particle cube"""
	var particle = MeshInstance3D.new()
	
	# Small cube mesh
	var box = BoxMesh.new()
	var size = 0.1 + randf() * 0.1  # 0.1-0.2m cubes
	box.size = Vector3(size, size, size)
	particle.mesh = box
	
	# Material with color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # Bright, no shadows
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle.material_override = material
	
	# Random velocity (outward explosion)
	var velocity = Vector3(
		(randf() - 0.5) * 4.0,  # X: -2 to 2
		randf() * 3.0 + 1.0,    # Y: 1 to 4 (upward bias)
		(randf() - 0.5) * 4.0   # Z: -2 to 2
	)
	
	# Random rotation speed
	var rotation_speed = Vector3(
		(randf() - 0.5) * 10.0,
		(randf() - 0.5) * 10.0,
		(randf() - 0.5) * 10.0
	)
	
	# Store animation data
	particle.set_meta("velocity", velocity)
	particle.set_meta("rotation_speed", rotation_speed)
	particle.set_meta("lifetime", 0.0)
	particle.set_meta("max_lifetime", 0.8 + randf() * 0.4)  # 0.8-1.2 seconds
	
	# Add script to animate
	var script = GDScript.new()
	script.source_code = """
extends MeshInstance3D

func _process(delta):
	var velocity = get_meta('velocity')
	var rotation_speed = get_meta('rotation_speed')
	var lifetime = get_meta('lifetime')
	var max_lifetime = get_meta('max_lifetime')
	
	# Update lifetime
	lifetime += delta
	set_meta('lifetime', lifetime)
	
	# Move particle
	global_position += velocity * delta
	
	# Apply gravity
	velocity.y -= 9.8 * delta
	set_meta('velocity', velocity)
	
	# Rotate
	rotation += rotation_speed * delta
	
	# Fade out
	var fade = 1.0 - (lifetime / max_lifetime)
	var mat = material_override as StandardMaterial3D
	if mat:
		var color = mat.albedo_color
		color.a = fade
		mat.albedo_color = color
	
	# Scale down slightly
	scale = Vector3.ONE * (0.5 + fade * 0.5)
	
	# Destroy when lifetime expired
	if lifetime >= max_lifetime:
		queue_free()
"""
	script.reload()
	particle.set_script(script)
	
	return particle

static func get_rock_particle_color() -> Color:
	"""Get stone colors - primarily grays and blacks, some blue-gray tints"""
	var color_type = randf()
	
	if color_type > 0.65:
		# Very dark, almost black (35%)
		var gray = 0.08 + randf() * 0.12  # 0.08-0.2
		return Color(gray, gray, gray)
	elif color_type > 0.4:
		# Dark gray/charcoal (25%)
		var gray = 0.2 + randf() * 0.15
		return Color(gray, gray, gray)
	elif color_type > 0.25:
		# Medium gray (15%)
		var gray = 0.4 + randf() * 0.15
		return Color(gray, gray, gray)
	elif color_type > 0.15:
		# Blue-gray stone (10%)
		var r = 0.3 + randf() * 0.1
		var g = 0.35 + randf() * 0.1
		var b = 0.4 + randf() * 0.15
		return Color(r, g, b)
	elif color_type > 0.05:
		# Light gray/granite (10%)
		var gray = 0.55 + randf() * 0.15
		return Color(gray, gray, gray)
	else:
		# White/pale stone (5%)
		var gray = 0.75 + randf() * 0.15
		return Color(gray, gray, gray)

static func get_wood_particle_color() -> Color:
	"""Get a warm brown color for wood particles - more orange/yellow tones"""
	var color_type = randf()
	
	if color_type > 0.7:
		# Dark wood/bark (30%)
		var r = 0.25 + randf() * 0.1
		var g = 0.15 + randf() * 0.08
		var b = 0.08 + randf() * 0.05
		return Color(r, g, b)
	elif color_type > 0.4:
		# Medium brown wood (30%)
		var r = 0.45 + randf() * 0.15
		var g = 0.3 + randf() * 0.1
		var b = 0.15 + randf() * 0.08
		return Color(r, g, b)
	elif color_type > 0.15:
		# Light/orange wood (25%)
		var r = 0.6 + randf() * 0.2
		var g = 0.4 + randf() * 0.15
		var b = 0.2 + randf() * 0.1
		return Color(r, g, b)
	else:
		# Yellow/tan wood (15%)
		var r = 0.7 + randf() * 0.15
		var g = 0.55 + randf() * 0.15
		var b = 0.3 + randf() * 0.1
		return Color(r, g, b)

static func get_foliage_particle_color() -> Color:
	"""Get a random green color for foliage particles"""
	return Color(0.2 + randf() * 0.2, 0.4 + randf() * 0.3, 0.1 + randf() * 0.15)
