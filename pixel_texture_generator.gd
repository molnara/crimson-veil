extends Node
class_name PixelTextureGenerator

"""
Generates low-resolution pixel art textures for Valheim-style graphics.
All textures use nearest-neighbor filtering for crisp pixels.
"""

# Texture resolution (keep low for pixel art)
const TEXTURE_SIZE = 16  # 16x16 pixels like classic Minecraft/Valheim

static func create_grass_texture() -> ImageTexture:
	"""Create a pixelated grass texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Base grass colors (green variations)
	var grass_colors = [
		Color(0.3, 0.5, 0.2),  # Dark green
		Color(0.35, 0.55, 0.25), # Medium green
		Color(0.4, 0.6, 0.3),  # Light green
		Color(0.25, 0.45, 0.15) # Very dark green
	]
	
	# Fill with random grass pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = grass_colors[randi() % grass_colors.size()]
			# Add slight variation
			color.r += (randf() - 0.5) * 0.05
			color.g += (randf() - 0.5) * 0.05
			color.b += (randf() - 0.5) * 0.05
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_stone_texture() -> ImageTexture:
	"""Create a pixelated stone texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Stone colors (gray variations)
	var stone_colors = [
		Color(0.4, 0.4, 0.4),  # Medium gray
		Color(0.5, 0.5, 0.5),  # Light gray
		Color(0.3, 0.3, 0.3),  # Dark gray
		Color(0.45, 0.45, 0.45) # Mid gray
	]
	
	# Fill with random stone pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = stone_colors[randi() % stone_colors.size()]
			# Add noise for rocky appearance
			color.r += (randf() - 0.5) * 0.1
			color.g += (randf() - 0.5) * 0.1
			color.b += (randf() - 0.5) * 0.1
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_wood_texture() -> ImageTexture:
	"""Create a pixelated wood plank texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Wood colors (brown variations)
	var base_color = Color(0.5, 0.35, 0.2)
	var dark_color = Color(0.4, 0.25, 0.1)
	
	# Create wood grain pattern (vertical stripes)
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = base_color
			
			# Add vertical grain lines
			if x % 3 == 0 or x % 5 == 0:
				color = dark_color
			
			# Add random variation
			color.r += (randf() - 0.5) * 0.08
			color.g += (randf() - 0.5) * 0.08
			color.b += (randf() - 0.5) * 0.08
			
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_dirt_texture() -> ImageTexture:
	"""Create a pixelated dirt texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Dirt colors (brown variations)
	var dirt_colors = [
		Color(0.35, 0.25, 0.15),  # Dark brown
		Color(0.4, 0.3, 0.2),     # Medium brown
		Color(0.3, 0.2, 0.1),     # Very dark brown
		Color(0.45, 0.35, 0.25)   # Light brown
	]
	
	# Fill with random dirt pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = dirt_colors[randi() % dirt_colors.size()]
			# Add variation
			color.r += (randf() - 0.5) * 0.1
			color.g += (randf() - 0.5) * 0.1
			color.b += (randf() - 0.5) * 0.1
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_bark_texture() -> ImageTexture:
	"""Create a pixelated tree bark texture (default/oak style)"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Bark colors (dark brown)
	var base_color = Color(0.3, 0.2, 0.1)
	var highlight_color = Color(0.4, 0.25, 0.15)
	
	# Create bark pattern (vertical-ish lines for oak)
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = base_color
			
			# Vertical bark lines with some variation
			if x % 4 == 0 or x % 4 == 1:
				color = highlight_color
			
			# Add horizontal breaks occasionally
			if y % 6 == 0:
				color = base_color
			
			# Add noise
			color.r += (randf() - 0.5) * 0.1
			color.g += (randf() - 0.5) * 0.1
			color.b += (randf() - 0.5) * 0.1
			
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_pine_bark_texture() -> ImageTexture:
	"""Create pine tree bark - rougher with horizontal segments"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Pine colors - reddish brown with more contrast
	var base_color = Color(0.35, 0.18, 0.12)  # Dark reddish-brown
	var plate_color = Color(0.45, 0.22, 0.15)  # Lighter plates
	var crack_color = Color(0.2, 0.1, 0.08)   # Very dark cracks
	
	# Create rough plated bark pattern (horizontal segments)
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = base_color
			
			# Horizontal plates/segments
			var plate_y = y % 5
			if plate_y == 0:
				color = crack_color  # Dark crack between plates
			elif plate_y == 1 or plate_y == 2:
				color = plate_color  # Raised plate
			else:
				color = base_color  # Base
			
			# Add vertical cracks/fissures
			if x % 7 == 0:
				color = crack_color.lerp(color, 0.5)
			
			# Random roughness
			color.r += (randf() - 0.5) * 0.12
			color.g += (randf() - 0.5) * 0.12
			color.b += (randf() - 0.5) * 0.12
			
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_palm_bark_texture() -> ImageTexture:
	"""Create palm tree bark - diamond/crosshatch pattern with rings"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Palm colors - tan/beige with more contrast
	var base_color = Color(0.55, 0.45, 0.35)    # Tan base
	var ring_color = Color(0.4, 0.32, 0.24)     # Darker rings
	var highlight_color = Color(0.65, 0.55, 0.42)  # Lighter spots
	
	# Create diamond/crosshatch pattern with horizontal rings
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = base_color
			
			# Horizontal ring pattern (distinctive palm feature)
			var ring_y = y % 6
			if ring_y == 0 or ring_y == 1:
				color = ring_color  # Dark ring/scar
			elif ring_y == 5:
				color = highlight_color  # Light ridge
			
			# Diamond/crosshatch texture
			var pattern = (x + y) % 5
			if pattern == 0 or pattern == 1:
				color = color.darkened(0.1)
			
			# Opposite diagonal for crosshatch
			var pattern2 = (x - y + TEXTURE_SIZE) % 5
			if pattern2 == 0:
				color = color.lightened(0.1)
			
			# Add subtle variation
			color.r += (randf() - 0.5) * 0.08
			color.g += (randf() - 0.5) * 0.08
			color.b += (randf() - 0.5) * 0.08
			
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_leaves_texture() -> ImageTexture:
	"""Create a pixelated leaves texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Leaf colors (various greens)
	var leaf_colors = [
		Color(0.2, 0.5, 0.2),   # Dark green
		Color(0.25, 0.55, 0.25), # Medium green
		Color(0.3, 0.6, 0.3),   # Light green
		Color(0.15, 0.45, 0.15) # Very dark green
	]
	
	# Fill with random leaf pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = leaf_colors[randi() % leaf_colors.size()]
			# Add variation
			color.r += (randf() - 0.5) * 0.08
			color.g += (randf() - 0.5) * 0.08
			color.b += (randf() - 0.5) * 0.08
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_sand_texture() -> ImageTexture:
	"""Create a pixelated sand texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Sand colors (tan/beige)
	var sand_colors = [
		Color(0.85, 0.75, 0.5),
		Color(0.9, 0.8, 0.55),
		Color(0.8, 0.7, 0.45),
		Color(0.88, 0.78, 0.52)
	]
	
	# Fill with random sand pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = sand_colors[randi() % sand_colors.size()]
			color.r += (randf() - 0.5) * 0.05
			color.g += (randf() - 0.5) * 0.05
			color.b += (randf() - 0.5) * 0.05
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_snow_texture() -> ImageTexture:
	"""Create a pixelated snow texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Snow colors (white/light blue variations)
	var snow_colors = [
		Color(0.95, 0.95, 1.0),
		Color(1.0, 1.0, 1.0),
		Color(0.9, 0.9, 0.95),
		Color(0.93, 0.93, 0.98)
	]
	
	# Fill with random snow pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = snow_colors[randi() % snow_colors.size()]
			color.r += (randf() - 0.5) * 0.03
			color.g += (randf() - 0.5) * 0.03
			color.b += (randf() - 0.5) * 0.03
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_strawberry_leaf_texture() -> ImageTexture:
	"""Create a pixelated dark green strawberry leaf texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Much darker leaf colors (almost black-green)
	var leaf_colors = [
		Color(0.08, 0.25, 0.08),   # Very dark green
		Color(0.1, 0.28, 0.1),     # Dark green
		Color(0.06, 0.22, 0.06),   # Super dark green
		Color(0.12, 0.3, 0.12)     # Medium dark green
	]
	
	# Fill with random leaf pixels
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = leaf_colors[randi() % leaf_colors.size()]
			# Add variation
			color.r += (randf() - 0.5) * 0.05
			color.g += (randf() - 0.5) * 0.05
			color.b += (randf() - 0.5) * 0.05
			image.set_pixel(x, y, color)
	
	return create_texture_from_image(image)

static func create_strawberry_berry_texture() -> ImageTexture:
	"""Create a pixelated red strawberry texture with seeds"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Strawberry red colors
	var berry_colors = [
		Color(0.85, 0.15, 0.1),   # Deep red
		Color(0.9, 0.2, 0.15),    # Bright red
		Color(0.8, 0.12, 0.08),   # Dark red
		Color(0.95, 0.25, 0.2)    # Light red
	]
	
	# Fill base with red
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = berry_colors[randi() % berry_colors.size()]
			# Add variation
			color.r += (randf() - 0.5) * 0.05
			color.g += (randf() - 0.5) * 0.05
			color.b += (randf() - 0.5) * 0.05
			image.set_pixel(x, y, color)
	
	# Add small yellow "seeds" scattered around
	var seed_count = 15 + randi() % 10
	for i in range(seed_count):
		var seed_x = randi() % TEXTURE_SIZE
		var seed_y = randi() % TEXTURE_SIZE
		var seed_color = Color(0.9, 0.85, 0.3)  # Yellow seed
		image.set_pixel(seed_x, seed_y, seed_color)
	
	return create_texture_from_image(image)

static func create_texture_from_image(image: Image) -> ImageTexture:
	"""Convert an Image to an ImageTexture with nearest-neighbor filtering"""
	var texture = ImageTexture.create_from_image(image)
	
	# CRITICAL: Set texture filter to NEAREST for crisp pixels (no blur)
	# This is what makes it look pixelated instead of blurry
	texture.set_meta("texture_filter", RenderingDevice.SAMPLER_FILTER_NEAREST)
	
	return texture

static func create_pixel_material(texture: ImageTexture, base_color: Color = Color.WHITE) -> StandardMaterial3D:
	"""Create a material with pixelated texture"""
	var material = StandardMaterial3D.new()
	
	# Set the texture
	material.albedo_texture = texture
	material.albedo_color = base_color
	
	# CRITICAL: Set texture filter to NEAREST (no interpolation)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	# Standard material settings
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED  # No shiny surfaces
	material.roughness = 1.0  # Matte finish
	
	# Enable UV mapping
	material.uv1_scale = Vector3(1, 1, 1)
	material.uv1_triplanar = true  # Auto UV mapping for procedural meshes
	
	return material

static func create_chest_texture() -> ImageTexture:
	"""Create a pixelated chest texture with wood planks and metal straps"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Wood colors (dark brown planks)
	var wood_base = Color(0.4, 0.25, 0.15)    # Dark brown
	var wood_light = Color(0.5, 0.35, 0.2)    # Lighter brown
	var wood_dark = Color(0.3, 0.18, 0.1)     # Very dark brown
	
	# Metal colors (iron straps)
	var metal_dark = Color(0.15, 0.15, 0.15)  # Dark gray/black
	var metal_light = Color(0.3, 0.3, 0.3)    # Light gray
	
	# Fill base with wood planks
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = wood_base
			
			# Vertical wood planks (every 4 pixels)
			if x % 4 == 0:
				color = wood_dark
			elif x % 4 == 3:
				color = wood_light
			
			# Add grain variation
			color.r += (randf() - 0.5) * 0.08
			color.g += (randf() - 0.5) * 0.08
			color.b += (randf() - 0.5) * 0.08
			
			image.set_pixel(x, y, color)
	
	# Add horizontal metal straps (3 rows)
	var strap_positions = [3, 7, 12]  # y positions for straps
	for strap_y in strap_positions:
		for x in range(TEXTURE_SIZE):
			# Metal strap (2 pixels tall)
			var metal_color = metal_dark
			if x % 3 == 0:
				metal_color = metal_light  # Highlight for metallic look
			
			image.set_pixel(x, strap_y, metal_color)
			if strap_y + 1 < TEXTURE_SIZE:
				image.set_pixel(x, strap_y + 1, metal_color.darkened(0.2))
	
	# Add vertical metal corner reinforcements
	for y in range(TEXTURE_SIZE):
		# Left edge strap
		image.set_pixel(0, y, metal_dark)
		image.set_pixel(1, y, metal_light if y % 3 == 0 else metal_dark)
		
		# Right edge strap
		image.set_pixel(TEXTURE_SIZE - 2, y, metal_light if y % 3 == 0 else metal_dark)
		image.set_pixel(TEXTURE_SIZE - 1, y, metal_dark)
	
	# Add keyhole in center (decorative)
	var center_x = TEXTURE_SIZE / 2
	var center_y = TEXTURE_SIZE / 2
	image.set_pixel(center_x, center_y, Color(0.1, 0.1, 0.1))  # Keyhole
	image.set_pixel(center_x, center_y + 1, Color(0.1, 0.1, 0.1))
	
	return create_texture_from_image(image)

static func get_biome_terrain_material(biome: int) -> StandardMaterial3D:
	"""Get the appropriate terrain material for a biome"""
	match biome:
		0: # OCEAN (dark seafloor)
			return create_pixel_material(create_stone_texture(), Color(0.5, 0.55, 0.6))
		1: # BEACH (light sandy tan)
			return create_pixel_material(create_sand_texture(), Color(1.1, 1.05, 0.9))
		2: # GRASSLAND (green grass)
			return create_pixel_material(create_grass_texture())
		3: # FOREST (darker green)
			return create_pixel_material(create_grass_texture(), Color(0.85, 0.9, 0.85))
		4: # DESERT (warm yellow sand)
			return create_pixel_material(create_sand_texture(), Color(1.05, 0.95, 0.75))
		5: # MOUNTAIN (gray stone)
			return create_pixel_material(create_stone_texture(), Color(0.95, 0.95, 0.95))
		6: # SNOW (white)
			return create_pixel_material(create_snow_texture())
		_:
			return create_pixel_material(create_grass_texture())
