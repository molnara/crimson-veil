class_name GroundCoverMeshes
extends RefCounted

"""
GroundCoverMeshes - Mesh creation for grass, flowers, and ground cover

v0.8.0: Extracted from vegetation_spawner.gd

Includes: grass, wildflowers, lichen, moss, shells, seaweed, driftwood
"""


static func create_grass_blade_mesh() -> ArrayMesh:
	"""Create a single 3D grass blade mesh for MultiMesh use"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var blade_height = 0.15 + randf() * 0.1
	var blade_width = 0.015
	var curve_amount = 0.03 + randf() * 0.02
	
	var segments = 3
	for seg in range(segments):
		var t1 = float(seg) / segments
		var t2 = float(seg + 1) / segments
		
		var y1 = t1 * blade_height
		var y2 = t2 * blade_height
		var curve1 = sin(t1 * PI) * curve_amount
		var curve2 = sin(t2 * PI) * curve_amount
		var width1 = blade_width * (1.0 - t1 * 0.7)
		var width2 = blade_width * (1.0 - t2 * 0.7)
		
		surface_tool.set_color(Color(0.3, 0.6, 0.2))
		surface_tool.add_vertex(Vector3(-width1, y1, curve1))
		surface_tool.add_vertex(Vector3(width1, y1, curve1))
		surface_tool.add_vertex(Vector3(width2, y2, curve2))
		
		surface_tool.add_vertex(Vector3(-width1, y1, curve1))
		surface_tool.add_vertex(Vector3(width2, y2, curve2))
		surface_tool.add_vertex(Vector3(-width2, y2, curve2))
	
	surface_tool.generate_normals()
	return surface_tool.commit()


static func create_wildflower(mesh_instance: MeshInstance3D, flower_color: Color) -> void:
	"""Create a wildflower"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var stem_color = Color(0.25, 0.45, 0.2)
	var stem_height = 0.12 + randf() * 0.08
	var flower_size = 0.025 + randf() * 0.015
	
	surface_tool.set_color(stem_color)
	surface_tool.add_vertex(Vector3(-0.008, 0, 0))
	surface_tool.add_vertex(Vector3(0.008, 0, 0))
	surface_tool.add_vertex(Vector3(0, stem_height, 0))
	
	var petal_count = 5
	for i in range(petal_count):
		var angle = (float(i) / petal_count) * TAU
		var next_angle = (float(i + 1) / petal_count) * TAU
		
		surface_tool.set_color(flower_color)
		surface_tool.add_vertex(Vector3(0, stem_height, 0))
		surface_tool.add_vertex(Vector3(cos(angle) * flower_size, stem_height + 0.01, sin(angle) * flower_size))
		surface_tool.add_vertex(Vector3(cos(next_angle) * flower_size, stem_height + 0.01, sin(next_angle) * flower_size))
	
	surface_tool.set_color(Color(1.0, 0.9, 0.3))
	for i in range(5):
		var angle = (float(i) / 5) * TAU
		var next_angle = (float(i + 1) / 5) * TAU
		surface_tool.add_vertex(Vector3(0, stem_height + 0.015, 0))
		surface_tool.add_vertex(Vector3(cos(angle) * flower_size * 0.3, stem_height + 0.012, sin(angle) * flower_size * 0.3))
		surface_tool.add_vertex(Vector3(cos(next_angle) * flower_size * 0.3, stem_height + 0.012, sin(next_angle) * flower_size * 0.3))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_mountain_flower(mesh_instance: MeshInstance3D) -> void:
	"""Create hardy alpine flower"""
	var color_rand = randf()
	var flower_color: Color
	if color_rand > 0.6:
		flower_color = Color(0.7, 0.5, 0.9)
	elif color_rand > 0.3:
		flower_color = Color(1.0, 1.0, 0.9)
	else:
		flower_color = Color(1.0, 0.9, 0.3)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var stem_height = 0.08 + randf() * 0.06
	var petal_size = 0.03 + randf() * 0.02
	
	surface_tool.set_color(Color(0.3, 0.45, 0.25))
	surface_tool.add_vertex(Vector3(-0.01, 0, 0))
	surface_tool.add_vertex(Vector3(0.01, 0, 0))
	surface_tool.add_vertex(Vector3(0, stem_height, 0))
	
	for i in range(5):
		var a1 = (float(i) / 5) * TAU
		var a2 = (float(i + 1) / 5) * TAU
		
		surface_tool.set_color(flower_color)
		surface_tool.add_vertex(Vector3(0, stem_height, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * petal_size, stem_height, sin(a1) * petal_size))
		surface_tool.add_vertex(Vector3(cos(a2) * petal_size, stem_height, sin(a2) * petal_size))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_mountain_lichen(mesh_instance: MeshInstance3D) -> void:
	"""Create lichen patch"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var color_rand = randf()
	var lichen_color: Color
	if color_rand > 0.6:
		lichen_color = Color(0.65, 0.70, 0.50)
	elif color_rand > 0.3:
		lichen_color = Color(0.50, 0.55, 0.45)
	else:
		lichen_color = Color(0.60, 0.55, 0.45)
	
	var radius = 0.08 + randf() * 0.06
	var points = 5 + randi() % 3
	
	for i in range(points):
		var a1 = (float(i) / points) * TAU
		var a2 = (float(i + 1) / points) * TAU
		var r1 = radius * (0.7 + randf() * 0.3)
		var r2 = radius * (0.7 + randf() * 0.3)
		
		surface_tool.set_color(lichen_color * (0.9 + randf() * 0.2))
		surface_tool.add_vertex(Vector3(0, 0.005, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0.005, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, 0.005, sin(a2) * r2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)


static func create_moss_patch(mesh_instance: MeshInstance3D) -> void:
	"""Create green moss patch"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var moss_color = Color(0.25, 0.45, 0.20)
	var radius = 0.12 + randf() * 0.1
	var points = 6 + randi() % 3
	
	for i in range(points):
		var a1 = (float(i) / points) * TAU
		var a2 = (float(i + 1) / points) * TAU
		var r1 = radius * (0.6 + randf() * 0.4)
		var r2 = radius * (0.6 + randf() * 0.4)
		var h1 = 0.02 + randf() * 0.03
		var h2 = 0.02 + randf() * 0.03
		
		surface_tool.set_color(moss_color * (0.8 + randf() * 0.4))
		surface_tool.add_vertex(Vector3(0, 0.02, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, h1, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, h2, sin(a2) * r2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	mesh_instance.set_surface_override_material(0, material)


static func create_alpine_grass(mesh_instance: MeshInstance3D) -> void:
	"""Create sparse alpine grass"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var grass_color = Color(0.4, 0.5, 0.35)
	var blade_count = 3 + randi() % 3
	
	for i in range(blade_count):
		var angle = randf() * TAU
		var dist = randf() * 0.04
		var height = 0.06 + randf() * 0.05
		
		var base_x = cos(angle) * dist
		var base_z = sin(angle) * dist
		
		surface_tool.set_color(grass_color * (0.8 + randf() * 0.4))
		surface_tool.add_vertex(Vector3(base_x - 0.008, 0, base_z))
		surface_tool.add_vertex(Vector3(base_x + 0.008, 0, base_z))
		surface_tool.add_vertex(Vector3(base_x, height, base_z))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_beach_shell(mesh_instance: MeshInstance3D) -> void:
	"""Create seashell"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var shell_color = Color(0.95, 0.90, 0.85)
	if randf() > 0.7:
		shell_color = Color(0.9, 0.75, 0.7)
	
	var size = 0.03 + randf() * 0.025
	
	for seg in range(6):
		var a1 = (float(seg) / 6) * PI
		var a2 = (float(seg + 1) / 6) * PI
		
		surface_tool.set_color(shell_color * (0.9 + randf() * 0.2))
		surface_tool.add_vertex(Vector3(0, 0.005, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * size, 0.01, sin(a1) * size * 0.5))
		surface_tool.add_vertex(Vector3(cos(a2) * size, 0.01, sin(a2) * size * 0.5))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.4
	mesh_instance.set_surface_override_material(0, material)
	mesh_instance.rotation.y = randf() * TAU


static func create_beach_seaweed(mesh_instance: MeshInstance3D) -> void:
	"""Create washed up seaweed"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var seaweed_color = Color(0.2, 0.35, 0.15)
	var strand_count = 2 + randi() % 3
	
	for s in range(strand_count):
		var length = 0.1 + randf() * 0.08
		var width = 0.015 + randf() * 0.01
		var start_x = (randf() - 0.5) * 0.05
		var start_z = (randf() - 0.5) * 0.05
		var angle = randf() * TAU
		
		for seg in range(3):
			var t1 = float(seg) / 3
			var t2 = float(seg + 1) / 3
			var wave1 = sin(t1 * PI * 2) * 0.02
			var wave2 = sin(t2 * PI * 2) * 0.02
			
			var x1 = start_x + cos(angle) * t1 * length
			var z1 = start_z + sin(angle) * t1 * length + wave1
			var x2 = start_x + cos(angle) * t2 * length
			var z2 = start_z + sin(angle) * t2 * length + wave2
			
			surface_tool.set_color(seaweed_color * (0.8 + randf() * 0.4))
			surface_tool.add_vertex(Vector3(x1 - width * 0.5, 0.005, z1))
			surface_tool.add_vertex(Vector3(x1 + width * 0.5, 0.005, z1))
			surface_tool.add_vertex(Vector3(x2, 0.008, z2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_beach_driftwood(mesh_instance: MeshInstance3D) -> void:
	"""Create small driftwood piece"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var wood_color = Color(0.55, 0.50, 0.45)
	var length = 0.1 + randf() * 0.1
	var radius = 0.012 + randf() * 0.008
	
	for seg in range(6):
		var a1 = (float(seg) / 6) * TAU
		var a2 = (float(seg + 1) / 6) * TAU
		
		var y1 = sin(a1) * radius + radius
		var z1 = cos(a1) * radius
		var y2 = sin(a2) * radius + radius
		var z2 = cos(a2) * radius
		
		surface_tool.set_color(wood_color * (0.85 + randf() * 0.3))
		surface_tool.add_vertex(Vector3(0, y1, z1))
		surface_tool.add_vertex(Vector3(length, y1, z1))
		surface_tool.add_vertex(Vector3(length, y2, z2))
		
		surface_tool.add_vertex(Vector3(0, y1, z1))
		surface_tool.add_vertex(Vector3(length, y2, z2))
		surface_tool.add_vertex(Vector3(0, y2, z2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)
	mesh_instance.rotation.y = randf() * TAU
