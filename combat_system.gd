extends Node
class_name CombatSystem

# CombatSystem - Handles all combat mechanics
# - Light attack (tap RT/LMB)
# - Heavy attack (charge 1.5s, release)
# - Dodge system (Space/A + direction)
# - Targeting with soft auto-aim for controller

# References
var player: CharacterBody3D
var camera: Camera3D
var health_hunger_system: HealthHungerSystem

# Combat state
var attack_cooldown: float = 0.0
var is_charging: bool = false
var charge_start_time: float = 0.0
var dodge_cooldown: float = 0.0
var is_dodging: bool = false
var dodge_timer: float = 0.0

# Weapon system
var current_weapon_id: String = "wooden_club"
var current_weapon: Weapon = null
var equipped_weapons: Array[String] = ["wooden_club"]  # Player's weapon inventory

# Bow system
var is_drawing_bow: bool = false
var draw_start_time: float = 0.0
var arrow_count: int = 20
var bow_equipped: bool = true  # Player has bow by default

# Combat constants
const CHARGE_THRESHOLD: float = 1.5  # Seconds to charge for heavy attack
const DODGE_COOLDOWN: float = 3.0
const DODGE_DURATION: float = 0.3
const DODGE_DISTANCE: float = 4.0
const DODGE_IFRAME_DURATION: float = 0.3  # Invincibility frames
const AUTO_AIM_CONE_ANGLE: float = 30.0  # Degrees for controller auto-aim

# Bow constants
const MAX_DRAW_TIME: float = 2.0
const MIN_ARROW_DAMAGE: int = 15
const MAX_ARROW_DAMAGE: int = 40
const BOW_RANGE: float = 30.0

# Camera shake
var camera_shake_intensity: float = 0.0
var camera_shake_duration: float = 0.0
var original_camera_position: Vector3 = Vector3.ZERO

# Signals
signal weapon_switched(weapon_name: String)
signal attack_performed(is_heavy: bool)
signal dodge_performed()
signal arrow_fired(damage: int)

func initialize(p: CharacterBody3D, cam: Camera3D, health_sys: HealthHungerSystem):
	"""Initialize combat system with references"""
	player = p
	camera = cam
	health_hunger_system = health_sys
	
	# Load initial weapon
	current_weapon = Weapon.get_weapon(current_weapon_id)
	
	if camera:
		original_camera_position = camera.position
	
	print("[CombatSystem] Initialized with weapon: ", current_weapon.weapon_name)

func _process(delta: float):
	# Update cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	if dodge_cooldown > 0:
		dodge_cooldown -= delta
	
	# Update dodge state
	if is_dodging:
		dodge_timer -= delta
		if dodge_timer <= 0:
			is_dodging = false
	
	# Update camera shake
	if camera_shake_duration > 0:
		camera_shake_duration -= delta
		apply_camera_shake(delta)
	elif camera:
		camera.position = original_camera_position

# ============================================================================
# MELEE COMBAT
# ============================================================================

func start_charging():
	"""Start charging a heavy attack"""
	if attack_cooldown > 0:
		return
	
	if not current_weapon:
		return
	
	is_charging = true
	charge_start_time = Time.get_ticks_msec() / 1000.0
	
	# Audio feedback (will be integrated when sounds are generated in Phase 3)
	# if AudioManager:
	# 	AudioManager.play_sound("charge_buildup", "sfx", false, true)
	
	# Start rumble feedback
	if RumbleManager:
		RumbleManager.play_custom(0.1, 0.1, 0.5)  # Light continuous rumble

func release_attack():
	"""Release attack (light or heavy based on charge time)"""
	if not is_charging:
		return
	
	var charge_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
	is_charging = false
	
	# Stop charge audio
	# TODO: AudioManager doesn't have stop_sound() - will need to implement when adding combat sounds
	# if AudioManager:
	# 	AudioManager.stop_sound("charge_buildup")
	
	# Determine attack type
	if charge_time >= CHARGE_THRESHOLD:
		perform_heavy_attack()
	else:
		perform_light_attack()

func perform_light_attack():
	"""Execute light attack"""
	print("💥 LIGHT ATTACK TRIGGERED!")
	if attack_cooldown > 0 or not current_weapon:
		print("   ❌ Blocked - Cooldown: ", attack_cooldown, " | Has weapon: ", current_weapon != null)
		return
	
	# Set cooldown
	attack_cooldown = current_weapon.attack_cooldown
	
	# Find target
	var target = raycast_for_enemy(current_weapon.attack_range)
	
	if target:
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(current_weapon.light_damage, false)
		
		# Audio feedback
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("swing_light", "sfx", true, false)
		# 	AudioManager.play_sound("hit_flesh", "sfx", true, false)
		
		# Camera shake (INCREASED 10X for visibility)
		shake_camera(1.0, 0.15)
		print("   📷 Camera shake: 1.0 intensity (STRONG)")
		
		# Rumble
		if RumbleManager:
			RumbleManager.play("medium")
			print("   🎮 Rumble: medium")
	else:
		# Swing but no hit
		print("   ⚔️ Swing (no target)")
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("swing_light", "sfx", true, false)
		
		# Camera shake (INCREASED 10X for visibility)
		shake_camera(0.5, 0.1)
		print("   📷 Camera shake: 0.5 intensity (MEDIUM)")
		
		# Light rumble
		if RumbleManager:
			RumbleManager.play("light")
			print("   🎮 Rumble: light")
	
	emit_signal("attack_performed", false)

func perform_heavy_attack():
	"""Execute heavy attack (charged)"""
	print("💥💥 HEAVY ATTACK TRIGGERED!")
	if attack_cooldown > 0 or not current_weapon:
		print("   ❌ Blocked - Cooldown: ", attack_cooldown, " | Has weapon: ", current_weapon != null)
		return
	
	# Set cooldown
	attack_cooldown = current_weapon.attack_cooldown
	
	# Find target
	var target = raycast_for_enemy(current_weapon.attack_range)
	
	if target:
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(current_weapon.heavy_damage, true)
		
		# Audio feedback
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("charge_ready", "sfx", false, false)
		# 	AudioManager.play_sound("swing_heavy", "sfx", true, false)
		# 	AudioManager.play_sound("hit_flesh", "sfx", true, false)
		
		# Camera shake (INCREASED 10X for visibility)
		shake_camera(3.0, 0.4)
		print("   📷 Camera shake: 3.0 intensity (VERY STRONG)")
		
		# Heavy rumble
		if RumbleManager:
			RumbleManager.play("heavy")
			print("   🎮 Rumble: heavy")
	else:
		# Swing but no hit
		print("   ⚔️ Heavy swing (no target)")
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("swing_heavy", "sfx", true, false)
		
		# Camera shake (INCREASED 10X for visibility)
		shake_camera(1.5, 0.3)
		print("   📷 Camera shake: 1.5 intensity (STRONG)")
		
		# Medium rumble
		if RumbleManager:
			RumbleManager.play("medium")
			print("   🎮 Rumble: medium")
	
	emit_signal("attack_performed", true)

# ============================================================================
# DODGE SYSTEM
# ============================================================================

func try_dodge(input_dir: Vector2) -> bool:
	"""Attempt to perform a dodge dash"""
	print("🏃 DODGE ATTEMPTED! Input dir: ", input_dir)
	if dodge_cooldown > 0:
		print("   ❌ Dodge on cooldown: ", dodge_cooldown)
		return false
	
	if is_dodging:
		return false
	
	# Get dodge direction (forward if no input)
	var dodge_direction: Vector3
	if input_dir.length() > 0.1:
		dodge_direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		# Dodge forward if no input
		dodge_direction = -player.transform.basis.z
	
	# Perform dodge
	print("   ✅ DODGE EXECUTING!")
	is_dodging = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown = DODGE_COOLDOWN
	
	# Apply dodge velocity
	player.velocity = dodge_direction * (DODGE_DISTANCE / DODGE_DURATION)
	player.velocity.y = 0  # Keep grounded
	
	# Camera shake (INCREASED for visibility)
	shake_camera(0.8, 0.2)
	print("   📷 Camera shake: 0.8 intensity")
	
	# Audio feedback (Phase 3)
	# if AudioManager:
	# 	AudioManager.play_sound("dodge_whoosh", "sfx", true, false)
	
	# Rumble feedback
	if RumbleManager:
		RumbleManager.play("medium")
		print("   🎮 Rumble: medium")
	
	emit_signal("dodge_performed")
	return true

func is_invincible() -> bool:
	"""Check if player is currently invincible (i-frames)"""
	return is_dodging and dodge_timer > (DODGE_DURATION - DODGE_IFRAME_DURATION)

# ============================================================================
# BOW SYSTEM
# ============================================================================

func start_drawing_bow():
	"""Start drawing the bow"""
	if arrow_count <= 0:
		print("[CombatSystem] No arrows!")
		return
	
	if attack_cooldown > 0:
		return
	
	is_drawing_bow = true
	draw_start_time = Time.get_ticks_msec() / 1000.0
	
	# Audio feedback (Phase 3)
	# if AudioManager:
	# 	AudioManager.play_sound("bow_draw", "sfx", false, true)
	
	# Light rumble while drawing
	if RumbleManager:
		RumbleManager.play_custom(0.05, 0.05, 0.5)

func release_arrow():
	"""Release arrow and fire"""
	if not is_drawing_bow:
		return
	
	var draw_time = (Time.get_ticks_msec() / 1000.0) - draw_start_time
	var draw_percent = clampf(draw_time / MAX_DRAW_TIME, 0.0, 1.0)
	is_drawing_bow = false
	
	# Stop draw audio
	# TODO: AudioManager doesn't have stop_sound() - will need to implement when adding combat sounds
	# if AudioManager:
	# 	AudioManager.stop_sound("bow_draw")
	
	# Calculate damage based on draw time
	var damage = int(lerp(MIN_ARROW_DAMAGE, MAX_ARROW_DAMAGE, draw_percent))
	
	# Fire arrow (hitscan)
	var target = raycast_for_enemy(BOW_RANGE)
	if target:
		if target.has_method("take_damage"):
			target.take_damage(damage, draw_percent >= 1.0)
		
		# Audio feedback
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("bow_release", "sfx", false, false)
		# 	AudioManager.play_sound("arrow_hit_flesh", "sfx", false, false)
		
		# Rumble based on charge
		if RumbleManager:
			var rumble_strength = lerp(0.2, 0.4, draw_percent)
			RumbleManager.play_custom(rumble_strength, 0.1, 0.2)
	else:
		# Miss
		# PLACEHOLDER: Audio will be added in Phase 3
		# if AudioManager:
		# 	AudioManager.play_sound("bow_release", "sfx", false, false)
		
		# Light rumble
		if RumbleManager:
			RumbleManager.play("light")
	
	# Consume arrow
	arrow_count -= 1
	
	# Camera recoil
	shake_camera(0.05 + (draw_percent * 0.15), 0.2)
	
	emit_signal("arrow_fired", damage)

func get_draw_percent() -> float:
	"""Get current bow draw percentage (for UI)"""
	if not is_drawing_bow:
		return 0.0
	
	var draw_time = (Time.get_ticks_msec() / 1000.0) - draw_start_time
	return clampf(draw_time / MAX_DRAW_TIME, 0.0, 1.0)

# ============================================================================
# TARGETING SYSTEM
# ============================================================================

func raycast_for_enemy(range: float) -> Node:
	"""Raycast from camera to find enemy target"""
	if not camera or not player:
		return null
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * range
	
	# Check for controller (soft auto-aim)
	var use_auto_aim = Input.get_connected_joypads().size() > 0
	
	if use_auto_aim:
		# Cone-based auto-aim for controller
		return raycast_with_auto_aim(from, to, range)
	else:
		# Precise raycast for mouse
		return raycast_direct(from, to)

func raycast_direct(from: Vector3, to: Vector3) -> Node:
	"""Direct raycast (mouse & keyboard)"""
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0b100000000  # Layer 9 (enemies)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		if result.collider.is_in_group("enemies"):
			return result.collider
	
	return null

func raycast_with_auto_aim(from: Vector3, to: Vector3, range: float) -> Node:
	"""Cone-based auto-aim for controller"""
	var forward = (to - from).normalized()
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var best_enemy = null
	var best_score = -1.0
	
	for enemy in enemies:
		var enemy_pos = enemy.global_position
		var distance = from.distance_to(enemy_pos)
		
		# Check if in range
		if distance > range:
			continue
		
		# Check angle
		var to_enemy = (enemy_pos - from).normalized()
		var angle = rad_to_deg(forward.angle_to(to_enemy))
		
		if angle <= AUTO_AIM_CONE_ANGLE:
			# Score based on angle (closer to center = better)
			var score = 1.0 - (angle / AUTO_AIM_CONE_ANGLE)
			
			# Prefer closer enemies slightly
			score += (1.0 - distance / range) * 0.2
			
			if score > best_score:
				best_score = score
				best_enemy = enemy
	
	return best_enemy

# ============================================================================
# WEAPON SWITCHING
# ============================================================================

func cycle_weapon():
	"""Cycle to next equipped weapon"""
	if equipped_weapons.size() == 0:
		return
	
	var current_index = equipped_weapons.find(current_weapon_id)
	var next_index = (current_index + 1) % equipped_weapons.size()
	current_weapon_id = equipped_weapons[next_index]
	current_weapon = Weapon.get_weapon(current_weapon_id)
	
	print("[CombatSystem] Switched to: ", current_weapon.weapon_name)
	emit_signal("weapon_switched", current_weapon.weapon_name)

func add_weapon(weapon_id: String):
	"""Add weapon to equipped weapons"""
	if weapon_id not in equipped_weapons:
		equipped_weapons.append(weapon_id)
		print("[CombatSystem] Added weapon: ", weapon_id)

# ============================================================================
# CAMERA EFFECTS
# ============================================================================

func shake_camera(intensity: float, duration: float):
	"""Shake the camera for combat feedback"""
	camera_shake_intensity = intensity
	camera_shake_duration = duration

func apply_camera_shake(delta: float):
	"""Apply camera shake effect"""
	if not camera:
		return
	
	var shake_amount = camera_shake_intensity * (camera_shake_duration / 0.5)
	var shake_offset = Vector3(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount),
		0
	)
	
	camera.position = original_camera_position + shake_offset

# ============================================================================
# UTILITY
# ============================================================================

func can_attack() -> bool:
	"""Check if player can currently attack"""
	return attack_cooldown <= 0 and not is_dodging

func can_dodge() -> bool:
	"""Check if player can currently dodge"""
	return dodge_cooldown <= 0 and not is_dodging

func get_charge_percent() -> float:
	"""Get current charge percentage (for UI)"""
	if not is_charging:
		return 0.0
	
	var charge_time = (Time.get_ticks_msec() / 1000.0) - charge_start_time
	return clampf(charge_time / CHARGE_THRESHOLD, 0.0, 1.0)
