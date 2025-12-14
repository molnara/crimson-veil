class_name TreeMeshes
extends RefCounted

"""
TreeMeshes - Mesh creation for all tree types

v0.8.0: Extracted from vegetation_spawner.gd

Note: Tree visuals are created by visual generator classes that take
a spawner reference for configuration parameters.
"""


static func create_tree(mesh_instance: MeshInstance3D, spawner) -> void:
	"""Create a harvestable oak tree"""
	var TreeVisual = load("res://vegetation/visuals/tree_visual.gd")
	TreeVisual.create(mesh_instance, spawner)


static func create_pine_tree(mesh_instance: MeshInstance3D, spawner) -> void:
	"""Create a harvestable pine tree"""
	var PineTreeVisual = load("res://vegetation/visuals/pine_tree_visual.gd")
	PineTreeVisual.create(mesh_instance, spawner)


static func create_palm_tree(mesh_instance: MeshInstance3D, spawner) -> void:
	"""Create a harvestable palm tree"""
	var PalmTreeVisual = load("res://vegetation/visuals/palm_tree_visual.gd")
	PalmTreeVisual.create(mesh_instance, spawner)


static func create_snow_pine_tree(mesh_instance: MeshInstance3D, spawner) -> void:
	"""Create a snow-covered pine tree"""
	# First create normal pine tree
	var PineTreeVisual = load("res://vegetation/visuals/pine_tree_visual.gd")
	PineTreeVisual.create(mesh_instance, spawner)
	
	# Add snow caps on top
	var snow_mesh = MeshInstance3D.new()
	mesh_instance.add_child(snow_mesh)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var snow_color = Color(0.95, 0.97, 1.0)
	var tree_height = 4.0 + randf() * 3.0
	
	# Add snow patches on branches
	for layer in range(3):
		var y = tree_height * (0.4 + layer * 0.2)
		var radius = 0.8 - layer * 0.15
		
		var segments = 6
		for seg in range(segments):
			var a1 = (float(seg) / segments) * TAU
			var a2 = (float(seg + 1) / segments) * TAU
			
			surface_tool.set_color(snow_color)
			surface_tool.add_vertex(Vector3(0, y + 0.1, 0))
			surface_tool.add_vertex(Vector3(cos(a1) * radius * 0.7, y + 0.05, sin(a1) * radius * 0.7))
			surface_tool.add_vertex(Vector3(cos(a2) * radius * 0.7, y + 0.05, sin(a2) * radius * 0.7))
	
	surface_tool.generate_normals()
	snow_mesh.mesh = surface_tool.commit()
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	snow_mesh.set_surface_override_material(0, material)
