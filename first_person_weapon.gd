extends Node3D
class_name FirstPersonWeapon

## First-Person Weapon Display System
## Shows the currently equipped tool/weapon in the player's view (lower-right, Minecraft-style)
## Creates CSG primitive tools and animates swing on attack
## Listens to ToolSystem for tool changes

# Weapon visual nodes
var weapon_holder: Node3D  # Holds the weapon, used for swing animation
var current_weapon_visual: Node3D  # The actual weapon mesh
var current_tool_id: String = ""

# Swing animation state
var is_swinging: bool = false
var swing_timer: float = 0.0
var swing_duration: float = 0.5

# Current swing parameters (set per weapon)
var swing_start_rot: Vector3 = Vector3.ZERO
var swing_end_rot: Vector3 = Vector3.ZERO
var swing_start_pos: Vector3 = Vector3.ZERO
var swing_end_pos: Vector3 = Vector3.ZERO

# Swing style presets
const SWING_HORIZONTAL = {  # Axe - diagonal chop from right shoulder down to left
	"duration": 0.45,
	"start_rot": Vector3(-15, -30, 20),   # Wind up: tilted right, rotated right
	"end_rot": Vector3(25, 40, -15),      # Follow through: tilted left, rotated left  
	"start_pos": Vector3(0.1, 0.06, 0.05),    # Pulled to right side
	"end_pos": Vector3(-0.1, -0.1, -0.1)      # Swung to left side and down
}

const SWING_OVERHEAD = {  # Pickaxe - overhead downward swing with head tilt
	"duration": 0.5,
	"start_rot": Vector3(60, 0, 5),    # Raised UP with head tilted back
	"end_rot": Vector3(-70, 0, -5),    # Swung DOWN with head tilted forward into strike
	"start_pos": Vector3(0, 0.12, 0.1),   # Up and back
	"end_pos": Vector3(0, -0.18, -0.25)   # Down and forward (deeper strike)
}

const SWING_SMASH = {  # Club - overhead smash (like pickaxe but heavier)
	"duration": 0.55,
	"start_rot": Vector3(50, 10, -5),   # Raised UP 
	"end_rot": Vector3(-60, -10, 15),   # Smashed DOWN
	"start_pos": Vector3(0.05, 0.15, 0.1),   # Up and back
	"end_pos": Vector3(-0.05, -0.18, -0.2)   # Down and forward
}

const SWING_THRUST = {  # Spear - forward thrust/jab
	"duration": 0.35,
	"start_rot": Vector3(10, 10, 0),   # Pulled back
	"end_rot": Vector3(-15, -5, 0),    # Thrust forward
	"start_pos": Vector3(0.05, 0, 0.15),  # Back
	"end_pos": Vector3(-0.02, -0.05, -0.25)  # Forward thrust
}

const SWING_SLASH = {  # Sword - diagonal slash
	"duration": 0.4,
	"start_rot": Vector3(-20, -25, 20),  # Upper left
	"end_rot": Vector3(30, 30, -25),     # Lower right
	"start_pos": Vector3(-0.05, 0.1, 0.05),
	"end_pos": Vector3(0.1, -0.1, -0.1)
}

# Idle bob animation
var bob_timer: float = 0.0
const BOB_SPEED: float = 2.0
const BOB_AMOUNT: float = 0.02

# Walk/Sprint bob settings
const WALK_BOB_SPEED: float = 10.0
const WALK_BOB_AMOUNT_Y: float = 0.04  # Vertical bob
const WALK_BOB_AMOUNT_X: float = 0.025  # Horizontal sway
const SPRINT_BOB_SPEED: float = 14.0
const SPRINT_BOB_AMOUNT_Y: float = 0.06
const SPRINT_BOB_AMOUNT_X: float = 0.04
const SPRINT_TILT: float = 5.0  # Slight forward tilt when sprinting

# Player reference for movement detection
var player: CharacterBody3D = null

# Position offsets (lower-right of screen)
const WEAPON_POSITION: Vector3 = Vector3(0.3, -0.2, -0.45)
const WEAPON_ROTATION: Vector3 = Vector3(0, -15, 0)

# References
var tool_system: ToolSystem
var combat_system: CombatSystem

func _ready() -> void:
	# Create weapon holder (for animations)
	weapon_holder = Node3D.new()
	weapon_holder.name = "WeaponHolder"
	add_child(weapon_holder)
	
	# Set base position
	weapon_holder.position = WEAPON_POSITION
	weapon_holder.rotation_degrees = WEAPON_ROTATION
	
	# Find systems and connect signals
	call_deferred("connect_to_systems")

func connect_to_systems() -> void:
	"""Find and connect to ToolSystem and CombatSystem"""
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("[FirstPersonWeapon] WARNING: Player not found")
		return
	
	# Connect to ToolSystem (primary)
	tool_system = player.get_node_or_null("ToolSystem")
	if not tool_system:
		tool_system = player.tool_system if "tool_system" in player else null
	
	if tool_system:
		tool_system.tool_changed.connect(_on_tool_changed)
		# Show initial tool
		var tool_id = tool_system.get_tool_visual_id()
		create_weapon_visual(tool_id)
		print("[FirstPersonWeapon] Connected to ToolSystem")
	else:
		print("[FirstPersonWeapon] WARNING: ToolSystem not found")
	
	# Connect to CombatSystem for attack animation
	combat_system = player.get_node_or_null("CombatSystem")
	if combat_system:
		combat_system.attack_performed.connect(_on_attack_performed)
		print("[FirstPersonWeapon] Connected to CombatSystem")
	else:
		print("[FirstPersonWeapon] WARNING: CombatSystem not found")

func _process(delta: float) -> void:
	# Handle swing animation
	if is_swinging:
		swing_timer += delta
		var swing_progress = swing_timer / swing_duration
		
		if swing_progress >= 1.0:
			# Swing complete - reset to idle
			is_swinging = false
			swing_timer = 0.0
			weapon_holder.rotation_degrees = WEAPON_ROTATION
			weapon_holder.position = WEAPON_POSITION
		else:
			# Three-phase swing: wind-up, swing, recovery
			var rot_offset: Vector3
			var pos_offset: Vector3
			
			if swing_progress < 0.2:
				# Phase 1: Wind-up (0% to 20%)
				var phase_progress = swing_progress / 0.2
				var ease_out = sin(phase_progress * PI * 0.5)
				rot_offset = swing_start_rot * ease_out
				pos_offset = swing_start_pos * ease_out
				
			elif swing_progress < 0.5:
				# Phase 2: Fast swing (20% to 50%)
				var phase_progress = (swing_progress - 0.2) / 0.30
				var smooth = phase_progress * phase_progress * (3.0 - 2.0 * phase_progress)
				rot_offset = swing_start_rot.lerp(swing_end_rot, smooth)
				pos_offset = swing_start_pos.lerp(swing_end_pos, smooth)
				
			else:
				# Phase 3: Slow recovery (50% to 100%)
				var phase_progress = (swing_progress - 0.5) / 0.5
				var ease_in = 1.0 - (1.0 - phase_progress) * (1.0 - phase_progress)
				rot_offset = swing_end_rot.lerp(Vector3.ZERO, ease_in)
				pos_offset = swing_end_pos.lerp(Vector3.ZERO, ease_in)
			
			# Apply to weapon holder
			weapon_holder.rotation_degrees = WEAPON_ROTATION + rot_offset
			weapon_holder.position = WEAPON_POSITION + pos_offset
	else:
		# Get player movement state
		var is_moving = false
		var is_sprinting = false
		var move_speed = 0.0
		
		if player and player is CharacterBody3D:
			var horizontal_velocity = Vector2(player.velocity.x, player.velocity.z)
			move_speed = horizontal_velocity.length()
			is_moving = move_speed > 0.5 and player.is_on_floor()
			is_sprinting = is_moving and move_speed > 6.0  # Adjust threshold as needed
		
		if is_moving:
			# Walk/Sprint bob
			var bob_speed = SPRINT_BOB_SPEED if is_sprinting else WALK_BOB_SPEED
			var bob_amount_y = SPRINT_BOB_AMOUNT_Y if is_sprinting else WALK_BOB_AMOUNT_Y
			var bob_amount_x = SPRINT_BOB_AMOUNT_X if is_sprinting else WALK_BOB_AMOUNT_X
			
			bob_timer += delta * bob_speed
			
			# Figure-8 motion: Y bobs twice as fast as X for natural walking feel
			var bob_y = sin(bob_timer * 2.0) * bob_amount_y
			var bob_x = sin(bob_timer) * bob_amount_x
			
			# Apply position bob
			weapon_holder.position.x = WEAPON_POSITION.x + bob_x
			weapon_holder.position.y = WEAPON_POSITION.y + bob_y
			weapon_holder.position.z = WEAPON_POSITION.z
			
			# Apply slight tilt when sprinting
			if is_sprinting:
				weapon_holder.rotation_degrees.x = WEAPON_ROTATION.x - SPRINT_TILT
				weapon_holder.rotation_degrees.y = WEAPON_ROTATION.y
				weapon_holder.rotation_degrees.z = WEAPON_ROTATION.z + sin(bob_timer) * 2.0
			else:
				weapon_holder.rotation_degrees = WEAPON_ROTATION
		else:
			# Idle bob animation (subtle movement when standing still)
			bob_timer += delta * BOB_SPEED
			var bob_offset = sin(bob_timer) * BOB_AMOUNT
			weapon_holder.position = WEAPON_POSITION
			weapon_holder.position.y = WEAPON_POSITION.y + bob_offset
			weapon_holder.rotation_degrees = WEAPON_ROTATION

func set_swing_style(style: Dictionary) -> void:
	"""Set swing animation parameters from a style preset"""
	swing_duration = style.get("duration", 0.5)
	swing_start_rot = style.get("start_rot", Vector3.ZERO)
	swing_end_rot = style.get("end_rot", Vector3.ZERO)
	swing_start_pos = style.get("start_pos", Vector3.ZERO)
	swing_end_pos = style.get("end_pos", Vector3.ZERO)

func create_weapon_visual(tool_id: String) -> void:
	"""Create CSG primitive visual for the specified tool"""
	# Remove old weapon
	if current_weapon_visual:
		current_weapon_visual.queue_free()
		current_weapon_visual = null
	
	current_tool_id = tool_id
	
	# Create new weapon and set swing style based on type
	match tool_id:
		"stone_axe":
			current_weapon_visual = create_stone_axe()
			set_swing_style(SWING_HORIZONTAL)  # Side swing for chopping
		"stone_pickaxe":
			current_weapon_visual = create_stone_pickaxe()
			set_swing_style(SWING_OVERHEAD)  # Overhead swing for mining
		"wooden_club":
			current_weapon_visual = create_wooden_club()
			set_swing_style(SWING_SMASH)  # Overhead smash
		"stone_spear":
			current_weapon_visual = create_stone_spear()
			set_swing_style(SWING_THRUST)  # Forward thrust
		"bone_sword":
			current_weapon_visual = create_bone_sword()
			set_swing_style(SWING_SLASH)  # Diagonal slash
		_:
			current_weapon_visual = create_wooden_club()
			set_swing_style(SWING_HORIZONTAL)
	
	if current_weapon_visual:
		weapon_holder.add_child(current_weapon_visual)
		print("[FirstPersonWeapon] Equipped: %s" % tool_id)

func create_stone_axe() -> Node3D:
	"""Create a stone axe (wooden handle + stone head)
	   Handle END is at origin (pivot point), head extends forward (-Z)"""
	var axe = Node3D.new()
	axe.name = "StoneAxe"
	
	# Handle (wooden cylinder) - bottom of handle at origin, extends forward
	var handle = CSGCylinder3D.new()
	handle.radius = 0.03
	handle.height = 0.45
	handle.sides = 8
	handle.rotation_degrees.x = 90  # Point forward
	handle.position.z = -0.225  # Center of handle (half of 0.45)
	
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.5, 0.35, 0.2)  # Light brown wood
	handle.material = handle_mat
	axe.add_child(handle)
	
	# Axe head (stone box) - at end of handle, blade faces LEFT
	var head = CSGBox3D.new()
	head.size = Vector3(0.18, 0.08, 0.12)
	head.position = Vector3(-0.08, 0, -0.48)  # At end of handle
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.5, 0.5, 0.5)  # Gray stone
	head.material = head_mat
	axe.add_child(head)
	
	# Axe blade edge (darker, on LEFT side)
	var edge = CSGBox3D.new()
	edge.size = Vector3(0.02, 0.06, 0.10)
	edge.position = Vector3(-0.17, 0, -0.48)
	
	var edge_mat = StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.35, 0.35, 0.35)
	edge.material = edge_mat
	axe.add_child(edge)
	
	return axe

func create_stone_pickaxe() -> Node3D:
	"""Create a stone pickaxe - picks oriented vertically for overhead swing"""
	var pick = Node3D.new()
	pick.name = "StonePickaxe"
	
	# Handle
	var handle = CSGCylinder3D.new()
	handle.radius = 0.03
	handle.height = 0.45
	handle.sides = 8
	handle.rotation_degrees.x = 90
	handle.position.z = -0.225
	
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.5, 0.35, 0.2)
	handle.material = handle_mat
	pick.add_child(handle)
	
	# Pickaxe head - oriented VERTICALLY (Y-axis) so picks point up/down
	var head = CSGBox3D.new()
	head.size = Vector3(0.06, 0.25, 0.06)  # Tall vertically
	head.position = Vector3(0, 0, -0.48)
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.5, 0.5, 0.5)
	head.material = head_mat
	pick.add_child(head)
	
	# Pick points - pointing UP and DOWN
	var point_mat = StandardMaterial3D.new()
	point_mat.albedo_color = Color(0.4, 0.4, 0.4)
	
	# Top pick point (pointing up)
	var point_top = CSGBox3D.new()
	point_top.size = Vector3(0.04, 0.08, 0.04)
	point_top.position = Vector3(0, 0.14, -0.48)
	point_top.rotation_degrees.x = -20  # Angled forward
	point_top.material = point_mat
	pick.add_child(point_top)
	
	# Bottom pick point (pointing down) - this hits the rock
	var point_bottom = CSGBox3D.new()
	point_bottom.size = Vector3(0.04, 0.08, 0.04)
	point_bottom.position = Vector3(0, -0.14, -0.48)
	point_bottom.rotation_degrees.x = 20  # Angled forward
	point_bottom.material = point_mat
	pick.add_child(point_bottom)
	
	return pick

func create_wooden_club() -> Node3D:
	"""Create a wooden club - handle end at origin, head extends forward"""
	var club = Node3D.new()
	club.name = "WoodenClub"
	
	# Handle
	var handle = CSGCylinder3D.new()
	handle.radius = 0.04
	handle.height = 0.4
	handle.sides = 8
	handle.rotation_degrees.x = 90
	handle.position.z = -0.2
	
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.3, 0.15)
	handle.material = handle_mat
	club.add_child(handle)
	
	# Club head (thicker)
	var head = CSGCylinder3D.new()
	head.radius = 0.06
	head.height = 0.18
	head.sides = 8
	head.rotation_degrees.x = 90
	head.position.z = -0.48
	
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.35, 0.22, 0.1)
	head.material = head_mat
	club.add_child(head)
	
	return club

func create_stone_spear() -> Node3D:
	"""Create a stone spear - grip at origin, tip extends forward"""
	var spear = Node3D.new()
	spear.name = "StoneSpear"
	
	# Shaft
	var shaft = CSGCylinder3D.new()
	shaft.radius = 0.025
	shaft.height = 0.7
	shaft.sides = 8
	shaft.rotation_degrees.x = 90
	shaft.position.z = -0.35
	
	var shaft_mat = StandardMaterial3D.new()
	shaft_mat.albedo_color = Color(0.5, 0.35, 0.2)
	shaft.material = shaft_mat
	spear.add_child(shaft)
	
	# Stone tip
	var tip = CSGBox3D.new()
	tip.size = Vector3(0.06, 0.06, 0.15)
	tip.rotation_degrees.x = 90
	tip.rotation_degrees.z = 45
	tip.position.z = -0.75
	
	var tip_mat = StandardMaterial3D.new()
	tip_mat.albedo_color = Color(0.5, 0.5, 0.5)
	tip.material = tip_mat
	spear.add_child(tip)
	
	return spear

func create_bone_sword() -> Node3D:
	"""Create a bone sword - handle at origin, blade extends forward"""
	var sword = Node3D.new()
	sword.name = "BoneSword"
	
	# Handle
	var handle = CSGBox3D.new()
	handle.size = Vector3(0.04, 0.05, 0.12)
	handle.rotation_degrees.x = 90
	handle.position.z = -0.06
	
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.3, 0.2, 0.15)
	handle.material = handle_mat
	sword.add_child(handle)
	
	# Guard
	var guard = CSGBox3D.new()
	guard.size = Vector3(0.12, 0.03, 0.03)
	guard.position.z = -0.13
	
	var guard_mat = StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.85, 0.8, 0.7)
	guard.material = guard_mat
	sword.add_child(guard)
	
	# Blade
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.9, 0.85, 0.75)
	
	var blade = CSGBox3D.new()
	blade.size = Vector3(0.06, 0.02, 0.35)
	blade.rotation_degrees.x = 90
	blade.position.z = -0.32
	blade.material = blade_mat
	sword.add_child(blade)
	
	# Blade tip
	var tip = CSGBox3D.new()
	tip.size = Vector3(0.06, 0.02, 0.1)
	tip.rotation_degrees.x = 90
	tip.rotation_degrees.y = 45
	tip.position.z = -0.52
	tip.material = blade_mat
	sword.add_child(tip)
	
	return sword

func play_swing_animation() -> void:
	"""Trigger swing animation (only if not already swinging)"""
	if not is_swinging:
		is_swinging = true
		swing_timer = 0.0

func is_swing_in_progress() -> bool:
	"""Check if currently in swing animation"""
	return is_swinging

# Signal handlers
func _on_tool_changed(tool, tool_data: Dictionary) -> void:
	"""Called when player switches tools via ToolSystem"""
	if tool_system:
		var tool_id = tool_system.get_tool_visual_id()
		create_weapon_visual(tool_id)

func _on_attack_performed(_is_heavy: bool) -> void:
	"""Called when player attacks - play swing animation"""
	play_swing_animation()
