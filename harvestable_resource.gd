extends StaticBody3D
class_name HarvestableResource

"""
HarvestableResource - Base class for all collectible resources in the world

ARCHITECTURE:
- Resources are StaticBody3D on collision layer 2 (player raycasts this layer)
- Extends this for specific types: HarvestableTree, HarvestableMushroom, HarvestableStrawberry
- VegetationSpawner creates instances during world generation

DEPENDENCIES:
- Requires DayNightCycle in "day_night_cycle" group for nighttime glow effect
- HarvestingSystem (player component) handles interaction via raycasts
- HarvestParticles spawned on destruction

PERFORMANCE NOTES:
- Materials are duplicated ONCE in prepare_materials_for_glow() during _ready()
- Do NOT duplicate materials per-frame (previous bottleneck, now fixed)
- Group lookup for DayNightCycle is O(1) vs recursive search O(n)

LIFECYCLE:
1. Spawned by VegetationSpawner -> _ready() initializes
2. Player raycast detects (layer 2) -> HarvestingSystem shows UI
3. Harvesting begins -> update_harvest() called per frame
4. Complete -> spawn particles, emit signal, queue_free()
"""

# Preload particle system
const HarvestParticles = preload("res://harvest_particles.gd")

# Resource properties
@export_group("Resource Properties")
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
@export_group("Drops")
@export var drop_item: String = "stone"
@export var drop_amount_min: int = 1
@export var drop_amount_max: int = 3

# State
var current_health: float
var is_being_harvested: bool = false
var harvester: Node3D = null

# Visual feedback during harvesting
var original_material: Material
var harvest_progress: float = 0.0  # 0.0 to 1.0
var original_rotation: Vector3 = Vector3.ZERO

# Nighttime glow system
# INTEGRATION: DayNightCycle must be in "day_night_cycle" group
var day_night_cycle: DayNightCycle = null
var mesh_instances: Array[MeshInstance3D] = []  # Cached in _ready()
var glow_pulse_time: float = 0.0

signal harvested(drops: Dictionary)
signal harvest_started()
signal harvest_cancelled()
signal health_changed(current: float, maximum: float)

func _ready():
	current_health = max_health
	original_rotation = rotation
	
	# INTEGRATION: Must be on layer 2 so player raycasts can detect
	# Player uses raycast on mask=2, not physics collision
	collision_layer = 2
	collision_mask = 0
	
	# Cache all mesh instances for glow effect (avoid searching every frame)
	find_mesh_instances(self)
	
	# Store original material for visual feedback during harvesting
	if has_node("MeshInstance3D"):
		var mesh_instance = get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			original_material = mesh_instance.get_surface_override_material(0)
	
	# PERFORMANCE: Duplicate materials ONCE here, not per-frame in apply_emission_to_mesh()
	# Previous bottleneck: was duplicating materials 60 times per second per resource
	if enable_nighttime_glow:
		prepare_materials_for_glow()
		call_deferred("find_day_night_cycle")

func find_mesh_instances(node: Node):
	"""Recursively find all MeshInstance3D children"""
	if node is MeshInstance3D:
		mesh_instances.append(node)
	
	for child in node.get_children():
		find_mesh_instances(child)

func prepare_materials_for_glow():
	"""Duplicate and setup materials once for glow effect
	
	PERFORMANCE CRITICAL: This runs ONCE in _ready()
	- Materials must be duplicated to modify emission per-resource
	- Previous bug: was duplicating in apply_emission_to_mesh() every frame
	- With 100+ resources, this caused major FPS drops
	"""
	for mesh_instance in mesh_instances:
		if not mesh_instance or not mesh_instance.mesh:
			continue
		
		for surface_idx in range(mesh_instance.mesh.get_surface_count()):
			var material = mesh_instance.get_surface_override_material(surface_idx)
			
			# If no override material, get from mesh and duplicate it
			if not material:
				material = mesh_instance.mesh.surface_get_material(surface_idx)
				if material and material is StandardMaterial3D:
					material = material.duplicate()
					mesh_instance.set_surface_override_material(surface_idx, material)

func find_day_night_cycle():
	"""Find the DayNightCycle node using groups (cached, no recursion)
	
	PERFORMANCE: Group lookup is O(1) constant time
	- Previous implementation: recursive tree search O(n) where n = all nodes
	- With 1000+ resources doing this, caused noticeable lag on spawn
	
	INTEGRATION: DayNightCycle must call add_to_group("day_night_cycle") in _ready()
	"""
	var cycles = get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.size() > 0:
		day_night_cycle = cycles[0]
		return
	
	# Fallback: direct search if not in group (backwards compatibility)
	var root = get_tree().root
	for child in root.get_children():
		if child.get_script() and child.get_script().get_global_name() == "DayNightCycle":
			day_night_cycle = child
			return

func find_node_by_type(node: Node, type_name: String) -> Node:
	"""Recursively search for node with specific script type name"""
	if node.get_script() and node.get_script().get_global_name() == type_name:
		return node
	
	for child in node.get_children():
		var found = find_node_by_type(child, type_name)
		if found:
			return found
	
	return null

func _process(delta):
	# Update nighttime glow
	if enable_nighttime_glow and day_night_cycle:
		update_nighttime_glow(delta)

func update_nighttime_glow(delta: float):
	"""Update emission glow based on time of day
	
	PERFORMANCE: This runs every frame for every resource with glow enabled
	- Materials already duplicated in _ready()
	- Just modifying emission parameters here (cheap)
	"""
	var time_of_day = day_night_cycle.time_of_day
	
	# Calculate how dark it is (0.0 = day, 1.0 = night)
	# Night is from 0.75 to 0.25 (sunset to sunrise)
	var darkness = 0.0
	
	# Apply fade delay - positive delay means glow only when it gets darker
	var adjusted_time = time_of_day + glow_fade_delay
	if adjusted_time > 1.0:
		adjusted_time -= 1.0
	
	if adjusted_time >= 0.75:
		# Evening - fade in (0.75 -> 1.0 becomes 0.0 -> 1.0)
		darkness = (adjusted_time - 0.75) / 0.25
	elif adjusted_time <= 0.25:
		# Night/Morning - stay at full or fade out (0.0 -> 0.25 becomes 1.0 -> 0.0)
		darkness = 1.0 - (adjusted_time / 0.25)
	
	# Apply pulsing effect if enabled
	if glow_pulse:
		glow_pulse_time += delta * 0.5  # Slow pulse
		var pulse = 0.85 + sin(glow_pulse_time) * 0.15  # Pulse between 0.7 and 1.0
		darkness *= pulse
	
	# Apply glow to all mesh instances
	for mesh_instance in mesh_instances:
		apply_emission_to_mesh(mesh_instance, darkness)

func apply_emission_to_mesh(mesh_instance: MeshInstance3D, intensity: float):
	"""Apply emission to a mesh instance based on night intensity"""
	if not mesh_instance or not mesh_instance.mesh:
		return
	
	# Process each surface - materials already duplicated in _ready
	for surface_idx in range(mesh_instance.mesh.get_surface_count()):
		var material = mesh_instance.get_surface_override_material(surface_idx)
		
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
	
	# AUDIO: Play resource break sound
	AudioManager.play_sound("resource_break", "sfx")
	
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
