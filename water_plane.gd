extends MeshInstance3D
class_name WaterPlane

"""
Creates an infinite water plane at sea level with Valheim-style pixel texture.
"""

@export var water_level: float = 0.0  # Y position of water surface
@export var water_size: float = 10000.0  # How far the water extends
@export var wave_enabled: bool = false  # Optional wave animation

func _ready():
	create_water_plane()

func create_water_plane():
	"""Create a large flat plane for water"""
	# Create a large quad mesh
	var plane = PlaneMesh.new()
	plane.size = Vector2(water_size, water_size)
	plane.subdivide_width = 10
	plane.subdivide_depth = 10
	
	mesh = plane
	
	# Position at sea level
	position.y = water_level
	
	# Create water material
	var material = StandardMaterial3D.new()
	
	# Water color - nice blue, very opaque so it's clearly visible
	material.albedo_color = Color(0.25, 0.5, 0.85, 0.98)  # 98% opaque
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	# Disable reflections for pixel art aesthetic
	material.metallic = 0.0
	material.roughness = 1.0  # Fully rough (no specular highlights)
	material.disable_receive_shadows = false  # Still receive shadows for depth
	
	# Cull back faces (only render from above)
	material.cull_mode = BaseMaterial3D.CULL_BACK
	
	material_override = material
	
	# Add collision body for water surface (so player can walk on it)
	var static_body = StaticBody3D.new()
	add_child(static_body)
	static_body.collision_layer = 1  # Same as terrain
	static_body.collision_mask = 0
	
	# Add collision shape (large flat box at water surface)
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(water_size, 0.5, water_size)  # 0.5m thick
	collision_shape.shape = box_shape
	
	# Position collision slightly BELOW water surface (-0.3m)
	# This allows terrain at y=0 to y=0.3 to be walkable
	collision_shape.position.y = -0.3  # Lowered
	
	static_body.add_child(collision_shape)
	
	# Set render layer for mesh
	layers = 2  # Put mesh on layer 2 (doesn't block raycasts for building)
