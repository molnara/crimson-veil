extends HarvestableResource
class_name HarvestableTree

# Tree-specific properties
enum TreeType {
	NORMAL,    # Regular deciduous tree
	PINE,      # Coniferous/evergreen
	PALM       # Tropical palm tree
}

@export var tree_type: TreeType = TreeType.NORMAL
@export var tree_height: float = 6.0  # Total height of tree
@export var leave_stump: bool = true

# Falling animation
var is_falling: bool = false
var fall_direction: Vector3 = Vector3.ZERO
var fall_progress: float = 0.0
var fall_duration: float = 1.5  # Seconds for tree to fall
var original_rotation: Vector3 = Vector3.ZERO

# Stump reference
var stump_mesh: MeshInstance3D = null

func _ready():
	# Set properties based on tree type FIRST
	match tree_type:
		TreeType.NORMAL:
			resource_name = "Tree"
			resource_type = "wood"
			max_health = 100.0
			harvest_time = 0.5  # Time per swing
			drop_item = "wood"
			drop_amount_min = 8
			drop_amount_max = 15
			mining_tool_required = "axe"
			
		TreeType.PINE:
			resource_name = "Pine Tree"
			resource_type = "wood"
			max_health = 120.0
			harvest_time = 0.5
			drop_item = "wood"
			drop_amount_min = 10
			drop_amount_max = 18
			mining_tool_required = "axe"
			
		TreeType.PALM:
			resource_name = "Palm Tree"
			resource_type = "wood"
			max_health = 80.0
			harvest_time = 0.5
			drop_item = "wood"
			drop_amount_min = 5
			drop_amount_max = 10
			mining_tool_required = "axe"
	
	# Store original rotation
	original_rotation = rotation
	
	# NOW call parent _ready
	super._ready()

func start_harvest(player: Node3D) -> bool:
	"""Override to calculate fall direction when harvest starts"""
	if not is_being_harvested:
		# Calculate fall direction (away from player)
		var to_player = (player.global_position - global_position).normalized()
		to_player.y = 0  # Keep it horizontal
		fall_direction = -to_player  # Fall away from player
	
	return super.start_harvest(player)

func update_harvest(delta: float) -> float:
	"""Update harvest progress with shake effect"""
	if not is_being_harvested:
		return 0.0
	
	harvest_progress += delta / harvest_time
	harvest_progress = clamp(harvest_progress, 0.0, 1.0)
	
	# Shake effect on each hit (when progress increases)
	apply_hit_shake()
	
	# Don't auto-complete - let harvesting system handle it
	return harvest_progress

func apply_hit_shake():
	"""Make tree shake when hit"""
	if not is_being_harvested:
		return
	
	# Quick shake using rotation
	var shake_amount = 0.05  # Radians
	var shake_speed = 30.0   # Speed of shake
	var time = Time.get_ticks_msec() * 0.001
	
	rotation.z = original_rotation.z + sin(time * shake_speed) * shake_amount * (1.0 - harvest_progress)
	rotation.x = original_rotation.x + cos(time * shake_speed * 0.7) * shake_amount * 0.5 * (1.0 - harvest_progress)

func apply_harvest_visual_feedback():
	"""Override to do shake instead of pulse"""
	# Shake is handled in apply_hit_shake
	pass

func complete_harvest():
	"""Override to trigger falling animation instead of immediate destruction"""
	if not is_being_harvested:
		return
	
	# Calculate drops
	var drop_count = randi_range(drop_amount_min, drop_amount_max)
	var drops = {
		"item": drop_item,
		"amount": drop_count
	}
	
	print("Tree chopped! Timber! ", resource_name, " - Got ", drop_count, "x ", drop_item)
	
	emit_signal("harvested", drops)
	
	# Reset harvest state
	is_being_harvested = false
	harvester = null
	harvest_progress = 0.0
	
	# Start falling animation instead of immediate destruction
	start_falling()

func start_falling():
	"""Begin the tree falling animation"""
	is_falling = true
	fall_progress = 0.0
	
	# Spawn wood particles at the base
	spawn_break_particles()
	
	# Create stump if enabled
	if leave_stump:
		create_stump()
	
	# Disable collision during fall
	collision_layer = 0
	collision_mask = 0

func create_stump():
	"""Create a stump that remains after tree falls"""
	stump_mesh = MeshInstance3D.new()
	get_parent().add_child(stump_mesh)
	
	# Position stump at tree base
	stump_mesh.global_position = global_position
	stump_mesh.rotation = Vector3.ZERO  # Keep upright
	
	# Create simple cylinder stump
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.4
	cylinder.bottom_radius = 0.5  # Slightly wider at bottom
	cylinder.height = 0.5  # Short stump
	stump_mesh.mesh = cylinder
	
	# Stump material (dark brown)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.2, 0.1)
	stump_mesh.material_override = material
	
	# Add collision to stump
	var static_body = StaticBody3D.new()
	stump_mesh.add_child(static_body)
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 0.5
	collision_shape.shape = shape
	static_body.add_child(collision_shape)

func _process(delta):
	if is_falling:
		animate_fall(delta)

func animate_fall(delta: float):
	"""Animate the tree falling over"""
	fall_progress += delta / fall_duration
	
	if fall_progress >= 1.0:
		# Falling complete - destroy tree
		queue_free()
		return
	
	# Smooth easing for fall
	var ease_progress = ease(fall_progress, -2.0)  # Ease out (accelerate at start, slow at end)
	
	# Rotate tree to fall over (90 degrees = fully fallen)
	var target_angle = PI / 2  # 90 degrees
	var fall_angle = ease_progress * target_angle
	
	# Calculate rotation axis (perpendicular to fall direction)
	var fall_axis = Vector3(fall_direction.z, 0, -fall_direction.x).normalized()
	
	# Apply rotation around the fall axis
	var fall_rotation = Basis(fall_axis, fall_angle)
	rotation = fall_rotation.get_euler()
	
	# Move tree slightly in fall direction as it tips
	position += fall_direction * delta * 2.0
	
	# Lower the tree as it falls (roots lift from ground)
	position.y -= delta * 1.0 * ease_progress

func cancel_harvest():
	"""Override to stop shake when cancelled"""
	super.cancel_harvest()
	# Reset rotation
	rotation = original_rotation
