extends Node3D
class_name DayNightCycle

# Time settings
@export var day_length_minutes: float = 10.0  ## Real-time minutes for a complete day/night cycle
@export_range(0, 23) var start_hour: int = 6  ## Starting hour (0-23, where 0=midnight, 6=6am, 12=noon, 18=6pm)
@export_range(0, 59) var start_minute: int = 0  ## Starting minute (0-59)
@export var enable_clouds: bool = true  ## Toggle cloud rendering on/off
@export_range(0, 200) var cloud_count: int = 20  ## Total number of clouds in the sky

@export_group("Cloud Distribution")
@export_range(100.0, 1000.0) var cloud_spread_area: float = 400.0  ## How far clouds spawn from origin (larger = more spread out, smaller = clustered)
@export_range(40.0, 120.0) var cloud_height_min: float = 60.0  ## Minimum height of cloud layer
@export_range(0.0, 50.0) var cloud_height_variation: float = 30.0  ## Vertical spread of clouds (0 = flat layer, higher = more variation)
@export_range(1.0, 10.0) var cloud_drift_speed_min: float = 2.0  ## Minimum drift speed in units per second
@export_range(1.0, 10.0) var cloud_drift_speed_max: float = 5.0  ## Maximum drift speed in units per second

# Cloud size distribution (percentages should add up to 1.0)
@export_group("Cloud Sizes")
@export_range(0.0, 1.0) var small_cloud_chance: float = 0.15  ## Percentage of clouds that are small (0.0 to 1.0)
@export_range(0.0, 1.0) var medium_cloud_chance: float = 0.30  ## Percentage of clouds that are medium (0.0 to 1.0). Large clouds = remaining percentage
# Large clouds = remaining percentage (1.0 - small - medium)

@export_subgroup("Small Clouds")
@export var small_cloud_min_size: float = 15.0  ## Minimum size in units for small clouds
@export var small_cloud_max_size: float = 30.0  ## Maximum size in units for small clouds
@export_range(0.1, 1.0) var small_cloud_min_aspect: float = 0.4  ## Minimum height/width ratio (lower = flatter/wider)
@export_range(0.1, 1.0) var small_cloud_max_aspect: float = 0.7  ## Maximum height/width ratio (higher = taller/rounder)

@export_subgroup("Medium Clouds")
@export var medium_cloud_min_size: float = 30.0  ## Minimum size in units for medium clouds
@export var medium_cloud_max_size: float = 55.0  ## Maximum size in units for medium clouds
@export_range(0.1, 1.0) var medium_cloud_min_aspect: float = 0.45  ## Minimum height/width ratio (lower = flatter/wider)
@export_range(0.1, 1.0) var medium_cloud_max_aspect: float = 0.8  ## Maximum height/width ratio (higher = taller/rounder)

@export_subgroup("Large Clouds")
@export var large_cloud_min_size: float = 50.0  ## Minimum size in units for large clouds
@export var large_cloud_max_size: float = 90.0  ## Maximum size in units for large clouds
@export_range(0.1, 1.0) var large_cloud_min_aspect: float = 0.5  ## Minimum height/width ratio (lower = flatter/wider)
@export_range(0.1, 1.0) var large_cloud_max_aspect: float = 0.9  ## Maximum height/width ratio (higher = taller/rounder)

@export_group("Cloud Noise Generation")
@export_range(0.01, 0.1) var base_noise_frequency: float = 0.02  ## Base cloud shape frequency (lower = bigger, smoother clouds)
@export_range(0.01, 0.2) var detail_noise_frequency: float = 0.08  ## Edge detail frequency (higher = more bumpy edges)
@export_range(0.0, 0.5) var detail_noise_strength: float = 0.15  ## How much edge detail affects the shape
@export_range(0.0, 2.0) var cloud_threshold: float = 0.5  ## Noise threshold for cloud formation (lower = larger clouds)
@export_range(0.5, 2.0) var center_falloff_strength: float = 1.2  ## How strongly clouds fade at edges

# References
@onready var sun: DirectionalLight3D = $SunLight
@onready var moon: DirectionalLight3D = $MoonLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment

# Player reference (set by world.gd)
var player: Node3D = null

# Celestial bodies
var sun_mesh: MeshInstance3D
var moon_mesh: MeshInstance3D
var stars_mesh: MultiMeshInstance3D
var clouds: Array = []

# Internal variables
var time_of_day: float = 0.0  # 0.0 to 1.0 (0 = midnight, 0.5 = noon)
var time_scale: float = 1.0

# Sky colors for different times of day
var night_sky_top_color = Color(0.01, 0.01, 0.05)      # Much darker blue-black at zenith
var night_sky_horizon_color = Color(0.05, 0.05, 0.08)   # Very dark at horizon
var sunrise_sky_top_color = Color(0.4, 0.6, 0.9)      # Light blue
var sunrise_sky_horizon_color = Color(1.0, 0.6, 0.4)  # Orange/pink
var day_sky_top_color = Color(0.35, 0.65, 1.0)        # Bright blue
var day_sky_horizon_color = Color(0.7, 0.85, 1.0)     # Light blue near horizon
var sunset_sky_top_color = Color(0.4, 0.5, 0.8)       # Purple-blue
var sunset_sky_horizon_color = Color(1.0, 0.5, 0.3)   # Orange/red

# Light colors
var night_light_color = Color(0.3, 0.3, 0.4)
var day_light_color = Color(1.0, 0.98, 0.95)
var sunrise_light_color = Color(1.0, 0.8, 0.6)
var sunset_light_color = Color(1.0, 0.7, 0.5)
var moon_light_color = Color(0.5, 0.6, 0.8)

func _ready():
	# Add to group for efficient lookup by resources
	add_to_group("day_night_cycle")
	
	# Convert start_hour and start_minute to time_of_day (0.0 to 1.0)
	time_of_day = (start_hour + start_minute / 60.0) / 24.0
	setup_environment()
	setup_moon()
	create_celestial_bodies()
	if enable_clouds:
		create_clouds()
	update_lighting()

func set_player(player_node: Node3D):
	"""Set player reference for positioning celestial bodies relative to player"""
	player = player_node

func _process(delta):
	# Update time of day
	var day_length_seconds = day_length_minutes * 60.0
	time_of_day += (delta * time_scale) / day_length_seconds
	
	# Wrap around after a full day
	if time_of_day >= 1.0:
		time_of_day -= 1.0
	
	update_lighting()
	update_celestial_bodies()
	if enable_clouds:
		update_clouds(delta)

func setup_environment():
	# Create environment if it doesn't exist
	if world_environment.environment == null:
		world_environment.environment = Environment.new()
	
	var env = world_environment.environment
	
	# Setup sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	# Disable sun/moon disc in procedural sky (we'll draw our own)
	sky_material.sun_angle_max = 0.0  # Hide sun disc
	sky_material.sun_curve = 0.0
	
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	
	# Setup ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.4
	
	# Add distance fog to hide far terrain/water edges
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.7, 0.8, 0.9)
	env.fog_light_energy = 0.2  # Reduced from 0.5 to make nights darker
	env.fog_depth_begin = 50.0  # Fog starts at 50 units
	env.fog_depth_end = 150.0  # Fully opaque at 150 units
	env.fog_aerial_perspective = 0.5  # Atmospheric scattering effect
	env.fog_sky_affect = 0.0  # Don't apply fog to sky/celestial bodies

func setup_moon():
	# Configure moon light properties
	if moon:
		moon.light_color = moon_light_color
		moon.light_energy = 0.0  # Start invisible
		moon.shadow_enabled = true

func create_celestial_bodies():
	# Create Sun with pixelated texture
	sun_mesh = MeshInstance3D.new()
	add_child(sun_mesh)
	
	# Use a quad (flat plane) for billboard effect
	var sun_quad = QuadMesh.new()
	sun_quad.size = Vector2(70.0, 70.0)  # Same size as moon for consistency
	sun_mesh.mesh = sun_quad
	
	# Create pixelated sun texture
	var sun_texture = create_pixelated_sun_texture()
	
	# Billboard material for sun
	var sun_material = StandardMaterial3D.new()
	sun_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sun_material.albedo_texture = sun_texture
	sun_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels
	sun_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sun_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
	sun_material.emission_enabled = true
	sun_material.emission_texture = sun_texture
	sun_material.emission_energy_multiplier = 1.0  # Reduced from 1.5
	sun_material.disable_fog = true  # Don't apply fog to sun
	# Let depth sorting handle render order naturally
	sun_mesh.material_override = sun_material
	
	# Position far away
	sun_mesh.position = Vector3(0, 100, -500)  # Much farther back so clouds are always in front
	
	# Create Moon with pixelated texture
	moon_mesh = MeshInstance3D.new()
	add_child(moon_mesh)
	
	var moon_quad = QuadMesh.new()
	moon_quad.size = Vector2(70.0, 70.0)  # Much bigger so pixels are visible
	moon_mesh.mesh = moon_quad
	
	# Create pixelated moon texture
	var moon_texture = create_pixelated_moon_texture()
	
	# Billboard material for moon
	var moon_material = StandardMaterial3D.new()
	moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon_material.albedo_texture = moon_texture
	moon_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels
	moon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moon_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED  # Always face camera
	moon_material.emission_enabled = true
	moon_material.emission_texture = moon_texture
	moon_material.emission_energy_multiplier = 0.3  # Reduced from 0.8
	moon_material.disable_fog = true  # Don't apply fog to moon
	# Let depth sorting handle render order naturally
	moon_mesh.material_override = moon_material
	
	# Position opposite sun
	moon_mesh.position = Vector3(0, 100, 500)  # Much farther back so clouds are always in front
	
	# Create Stars
	create_stars()

func create_pixelated_sun_texture() -> ImageTexture:
	"""Create a Minecraft-style pixelated sun texture"""
	var size = 64  # 64x64 pixels to match moon resolution
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Sun colors - bright yellow/orange with less contrast
	var sun_center = Color(1.0, 1.0, 0.95, 1.0)  # Bright white-yellow center
	var sun_mid = Color(1.0, 0.95, 0.6, 1.0)     # Yellow (closer to center)
	var sun_edge = Color(1.0, 0.85, 0.4, 1.0)    # Orange edge (lighter)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				# Create gradient from center to edge
				var t = dist / max_radius
				var color: Color
				
				if t < 0.4:
					# Center - bright white/yellow with smooth gradient
					color = sun_center
				elif t < 0.75:
					# Mid - yellow with gradual transition
					color = sun_center.lerp(sun_mid, (t - 0.4) / 0.35)
				elif t < 0.92:
					# Edge - orange with smooth transition
					color = sun_mid.lerp(sun_edge, (t - 0.75) / 0.17)
				else:
					# Very edge - gentle fade out
					color = sun_edge
					color.a = (1.0 - t) / 0.08
				
				# Add subtle pixel variation for texture (less extreme)
				if randf() > 0.92:
					color = color.lightened(0.05)
				elif randf() > 0.92:
					color = color.darkened(0.05)
				
				image.set_pixel(x, y, color)
			else:
				# Transparent outside circle
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)

func create_pixelated_moon_texture() -> ImageTexture:
	"""Create a Minecraft-style pixelated moon texture with craters"""
	var size = 64  # 64x64 pixels for better visibility at distance
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Moon colors - gray/white with less contrast
	var moon_bright = Color(0.95, 0.95, 1.0, 1.0)  # Bright areas
	var moon_mid = Color(0.85, 0.85, 0.95, 1.0)    # Mid tone (closer to bright)
	var moon_dark = Color(0.65, 0.65, 0.75, 1.0)   # Craters/shadows (lighter)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var max_radius = size / 2.0
	
	# Pre-calculate some crater positions (small dark spots) - more spread out
	var craters = [
		{"pos": Vector2(11, 9), "size": 3.0},
		{"pos": Vector2(21, 14), "size": 2.5},
		{"pos": Vector2(15, 23), "size": 2.0},
		{"pos": Vector2(24, 19), "size": 2.8},
		{"pos": Vector2(9, 20), "size": 2.2},
		{"pos": Vector2(19, 7), "size": 1.8},
		{"pos": Vector2(26, 10), "size": 1.5},
		{"pos": Vector2(7, 13), "size": 2.0}
	]
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= max_radius:
				var t = dist / max_radius
				var color: Color
				
				# Check if this pixel is in a crater - with soft falloff
				var crater_darkening = 0.0
				for crater in craters:
					var crater_dist = pos.distance_to(crater["pos"])
					var crater_size = crater["size"]
					if crater_dist < crater_size:
						# Soft gradient for crater edge
						var crater_strength = 1.0 - (crater_dist / crater_size)
						crater_darkening = max(crater_darkening, crater_strength * 0.4)  # Max 40% darkening
				
				if t < 0.6:
					# Center - bright
					color = moon_bright
				elif t < 0.85:
					# Mid - slightly darker
					color = moon_bright.lerp(moon_mid, (t - 0.6) / 0.25)
				else:
					# Edge - gentle fade to darker
					color = moon_mid.lerp(moon_dark, (t - 0.85) / 0.15)
					# Smoother alpha fade at edge
					if t > 0.92:
						color.a = (1.0 - t) / 0.08
				
				# Apply crater darkening as a multiplier
				if crater_darkening > 0:
					color = color.lerp(moon_dark, crater_darkening)
				
				# Add subtle pixel variation
				if randf() > 0.85:
					if randf() > 0.5:
						color = color.lightened(0.1)
					else:
						color = color.darkened(0.1)
				
				image.set_pixel(x, y, color)
			else:
				# Transparent outside circle
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	return ImageTexture.create_from_image(image)

func create_stars():
	"""Create a starfield for nighttime"""
	stars_mesh = MultiMeshInstance3D.new()
	add_child(stars_mesh)
	
	# Create particle-like stars using MultiMesh
	var star_mesh = SphereMesh.new()
	star_mesh.radius = 0.3
	star_mesh.height = 0.6
	
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = star_mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = 200
	
	# Randomly place stars in a sphere around the world
	for i in range(200):
		# Random position on sphere
		var theta = randf() * TAU
		var phi = randf() * PI
		var radius = 300.0
		
		var x = radius * sin(phi) * cos(theta)
		var y = radius * sin(phi) * sin(theta) 
		var z = radius * cos(phi)
		
		# Only place stars in upper hemisphere (above horizon)
		if y > 0:
			var transform = Transform3D()
			transform.origin = Vector3(x, y, z)
			var scale = 0.5 + randf() * 1.5  # Random sizes
			transform = transform.scaled(Vector3.ONE * scale)
			multi_mesh.set_instance_transform(i, transform)
	
	stars_mesh.multimesh = multi_mesh
	
	# Glowing star material
	var star_material = StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(1, 1, 1)
	star_material.emission_enabled = true
	star_material.emission = Color(1, 1, 1)
	star_material.emission_energy_multiplier = 2.0
	star_material.disable_fog = true  # Don't apply fog to stars
	stars_mesh.material_override = star_material
	
	# Start invisible
	stars_mesh.visible = false

func clear_clouds():
	"""Remove all existing clouds"""
	for cloud_data in clouds:
		if is_instance_valid(cloud_data["node"]):
			cloud_data["node"].queue_free()
	clouds.clear()

func update_cloud_count(new_count: int):
	"""Update the number of clouds at runtime"""
	cloud_count = new_count
	if enable_clouds:
		create_clouds()
		print("Cloud count updated to: ", new_count)

func create_clouds():
	"""Create pixelated billboard clouds with procedural textures"""
	# Clear existing clouds first
	clear_clouds()
	
	for i in range(cloud_count):
		var cloud = MeshInstance3D.new()
		add_child(cloud)
		
		# Create a simple quad for billboard
		var quad_mesh = QuadMesh.new()
		
		# Size distribution using export variables
		var size_roll = randf()
		var base_size: float
		var aspect: float
		
		if size_roll < small_cloud_chance:
			# Small clouds
			base_size = small_cloud_min_size + randf() * (small_cloud_max_size - small_cloud_min_size)
			aspect = small_cloud_min_aspect + randf() * (small_cloud_max_aspect - small_cloud_min_aspect)
		elif size_roll < small_cloud_chance + medium_cloud_chance:
			# Medium clouds
			base_size = medium_cloud_min_size + randf() * (medium_cloud_max_size - medium_cloud_min_size)
			aspect = medium_cloud_min_aspect + randf() * (medium_cloud_max_aspect - medium_cloud_min_aspect)
		else:
			# Large clouds (remaining percentage)
			base_size = large_cloud_min_size + randf() * (large_cloud_max_size - large_cloud_min_size)
			aspect = large_cloud_min_aspect + randf() * (large_cloud_max_aspect - large_cloud_min_aspect)
		
		quad_mesh.size = Vector2(base_size, base_size * aspect)
		cloud.mesh = quad_mesh
		
		# Generate unique pixelated cloud texture for each cloud
		var cloud_texture = create_pixelated_cloud_texture()
		
		# Cloud material with pixel texture
		var cloud_material = StandardMaterial3D.new()
		cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud_material.albedo_texture = cloud_texture
		cloud_material.albedo_color = Color(1.0, 1.0, 1.0, 0.75)  # 75% opacity - more transparent
		cloud_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels
		cloud_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		cloud_material.disable_fog = true  # Don't apply fog to clouds
		# Sun/moon are at z=±500, clouds at z=±200, so depth sorting handles render order
		cloud.material_override = cloud_material
		
		# Random position in sky using export variables
		var x = (randf() - 0.5) * cloud_spread_area
		var y = cloud_height_min + randf() * cloud_height_variation
		var z = (randf() - 0.5) * cloud_spread_area
		cloud.position = Vector3(x, y, z)
		
		# Store cloud data
		clouds.append({
			"node": cloud,
			"speed": cloud_drift_speed_min + randf() * (cloud_drift_speed_max - cloud_drift_speed_min),
			"base_y": y
		})

func create_pixelated_cloud_texture() -> ImageTexture:
	"""Create organic pixel-art clouds using Perlin noise"""
	var width = 128
	var height = 64
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Create noise generator
	var noise = FastNoiseLite.new()
	noise.seed = randi()  # Random seed for each cloud
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = base_noise_frequency  # Use exported parameter
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.6
	
	# Secondary noise for edge detail
	var detail_noise = FastNoiseLite.new()
	detail_noise.seed = randi()
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = detail_noise_frequency  # Use exported parameter
	detail_noise.fractal_octaves = 2
	
	# Define cloud colors
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var light_gray = Color(0.98, 0.98, 0.98, 1.0)
	var edge_gray = Color(0.7, 0.7, 0.75, 0.9)
	
	# Generate cloud shape from noise
	for x in range(width):
		for y in range(height):
			# Get main cloud shape (large, smooth)
			var base_noise = noise.get_noise_2d(x, y)
			
			# Get edge detail (small bumps)
			var detail = detail_noise.get_noise_2d(x, y) * detail_noise_strength  # Use exported parameter
			
			# Add bias toward center (elliptical falloff)
			var center_x = width / 2.0
			var center_y = height / 2.0
			var dx = (x - center_x) / (width * 0.45)  # Horizontal falloff
			var dy = (y - center_y) / (height * 0.4)   # Vertical falloff (tighter)
			var dist_squared = dx * dx + dy * dy
			var center_falloff = 1.0 - clamp(dist_squared, 0.0, 1.0)  # Smooth elliptical gradient
			
			# Combine: base shape + edge detail + center falloff
			var final_val = (base_noise * 0.7) + detail + (center_falloff * center_falloff_strength)  # Use exported parameter
			
			# Threshold for cloud
			if final_val > cloud_threshold:  # Use exported parameter
				# Vary color slightly for texture
				var color = white if randf() > 0.3 else light_gray
				image.set_pixel(x, y, color)
			else:
				# Transparent (sky)
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Add gray outline/halo
	var outline_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for x in range(width):
		for y in range(height):
			outline_image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Detect edges and add gray outline
	for x in range(1, width - 1):
		for y in range(1, height - 1):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.3:
				var is_edge = false
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var neighbor = image.get_pixel(x + dx, y + dy)
						if neighbor.a < 0.2:
							is_edge = true
							break
					if is_edge:
						break
				
				if is_edge:
					outline_image.set_pixel(x, y, edge_gray)
	
	# Composite outline under main cloud
	for x in range(width):
		for y in range(height):
			var outline_pixel = outline_image.get_pixel(x, y)
			var cloud_pixel = image.get_pixel(x, y)
			
			if outline_pixel.a > 0 and cloud_pixel.a < 0.5:
				image.set_pixel(x, y, outline_pixel)
	
	# Add subtle bottom shading
	for x in range(width):
		for y in range(height):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.5 and y > height * 0.55:
				var shadow_amount = (y - height * 0.55) / (height * 0.45) * 0.08
				pixel.r = clamp(pixel.r - shadow_amount, 0.92, 1.0)
				pixel.g = clamp(pixel.g - shadow_amount, 0.92, 1.0)
				pixel.b = clamp(pixel.b - shadow_amount, 0.92, 1.0)
				image.set_pixel(x, y, pixel)
	
	return ImageTexture.create_from_image(image)

func draw_rounded_rect(image: Image, cx: float, cy: float, w: float, h: float, 
					   corner_radius: int, white: Color, light_gray: Color):
	"""Draw a rectangle with rounded corners"""
	var img_width = image.get_width()
	var img_height = image.get_height()
	
	var left = int(cx - w / 2)
	var right = int(cx + w / 2)
	var top = int(cy - h / 2)
	var bottom = int(cy + h / 2)
	
	for x in range(max(0, left - corner_radius), min(img_width, right + corner_radius)):
		for y in range(max(0, top - corner_radius), min(img_height, bottom + corner_radius)):
			# Determine if pixel is inside the rounded rectangle
			var in_main_rect = x >= left and x < right and y >= top and y < bottom
			
			# Check corners
			var in_corner = false
			var corner_dist = 0.0
			
			# Top-left corner
			if x < left and y < top:
				var dx = left - x
				var dy = top - y
				corner_dist = sqrt(dx * dx + dy * dy)
				in_corner = corner_dist <= corner_radius
			# Top-right corner
			elif x >= right and y < top:
				var dx = x - right + 1
				var dy = top - y
				corner_dist = sqrt(dx * dx + dy * dy)
				in_corner = corner_dist <= corner_radius
			# Bottom-left corner
			elif x < left and y >= bottom:
				var dx = left - x
				var dy = y - bottom + 1
				corner_dist = sqrt(dx * dx + dy * dy)
				in_corner = corner_dist <= corner_radius
			# Bottom-right corner
			elif x >= right and y >= bottom:
				var dx = x - right + 1
				var dy = y - bottom + 1
				corner_dist = sqrt(dx * dx + dy * dy)
				in_corner = corner_dist <= corner_radius
			# Edges (not corners)
			elif (x < left or x >= right) and y >= top and y < bottom:
				in_corner = x >= left - corner_radius and x < right + corner_radius
			elif (y < top or y >= bottom) and x >= left and x < right:
				in_corner = y >= top - corner_radius and y < bottom + corner_radius
			
			if in_main_rect or in_corner:
				# Determine color - slight variation
				var color = white if randf() > 0.15 else light_gray
				
				# Edge softness
				if in_corner and not in_main_rect:
					var edge_fade = 1.0 - (corner_dist / corner_radius) * 0.3
					color.a = clamp(color.a * edge_fade, 0.7, 1.0)
				
				# Blend with existing pixel
				var existing = image.get_pixel(x, y)
				var new_r = max(existing.r, color.r)
				var new_g = max(existing.g, color.g)
				var new_b = max(existing.b, color.b)
				var new_a = clamp(existing.a + color.a, 0.0, 1.0)
				
				image.set_pixel(x, y, Color(new_r, new_g, new_b, new_a))

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	"""Smooth interpolation function for gradual falloff"""
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func update_clouds(delta):
	"""Animate clouds drifting"""
	var wrap_distance = cloud_spread_area / 2.0
	
	for cloud_data in clouds:
		var cloud = cloud_data["node"]
		# Drift in X direction
		cloud.position.x += cloud_data["speed"] * delta
		
		# Wrap around using dynamic spread area
		if cloud.position.x > wrap_distance:
			cloud.position.x = -wrap_distance
		
		# Subtle up/down bobbing
		cloud.position.y = cloud_data["base_y"] + sin(Time.get_ticks_msec() * 0.0003 + cloud.position.x * 0.01) * 2.0

func update_celestial_bodies():
	"""Update sun and moon positions relative to player"""
	# Calculate angle (0 to 360 degrees through the day)
	var sun_angle = time_of_day * 360.0
	var angle_rad = deg_to_rad(sun_angle)
	
	# Get player position (or use origin if player not set yet)
	var reference_pos = player.global_position if player else Vector3.ZERO
	
	# Sun moves in an arc across the sky, positioned relative to player
	var sun_distance = 200.0
	sun_mesh.position = reference_pos + Vector3(
		0,
		sun_distance * sin(angle_rad - PI/2),  # Vertical movement
		-sun_distance * cos(angle_rad - PI/2)  # Horizontal movement
	)
	
	# Moon is opposite (180 degrees offset)
	var moon_angle_rad = angle_rad + PI
	moon_mesh.position = reference_pos + Vector3(
		0,
		sun_distance * sin(moon_angle_rad - PI/2),
		-sun_distance * cos(moon_angle_rad - PI/2)
	)
	
	# Show/hide sun and moon based on position
	sun_mesh.visible = sun_mesh.position.y > reference_pos.y - 20.0  # Hide when below horizon
	moon_mesh.visible = moon_mesh.position.y > reference_pos.y - 20.0
	
	# Stars only visible at night
	if stars_mesh:
		# Fade stars in/out
		var star_alpha = 0.0
		if time_of_day < 0.2 or time_of_day > 0.8:  # Night time
			star_alpha = 1.0
		elif time_of_day < 0.3:  # Morning fade out
			star_alpha = 1.0 - ((time_of_day - 0.2) / 0.1)
		elif time_of_day > 0.7:  # Evening fade in
			star_alpha = (time_of_day - 0.7) / 0.1
		
		stars_mesh.visible = star_alpha > 0.0
		if stars_mesh.visible:
			var mat = stars_mesh.material_override as StandardMaterial3D
			mat.albedo_color.a = star_alpha

func update_lighting():
	# Calculate sun rotation (sun moves in a circle)
	var sun_angle = time_of_day * 360.0
	sun.rotation_degrees.x = sun_angle - 90.0
	
	# Moon is opposite the sun
	if moon:
		moon.rotation_degrees.x = (sun_angle + 180.0) - 90.0
	
	# Get current sky material
	var env = world_environment.environment
	var sky_material = env.sky.sky_material as ProceduralSkyMaterial
	
	# Calculate lighting based on time of day
	if time_of_day < 0.25:  # Night to sunrise (midnight to 6am)
		var t = time_of_day / 0.25
		sun.light_energy = lerp(0.0, 0.3, t)
		sun.light_color = night_light_color.lerp(sunrise_light_color, t)
		
		# Sky gradient
		sky_material.sky_top_color = night_sky_top_color.lerp(sunrise_sky_top_color, t)
		sky_material.sky_horizon_color = night_sky_horizon_color.lerp(sunrise_sky_horizon_color, t)
		
		# Moon dimmer at night
		if moon:
			moon.light_energy = lerp(0.08, 0.0, t)
		
		# Ambient light - very dark at night
		env.ambient_light_energy = lerp(0.02, 0.15, t)
		
		# Fog energy - very dim at night
		env.fog_light_energy = lerp(0.02, 0.15, t)
		
		# Fog color
		env.fog_light_color = night_sky_horizon_color.lerp(sunrise_sky_horizon_color, t)
		
	elif time_of_day < 0.5:  # Sunrise to noon (6am to 12pm)
		var t = (time_of_day - 0.25) / 0.25
		sun.light_energy = lerp(0.3, 1.0, t)
		sun.light_color = sunrise_light_color.lerp(day_light_color, t)
		
		sky_material.sky_top_color = sunrise_sky_top_color.lerp(day_sky_top_color, t)
		sky_material.sky_horizon_color = sunrise_sky_horizon_color.lerp(day_sky_horizon_color, t)
		
		if moon:
			moon.light_energy = 0.0
		
		# Ambient light - brighten during sunrise
		env.ambient_light_energy = lerp(0.15, 0.4, t)
		
		# Fog energy - brighten during sunrise
		env.fog_light_energy = lerp(0.15, 0.4, t)
		
		env.fog_light_color = sunrise_sky_horizon_color.lerp(day_sky_horizon_color, t)
		
	elif time_of_day < 0.75:  # Noon to sunset (12pm to 6pm)
		var t = (time_of_day - 0.5) / 0.25
		sun.light_energy = lerp(1.0, 0.3, t)
		sun.light_color = day_light_color.lerp(sunset_light_color, t)
		
		sky_material.sky_top_color = day_sky_top_color.lerp(sunset_sky_top_color, t)
		sky_material.sky_horizon_color = day_sky_horizon_color.lerp(sunset_sky_horizon_color, t)
		
		if moon:
			moon.light_energy = 0.0
		
		# Ambient light - stay bright during day
		env.ambient_light_energy = lerp(0.4, 0.15, t)
		
		# Fog energy - stay bright during day
		env.fog_light_energy = lerp(0.4, 0.15, t)
		
		env.fog_light_color = day_sky_horizon_color.lerp(sunset_sky_horizon_color, t)
		
	else:  # Sunset to night (6pm to midnight)
		var t = (time_of_day - 0.75) / 0.25
		sun.light_energy = lerp(0.3, 0.0, t)
		sun.light_color = sunset_light_color.lerp(night_light_color, t)
		
		sky_material.sky_top_color = sunset_sky_top_color.lerp(night_sky_top_color, t)
		sky_material.sky_horizon_color = sunset_sky_horizon_color.lerp(night_sky_horizon_color, t)
		
		# Moon rises at sunset - much dimmer
		if moon:
			moon.light_energy = lerp(0.0, 0.08, t)
		
		# Ambient light - get very dark at night
		env.ambient_light_energy = lerp(0.15, 0.02, t)
		
		# Fog energy - get very dim at night
		env.fog_light_energy = lerp(0.15, 0.02, t)
		
		env.fog_light_color = sunset_sky_horizon_color.lerp(night_sky_horizon_color, t)
	
	# Ground color (darker at night)
	var ground_brightness = max(sun.light_energy * 0.7, 0.1)
	sky_material.ground_bottom_color = Color(0.15, 0.12, 0.1) * ground_brightness
	sky_material.ground_horizon_color = sky_material.sky_horizon_color * 0.6
	
	# Update cloud brightness based on time of day
	if enable_clouds:
		var cloud_brightness = max(sun.light_energy, 0.3)
		for cloud_data in clouds:
			var cloud = cloud_data["node"]
			var mat = cloud.material_override as StandardMaterial3D
			# Tint the cloud texture instead of changing albedo_color
			mat.albedo_color = Color(cloud_brightness, cloud_brightness, cloud_brightness, 1.0)

func get_time_of_day() -> float:
	return time_of_day

func set_time_of_day(new_time: float):
	time_of_day = clamp(new_time, 0.0, 1.0)
	update_lighting()
	update_celestial_bodies()

func get_time_string() -> String:
	var hour = int(time_of_day * 24.0)
	var minute = int((time_of_day * 24.0 - hour) * 60.0)
	return "%02d:%02d" % [hour, minute]

func is_day() -> bool:
	return time_of_day >= 0.25 and time_of_day < 0.75

func is_night() -> bool:
	return !is_day()
