extends Node
class_name MeshBuilder

"""
MeshBuilder - Shared mesh creation utilities

Provides common mesh generation functions used across vegetation and critter visuals.
Reduces code duplication and ensures consistent mesh construction patterns.
"""

## Add a box primitive to a SurfaceTool
static func add_box(surface_tool: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var half_size = size / 2.0
	var corners = [
		center + Vector3(-half_size.x, -half_size.y, -half_size.z),
		center + Vector3(half_size.x, -half_size.y, -half_size.z),
		center + Vector3(half_size.x, -half_size.y, half_size.z),
		center + Vector3(-half_size.x, -half_size.y, half_size.z),
		center + Vector3(-half_size.x, half_size.y, -half_size.z),
		center + Vector3(half_size.x, half_size.y, -half_size.z),
		center + Vector3(half_size.x, half_size.y, half_size.z),
		center + Vector3(-half_size.x, half_size.y, half_size.z)
	]
	
	var faces = [
		[0, 1, 2, 3],  # Bottom
		[4, 7, 6, 5],  # Top
		[0, 4, 5, 1],  # Front
		[2, 6, 7, 3],  # Back
		[1, 5, 6, 2],  # Right
		[0, 3, 7, 4]   # Left
	]
	
	for face in faces:
		surface_tool.set_color(color)
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[1]])
		surface_tool.add_vertex(corners[face[2]])
		
		surface_tool.add_vertex(corners[face[0]])
		surface_tool.add_vertex(corners[face[2]])
		surface_tool.add_vertex(corners[face[3]])

## Finalize a SurfaceTool mesh and apply it to a MeshInstance3D
static func finalize_mesh(surface_tool: SurfaceTool, mesh_instance: MeshInstance3D) -> void:
	surface_tool.generate_normals()
	var array_mesh = surface_tool.commit()
	mesh_instance.mesh = array_mesh

## Create a cylinder mesh with the given parameters
static func create_cylinder(height: float, top_radius: float, bottom_radius: float, radial_segments: int = 8, rings: int = 1) -> CylinderMesh:
	var cylinder = CylinderMesh.new()
	cylinder.height = height
	cylinder.top_radius = top_radius
	cylinder.bottom_radius = bottom_radius
	cylinder.radial_segments = radial_segments
	cylinder.rings = rings
	return cylinder

## Create a sphere mesh with the given parameters
static func create_sphere(radius: float, radial_segments: int = 8, rings: int = 4) -> SphereMesh:
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = radial_segments
	sphere.rings = rings
	return sphere

## Helper to create a disc (flat cylinder) for foliage
static func create_disc(radius: float, thickness: float, radial_segments: int = 8) -> CylinderMesh:
	return create_cylinder(thickness, radius, radius * 0.9, radial_segments, 1)

## Apply a material to all surfaces of a MeshInstance3D
static func apply_material(mesh_instance: MeshInstance3D, material: Material, surface_index: int = 0) -> void:
	mesh_instance.set_surface_override_material(surface_index, material)
