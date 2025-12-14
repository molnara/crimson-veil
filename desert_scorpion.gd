extends Enemy
class_name DesertScorpion

## Desert Scorpion - Ground-based melee enemy
## Behavior: Standard chase and attack (buried mechanics removed for v0.6.0)
## Stats: 60 HP, 15 DMG, 3.0 speed, 2.5m attack range

# Ambient sound timer (performance optimization)
var ambient_sound_timer: float = 0.0
var next_ambient_delay: float = 0.0

func _ready() -> void:
	# Set scorpion stats from balance table
	max_health = 60
	damage = 15
	move_speed = 3.0
	attack_range = 2.5
	detection_range = 15.0
	attack_cooldown_duration = 2.0
	attack_telegraph_duration = 0.5
	
	# Prevent falling through terrain
	floor_snap_length = 0.5  # Snap to floor within 0.5m
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(45)
	
	# Configure drop table
	drop_table = [
		{"item": "chitin", "chance": 1.0},  # 100% chance
		{"item": "venom_sac", "chance": 0.25}  # 25% rare drop
	]
	
	# Setup collision shape before calling super
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.8
		shape.height = 1.5
		collision_shape.shape = shape
		collision_shape.position = Vector3(0, 0.5, 0)
		add_child(collision_shape)
	
	# Call parent _ready to initialize
	super._ready()

func update_ai(_delta: float) -> void:
	"""Override AI for ambient sounds"""
	# Ambient sounds (timer-based - every 5-8 seconds)
	ambient_sound_timer += _delta
	if ambient_sound_timer >= next_ambient_delay:
		AudioManager.play_sound_3d("scorpion_ambient", global_position, "sfx", false, false)
		ambient_sound_timer = 0.0
		next_ambient_delay = randf_range(5.0, 8.0)
	
	# Call parent AI
	super.update_ai(_delta)

func execute_attack() -> void:
	"""Execute tail strike attack"""
	super.execute_attack()

func on_attack_telegraph() -> void:
	"""Wind up tail for strike - flash red"""
	var visual = get_node_or_null("Visual")
	if not visual:
		return
	
	var stinger = visual.get_node_or_null("Stinger")
	if not stinger:
		return
	
	# Flash stinger red during telegraph
	var mat = stinger.material as StandardMaterial3D
	if mat:
		var original_color = mat.albedo_color
		mat.albedo_color = Color.RED
		
		# Restore after telegraph
		await get_tree().create_timer(attack_telegraph_duration).timeout
		if mat:
			mat.albedo_color = original_color
	
	# Play attack sound
	AudioManager.play_sound_3d("scorpion_attack", global_position, "sfx", false, false)

func on_hit() -> void:
	"""Play hit sound effect"""
	AudioManager.play_sound_3d("scorpion_hit", global_position, "sfx", false, false)

func on_death() -> void:
	"""Play death sound"""
	AudioManager.play_sound_3d("scorpion_death", global_position, "sfx", false, false)
	pass

func flash_white() -> void:
	"""Override damage flash for Visual node structure"""
	var visual = get_node_or_null("Visual")
	if not visual:
		return
	
	# Flash all children white
	for child in visual.get_children():
		if child is GeometryInstance3D:
			var mat = child.get("material")
			if mat is StandardMaterial3D:
				var original_color = mat.albedo_color
				mat.albedo_color = Color.WHITE
				
				# Restore after 0.1s
				await get_tree().create_timer(0.1).timeout
				if mat:
					mat.albedo_color = original_color
				break  # Only flash first segment to avoid multiple timers

func create_enemy_visual() -> void:
	"""Create CSG scorpion appearance"""
	# Create visual container
	var visual_root = Node3D.new()
	visual_root.name = "Visual"
	visual_root.rotation_degrees.y = 180  # Fix backward movement
	add_child(visual_root)
	
	var sandy_yellow = Color(0.85, 0.75, 0.4)
	
	# Load chitin texture
	var chitin_texture = preload("res://textures/desert_scorpion_chitin.jpg")
	
	# === BODY SEGMENTS (3 segments, sandy yellow) ===
	for i in range(3):
		var segment = CSGBox3D.new()
		segment.use_collision = false  # Disable CSG collision
		segment.size = Vector3(0.8 - (i * 0.15), 0.4, 0.6)
		segment.position = Vector3(0, 0.5, -i * 0.6)
		segment.name = "BodySegment" + str(i)
		visual_root.add_child(segment)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = sandy_yellow
		mat.albedo_texture = chitin_texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.roughness = 0.7  # Shiny chitin
		segment.material = mat
	
	# === PINCERS (2x front claws) ===
	for i in range(2):
		var pincer = CSGBox3D.new()
		pincer.use_collision = false
		pincer.size = Vector3(0.3, 0.2, 0.5)
		var side = -1.0 if i == 0 else 1.0
		pincer.position = Vector3(side * 0.5, 0.3, 0.5)
		pincer.rotation_degrees = Vector3(0, side * 20, 0)
		pincer.name = "Pincer" + ("Left" if i == 0 else "Right")
		visual_root.add_child(pincer)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = sandy_yellow.darkened(0.2)
		mat.albedo_texture = chitin_texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.roughness = 0.7
		pincer.material = mat
	
	# === TAIL (curved upward with 4 segments) ===
	for i in range(4):
		var tail_seg = CSGCylinder3D.new()
		tail_seg.use_collision = false
		tail_seg.radius = 0.15 - (i * 0.02)
		tail_seg.height = 0.4
		
		# Curve upward
		var y_pos = 0.3 + (i * 0.4)
		var z_pos = -1.8 - (i * 0.3)
		tail_seg.position = Vector3(0, y_pos, z_pos)
		tail_seg.rotation_degrees = Vector3(30 + (i * 10), 0, 0)
		tail_seg.name = "TailSegment" + str(i)
		visual_root.add_child(tail_seg)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = sandy_yellow.darkened(0.1)
		mat.albedo_texture = chitin_texture
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.roughness = 0.7
		tail_seg.material = mat
	
	# === STINGER (at tip of tail) ===
	var stinger = CSGSphere3D.new()
	stinger.use_collision = false
	stinger.radius = 0.15
	stinger.position = Vector3(0, 1.8, -3.0)
	stinger.name = "Stinger"
	visual_root.add_child(stinger)
	
	var stinger_mat = StandardMaterial3D.new()
	stinger_mat.albedo_color = Color(0.2, 0.1, 0.1)  # Dark for venom
	stinger.material = stinger_mat
	
	# === EYES (2x small black stalked eyes) ===
	for i in range(2):
		var eye = CSGSphere3D.new()
		eye.radius = 0.08
		var side = -1.0 if i == 0 else 1.0
		eye.position = Vector3(side * 0.3, 0.7, 0.3)
		eye.name = "Eye" + ("Left" if i == 0 else "Right")
		visual_root.add_child(eye)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.BLACK
		eye.material = mat
