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

# References
@onready var sun: DirectionalLight3D = $SunLight
@onready var moon: DirectionalLight3D = $MoonLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment

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
	# Convert start_hour and start_minute to time_of_day (0.0 to 1.0)
	time_of_day = (start_hour + start_minute / 60.0) / 24.0
	setup_environment()
	setup_moon()
	create_celestial_bodies()
	if enable_clouds:
		create_clouds()
	update_lighting()

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
	
	# Add subtle fog for atmosphere
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.8, 0.9)
	env.fog_light_energy = 0.2  # Reduced from 0.5 to make nights darker
	env.fog_density = 0.001  # Very subtle
	env.fog_aerial_perspective = 0.3

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
	sun_quad.size = Vector2(40.0, 40.0)  # Much bigger - like Minecraft
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
	sun_mesh.material_override = sun_material
	
	# Position far away
	sun_mesh.position = Vector3(0, 100, -200)
	
	# Create Moon with pixelated texture
	moon_mesh = MeshInstance3D.new()
	add_child(moon_mesh)
	
	var moon_quad = QuadMesh.new()
	moon_quad.size = Vector2(35.0, 35.0)  # Slightly smaller than sun
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
	moon_mesh.material_override = moon_material
	
	# Position opposite sun
	moon_mesh.position = Vector3(0, 100, 200)
	
	# Create Stars
	create_stars()

func create_pixelated_sun_texture() -> ImageTexture:
	"""Create a Minecraft-style pixelated sun texture"""
	var size = 32  # 32x32 pixels for smoother look
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
	var size = 32  # 32x32 pixels for finer detail
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
	stars_mesh.material_override = star_material
	
	# Start invisible
	stars_mesh.visible = false

func create_clouds():
	"""Create pixelated billboard clouds with procedural textures"""
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
		cloud_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Crisp pixels
		cloud_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
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
	"""Create a Minecraft-style chunky blocky cloud texture"""
	var width = 32 + randi() % 32  # 32-64 pixels
	var height = 16 + randi() % 16  # 16-32 pixels
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Fill with transparent
	for x in range(width):
		for y in range(height):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Create cloud using rectangular "blocks" like Minecraft
	var num_blocks = 5 + randi() % 8  # 5-12 blocks
	
	# Start with a base horizontal strip
	var base_y = height / 2 + (randi() % 4 - 2)
	var base_x_start = 8 + randi() % (width / 4)
	var base_width = width / 2 + randi() % (width / 3)
	var base_height = 4 + randi() % 4  # 4-7 pixels tall
	
	# Draw base block
	draw_cloud_block(image, base_x_start, base_y, base_width, base_height)
	
	# Add additional blocks on top and sides
	for i in range(num_blocks):
		# Random position relative to center
		var block_x = base_x_start + randi() % int(base_width) - 4
		var block_y = base_y - 6 + randi() % 10  # Can be above or below base
		
		# Random block size
		var block_w = 6 + randi() % 10  # 6-15 pixels wide
		var block_h = 4 + randi() % 6   # 4-9 pixels tall
		
		# Keep within bounds
		block_x = clampi(block_x, 2, width - block_w - 2)
		block_y = clampi(block_y, 2, height - block_h - 2)
		
		draw_cloud_block(image, block_x, block_y, block_w, block_h)
	
	return ImageTexture.create_from_image(image)

func draw_cloud_block(image: Image, start_x: int, start_y: int, w: int, h: int):
	"""Draw a single cloud block with soft edges"""
	for x in range(start_x, start_x + w):
		for y in range(start_y, start_y + h):
			if x < 0 or x >= image.get_width() or y < 0 or y >= image.get_height():
				continue
			
			# Distance from edge of block
			var edge_dist_x = min(x - start_x, start_x + w - 1 - x)
			var edge_dist_y = min(y - start_y, start_y + h - 1 - y)
			var edge_dist = min(edge_dist_x, edge_dist_y)
			
			# Soft falloff at edges
			var alpha = 1.0
			var brightness = 0.95 + randf() * 0.05
			
			if edge_dist == 0:
				# Outer edge - soft
				alpha = 0.3 + randf() * 0.3
				brightness = 0.85
			elif edge_dist == 1:
				# Near edge - medium
				alpha = 0.7 + randf() * 0.2
				brightness = 0.90
			else:
				# Interior - solid
				alpha = 1.0
				brightness = 0.93 + randf() * 0.05
			
			# Blend with existing pixel (additive)
			var existing = image.get_pixel(x, y)
			var new_alpha = min(existing.a + alpha, 1.0)
			var new_brightness = max(existing.r, brightness)
			
			image.set_pixel(x, y, Color(new_brightness, new_brightness, new_brightness, new_alpha))

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
	"""Update sun and moon positions"""
	# Calculate angle (0 to 360 degrees through the day)
	var sun_angle = time_of_day * 360.0
	var angle_rad = deg_to_rad(sun_angle)
	
	# Sun moves in an arc across the sky
	var sun_distance = 200.0
	sun_mesh.position = Vector3(
		0,
		sun_distance * sin(angle_rad - PI/2),  # Vertical movement
		-sun_distance * cos(angle_rad - PI/2)  # Horizontal movement
	)
	
	# Moon is opposite (180 degrees offset)
	var moon_angle_rad = angle_rad + PI
	moon_mesh.position = Vector3(
		0,
		sun_distance * sin(moon_angle_rad - PI/2),
		-sun_distance * cos(moon_angle_rad - PI/2)
	)
	
	# Show/hide sun and moon based on position
	sun_mesh.visible = sun_mesh.position.y > -20.0  # Hide when below horizon
	moon_mesh.visible = moon_mesh.position.y > -20.0
	
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
