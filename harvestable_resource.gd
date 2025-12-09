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
	
	# Store original material for visual feedback
	if has_node("MeshInstance3D"):
		var mesh_instance = get_node("MeshInstance3D")
		if mesh_instance.get_surface_override_material_count() > 0:
			original_material = mesh_instance.get_surface_override_material(0)

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
