extends Enemy

## Simple test enemy for validating Enemy base class
## Basic hostile creature with red cube visual and simple drop table

func _ready() -> void:
	# Set stats
	max_health = 50
	damage = 10
	move_speed = 3.0
	detection_range = 10.0
	attack_range = 2.0
	
	# Setup drop table - 50% chance for wood, 25% chance for stone
	drop_table = [
		{"item": "wood", "chance": 0.5},
		{"item": "stone", "chance": 0.25}
	]
	
	# Call parent _ready
	super._ready()

func create_enemy_visual() -> void:
	"""Create a simple red cube enemy - LARGER AND BRIGHTER FOR VISIBILITY"""
	visual_mesh = MeshInstance3D.new()
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(2, 3, 2)  # Larger: 2m wide, 3m tall
	visual_mesh.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0)  # Bright red
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.2)  # Glowing red
	mat.emission_energy = 2.0
	visual_mesh.set_surface_override_material(0, mat)
	
	add_child(visual_mesh)
	original_material = mat
	
	# Add tall marker pole for visibility
	var marker = MeshInstance3D.new()
	var marker_mesh = CylinderMesh.new()
	marker_mesh.top_radius = 0.1
	marker_mesh.bottom_radius = 0.1
	marker_mesh.height = 10.0
	marker.mesh = marker_mesh
	marker.position = Vector3(0, 5, 0)  # Position above enemy
	
	var marker_mat = StandardMaterial3D.new()
	marker_mat.albedo_color = Color(1.0, 1.0, 0.0)  # Bright yellow
	marker_mat.emission_enabled = true
	marker_mat.emission = Color(1.0, 1.0, 0.0)
	marker_mat.emission_energy = 3.0
	marker.set_surface_override_material(0, marker_mat)
	
	add_child(marker)

func on_attack_telegraph() -> void:
	"""Flash darker during wind-up"""
	if visual_mesh:
		var mat = visual_mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color(0.4, 0.1, 0.1)  # Darker red

func on_attack_execute() -> void:
	"""Restore color after attack"""
	if visual_mesh and original_material:
		visual_mesh.set_surface_override_material(0, original_material)

func on_death() -> void:
	"""Simple death feedback"""
	print("Test enemy died at: ", global_position)
