extends Node3D
class_name StorageContainer

"""
StorageContainer - Placeable chest with independent inventory

ARCHITECTURE:
- Extends Node3D (not StaticBody3D, that's a child)
- Child: StaticBody3D on Layer 3 for raycast interaction
- Child: MeshInstance3D for visual representation
- Has own Inventory instance for storage

INTEGRATION:
- Placed by BuildingSystem (like blocks but with is_container flag)
- Interacted via Player raycast on Layer 3 (3m range)
- Opens Container UI when player presses E or A button

COLLISION LAYERS:
- Layer 3 (interactive objects) - player raycasts this
- Not Layer 1 (terrain) - containers don't block movement pathfinding
"""

# Container properties
@export var container_name: String = "Chest"
@export var slot_count: int = 32  # Same as player inventory

# State
var inventory: Inventory
var is_open: bool = false
var world_position: Vector3 = Vector3.ZERO

# Visual components
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

# Signals for UI integration
signal container_opened(container: StorageContainer)
signal container_closed(container: StorageContainer)
signal inventory_changed()

func _ready():
	# Create inventory instance
	inventory = Inventory.new()
	add_child(inventory)
	
	# Connect inventory signals
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	print("StorageContainer initialized at ", global_position)

func initialize(pos: Vector3):
	"""Initialize container at a specific world position"""
	world_position = pos
	global_position = pos
	
	# Create visual mesh
	create_visual()
	
	# Create collision for interaction
	create_collision()
	
	print("Container created at: ", pos)

func create_visual():
	"""Create the low-poly chest mesh with 16x16 texture"""
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create chest mesh (low-poly cube with lid details)
	var mesh = create_chest_mesh()
	mesh_instance.mesh = mesh
	
	# Create material with chest texture
	var texture = PixelTextureGenerator.create_chest_texture()
	var material = PixelTextureGenerator.create_pixel_material(texture)
	mesh_instance.material_override = material
	
	print("Container visual created")

func create_chest_mesh() -> ArrayMesh:
	"""Create a low-poly chest mesh (1x0.8x0.8 meters with slight taper)"""
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	# Vertices for a chest (slightly smaller than 1x1x1 to fit in grid nicely)
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Chest dimensions (slightly smaller than grid cell)
	var width = 0.9
	var height = 0.7
	var depth = 0.8
	
	# Bottom vertices (y = 0)
	var v0 = Vector3(-width/2, 0, -depth/2)
	var v1 = Vector3(width/2, 0, -depth/2)
	var v2 = Vector3(width/2, 0, depth/2)
	var v3 = Vector3(-width/2, 0, depth/2)
	
	# Top vertices (y = height)
	var v4 = Vector3(-width/2, height, -depth/2)
	var v5 = Vector3(width/2, height, -depth/2)
	var v6 = Vector3(width/2, height, depth/2)
	var v7 = Vector3(-width/2, height, depth/2)
	
	# Front face
	vertices.append(v0)
	vertices.append(v1)
	vertices.append(v5)
	vertices.append(v4)
	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(0, 0, -1))
	normals.append(Vector3(0, 0, -1))
	normals.append(Vector3(0, 0, -1))
	normals.append(Vector3(0, 0, -1))
	
	# Back face
	vertices.append(v2)
	vertices.append(v3)
	vertices.append(v7)
	vertices.append(v6)
	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(0, 0, 1))
	normals.append(Vector3(0, 0, 1))
	normals.append(Vector3(0, 0, 1))
	normals.append(Vector3(0, 0, 1))
	
	# Left face
	vertices.append(v3)
	vertices.append(v0)
	vertices.append(v4)
	vertices.append(v7)
	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(-1, 0, 0))
	normals.append(Vector3(-1, 0, 0))
	normals.append(Vector3(-1, 0, 0))
	normals.append(Vector3(-1, 0, 0))
	
	# Right face
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v6)
	vertices.append(v5)
	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(1, 0, 0))
	normals.append(Vector3(1, 0, 0))
	normals.append(Vector3(1, 0, 0))
	normals.append(Vector3(1, 0, 0))
	
	# Top face
	vertices.append(v4)
	vertices.append(v5)
	vertices.append(v6)
	vertices.append(v7)
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(0, 1))
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	normals.append(Vector3(0, 1, 0))
	
	# Bottom face
	vertices.append(v3)
	vertices.append(v2)
	vertices.append(v1)
	vertices.append(v0)
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(0, 1))
	normals.append(Vector3(0, -1, 0))
	normals.append(Vector3(0, -1, 0))
	normals.append(Vector3(0, -1, 0))
	normals.append(Vector3(0, -1, 0))
	
	# Build indices (two triangles per quad)
	for i in range(6):  # 6 faces
		var base = i * 4
		indices.append(base + 0)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 0)
		indices.append(base + 2)
		indices.append(base + 3)
	
	# Set arrays
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	# Create mesh
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	return array_mesh

func create_collision():
	"""Create collision body for raycast interaction (Layer 3)"""
	static_body = StaticBody3D.new()
	add_child(static_body)
	
	# CRITICAL: Layer 3 for interactive objects
	# Layer mask 4 = Layer 3 (2^2 = 4)
	static_body.collision_layer = 4  # Layer 3
	static_body.collision_mask = 0   # Don't collide with anything
	
	# Create collision shape
	collision_shape = CollisionShape3D.new()
	static_body.add_child(collision_shape)
	
	# Box shape matching chest dimensions
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.7, 0.8)  # Match chest mesh size
	collision_shape.shape = box_shape
	
	# Position collision at center of chest
	collision_shape.position = Vector3(0, 0.35, 0)  # Half of height
	
	print("Container collision created on Layer 3")

func open():
	"""Open the container (called by player interaction)"""
	if is_open:
		print("Container already open")
		return
	
	is_open = true
	emit_signal("container_opened", self)
	print("Container opened: ", container_name)

func close():
	"""Close the container"""
	if not is_open:
		return
	
	is_open = false
	emit_signal("container_closed", self)
	print("Container closed: ", container_name)

func get_inventory() -> Inventory:
	"""Get the container's inventory instance"""
	return inventory

func has_items() -> bool:
	"""Check if container has any items"""
	if not inventory:
		return false
	return inventory.items.size() > 0

func get_item_count() -> int:
	"""Get total number of item types in container"""
	if not inventory:
		return 0
	return inventory.items.size()

func _on_inventory_changed():
	"""Relay inventory changes to listeners"""
	emit_signal("inventory_changed")

func get_mesh_instance() -> MeshInstance3D:
	"""Get the mesh instance for highlighting"""
	return mesh_instance
