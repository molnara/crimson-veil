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
	"""Create a pixelated tree bark texture"""
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	
	# Bark colors (dark brown)
	var base_color = Color(0.3, 0.2, 0.1)
	var highlight_color = Color(0.4, 0.25, 0.15)
	
	# Create bark pattern (horizontal-ish lines)
	for x in range(TEXTURE_SIZE):
		for y in range(TEXTURE_SIZE):
			var color = base_color
			
			# Horizontal bark lines
			if y % 4 == 0 or y % 4 == 1:
				color = highlight_color
			
			# Add noise
			color.r += (randf() - 0.5) * 0.1
			color.g += (randf() - 0.5) * 0.1
			color.b += (randf() - 0.5) * 0.1
			
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
