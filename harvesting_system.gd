extends Node
class_name HarvestingSystem

# Manages the harvesting/mining interaction with resources

var player: CharacterBody3D
var camera: Camera3D
var inventory: Inventory
var tool_system: ToolSystem

# Raycasting
var raycast_distance: float = 5.0
var container_raycast_distance: float = 3.0  # Shorter range for containers
var current_target: HarvestableResource = null
var current_container: Node = null  # Container player is looking at
var is_harvesting: bool = false
var just_completed_harvest: bool = false  # Prevent cancel message after completion

# Wrong tool feedback cooldown (prevent spam from held controller input)
var wrong_tool_cooldown: float = 0.0
const WRONG_TOOL_COOLDOWN_TIME: float = 0.5  # 500ms between wrong tool sounds

# UI references (will be set from outside)
var progress_bar: ProgressBar = null
var target_label: Label = null

# Highlight system
var outline_shader: Shader = null
var outline_material: ShaderMaterial = null
var highlighted_meshes: Array[MeshInstance3D] = []  # Track which meshes have outline
const CORRECT_TOOL_COLOR = Color(0.2, 1.0, 0.3, 1.0)  # Bright green
const WRONG_TOOL_COLOR = Color(1.0, 0.2, 0.2, 1.0)    # Bright red
const OUTLINE_WIDTH = 0.025  # Outline thickness

signal target_changed(resource: HarvestableResource)
signal harvest_started(resource: HarvestableResource)
signal harvest_completed(resource: HarvestableResource, drops: Dictionary)
signal harvest_cancelled()

func _ready():
	# Load outline shader
	outline_shader = load("res://resource_outline.gdshader")
	if outline_shader:
		outline_material = ShaderMaterial.new()
		outline_material.shader = outline_shader
		print("Outline shader loaded successfully")
	else:
		print("WARNING: Failed to load outline shader")

func initialize(player_node: CharacterBody3D, player_camera: Camera3D, player_inventory: Inventory, player_tool_system: ToolSystem):
	"""Initialize the harvesting system with player references"""
	player = player_node
	camera = player_camera
	inventory = player_inventory
	tool_system = player_tool_system
	
	# Connect to tool changes to update UI
	if tool_system:
		tool_system.tool_equipped.connect(_on_tool_equipped)
	
	print("HarvestingSystem initialized")

func _process(delta):
	if player == null or camera == null:
		return
	
	# Tick down wrong tool cooldown
	if wrong_tool_cooldown > 0:
		wrong_tool_cooldown -= delta
	
	# Always update what the player is looking at
	update_raycast()
	
	# Update harvesting progress if actively harvesting
	if is_harvesting and current_target != null:
		update_harvest_progress(delta)

func update_raycast():
	"""Check what resource or container the player is looking at"""
	if camera == null:
		return
	
	# First, check for containers (Layer 3, 3m range) - priority
	var container_target = check_for_container()
	
	# If looking at a container, skip resource checking
	if container_target:
		# Remove resource highlight if any
		if current_target:
			remove_highlight(current_target)
			current_target = null
		
		# Update container highlighting
		if container_target != current_container:
			if current_container:
				remove_container_highlight(current_container)
			current_container = container_target
			add_container_highlight(current_container)
		return
	
	# No container - remove container highlight if any
	if current_container:
		remove_container_highlight(current_container)
		current_container = null
	
	# Check for resources (Layer 2, 5m range)
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -raycast_distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Layer 2 - harvestable resources
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider is HarvestableResource:
			# Found a new target
			if collider != current_target:
				# Remove highlight from old target
				if current_target:
					remove_highlight(current_target)
				
				# Set new target
				current_target = collider
				
				# Add highlight to new target
				add_highlight(current_target)
				
				emit_signal("target_changed", current_target)
				update_ui()
	else:
		# No target found
		if current_target:
			remove_highlight(current_target)
			current_target = null
			emit_signal("target_changed", null)
			update_ui()

func check_for_container() -> Node:
	"""Check if player is looking at a container (Layer 3, 3m range)"""
	if camera == null:
		return null
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -container_raycast_distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Layer 3 - interactive objects (containers)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		# Check if it's a storage container
		if collider.has_method("open_container"):
			return collider
	
	return null

func add_container_highlight(container: Node):
	"""Add green highlight to container"""
	if not container or not outline_material:
		return
	
	# Find mesh instances in container
	var meshes = _find_mesh_instances(container)
	for mesh_instance in meshes:
		if mesh_instance:
			mesh_instance.material_overlay = outline_material.duplicate()
			mesh_instance.material_overlay.set_shader_parameter("outline_color", Color(0.2, 1.0, 0.3, 1.0))  # Green
			mesh_instance.material_overlay.set_shader_parameter("outline_width", OUTLINE_WIDTH)

func remove_container_highlight(container: Node):
	"""Remove highlight from container"""
	if not container:
		return
	
	var meshes = _find_mesh_instances(container)
	for mesh_instance in meshes:
		if mesh_instance:
			mesh_instance.material_overlay = null

func add_highlight(resource: HarvestableResource):
	"""Add colored outline to resource based on tool correctness"""
	if not resource or not outline_material:
		return
	
	# Determine color based on tool requirement
	var color = CORRECT_TOOL_COLOR
	
	if tool_system:
		var resource_info = resource.get_info()
		var resource_type = resource_info.get("type", "generic")
		if not tool_system.can_harvest(resource_type):
			color = WRONG_TOOL_COLOR
	
	# Find all mesh instances in the resource
	var meshes = _find_mesh_instances(resource)
	
	for mesh_instance in meshes:
		if mesh_instance:
			# Create a duplicate material for this mesh
			var mat = outline_material.duplicate()
			mat.set_shader_parameter("outline_color", color)
			mat.set_shader_parameter("outline_width", OUTLINE_WIDTH)
			
			mesh_instance.material_overlay = mat
			highlighted_meshes.append(mesh_instance)

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	"""Recursively find all MeshInstance3D children"""
	var meshes: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		meshes.append(node)
	
	for child in node.get_children():
		meshes.append_array(_find_mesh_instances(child))
	
	return meshes

func update_highlight_color():
	"""Update highlight color based on current tool (called when tool changes)"""
	if current_target:
		# Remove and re-add highlight to update color
		remove_highlight(current_target)
		add_highlight(current_target)

func remove_highlight(resource: HarvestableResource):
	"""Remove outline from resource"""
	if not resource:
		return
	
	# Find all mesh instances and remove overlay
	var meshes = _find_mesh_instances(resource)
	
	for mesh_instance in meshes:
		if mesh_instance:
			mesh_instance.material_overlay = null
			if highlighted_meshes.has(mesh_instance):
				highlighted_meshes.erase(mesh_instance)

func start_harvest():
	"""Start harvesting the current target"""
	if current_target == null:
		return
	
	# Prevent starting harvest if already harvesting
	if is_harvesting:
		return
	
	# Check if we have the required tool
	if tool_system:
		var resource_info = current_target.get_info()
		var resource_type = resource_info.get("type", "generic")
		
		if not tool_system.can_harvest(resource_type):
			# Only play wrong tool sound if cooldown has expired
			if wrong_tool_cooldown <= 0:
				var required_tool = tool_system.get_required_tool_name(resource_type)
				print("Cannot harvest ", current_target.resource_name, " - requires ", required_tool)
				# VISUAL FEEDBACK: Show error in target label
				if target_label:
					target_label.text = "❌ Requires " + required_tool
					target_label.modulate = Color.RED
					# Will reset when looking away (update_target_ui() will fix it)
				
				# AUDIO: Play wrong tool sound
				AudioManager.play_sound("wrong_tool", "sfx")
				
				# RUMBLE: Wrong tool feedback
				RumbleManager.play_wrong_tool()
				
				# Set cooldown to prevent spam
				wrong_tool_cooldown = WRONG_TOOL_COOLDOWN_TIME
			return
	
	if current_target.start_harvest(player):
		is_harvesting = true
		
		# Connect to the resource's harvested signal
		if not current_target.harvested.is_connected(_on_resource_harvested):
			current_target.harvested.connect(_on_resource_harvested)
		
		emit_signal("harvest_started", current_target)
		update_ui()
		print("Started harvesting: ", current_target.resource_name)
		
		# AUDIO: Play initial hit sound based on resource type
		_play_harvest_hit_sound(current_target)

func _play_harvest_hit_sound(resource: HarvestableResource):
	"""Play the appropriate hit sound based on resource type"""
	if not resource:
		return
	
	var resource_info = resource.get_info()
	var resource_type = resource_info.get("type", "generic")
	
	# Determine which sound to play
	var sound_name = ""
	match resource_type:
		"wood":
			sound_name = "axe_chop"
		"stone", "ore":
			sound_name = "pickaxe_hit"
		"foliage":
			# Check specific resource name for mushroom vs strawberry
			if resource.resource_name.to_lower().contains("mushroom"):
				sound_name = "mushroom_pick"
			elif resource.resource_name.to_lower().contains("strawberry"):
				sound_name = "strawberry_pick"
			else:
				sound_name = "mushroom_pick"  # Default for foliage
	
	if sound_name != "":
		AudioManager.play_sound(sound_name, "sfx")
		# RUMBLE: Harvest hit feedback
		RumbleManager.play_harvest_hit()

func update_harvest_progress(delta: float):
	"""Update the progress of the current harvest"""
	if current_target == null or not is_harvesting:
		return
	
	var progress = current_target.update_harvest(delta)
	
	# Update progress bar
	if progress_bar:
		progress_bar.value = progress * 100.0
		progress_bar.visible = true
	
	# Check if harvest completed
	if progress >= 1.0:
		finish_harvest()

func finish_harvest():
	"""Called when harvest completes successfully"""
	# Remove highlight before completing
	if current_target:
		remove_highlight(current_target)
		current_target.complete_harvest()
		# RUMBLE: Harvest complete feedback
		RumbleManager.play_harvest_complete()
	
	is_harvesting = false
	just_completed_harvest = true  # Prevent cancel on next frame
	
	# The resource will emit harvested signal and queue_free itself
	# We just need to clean up our references
	current_target = null
	
	# Hide UI elements
	if progress_bar:
		progress_bar.visible = false
		progress_bar.value = 0
	if target_label:
		target_label.visible = false
	
	print("finish_harvest() - UI elements hidden")
	update_ui()

func _on_resource_harvested(drops: Dictionary):
	"""Called when a resource is successfully harvested"""
	print("HarvestingSystem: Resource harvested with drops: ", drops)
	emit_signal("harvest_completed", current_target, drops)

func _on_tool_equipped(_tool):
	"""Called when the player equips a different tool"""
	# Update UI to reflect new tool (changes color if wrong tool)
	update_ui()
	# Update highlight color to match new tool
	update_highlight_color()
	
	# AUDIO: Play tool switch sound
	AudioManager.play_sound("tool_switch", "ui", false)

func cancel_harvest():
	"""Cancel the current harvest"""
	if not is_harvesting:
		return
	
	if current_target:
		current_target.cancel_harvest()
	
	is_harvesting = false
	emit_signal("harvest_cancelled")
	update_ui()
	print("Harvest cancelled")

func update_ui():
	"""Update UI elements to reflect current state"""
	if progress_bar:
		if is_harvesting:
			progress_bar.visible = true
			print("Showing progress bar")
		else:
			progress_bar.visible = false
			progress_bar.value = 0
			print("Hiding progress bar")
	
	if target_label:
		if current_target and not is_harvesting:
			var resource_info = current_target.get_info()
			var tool_required = resource_info.get("tool_required", "none")
			
			# Check if we have the right tool
			var has_correct_tool = true
			if tool_system and tool_required != "none":
				var resource_type = resource_info.get("type", "generic")
				has_correct_tool = tool_system.can_harvest(resource_type)
			
			# Update label
			var label_text = resource_info.get("name", "Resource")
			if not has_correct_tool and tool_system:
				var required_tool = tool_system.get_required_tool_name(resource_info.get("type", "generic"))
				label_text += " (Requires " + required_tool + ")"
				target_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red
			else:
				target_label.remove_theme_color_override("font_color")
			
			target_label.text = label_text
			target_label.visible = true
		else:
			target_label.visible = false

func is_looking_at_resource() -> bool:
	"""Check if player is currently looking at a harvestable resource"""
	return current_target != null

func is_looking_at_container() -> bool:
	"""Check if player is currently looking at a container"""
	return current_container != null

