class_name SnowMeshes
extends RefCounted

"""
SnowMeshes - Mesh creation for snow biome vegetation

v0.8.0: Extracted from vegetation_spawner.gd

Includes: snow mounds, ice crystals, icicles, frozen lake edges,
          frozen shrubs, berry bushes
"""


static func create_snow_mound(mesh_instance: MeshInstance3D) -> void:
	"""Create small snow pile/mound"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var snow_color = Color(0.95, 0.97, 1.0)
	var radius = 0.15 + randf() * 0.15
	var height = 0.08 + randf() * 0.08
	
	# Dome shape
	var segments = 8
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		var r1 = radius * (0.8 + randf() * 0.2)
		var r2 = radius * (0.8 + randf() * 0.2)
		
		surface_tool.set_color(snow_color * (0.95 + randf() * 0.1))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, 0, sin(a2) * r2))
		surface_tool.add_vertex(Vector3(0, height, 0))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	mesh_instance.set_surface_override_material(0, material)


static func create_ice_crystal(mesh_instance: MeshInstance3D) -> void:
	"""Create ice crystal formation"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var ice_color = Color(0.75, 0.88, 1.0, 0.85)
	
	# Create 2-4 crystal spikes
	var crystal_count = 2 + randi() % 3
	
	for i in range(crystal_count):
		var offset_x = (randf() - 0.5) * 0.15
		var offset_z = (randf() - 0.5) * 0.15
		var height = 0.15 + randf() * 0.2
		var width = 0.03 + randf() * 0.03
		
		# Crystal spike (4-sided pyramid)
		var tip = Vector3(offset_x, height, offset_z)
		
		surface_tool.set_color(ice_color)
		# Front
		surface_tool.add_vertex(Vector3(offset_x - width, 0, offset_z - width))
		surface_tool.add_vertex(Vector3(offset_x + width, 0, offset_z - width))
		surface_tool.add_vertex(tip)
		# Right
		surface_tool.add_vertex(Vector3(offset_x + width, 0, offset_z - width))
		surface_tool.add_vertex(Vector3(offset_x + width, 0, offset_z + width))
		surface_tool.add_vertex(tip)
		# Back
		surface_tool.add_vertex(Vector3(offset_x + width, 0, offset_z + width))
		surface_tool.add_vertex(Vector3(offset_x - width, 0, offset_z + width))
		surface_tool.add_vertex(tip)
		# Left
		surface_tool.add_vertex(Vector3(offset_x - width, 0, offset_z + width))
		surface_tool.add_vertex(Vector3(offset_x - width, 0, offset_z - width))
		surface_tool.add_vertex(tip)
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	material.metallic = 0.2
	mesh_instance.set_surface_override_material(0, material)


static func create_icicle_cluster(mesh_instance: MeshInstance3D) -> void:
	"""Create hanging icicles cluster"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var ice_color = Color(0.75, 0.88, 1.0, 0.85)
	
	# Create 3-6 icicles
	var icicle_count = 3 + randi() % 4
	
	for i in range(icicle_count):
		var offset_x = (randf() - 0.5) * 0.3
		var offset_z = (randf() - 0.5) * 0.3
		var length = 0.15 + randf() * 0.25
		var width = 0.02 + randf() * 0.02
		
		# Icicle pointing down (inverted cone)
		var tip = Vector3(offset_x, -length, offset_z)
		
		surface_tool.set_color(ice_color)
		surface_tool.add_vertex(Vector3(offset_x - width, 0, offset_z))
		surface_tool.add_vertex(Vector3(offset_x + width, 0, offset_z))
		surface_tool.add_vertex(tip)
		
		surface_tool.add_vertex(Vector3(offset_x, 0, offset_z - width))
		surface_tool.add_vertex(Vector3(offset_x, 0, offset_z + width))
		surface_tool.add_vertex(tip)
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.1
	material.metallic = 0.2
	mesh_instance.set_surface_override_material(0, material)
	
	# Position above ground (as if hanging from something)
	mesh_instance.position.y += 0.5


static func create_frozen_lake_edge(mesh_instance: MeshInstance3D) -> void:
	"""Create ice sheet edge decoration"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var ice_color = Color(0.8, 0.9, 1.0, 0.7)
	var size = 0.4 + randf() * 0.4
	
	# Flat irregular ice sheet
	var points = 5 + randi() % 3
	for i in range(points):
		var a1 = (float(i) / points) * TAU
		var a2 = (float(i + 1) / points) * TAU
		var r1 = size * (0.6 + randf() * 0.4)
		var r2 = size * (0.6 + randf() * 0.4)
		
		surface_tool.set_color(ice_color)
		surface_tool.add_vertex(Vector3(0, 0.02, 0))
		surface_tool.add_vertex(Vector3(cos(a1) * r1, 0.01, sin(a1) * r1))
		surface_tool.add_vertex(Vector3(cos(a2) * r2, 0.01, sin(a2) * r2))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.05
	material.metallic = 0.1
	mesh_instance.set_surface_override_material(0, material)


static func create_frozen_shrub(mesh_instance: MeshInstance3D) -> void:
	"""Create frost-covered shrub"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var frost_color = Color(0.8, 0.85, 0.9)  # Pale blue-gray
	var branch_color = Color(0.4, 0.35, 0.3)
	
	var height = 0.2 + randf() * 0.15
	var width = 0.15 + randf() * 0.1
	
	# Bare branches with frost
	var branch_count = 4 + randi() % 3
	for i in range(branch_count):
		var angle = (float(i) / branch_count) * TAU + randf() * 0.3
		var branch_len = height * (0.6 + randf() * 0.4)
		var branch_angle = 0.5 + randf() * 0.4
		
		var tip_x = cos(angle) * sin(branch_angle) * branch_len
		var tip_z = sin(angle) * sin(branch_angle) * branch_len
		var tip_y = cos(branch_angle) * branch_len
		
		var bwidth = 0.012
		# Branch
		surface_tool.set_color(branch_color)
		surface_tool.add_vertex(Vector3(-bwidth, 0.02, 0))
		surface_tool.add_vertex(Vector3(bwidth, 0.02, 0))
		surface_tool.add_vertex(Vector3(tip_x, tip_y, tip_z))
		
		# Frost on tip
		surface_tool.set_color(frost_color)
		surface_tool.add_vertex(Vector3(tip_x - 0.02, tip_y, tip_z))
		surface_tool.add_vertex(Vector3(tip_x + 0.02, tip_y, tip_z))
		surface_tool.add_vertex(Vector3(tip_x, tip_y + 0.03, tip_z))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)


static func create_berry_bush_snow(mesh_instance: MeshInstance3D) -> void:
	"""Create frozen berry bush with red berries"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var branch_color = Color(0.75, 0.80, 0.85)  # Frosted branches
	var berry_color = Color(0.8, 0.15, 0.15)   # Red berries
	
	var height = 0.25 + randf() * 0.15
	var width = 0.2 + randf() * 0.1
	
	# Frosted branches
	var branch_count = 4 + randi() % 3
	for i in range(branch_count):
		var angle = (float(i) / branch_count) * TAU + randf() * 0.3
		var branch_len = height * (0.6 + randf() * 0.4)
		var branch_angle = 0.4 + randf() * 0.3
		
		var tip_x = cos(angle) * sin(branch_angle) * branch_len
		var tip_z = sin(angle) * sin(branch_angle) * branch_len
		var tip_y = cos(branch_angle) * branch_len
		
		var bwidth = 0.015
		surface_tool.set_color(branch_color)
		surface_tool.add_vertex(Vector3(-bwidth, 0.02, 0))
		surface_tool.add_vertex(Vector3(bwidth, 0.02, 0))
		surface_tool.add_vertex(Vector3(tip_x, tip_y, tip_z))
	
	# Add red berries
	var berry_count = 3 + randi() % 4
	for b in range(berry_count):
		var bx = (randf() - 0.5) * width
		var bz = (randf() - 0.5) * width
		var by = 0.1 + randf() * (height - 0.1)
		var berry_size = 0.02 + randf() * 0.01
		
		surface_tool.set_color(berry_color)
		surface_tool.add_vertex(Vector3(bx, by + berry_size, bz))
		surface_tool.add_vertex(Vector3(bx - berry_size, by, bz))
		surface_tool.add_vertex(Vector3(bx + berry_size, by, bz))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.7
	mesh_instance.set_surface_override_material(0, material)
