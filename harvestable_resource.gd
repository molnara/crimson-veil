extends StaticBody3D
class_name HarvestableResource

# Preload particle system
const HarvestParticles = preload("res://harvest_particles.gd")

# Resource properties
@export var resource_name: String = "Resource"
@export var resource_type: String = "generic"  # wood, stone, ore, etc.
@export var max_health: float = 100.0
@export var harvest_time: float = 3.0  # Seconds to fully harvest
@export var mining_tool_required: String = "none"  # none, pickaxe, axe, etc.

# Nighttime glow settings
@export_group("Nighttime Glow")
@export var enable_nighttime_glow: bool = true  ## Enable emission glow at night
@export var glow_color: Color = Color(0.3, 0.6, 0.4, 1.0)  ## Color of the nighttime glow (soft cyan-green)
@export_range(0.0, 3.0) var glow_strength: float = 0.4  ## Strength of emission glow
@export var glow_pulse: bool = true  ## Enable subtle pulsing effect
@export_range(0.0, 0.3) var glow_fade_delay: float = 0.18  ## Delay glow transitions (positive = glow only when darker, starts later at night)

# Drops
@export var drop_item: String = "stone"
@export var drop_amount_min: int = 1
@export var drop_amount_max: int = 3

# State
var current_health: float
var is_being_harvested: bool = false
var harvester: Node3D = null

# Visual feedback
var original_material: Material
var harvest_progress: float = 0.0
var original_rotation: Vector3 = Vector3.ZERO

# Nighttime glow
var day_night_cycle: DayNightCycle = null
var mesh_instances: Array[MeshInstance3D] = []
var glow_pulse_time: float = 0.0

signal harvested(drops: Dictionary)
signal harvest_started()
signal harvest_cancelled()
signal health_changed(current: float, maximum: float)

func _ready():
	current_health = max_health
	original_rotation = rotation
	
	# Set collision layers - layer 2 for resources
	collision_layer = 2
	collision_mask = 0
	
	# Find all mesh instances for glow effect
	find_mesh_instances(self)
	
	# Store original material for visual feedback
	if has_node("MeshInstance3D"):
		var mesh_instance = get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			original_material = mesh_instance.get_surface_override_material(0)
	
	# Find the DayNightCycle node
	if enable_nighttime_glow:
		call_deferred("find_day_night_cycle")

func find_mesh_instances(node: Node):
	"""Recursively find all MeshInstance3D children"""
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		find_mesh_instances(child)

func find_day_night_cycle():
	"""Find the DayNightCycle node in the scene"""
	# Look for DayNightCycle in the scene tree
	var root = get_tree().root
	for child in root.get_children():
		var cycle = find_node_by_type(child, "DayNightCycle")
		if cycle:
			day_night_cycle = cycle
			print("Found DayNightCycle for ", resource_name)
			return
	
	print("Warning: DayNightCycle not found for ", resource_name)

func find_node_by_type(node: Node, type_name: String) -> Node:
	"""Recursively search for a node by class name"""
	if node.get_class() == type_name or (node.get_script() and node.get_script().get_global_name() == type_name):
		return node
	
	for child in node.get_children():
		var result = find_node_by_type(child, type_name)
		if result:
			return result
	
	return null

func _process(delta):
	if enable_nighttime_glow and day_night_cycle:
		update_nighttime_glow(delta)

func update_nighttime_glow(delta: float):
	"""Update emission based on time of day"""
	if mesh_instances.is_empty():
		return
	
	# Get night intensity (0.0 = day, 1.0 = night)
	var night_intensity = 0.0
	var time = day_night_cycle.get_time_of_day()
	
	# Apply fade delay to transition times
	# Positive delay = glow starts later (darker) and ends earlier (less time glowing)
	var morning_end = 0.25 - glow_fade_delay  # Earlier morning end = glow stops sooner
	var evening_start = 0.75 + glow_fade_delay  # Later evening start = glow starts later
	
	# Night is from 0.0-morning_end and evening_start-1.0
	if time < morning_end:
		# Early morning - fade out as sun rises
		night_intensity = 1.0 - (time / morning_end)
	elif time < evening_start:
		# Day - no glow
		night_intensity = 0.0
	else:
		# Evening - fade in as sun sets
		night_intensity = (time - evening_start) / (1.0 - evening_start)
	
	# Add pulsing effect if enabled
	if glow_pulse:
		glow_pulse_time += delta
		var pulse = 0.9 + sin(glow_pulse_time * 1.5) * 0.1  # Pulse between 0.9 and 1.0 (subtle)
		night_intensity *= pulse
	
	# Apply emission to all mesh instances
	for mesh_instance in mesh_instances:
		apply_emission_to_mesh(mesh_instance, night_intensity)

func apply_emission_to_mesh(mesh_instance: MeshInstance3D, intensity: float):
	"""Apply emission to a mesh instance based on night intensity"""
	if not mesh_instance or not mesh_instance.mesh:
		return
	
	# Process each surface
	for surface_idx in range(mesh_instance.mesh.get_surface_count()):
		var material = mesh_instance.get_surface_override_material(surface_idx)
		
		# If no override material, get from mesh and duplicate it
		if not material:
			material = mesh_instance.mesh.surface_get_material(surface_idx)
			if material and material is StandardMaterial3D:
				material = material.duplicate()
				mesh_instance.set_surface_override_material(surface_idx, material)
		
		if material and material is StandardMaterial3D:
			var std_mat = material as StandardMaterial3D
			
			# Enable/disable emission based on intensity
			if intensity > 0.01:
				std_mat.emission_enabled = true
				std_mat.emission = glow_color
				std_mat.emission_energy_multiplier = glow_strength * intensity
			else:
				std_mat.emission_enabled = false

func start_harvest(player: Node3D) -> bool:
	"""Start harvesting this resource. Returns true if harvest can begin."""
	if is_being_harvested:
		return false
	
	# TODO: Check if player has required tool
	
	is_being_harvested = true
	harvester = player
	harvest_progress = 0.0
	
	emit_signal("harvest_started")
	print("Started harvesting ", resource_name)
	return true

func update_harvest(delta: float) -> float:
	"""Update harvest progress. Returns progress 0.0 to 1.0"""
	if not is_being_harvested:
		return 0.0
	
	harvest_progress += delta / harvest_time
	harvest_progress = clamp(harvest_progress, 0.0, 1.0)
	
	# Visual feedback - could make it shake or change color
	apply_harvest_visual_feedback()
	
	# Don't auto-complete here - let the harvesting system handle it
	# Just return the progress
	
	return harvest_progress

func apply_harvest_visual_feedback():
	"""Apply visual effects during harvesting"""
	# Could add screen shake, particle effects, color changes, etc.
	# For now, just a subtle scale pulse
	var pulse = 1.0 + (sin(harvest_progress * PI * 8.0) * 0.05)
	scale = Vector3.ONE * pulse

func cancel_harvest():
	"""Cancel the current harvest"""
	if not is_being_harvested:
		return
	
	is_being_harvested = false
	harvester = null
	harvest_progress = 0.0
	scale = Vector3.ONE  # Reset scale
	rotation = original_rotation  # Reset rotation
	
	emit_signal("harvest_cancelled")
	print("Cancelled harvesting ", resource_name)

func complete_harvest():
	"""Complete the harvest and drop items"""
	if not is_being_harvested:
		return
	
	# Calculate drops
	var drop_count = randi_range(drop_amount_min, drop_amount_max)
	var drops = {
		"item": drop_item,
		"amount": drop_count
	}
	
	print("Harvested ", resource_name, " - Got ", drop_count, "x ", drop_item)
	
	emit_signal("harvested", drops)
	
	# Spawn break particles
	spawn_break_particles()
	
	# Reset state
	is_being_harvested = false
	harvester = null
	harvest_progress = 0.0
	
	# Destroy this resource
	queue_free()

func take_damage(amount: float):
	"""Damage the resource directly (alternative to harvesting)"""
	current_health -= amount
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0:
		complete_harvest()

func get_info() -> Dictionary:
	"""Return info about this resource for UI display"""
	return {
		"name": resource_name,
		"type": resource_type,
		"health": current_health,
		"max_health": max_health,
		"harvest_time": harvest_time,
		"tool_required": mining_tool_required
	}

func spawn_break_particles():
	"""Spawn particle effect when resource breaks"""
	# Get the world root to spawn particles in
	var world = get_tree().root
	if world:
		HarvestParticles.create_break_particles(global_position, resource_type, world)
