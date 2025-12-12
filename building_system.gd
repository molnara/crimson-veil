extends Node3D
class_name BuildingSystem

# References
var player: Node3D
var camera: Camera3D
var inventory: Inventory
var warning_ui: Control  # Container warning dialog

# Building settings
@export var placement_range: float = 5.0  # How far you can place blocks
@export var grid_size: float = 1.0  # 1 meter grid

# Current state
var preview_mode: bool = false
var current_block_type: String = "stone_block"
var preview_mesh: MeshInstance3D = null
var placement_position: Vector3 = Vector3.ZERO
var can_place: bool = false

# Placed blocks tracking
var placed_blocks: Dictionary = {}  # position -> block_data

# Block definitions
var block_types = {
	"stone_block": {
		"name": "Stone Block",
		"cost": {"stone": 5},
		"mesh_type": "cube",
		"material_color": Color(0.5, 0.5, 0.5),
		"size": Vector3(1, 1, 1)
	},
	"stone_wall": {
		"name": "Stone Wall",
		"cost": {"stone": 3},
		"mesh_type": "cube",
		"material_color": Color(0.6, 0.6, 0.6),
		"size": Vector3(1, 2, 0.2)  # Tall and thin
	},
	"stone_floor": {
		"name": "Stone Floor",
		"cost": {"stone": 2},
		"mesh_type": "cube",
		"material_color": Color(0.55, 0.55, 0.55),
		"size": Vector3(1, 0.1, 1)  # Flat
	},
	"wood_plank": {
		"name": "Wood Plank",
		"cost": {"wood": 2},
		"mesh_type": "cube",
		"material_color": Color(0.6, 0.4, 0.2),
		"size": Vector3(1, 1, 1)
	},
	"chest": {
		"name": "Chest",
		"cost": {"wood": 10},
		"mesh_type": "container",  # Special type
		"material_color": Color(0.4, 0.25, 0.15),
		"size": Vector3(1, 1, 1),
		"is_container": true  # Flag for special handling
	}
}

# Signals
signal block_placed(block_type: String, position: Vector3)
signal block_removed(block_type: String, position: Vector3)
signal preview_updated(can_place: bool, position: Vector3)

func _ready():
	# Create preview mesh
	create_preview_mesh()
	
	# Create warning UI (deferred to avoid issues with scene tree)
	call_deferred("create_warning_ui")

func create_warning_ui():
	"""Create the container warning dialog"""
	var warning_script = load("res://container_warning_ui.gd")
	if warning_script:
		warning_ui = warning_script.new()
		get_tree().root.add_child(warning_ui)
		warning_ui.remove_confirmed.connect(_on_container_remove_confirmed)
		warning_ui.remove_cancelled.connect(_on_container_remove_cancelled)
		print("Container warning UI created")
	else:
		print("Warning: Could not load container_warning_ui.gd")

func initialize(p: Node3D, cam: Camera3D, inv: Inventory):
	"""Initialize with player, camera, and inventory references"""
	player = p
	camera = cam
	inventory = inv

func _process(delta: float):
	if not preview_mode:
		return
	
	update_preview()

func create_preview_mesh():
	"""Create the ghost preview mesh"""
	preview_mesh = MeshInstance3D.new()
	add_child(preview_mesh)
	
	# Create a basic cube mesh
	var mesh = BoxMesh.new()
	preview_mesh.mesh = mesh
	
	# Create semi-transparent material
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1, 1, 1, 0.5)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	preview_mesh.material_override = material
	
	preview_mesh.visible = false

func update_preview():
	"""Update the preview mesh position and validity"""
	if not camera or not preview_mesh:
		return
	
	# Raycast from camera
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * placement_range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Only hit terrain (layer 1)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result:
		# Snap to grid
		var hit_point = result.position
		var snapped_pos = snap_to_grid(hit_point)
		
		# Offset up by half the block height so it sits on the surface
		var block_def = block_types[current_block_type]
		snapped_pos.y += block_def["size"].y / 2.0
		
		placement_position = snapped_pos
		
		# Check if we can place here (not overlapping existing blocks)
		can_place = check_can_place(snapped_pos)
		
		# Update preview mesh
		preview_mesh.global_position = snapped_pos
		preview_mesh.visible = true
		
		# Update preview mesh size and color
		var mesh = preview_mesh.mesh as BoxMesh
		mesh.size = block_def["size"]
		
		# Green if can place, red if cannot
		var material = preview_mesh.material_override as StandardMaterial3D
		if can_place:
			material.albedo_color = Color(0, 1, 0, 0.5)  # Green
		else:
			material.albedo_color = Color(1, 0, 0, 0.5)  # Red
		
		emit_signal("preview_updated", can_place, snapped_pos)
	else:
		# No surface hit, hide preview
		preview_mesh.visible = false
		can_place = false

func snap_to_grid(pos: Vector3) -> Vector3:
	"""Snap a position to the grid"""
	return Vector3(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
		round(pos.z / grid_size) * grid_size
	)

func check_can_place(pos: Vector3) -> bool:
	"""Check if we can place a block at this position"""
	# Check if position is already occupied
	var pos_key = position_to_key(pos)
	if placed_blocks.has(pos_key):
		return false
	
	# Check if player has required resources
	var block_def = block_types[current_block_type]
	for item in block_def["cost"]:
		var required = block_def["cost"][item]
		if not inventory.has_item(item, required):
			return false
	
	return true

func position_to_key(pos: Vector3) -> String:
	"""Convert position to dictionary key"""
	return "%d,%d,%d" % [int(pos.x * 10), int(pos.y * 10), int(pos.z * 10)]

func enable_building_mode(block_type: String = "stone_block"):
	"""Enable building mode with the specified block type"""
	if not block_types.has(block_type):
		print("Invalid block type: ", block_type)
		return
	
	current_block_type = block_type
	preview_mode = true
	
	# Play build mode toggle sound
	AudioManager.play_sound("build_mode_toggle", "ui")
	
	print("Building mode enabled: ", block_types[block_type]["name"])

func disable_building_mode():
	"""Disable building mode"""
	preview_mode = false
	if preview_mesh:
		preview_mesh.visible = false
	
	# Play build mode toggle sound
	AudioManager.play_sound("build_mode_toggle", "ui")
	
	print("Building mode disabled")

func place_block() -> bool:
	"""Attempt to place a block at the current preview position"""
	if not preview_mode or not can_place:
		print("Cannot place block")
		return false
	
	var block_def = block_types[current_block_type]
	
	# Deduct resources from inventory
	for item in block_def["cost"]:
		var cost = block_def["cost"][item]
		inventory.remove_item(item, cost)
	
	# Check if this is a container block (special handling)
	if block_def.get("is_container", false):
		# Create StorageContainer instead of regular block
		var container_script = load("res://storage_container.gd")
		var container = container_script.new()
		get_tree().root.add_child(container)
		
		# Containers sit ON the surface (bottom at ground level), not centered
		# Regular blocks are centered (offset by half height), containers are not
		var container_position = placement_position
		container_position.y -= block_def["size"].y / 2.0  # Undo the preview offset
		container.initialize(container_position)
		
		# Store container reference
		var pos_key = position_to_key(placement_position)
		placed_blocks[pos_key] = {
			"type": current_block_type,
			"position": placement_position,
			"node": container,
			"is_container": true
		}
		
		# Play block placement sound
		AudioManager.play_sound("block_place", "sfx")
		
		emit_signal("block_placed", current_block_type, placement_position)
		print("Placed ", block_def["name"], " at ", placement_position)
		return true
	
	# Regular block placement (existing code)
	var block = MeshInstance3D.new()
	get_tree().root.add_child(block)
	
	# Create mesh
	var mesh = BoxMesh.new()
	mesh.size = block_def["size"]
	block.mesh = mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = block_def["material_color"]
	block.material_override = material
	
	# Add collision
	var static_body = StaticBody3D.new()
	block.add_child(static_body)
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = block_def["size"]
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	
	# Position the block
	block.global_position = placement_position
	
	# Store block data
	var pos_key = position_to_key(placement_position)
	placed_blocks[pos_key] = {
		"type": current_block_type,
		"position": placement_position,
		"node": block
	}
	
	# Play block placement sound
	AudioManager.play_sound("block_place", "sfx")
	
	emit_signal("block_placed", current_block_type, placement_position)
	print("Placed ", block_def["name"], " at ", placement_position)
	
	return true

func remove_block_at_position(pos: Vector3) -> bool:
	"""Remove a block at the given position and refund resources"""
	var pos_key = position_to_key(pos)
	
	if not placed_blocks.has(pos_key):
		return false
	
	var block_data = placed_blocks[pos_key]
	var block_type = block_data["type"]
	var block_def = block_types[block_type]
	
	# Check if this is a container with items
	if block_data.get("is_container", false):
		var container = block_data["node"]
		if container.has_method("has_items") and container.has_items():
			# Container has items - show warning UI
			if warning_ui:
				var item_count = container.get_item_count()
				warning_ui.show_warning(container, item_count, pos)
			else:
				print("Cannot remove container - has items inside! (Warning UI not available)")
			return false
	
	# Refund resources
	for item in block_def["cost"]:
		var amount = block_def["cost"][item]
		inventory.add_item(item, amount)
	
	# Remove the block node
	block_data["node"].queue_free()
	
	# Remove from tracking
	placed_blocks.erase(pos_key)
	
	# Play block removal sound
	AudioManager.play_sound("block_remove", "sfx")
	
	emit_signal("block_removed", block_type, pos)
	print("Removed ", block_def["name"], " from ", pos)
	
	return true

func _on_container_remove_confirmed(pos: Vector3):
	"""User confirmed removal of container with items - force remove"""
	var pos_key = position_to_key(pos)
	
	if not placed_blocks.has(pos_key):
		return
	
	var block_data = placed_blocks[pos_key]
	var block_type = block_data["type"]
	var block_def = block_types[block_type]
	
	# TODO: Drop items to ground (next phase)
	print("Dropping container items to ground...")
	
	# Refund resources
	for item in block_def["cost"]:
		var amount = block_def["cost"][item]
		inventory.add_item(item, amount)
	
	# Remove the block node
	block_data["node"].queue_free()
	
	# Remove from tracking
	placed_blocks.erase(pos_key)
	
	# Play block removal sound
	AudioManager.play_sound("block_remove", "sfx")
	
	emit_signal("block_removed", block_type, pos)
	print("Removed ", block_def["name"], " (forced)")

func _on_container_remove_cancelled():
	"""User cancelled container removal"""
	print("Container removal cancelled by user")

func get_block_at_raycast() -> Dictionary:
	"""Get block data at the current raycast position (for removal)"""
	if not camera:
		return {}
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * placement_range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1  # Check layer 1 (terrain and placed blocks)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		# Check if we hit a placed block
		var hit_node = result.collider.get_parent()
		
		# Find the block in our placed_blocks dictionary
		for pos_key in placed_blocks:
			var block_data = placed_blocks[pos_key]
			if block_data["node"] == hit_node:
				return block_data
	
	return {}

func set_block_type(block_type: String):
	"""Change the current block type being placed"""
	if block_types.has(block_type):
		current_block_type = block_type
		print("Block type changed to: ", block_types[block_type]["name"])
	else:
		print("Invalid block type: ", block_type)

func get_block_info(block_type: String) -> Dictionary:
	"""Get information about a block type"""
	if block_types.has(block_type):
		return block_types[block_type]
	return {}
