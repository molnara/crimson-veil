class_name DesertMeshes
extends RefCounted

"""
DesertMeshes - Mesh creation for desert biome vegetation

v0.8.0: Extracted from vegetation_spawner.gd

Includes: cacti, dead shrubs, dry grass tufts, bones
"""


static func create_cactus(mesh_instance: MeshInstance3D) -> void:
	"""Create a cactus"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var cactus_color = Color(0.2, 0.5, 0.25)
	var spine_color = Color(0.9, 0.9, 0.8)
	
	var height = 0.8 + randf() * 0.6
	var radius = 0.12 + randf() * 0.06
	
	# Main body - cylinder with ridges
	var segments = 8
	var layers = 6
	
	for layer in range(layers):
		var y1 = (float(layer) / layers) * height
		var y2 = (float(layer + 1) / layers) * height
		var taper = 1.0 - (float(layer) / layers) * 0.2
		
		for seg in range(segments):
			var a1 = (float(seg) / segments) * TAU
			var a2 = (float(seg + 1) / segments) * TAU
			
			# Ridge effect
			var r1 = radius * taper * (0.9 + 0.1 * sin(a1 * 4))
			var r2 = radius * taper * (0.9 + 0.1 * sin(a2 * 4))
			
			surface_tool.set_color(cactus_color * (0.9 + randf() * 0.2))
			surface_tool.add_vertex(Vector3(cos(a1) * r1, y1, sin(a1) * r1))
			surface_tool.add_vertex(Vector3(cos(a2) * r2, y1, sin(a2) * r2))
			surface_tool.add_vertex(Vector3(cos(a1) * r1 * 0.95, y2, sin(a1) * r1 * 0.95))
			
			surface_tool.add_vertex(Vector3(cos(a2) * r2, y1, sin(a2) * r2))
			surface_tool.add_vertex(Vector3(cos(a2) * r2 * 0.95, y2, sin(a2) * r2 * 0.95))
			surface_tool.add_vertex(Vector3(cos(a1) * r1 * 0.95, y2, sin(a1) * r1 * 0.95))
	
	# Top cap
	for seg in range(segments):
		var a1 = (float(seg) / segments) * TAU
		var a2 = (float(seg + 1) / segments) * TAU
		var r = radius * 0.8
		
		surface_tool.set_color(cactus_color * 1.1)
		surface_tool.add_vertex(Vector3(0, height, 0))
		surface_tool.add_vertex(Vector3(cos(a2) * r * 0.8, height * 0.95, sin(a2) * r * 0.8))
		surface_tool.add_vertex(Vector3(cos(a1) * r * 0.8, height * 0.95, sin(a1) * r * 0.8))
	
	# Arms (50% chance)
	if randf() > 0.5:
		var arm_height = height * (0.4 + randf() * 0.2)
		var arm_angle = randf() * TAU
		var arm_length = 0.2 + randf() * 0.15
		var arm_radius = radius * 0.6
		
		# Simple arm - just a small cylinder
		var arm_dir = Vector3(cos(arm_angle), 0.3, sin(arm_angle)).normalized()
		var arm_tip = Vector3(0, arm_height, 0) + arm_dir * arm_length
		
		for seg in range(4):
			var a1 = (float(seg) / 4) * TAU
			var a2 = (float(seg + 1) / 4) * TAU
			
			surface_tool.set_color(cactus_color)
			surface_tool.add_vertex(Vector3(cos(a1) * arm_radius * 0.5 + arm_dir.x * arm_length * 0.3, 
				arm_height, sin(a1) * arm_radius * 0.5 + arm_dir.z * arm_length * 0.3))
			surface_tool.add_vertex(Vector3(cos(a2) * arm_radius * 0.5 + arm_dir.x * arm_length * 0.3,
				arm_height, sin(a2) * arm_radius * 0.5 + arm_dir.z * arm_length * 0.3))
			surface_tool.add_vertex(arm_tip + Vector3(0, 0.1, 0))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.8
	mesh_instance.set_surface_override_material(0, material)


static func create_dead_shrub(mesh_instance: MeshInstance3D) -> void:
	"""Create dried dead shrub for desert"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var dead_color = Color(0.45, 0.35, 0.25)  # Tan/brown
	
	var height = 0.15 + randf() * 0.12
	var width = 0.12 + randf() * 0.08
	
	# Dead branching structure
	var branch_count = 4 + randi() % 4
	for i in range(branch_count):
		var angle = (float(i) / branch_count) * TAU + randf() * 0.5
		var branch_len = height * (0.5 + randf() * 0.5)
		var branch_angle = 0.3 + randf() * 0.5
		
		var tip_x = cos(angle) * sin(branch_angle) * branch_len
		var tip_z = sin(angle) * sin(branch_angle) * branch_len
		var tip_y = cos(branch_angle) * branch_len
		
		var bwidth = 0.008
		surface_tool.set_color(dead_color * (0.8 + randf() * 0.4))
		surface_tool.add_vertex(Vector3(-bwidth, 0.01, 0))
		surface_tool.add_vertex(Vector3(bwidth, 0.01, 0))
		surface_tool.add_vertex(Vector3(tip_x, tip_y, tip_z))
		
		# Sub-branches
		if randf() > 0.5:
			var sub_angle = angle + (randf() - 0.5) * 0.8
			var sub_len = branch_len * 0.5
			var sub_tip = Vector3(tip_x + cos(sub_angle) * sub_len * 0.5,
				tip_y + sub_len * 0.3,
				tip_z + sin(sub_angle) * sub_len * 0.5)
			
			surface_tool.set_color(dead_color * (0.7 + randf() * 0.3))
			surface_tool.add_vertex(Vector3(tip_x - 0.005, tip_y, tip_z))
			surface_tool.add_vertex(Vector3(tip_x + 0.005, tip_y, tip_z))
			surface_tool.add_vertex(sub_tip)
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_dry_grass_tuft(mesh_instance: MeshInstance3D) -> void:
	"""Create tan/brown dry grass for desert"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var dry_color = Color(0.6, 0.5, 0.35)  # Tan
	
	# Sparse blades
	var blade_count = 3 + randi() % 3
	for i in range(blade_count):
		var angle = randf() * TAU
		var dist = randf() * 0.05
		var height = 0.08 + randf() * 0.06
		var blade_width = 0.008
		
		var base_x = cos(angle) * dist
		var base_z = sin(angle) * dist
		
		# Curved drooping blade
		var tip_lean = 0.03 + randf() * 0.03
		var lean_dir = randf() * TAU
		
		surface_tool.set_color(dry_color * (0.8 + randf() * 0.4))
		surface_tool.add_vertex(Vector3(base_x - blade_width, 0, base_z))
		surface_tool.add_vertex(Vector3(base_x + blade_width, 0, base_z))
		surface_tool.add_vertex(Vector3(base_x + cos(lean_dir) * tip_lean, height, base_z + sin(lean_dir) * tip_lean))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.set_surface_override_material(0, material)


static func create_desert_bones(mesh_instance: MeshInstance3D) -> void:
	"""Create scattered bones for desert"""
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bone_color = Color(0.9, 0.88, 0.8)  # Off-white
	
	# Random bone type
	var bone_type = randi() % 3
	
	match bone_type:
		0:  # Long bone
			var length = 0.12 + randf() * 0.08
			var radius = 0.015 + randf() * 0.01
			
			# Simple cylinder lying flat
			for seg in range(6):
				var a1 = (float(seg) / 6) * TAU
				var a2 = (float(seg + 1) / 6) * TAU
				
				surface_tool.set_color(bone_color * (0.9 + randf() * 0.2))
				surface_tool.add_vertex(Vector3(0, sin(a1) * radius + radius, cos(a1) * radius))
				surface_tool.add_vertex(Vector3(length, sin(a1) * radius + radius, cos(a1) * radius))
				surface_tool.add_vertex(Vector3(length, sin(a2) * radius + radius, cos(a2) * radius))
				
				surface_tool.add_vertex(Vector3(0, sin(a1) * radius + radius, cos(a1) * radius))
				surface_tool.add_vertex(Vector3(length, sin(a2) * radius + radius, cos(a2) * radius))
				surface_tool.add_vertex(Vector3(0, sin(a2) * radius + radius, cos(a2) * radius))
		
		1:  # Rib bones
			var count = 2 + randi() % 2
			for i in range(count):
				var offset = i * 0.04
				var curve_height = 0.04 + randf() * 0.02
				var rib_length = 0.06 + randf() * 0.03
				
				surface_tool.set_color(bone_color)
				surface_tool.add_vertex(Vector3(offset, 0.01, 0))
				surface_tool.add_vertex(Vector3(offset + 0.01, 0.01, 0))
				surface_tool.add_vertex(Vector3(offset + rib_length * 0.5, curve_height, rib_length))
		
		2:  # Skull fragment
			var size = 0.04 + randf() * 0.03
			var segments = 5
			for seg in range(segments):
				var a1 = (float(seg) / segments) * TAU
				var a2 = (float(seg + 1) / segments) * TAU
				
				surface_tool.set_color(bone_color * (0.85 + randf() * 0.2))
				surface_tool.add_vertex(Vector3(0, size * 0.5, 0))
				surface_tool.add_vertex(Vector3(cos(a1) * size, 0.01, sin(a1) * size))
				surface_tool.add_vertex(Vector3(cos(a2) * size, 0.01, sin(a2) * size))
	
	surface_tool.generate_normals()
	mesh_instance.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.85
	mesh_instance.set_surface_override_material(0, material)
	
	# Random rotation
	mesh_instance.rotation.y = randf() * TAU
