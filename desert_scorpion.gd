extends Enemy
class_name DesertScorpion

## Desert Scorpion - Ambush predator enemy
## Behavior: Starts buried, emerges when player approaches, tail strike attacks, can re-burrow
## Stats: 60 HP, 15 DMG, 3.0 speed, 2.5m attack range

# Scorpion-specific behavior
enum ScorpionState { BURIED, EMERGING, SURFACED, BURROWING }

const EMERGE_DISTANCE: float = 8.0  # Distance to trigger emerge
const EMERGE_DURATION: float = 0.5  # Time to emerge from sand
const BURROW_DURATION: float = 0.5  # Time to burrow back
const REBURROW_CHANCE: float = 0.3  # 30% chance to burrow after attack
const BURIED_Y_OFFSET: float = -2.0  # How deep underground when buried

var scorpion_state: ScorpionState = ScorpionState.BURIED
var is_transitioning: bool = false
var surface_y_position: float = 0.0  # Y position when fully surfaced

func _ready() -> void:
	# Set scorpion stats from balance table
	max_health = 60
	damage = 15
	move_speed = 3.0
	attack_range = 2.5
	detection_range = 15.0  # Larger detection for buried state
	attack_cooldown_duration = 2.0
	attack_telegraph_duration = 0.5
	
	# Configure drop table
	drop_table = [
		{"item": "chitin", "chance": 1.0},  # 100% chance
		{"item": "venom_sac", "chance": 0.25}  # 25% rare drop
	]
	
	# Store initial surface position BEFORE calling super
	surface_y_position = global_position.y
	
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
	
	# Start buried (AFTER super._ready so player reference is set)
	if scorpion_state == ScorpionState.BURIED:
		global_position.y += BURIED_Y_OFFSET
		set_buried_visibility(false)

func _physics_process(delta: float) -> void:
	# Handle buried state separately
	if scorpion_state == ScorpionState.BURIED and not is_transitioning:
		check_for_emerge()
		# Still apply gravity even when buried
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		move_and_slide()
		return
	
	# Call parent physics
	super._physics_process(delta)

func check_for_emerge() -> void:
	"""Check if player is close enough to trigger emerge"""
	# Get player reference if we don't have it
	if not player:
		player = get_tree().get_first_node_in_group("player")
	
	if not player or is_transitioning:
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance < EMERGE_DISTANCE:
		emerge_from_sand()

func emerge_from_sand() -> void:
	"""Emerge from buried state with animation"""
	if is_transitioning or scorpion_state != ScorpionState.BURIED:
		return
	
	is_transitioning = true
	scorpion_state = ScorpionState.EMERGING
	
	# Make visible immediately
	set_buried_visibility(true)
	
	# Tween position upward
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", surface_y_position, EMERGE_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	
	scorpion_state = ScorpionState.SURFACED
	is_transitioning = false
	current_state = State.IDLE  # Enter normal AI

func burrow_into_sand() -> void:
	"""Burrow back underground"""
	if is_transitioning or scorpion_state == ScorpionState.BURIED:
		return
	
	is_transitioning = true
	scorpion_state = ScorpionState.BURROWING
	current_state = State.IDLE  # Stop AI while burrowing
	velocity = Vector3.ZERO
	
	# Tween position downward
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", surface_y_position + BURIED_Y_OFFSET, BURROW_DURATION)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	
	# Hide when fully buried
	set_buried_visibility(false)
	scorpion_state = ScorpionState.BURIED
	is_transitioning = false
	
	# Reset health slightly when burrowing (ambush predator advantage)
	current_health = min(current_health + 10, max_health)

func set_buried_visibility(visible_state: bool) -> void:
	"""Toggle visibility of visual node"""
	var visual = get_node_or_null("Visual")
	if visual:
		visual.visible = visible_state

func update_ai(_delta: float) -> void:
	"""Override AI to handle burrow state"""
	# Don't run AI if buried or transitioning
	if scorpion_state == ScorpionState.BURIED or is_transitioning:
		return
	
	# Call parent AI
	super.update_ai(_delta)

func execute_attack() -> void:
	"""Execute tail strike attack"""
	super.execute_attack()
	
	# Chance to re-burrow after attacking
	if scorpion_state == ScorpionState.SURFACED and randf() < REBURROW_CHANCE:
		# Delay burrow slightly
		await get_tree().create_timer(1.0).timeout
		if current_state != State.DEATH:
			burrow_into_sand()

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

func on_attack_execute() -> void:
	"""Play attack sound (TODO: integrate with AudioManager)"""
	# TODO: AudioManager.play_sound("scorpion_strike", "combat")
	pass

func on_death() -> void:
	"""Play death sound (TODO: integrate with AudioManager)"""
	# TODO: AudioManager.play_sound("scorpion_death", "combat")
	pass

func take_damage(amount: int) -> void:
	"""Override to force emerge when damaged while buried"""
	# If buried and damaged, emerge immediately
	if scorpion_state == ScorpionState.BURIED:
		emerge_from_sand()
	
	super.take_damage(amount)

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
	add_child(visual_root)
	
	var sandy_yellow = Color(0.85, 0.75, 0.4)
	
	# === BODY SEGMENTS (3 segments, sandy yellow) ===
	for i in range(3):
		var segment = CSGBox3D.new()
		segment.size = Vector3(0.8 - (i * 0.15), 0.4, 0.6)
		segment.position = Vector3(0, 0.5, -i * 0.6)
		segment.name = "BodySegment" + str(i)
		visual_root.add_child(segment)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = sandy_yellow
		segment.material = mat
	
	# === PINCERS (2x front claws) ===
	for i in range(2):
		var pincer = CSGBox3D.new()
		pincer.size = Vector3(0.3, 0.2, 0.5)
		var side = -1.0 if i == 0 else 1.0
		pincer.position = Vector3(side * 0.5, 0.3, 0.5)
		pincer.rotation_degrees = Vector3(0, side * 20, 0)
		pincer.name = "Pincer" + ("Left" if i == 0 else "Right")
		visual_root.add_child(pincer)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = sandy_yellow.darkened(0.2)
		pincer.material = mat
	
	# === TAIL (curved upward with 4 segments) ===
	for i in range(4):
		var tail_seg = CSGCylinder3D.new()
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
		tail_seg.material = mat
	
	# === STINGER (at tip of tail) ===
	var stinger = CSGSphere3D.new()
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
