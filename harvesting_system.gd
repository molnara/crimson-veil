extends Node
class_name HarvestingSystem

# Manages the harvesting/mining interaction with resources

var player: CharacterBody3D
var camera: Camera3D
var inventory: Inventory
var tool_system: ToolSystem

# Raycasting
var raycast_distance: float = 5.0
var current_target: HarvestableResource = null
var is_harvesting: bool = false
var just_completed_harvest: bool = false  # Prevent cancel message after completion

# UI references (will be set from outside)
var progress_bar: ProgressBar = null
var target_label: Label = null

signal target_changed(resource: HarvestableResource)
signal harvest_started(resource: HarvestableResource)
signal harvest_completed(resource: HarvestableResource, drops: Dictionary)
signal harvest_cancelled()

func _ready():
	# Will be initialized by the player
	pass

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
	
	# Always update what the player is looking at
	update_raycast()
	
	# Update harvesting progress if actively harvesting
	if is_harvesting and current_target != null:
		update_harvest_progress(delta)

func update_raycast():
	"""Check what resource the player is looking at"""
	if camera == null:
		return
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * raycast_distance
	
	# Create raycast query parameters
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Layer 2 for resources
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	var new_target: HarvestableResource = null
	if result and result.collider is HarvestableResource:
		new_target = result.collider as HarvestableResource
	
	# Update target if changed
	if new_target != current_target:
		# Don't cancel if we just completed a harvest
		if just_completed_harvest:
			just_completed_harvest = false
		# Cancel harvest if we were harvesting something else
		elif is_harvesting and current_target != null:
			cancel_harvest()
		
		current_target = new_target
		emit_signal("target_changed", current_target)
		update_ui()

func start_harvest():
	"""Start harvesting the current target"""
	if current_target == null:
		return
	
	# Check if we have the required tool
	if tool_system:
		var resource_info = current_target.get_info()
		var resource_type = resource_info.get("type", "generic")
		
		if not tool_system.can_harvest(resource_type):
			var required_tool = tool_system.get_required_tool_name(resource_type)
			print("Cannot harvest ", current_target.resource_name, " - requires ", required_tool)
			return
	
	if current_target.start_harvest(player):
		is_harvesting = true
		
		# Connect to the resource's harvested signal
		if not current_target.harvested.is_connected(_on_resource_harvested):
			current_target.harvested.connect(_on_resource_harvested)
		
		emit_signal("harvest_started", current_target)
		update_ui()
		print("Started harvesting: ", current_target.resource_name)

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
	# Explicitly complete the harvest on the resource
	if current_target:
		current_target.complete_harvest()
	
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
		if current_target:
			# Show target name when looking at resource
			var info = current_target.get_info()
			target_label.text = info["name"]
			target_label.visible = true
			
			# Check if we have the right tool - color label red if not
			if tool_system:
				var resource_type = info.get("type", "generic")
				var has_correct_tool = tool_system.can_harvest(resource_type)
				
				if has_correct_tool:
					# White for correct tool
					target_label.add_theme_color_override("font_color", Color.WHITE)
				else:
					# Red for wrong tool
					target_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
					# Show required tool in the label
					var required_tool = tool_system.get_required_tool_name(resource_type)
					target_label.text = info["name"] + " (Requires " + required_tool + ")"
		else:
			target_label.visible = false
	
	# Debug
	if progress_bar:
		print("UI Update - Progress bar visible: ", progress_bar.visible, " is_harvesting: ", is_harvesting)

func handle_input(event: InputEvent):
	"""Handle input events for harvesting"""
	# Start harvest on left click
	if event.is_action_pressed("interact"):  # We'll need to add this action
		if current_target and not is_harvesting:
			start_harvest()
	
	# Cancel harvest on release or movement
	if event.is_action_released("interact"):
		if is_harvesting:
			cancel_harvest()

func is_looking_at_resource() -> bool:
	"""Check if player is currently looking at a harvestable resource"""
	return current_target != null

func get_current_target() -> HarvestableResource:
	"""Get the resource the player is currently looking at"""
	return current_target
