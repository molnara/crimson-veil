class_name ForestMeshes
extends RefCounted

"""
ForestMeshes - Mesh creation for forest biome specific vegetation

v0.8.0: Extracted from vegetation_spawner.gd
v0.8.1: Restored original mushroom geometry (proper stem + dome cap)

Includes: mushrooms, fallen logs, tree stumps
Note: Trees are in tree_meshes.gd
"""


static func create_mushroom_visual(mesh_instance: MeshInstance3D, is_red: bool, is_cluster: bool) -> void:
	"""Create mushroom visual mesh"""
	if is_cluster:
		# Create cluster of small mushrooms
		var cluster_count = 3 + randi() % 3
		for i in range(cluster_count):
			var small_mushroom = MeshInstance3D.new()
			mesh_instance.add_child(small_mushroom)
			
			var offset_x = (randf() - 0.5) * 0.3
			var offset_z = (randf() - 0.5) * 0.3
			small_mushroom.position = Vector3(offset_x, 0, offset_z)
			
			_create_single_mushroom(small_mushroom, false, 0.15 + randf() * 0.1)
	else:
		var size = 0.2 + randf() * 0.15
		_create_single_mushroom(mesh_instance, is_red, size)


static func _create_single_mushroom(mesh_instance: MeshInstance3D, is_red: bool, size: float) -> void:
	"""Create a single mushroom with proper stem and dome cap - original geometry"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var stem_height = size * 1.5
	var stem_radius = size * 0.15
	var cap_radius = size * 0.8
	var cap_height = size * 0.5
	
	var stem_color = Color(0.9, 0.85, 0.75)
	var cap_color = Color(0.8, 0.15, 0.1) if is_red else Color(0.5, 0.35, 0.25)
	
	var sides = 8
	
	# Stem - vertical cylinder
	for i in range(sides):
		var angle1 = (i / float(sides)) * TAU
		var angle2 = ((i + 1) / float(sides)) * TAU
		
		var x1 = cos(angle1) * stem_radius
		var z1 = sin(angle1) * stem_radius
		var x2 = cos(angle2) * stem_radius
		var z2 = sin(angle2) * stem_radius
		
		surface_tool.set_color(stem_color)
		surface_tool.add_vertex(Vector3(x1, 0, z1))
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
		
		surface_tool.add_vertex(Vector3(x2, 0, z2))
		surface_tool.add_vertex(Vector3(x2, stem_height, z2))
		surface_tool.add_vertex(Vector3(x1, stem_height, z1))
	
	# Cap - dome shape built from segments
	var cap_base_y = stem_height
	var cap_segments = 5
	
	for segment in range(cap_segments):
		var t1 = segment / float(cap_segments)
		var t2 = (segment + 1) / float(cap_segments)
		
		var radius1 = cap_radius * sin(t1 * PI * 0.5)
		var radius2 = cap_radius * sin(t2 * PI * 0.5)
		var height1 = cap_base_y + (1.0 - cos(t1 * PI * 0.5)) * cap_height
		var height2 = cap_base_y + (1.0 - cos(t2 * PI * 0.5)) * cap_height
		
		if segment == cap_segments - 1:
			# Top cap - converge to center point
			radius2 = 0.0
			height2 = cap_base_y + cap_height
			
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1 = cos(angle1) * radius1
				var z1 = sin(angle1) * radius1
				var x2 = cos(angle2) * radius1
				var z2 = sin(angle2) * radius1
				
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1, height1, z1))
				surface_tool.add_vertex(Vector3(x2, height1, z2))
				surface_tool.add_vertex(Vector3(0, height2, 0))
		else:
			# Middle cap segments - rings
			for i in range(sides):
				var angle1 = (i / float(sides)) * TAU
				var angle2 = ((i + 1) / float(sides)) * TAU
				
				var x1a = cos(angle1) * radius1
				var z1a = sin(angle1) * radius1
				var x2a = cos(angle2) * radius1
				var z2a = sin(angle2) * radius1
				
				var x1b = cos(angle1) * radius2
				var z1b = sin(angle1) * radius2
				var x2b = cos(angle2) * radius2
				var z2b = sin(angle2) * radius2
				
				surface_tool.set_color(cap_color)
				surface_tool.add_vertex(Vector3(x1a, height1, z1a))
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
				
				surface_tool.add_vertex(Vector3(x2a, height1, z2a))
				surface_tool.add_vertex(Vector3(x2b, height2, z2b))
				surface_tool.add_vertex(Vector3(x1b, height2, z1b))
	
	surface_tool.generate_normals()
	var mushroom_mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.roughness = 0.6
	mushroom_mesh.surface_set_material(0, material)
	
	mesh_instance.mesh = mushroom_mesh


static func create_fallen_log(mesh_instance: MeshInstance3D) -> void:
	"""Create fallen tree log"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bark_color = Color(0.35, 0.25, 0.18)
	var inner_color = Color(0.55, 0.45, 0.30)
	
	var length = 1.5 + randf() * 1.5
	var radius = 0.15 + randf() * 0.1
	
	# Horizontal cylinder
	var segments = 8
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		
		var y1 = sin(a1) * radius + radius
		var z1 = cos(a1) * radius
		var y2 = sin(a2) * radius + radius
		var z2 = cos(a2) * radius
		
		# Side of log
		surface_tool.set_color(bark_color * (0.85 + randf() * 0.3))
		surface_tool.add_vertex(Vector3(0, y1, z1))
		surface_tool.add_vertex(Vector3(length, y1, z1))
		surface_tool.add_vertex(Vector3(length, y2, z2))
		
		surface_tool.add_vertex(Vector3(0, y1, z1))
		surface_tool.add_vertex(Vector3(length, y2, z2))
		surface_tool.add_vertex(Vector3(0, y2, z2))
	
	# End caps
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		
		surface_tool.set_color(inner_color)
		# Front cap
		surface_tool.add_vertex(Vector3(0, radius, 0))
		surface_tool.add_vertex(Vector3(0, sin(a1) * radius + radius, cos(a1) * radius))
		surface_tool.add_vertex(Vector3(0, sin(a2) * radius + radius, cos(a2) * radius))
		# Back cap
		surface_tool.add_vertex(Vector3(length, radius, 0))
		surface_tool.add_vertex(Vector3(length, sin(a2) * radius + radius, cos(a2) * radius))
		surface_tool.add_vertex(Vector3(length, sin(a1) * radius + radius, cos(a1) * radius))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	mesh_instance.set_surface_override_material(0, material)
	mesh_instance.rotation.y = randf() * TAU


static func create_tree_stump(mesh_instance: MeshInstance3D) -> void:
	"""Create old tree stump"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bark_color = Color(0.30, 0.22, 0.15)
	var top_color = Color(0.45, 0.38, 0.28)
	
	var height = 0.2 + randf() * 0.25
	var radius = 0.2 + randf() * 0.15
	
	var segments = 8
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		
		var r1 = radius * (0.9 + randf() * 0.2)
		var r2 = radius * (0.9 + randf() * 0.2)
		
		# Side
		surface_tool.set_color(bark_color * (0.85 + randf() * 0.3))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a1) * r1 * 0.9, height, sin(a1) * r1 * 0.9))
		surface_tool.add_vertex(Vector3(cos(a2) * r2 * 0.9, height, sin(a2) * r2 * 0.9))
		
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2 * 0.9, height, sin(a2) * r2 * 0.9))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, 0, sin(a2) * r2))
		
		# Top
		surface_tool.set_color(top_color)
		surface_tool.add_vertex(Vector3(0, height, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * r1 * 0.9, height, sin(a1) * r1 * 0.9))
		surface_tool.add_vertex(Vector3(cos(a2) * r2 * 0.9, height, sin(a2) * r2 * 0.9))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)
