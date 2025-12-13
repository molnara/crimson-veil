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

# Weapon system
var current_weapon_id: String = "wooden_club"
var current_weapon: Weapon = null
var equipped_weapons: Array[String] = ["wooden_club"]  # Player's weapon inventory

# Combat settings (configurable via inspector)
@export_group("Combat Timing")
@export_range(0.1, 2.0, 0.1) var attack_cooldown_duration: float = 0.5  ## Cooldown between attacks in seconds
@export_range(1.0, 10.0, 0.5) var attack_range: float = 3.0  ## Base attack range in meters (overridden by equipped weapon)

@export_group("Targeting")
@export_range(0.0, 90.0, 5.0) var auto_aim_cone_angle: float = 30.0  ## Controller auto-aim cone angle in degrees (0 = no auto-aim, 90 = very forgiving)

# Camera shake
var camera_shake_intensity: float = 0.0
var camera_shake_duration: float = 0.0
var original_camera_position: Vector3 = Vector3.ZERO

# Signals
signal weapon_switched(weapon_name: String)
signal attack_performed(is_heavy: bool)

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
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Update camera shake
	if camera_shake_duration > 0:
		camera_shake_duration -= delta
		apply_camera_shake(delta)
	elif camera:
		camera.position = original_camera_position

# ============================================================================
# MELEE COMBAT
# ============================================================================

func perform_attack():
	"""Execute simple melee attack - Minecraft style
	
	Single-shot attack on button press:
	- Raycast hit detection from camera
	- Soft auto-aim (30° cone) for controllers
	- Weapon-specific range and damage
	- 0.5s cooldown between attacks
	"""
	if attack_cooldown > 0 or not current_weapon:
		return
	
	# Set cooldown
	attack_cooldown = attack_cooldown_duration
	
	# Find target
	var target = raycast_for_enemy(current_weapon.attack_range)
	
	if target:
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(current_weapon.light_damage, false)
		
		# Audio feedback (Phase 3)
		# if AudioManager:
		# 	AudioManager.play_sound("swing_light", "sfx", true, false)
		# 	AudioManager.play_sound("hit_flesh", "sfx", true, false)
		
		# Camera shake
		shake_camera(0.5, 0.1)
		
		# Rumble
		if RumbleManager:
			RumbleManager.play("medium")
	else:
		# Swing but no hit
		# if AudioManager:
		# 	AudioManager.play_sound("swing_light", "sfx", true, false)
		
		# Light camera shake
		shake_camera(0.3, 0.08)
		
		# Light rumble
		if RumbleManager:
			RumbleManager.play("light")
	
	emit_signal("attack_performed", false)

# ============================================================================
# TARGETING SYSTEM
# ============================================================================

func raycast_for_enemy(range: float) -> Node:
	"""Raycast from camera to find enemy target - Task 1.2 Targeting System
	
	Two modes:
	1. Mouse & Keyboard: Precise raycast from camera center
	2. Controller: Soft auto-aim with 30° cone
	   - Finds enemies within cone
	   - Prioritizes closest to crosshair center
	   - Slightly favors closer enemies
	
	Returns:
	- Enemy node if found in range
	- null if no valid target
	"""
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
		
		if angle <= auto_aim_cone_angle:
			# Score based on angle (closer to center = better)
			var score = 1.0 - (angle / auto_aim_cone_angle)
			
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
	return attack_cooldown <= 0
