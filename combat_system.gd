extends Node
class_name CombatSystem

# CombatSystem - Unified Attack/Harvest System
# - Single RT/LMB button for both combat AND harvesting
# - Swing tool at enemies = deal damage
# - Swing tool at resources = harvest hit
# - Gets damage/range from ToolSystem (unified tool/weapon system)

# References
var player: CharacterBody3D
var camera: Camera3D
var health_hunger_system: HealthHungerSystem
var tool_system: ToolSystem  # Unified tool/weapon system
var harvesting_system: Node  # Reference to harvesting system for resource hits

# Combat state
var attack_cooldown: float = 0.0

# Legacy weapon support (for backwards compatibility)
var current_weapon_id: String = "wooden_club"
var current_weapon: Weapon = null
var equipped_weapons: Array[String] = ["wooden_club"]

# Combat settings (configurable via inspector)
@export_group("Combat Timing")
@export_range(0.1, 2.0, 0.1) var attack_cooldown_duration: float = 0.5  ## Fallback cooldown
@export_range(1.0, 10.0, 0.5) var attack_range: float = 3.0  ## Fallback range

@export_group("Targeting")
@export_range(0.0, 90.0, 5.0) var auto_aim_cone_angle: float = 30.0  ## Controller auto-aim cone

# Harvesting settings
@export_group("Harvesting")
@export_range(0.1, 1.0, 0.05) var harvest_hit_amount: float = 0.5  ## Progress per hit (2 hits to harvest)

# Camera shake
var camera_shake_intensity: float = 0.0
var camera_shake_duration: float = 0.0
var original_camera_position: Vector3 = Vector3.ZERO

# Signals
signal weapon_switched(weapon_name: String)
signal attack_performed(is_heavy: bool)
signal resource_hit(resource: Node, progress: float)

func initialize(p: CharacterBody3D, cam: Camera3D, health_sys: HealthHungerSystem):
	"""Initialize combat system with references"""
	player = p
	camera = cam
	health_hunger_system = health_sys
	
	# Find ToolSystem
	tool_system = player.get_node_or_null("ToolSystem")
	if not tool_system:
		tool_system = player.tool_system if "tool_system" in player else null
	
	if tool_system:
		print("[CombatSystem] Connected to ToolSystem")
		tool_system.tool_changed.connect(_on_tool_changed)
	else:
		print("[CombatSystem] WARNING: ToolSystem not found, using legacy Weapon.gd")
		current_weapon = Weapon.get_weapon(current_weapon_id)
	
	# Find HarvestingSystem
	harvesting_system = player.get_node_or_null("HarvestingSystem")
	if harvesting_system:
		print("[CombatSystem] Connected to HarvestingSystem")
	
	if camera:
		original_camera_position = camera.position
	
	print("[CombatSystem] Initialized (unified attack/harvest)")

func _on_tool_changed(tool, tool_data: Dictionary) -> void:
	"""Called when player switches tools via ToolSystem"""
	var tool_name = tool_data.get("name", "Unknown")
	emit_signal("weapon_switched", tool_name)
	print("[CombatSystem] Tool changed to: %s" % tool_name)

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
# UNIFIED ATTACK (Combat + Harvesting)
# ============================================================================

func perform_attack():
	"""Execute unified attack - hits enemies OR resources
	
	Minecraft-style single button:
	- Raycast from camera
	- Priority: 1) Enemy (deal damage), 2) Resource (harvest hit), 3) Miss
	- Tool-specific range and damage (from ToolSystem)
	"""
	if attack_cooldown > 0:
		return
	
	# Get combat stats from ToolSystem or fallback
	var damage: int
	var attack_range_val: float
	var cooldown: float
	
	if tool_system:
		damage = tool_system.get_combat_damage()
		attack_range_val = tool_system.get_combat_range()
		cooldown = tool_system.get_attack_cooldown()
	elif current_weapon:
		damage = current_weapon.light_damage
		attack_range_val = current_weapon.attack_range
		cooldown = current_weapon.attack_cooldown
	else:
		damage = 10
		attack_range_val = attack_range
		cooldown = attack_cooldown_duration
	
	# Set cooldown
	attack_cooldown = cooldown
	
	# Always emit attack signal (for swing animation)
	emit_signal("attack_performed", false)
	
	# Try to find enemy first
	var enemy_target = raycast_for_enemy(attack_range_val)
	
	if enemy_target:
		# Hit enemy - deal damage
		hit_enemy(enemy_target, damage)
		return
	
	# No enemy - try to find resource
	var resource_target = raycast_for_resource(attack_range_val)
	
	if resource_target:
		# Hit resource - harvest
		hit_resource(resource_target)
		return
	
	# Miss - just swing
	swing_miss()

func hit_enemy(target: Node, damage: int) -> void:
	"""Deal damage to enemy target"""
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Audio feedback
	if AudioManager:
		AudioManager.play_sound("swing_light", "sfx", true, false)
		AudioManager.play_sound("hit_flesh", "sfx", true, false)
	
	# Camera shake (stronger on hit)
	shake_camera(0.5, 0.12)
	
	# Rumble
	if RumbleManager:
		RumbleManager.play("attack_light")

func hit_resource(resource: Node) -> void:
	"""Hit a harvestable resource"""
	print("[CombatSystem] hit_resource called on: ", resource.name if resource else "null")
	
	# Check if we have the right tool
	if tool_system and resource.has_method("get_info"):
		var resource_info = resource.get_info()
		var resource_type = resource_info.get("type", "generic")
		print("[CombatSystem] Resource type: ", resource_type, " | Tool can harvest: ", tool_system.can_harvest(resource_type))
		
		if not tool_system.can_harvest(resource_type):
			# Wrong tool!
			print("[CombatSystem] WRONG TOOL for ", resource_type)
			if AudioManager:
				AudioManager.play_sound("wrong_tool", "sfx")
			if RumbleManager:
				RumbleManager.play_wrong_tool()
			
			# Still play swing sound
			if AudioManager:
				AudioManager.play_sound("swing_light", "sfx", true, false)
			return
	
	# Apply harvest hit
	if resource.has_method("apply_harvest_hit"):
		var progress = resource.apply_harvest_hit(harvest_hit_amount)
		print("[CombatSystem] Applied harvest hit, progress: ", progress)
		emit_signal("resource_hit", resource, progress)
	elif resource.has_method("take_hit"):
		resource.take_hit(harvest_hit_amount)
	else:
		print("[CombatSystem] WARNING: Resource has no apply_harvest_hit or take_hit method!")
	
	# Play appropriate sound based on resource type
	_play_harvest_sound(resource)
	
	# Camera shake (light)
	shake_camera(0.3, 0.1)
	
	# Rumble
	if RumbleManager:
		RumbleManager.play_harvest_hit()

func _play_harvest_sound(resource: Node) -> void:
	"""Play harvest sound based on resource type"""
	if not resource.has_method("get_info"):
		if AudioManager:
			AudioManager.play_sound("swing_light", "sfx", true, false)
		return
	
	var resource_info = resource.get_info()
	var resource_type = resource_info.get("type", "generic")
	
	if AudioManager:
		AudioManager.play_sound("swing_light", "sfx", true, false)
		match resource_type:
			"wood":
				AudioManager.play_sound("axe_chop", "sfx")
			"stone", "ore":
				AudioManager.play_sound("pickaxe_hit", "sfx")
			"foliage":
				AudioManager.play_sound("mushroom_pick", "sfx")

func swing_miss() -> void:
	"""Swing but hit nothing"""
	if AudioManager:
		AudioManager.play_sound("swing_light", "sfx", true, false)
	
	# Light camera shake
	shake_camera(0.2, 0.08)
	
	# Light rumble
	if RumbleManager:
		RumbleManager.play("light")

# ============================================================================
# TARGETING SYSTEM
# ============================================================================

func raycast_for_enemy(range_val: float) -> Node:
	"""Raycast from camera to find enemy target"""
	if not camera or not player:
		return null
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * range_val
	
	# Check for controller (soft auto-aim)
	var use_auto_aim = Input.get_connected_joypads().size() > 0
	
	if use_auto_aim:
		return raycast_with_auto_aim(from, to, range_val)
	else:
		return raycast_direct_enemy(from, to)

func raycast_for_resource(range_val: float) -> Node:
	"""Raycast from camera to find harvestable resource"""
	if not camera or not player:
		return null
	
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from - camera.global_transform.basis.z * range_val
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0b10  # Layer 2 (harvestable resources)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider:
		# Check if it's a harvestable resource
		if result.collider.has_method("get_info") or result.collider.is_in_group("harvestable"):
			return result.collider
	
	return null

func raycast_direct_enemy(from: Vector3, to: Vector3) -> Node:
	"""Direct raycast for enemies (mouse & keyboard)"""
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

func raycast_with_auto_aim(from: Vector3, to: Vector3, range_val: float) -> Node:
	"""Cone-based auto-aim for controller"""
	var forward = (to - from).normalized()
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var best_enemy = null
	var best_score = -1.0
	
	for enemy in enemies:
		var enemy_pos = enemy.global_position
		var distance = from.distance_to(enemy_pos)
		
		if distance > range_val:
			continue
		
		var to_enemy = (enemy_pos - from).normalized()
		var angle = rad_to_deg(forward.angle_to(to_enemy))
		
		if angle <= auto_aim_cone_angle:
			var score = 1.0 - (angle / auto_aim_cone_angle)
			score += (1.0 - distance / range_val) * 0.2
			
			if score > best_score:
				best_score = score
				best_enemy = enemy
	
	return best_enemy

# ============================================================================
# WEAPON SWITCHING (Legacy support)
# ============================================================================

func cycle_weapon():
	"""Cycle to next equipped weapon (legacy - use ToolSystem instead)"""
	if tool_system:
		tool_system.cycle_tool()
		return
	
	if equipped_weapons.size() == 0:
		return
	
	var current_index = equipped_weapons.find(current_weapon_id)
	var next_index = (current_index + 1) % equipped_weapons.size()
	current_weapon_id = equipped_weapons[next_index]
	current_weapon = Weapon.get_weapon(current_weapon_id)
	
	emit_signal("weapon_switched", current_weapon.weapon_name)

func add_weapon(weapon_id: String):
	"""Add weapon to equipped weapons"""
	if weapon_id not in equipped_weapons:
		equipped_weapons.append(weapon_id)

# ============================================================================
# CAMERA EFFECTS
# ============================================================================

func shake_camera(intensity: float, duration: float):
	"""Shake the camera for feedback"""
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
