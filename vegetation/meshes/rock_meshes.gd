class_name RockMeshes
extends RefCounted

"""
RockMeshes - Mesh creation for rocks, boulders, and snow rocks

v0.8.0: Extracted from vegetation_spawner.gd
"""


static func create_rock(mesh_instance: MeshInstance3D, is_boulder: bool) -> void:
	"""Create a harvestable rock or boulder"""
	print("[RockMeshes] Creating rock boulder=%s at %s" % [is_boulder, mesh_instance.global_position])
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Rock colors - gray with slight variation
	var base_gray = 0.45 + randf() * 0.15
	var rock_color = Color(base_gray, base_gray * 0.95, base_gray * 0.9)
	
	# Size based on type
	var size_mult = 2.0 if is_boulder else 1.0
	var base_radius = (0.3 + randf() * 0.2) * size_mult
	var height = (0.4 + randf() * 0.3) * size_mult
	
	# Create irregular rock shape
	var segments = 8
	var layers = 4
	var vertices = []
	
	# Generate vertex positions
	for layer in range(layers + 1):
		var layer_t = float(layer) / layers
		var y = layer_t * height
		var layer_radius = base_radius * (1.0 - layer_t * 0.6)  # Taper toward top
		
		for seg in range(segments):
			var angle = (float(seg) / segments) * TAU
			var radius_variation = layer_radius * (0.7 + randf() * 0.3)
			var x = cos(angle) * radius_variation
			var z = sin(angle) * radius_variation
			vertices.append(Vector3(x, y, z))
	
	# Create triangles
	for layer in range(layers):
		for seg in range(segments):
			var next_seg = (seg + 1) % segments
			var i0 = layer * segments + seg
			var i1 = layer * segments + next_seg
			var i2 = (layer + 1) * segments + seg
			var i3 = (layer + 1) * segments + next_seg
			
			var color_var = rock_color * (0.85 + randf() * 0.3)
			surface_tool.set_color(color_var)
			
			surface_tool.add_vertex(vertices[i0])
			surface_tool.add_vertex(vertices[i1])
			surface_tool.add_vertex(vertices[i2])
			
			surface_tool.add_vertex(vertices[i1])
			surface_tool.add_vertex(vertices[i3])
			surface_tool.add_vertex(vertices[i2])
	
	# Top cap
	var top_center = Vector3(0, height, 0)
	var top_start = layers * segments
	for seg in range(segments):
		var next_seg = (seg + 1) % segments
		surface_tool.set_color(rock_color * (0.9 + randf() * 0.2))
		surface_tool.add_vertex(vertices[top_start + seg])
		surface_tool.add_vertex(vertices[top_start + next_seg])
		surface_tool.add_vertex(top_center)
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)


static func create_small_rock(mesh_instance: MeshInstance3D) -> void:
	"""Create a small decorative rock (1/3 size of regular)"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var base_gray = 0.40 + randf() * 0.2
	var rock_color = Color(base_gray, base_gray * 0.95, base_gray * 0.9)
	
	# Small size
	var radius = 0.08 + randf() * 0.06
	var height = 0.06 + randf() * 0.05
	
	# Simple 6-sided rock
	var segments = 6
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		var r1 = radius * (0.7 + randf() * 0.3)
		var r2 = radius * (0.7 + randf() * 0.3)
		
		# Side faces
		surface_tool.set_color(rock_color * (0.85 + randf() * 0.3))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, 0, sin(a2) * r2))
		surface_tool.add_vertex(Vector3(0, height, 0))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)


static func create_snow_rock(mesh_instance: MeshInstance3D) -> void:
	"""Create a rock with snow cap on top"""
	# Create base rock first
	create_rock(mesh_instance, false)
	
	# Add snow cap
	var snow_mesh = MeshInstance3D.new()
	mesh_instance.add_child(snow_mesh)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var snow_color = Color(0.95, 0.97, 1.0)
	var rock_height = 0.4 + randf() * 0.3
	var rock_radius = 0.3 + randf() * 0.2
	
	# Snow on top - irregular white cap
	var segments = 6
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		var r1 = rock_radius * (0.6 + randf() * 0.3)
		var r2 = rock_radius * (0.6 + randf() * 0.3)
		
		surface_tool.set_color(snow_color)
		surface_tool.add_vertex(Vector3(0, rock_height + 0.05, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, rock_height, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, rock_height, sin(a2) * r2))
	
	surface_tool.generate_normals()
	snow_mesh.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	snow_mesh.set_surface_override_material(0, material)
