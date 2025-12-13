extends Control
class_name CombatUI

# CombatUI - Simple combat visual feedback (Minecraft-style)
# - Crosshair with states (default/targeting)
# - No charging mechanics

@onready var crosshair: ColorRect = $Crosshair

var combat_system: CombatSystem

# Crosshair states
enum CrosshairState {
	DEFAULT,    # White dot - no target
	TARGETING   # Red dot - enemy in range
}

var current_crosshair_state: CrosshairState = CrosshairState.DEFAULT

func _ready():
	# Find combat system
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("[CombatUI] Player found")
		combat_system = player.get_node_or_null("CombatSystem")
		if combat_system:
			print("[CombatUI] Combat system found and connected!")
			# Connect to combat signals
			combat_system.attack_performed.connect(_on_attack_performed)
		else:
			print("[CombatUI] ERROR: Combat system not found as child of player!")
	else:
		print("[CombatUI] ERROR: Player not found in group 'player'!")
	
	# Initialize crosshair (centered via anchors, 4x4 white dot)
	if crosshair:
		crosshair.color = Color.WHITE
		print("[CombatUI] Crosshair initialized")
	else:
		print("[CombatUI] ERROR: Crosshair node not found!")

func _process(delta: float):
	if not combat_system:
		return
	
	# Update crosshair state based on combat system
	update_crosshair_state()

func update_crosshair_state():
	"""Update crosshair appearance based on combat state"""
	if not crosshair:
		return
	
	# Determine new state - simple: targeting or default
	var new_state: CrosshairState
	
	if is_targeting_enemy():
		new_state = CrosshairState.TARGETING
	else:
		new_state = CrosshairState.DEFAULT
	
	# Apply state if changed
	if new_state != current_crosshair_state:
		current_crosshair_state = new_state
		apply_crosshair_state()

func apply_crosshair_state():
	"""Apply visual changes based on crosshair state"""
	if not crosshair:
		return
	
	match current_crosshair_state:
		CrosshairState.DEFAULT:
			# White dot, normal size (4x4)
			crosshair.color = Color.WHITE
			crosshair.offset_left = -2.0
			crosshair.offset_top = -2.0
			crosshair.offset_right = 2.0
			crosshair.offset_bottom = 2.0
		
		CrosshairState.TARGETING:
			# Red dot, slightly larger (6x6)
			crosshair.color = Color(1.0, 0.3, 0.3)  # Red
			crosshair.offset_left = -3.0
			crosshair.offset_top = -3.0
			crosshair.offset_right = 3.0
			crosshair.offset_bottom = 3.0

func is_targeting_enemy() -> bool:
	"""Check if player is currently targeting an enemy"""
	if not combat_system or not combat_system.current_weapon:
		return false
	
	# Use combat system's raycast to check for enemy
	var target = combat_system.raycast_for_enemy(combat_system.current_weapon.attack_range)
	return target != null

# Signal handlers
func _on_attack_performed(is_heavy: bool):
	"""Visual feedback when attack is performed"""
	# Quick flash effect on crosshair
	if crosshair:
		crosshair.color = Color.WHITE
