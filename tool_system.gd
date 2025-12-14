extends Node
class_name ToolSystem

"""
ToolSystem - Unified Tool & Weapon System

ARCHITECTURE:
- Each tool serves BOTH harvesting AND combat purposes
- Single RB button cycles through all equipped tools
- Tools have harvest type requirements AND combat damage/range
- Integrates with HarvestingSystem (unchanged) and CombatSystem (updated)

TOOLS:
- Stone Axe: Chops wood, decent combat (18 dmg)
- Stone Pickaxe: Mines stone/ore, weak combat (12 dmg)
- Wooden Club: Poor harvesting, starter combat (15 dmg)
- Stone Spear: Poor harvesting, reach combat (20 dmg, 3.5m)
- Bone Sword: Poor harvesting, best combat (25 dmg)
"""

# Tool definitions
enum Tool {
	STONE_AXE,
	STONE_PICKAXE,
	WOODEN_CLUB,
	STONE_SPEAR,
	BONE_SWORD
}

# Tool data: harvest_type, combat_damage, combat_range, attack_cooldown, display_name
const TOOL_DATA = {
	Tool.STONE_AXE: {
		"name": "Stone Axe",
		"harvest_types": ["wood"],  # What it can harvest efficiently
		"damage": 18,
		"range": 2.5,
		"cooldown": 1.0,
		"description": "Chops trees. Decent weapon."
	},
	Tool.STONE_PICKAXE: {
		"name": "Stone Pickaxe",
		"harvest_types": ["stone", "ore"],
		"damage": 12,
		"range": 2.5,
		"cooldown": 1.2,
		"description": "Mines stone and ore. Weak weapon."
	},
	Tool.WOODEN_CLUB: {
		"name": "Wooden Club",
		"harvest_types": [],  # Can't harvest efficiently
		"damage": 15,
		"range": 2.5,
		"cooldown": 1.0,
		"description": "Basic weapon. Poor harvesting."
	},
	Tool.STONE_SPEAR: {
		"name": "Stone Spear",
		"harvest_types": [],
		"damage": 20,
		"range": 3.5,  # Longest reach
		"cooldown": 1.2,
		"description": "Long reach weapon. Poor harvesting."
	},
	Tool.BONE_SWORD: {
		"name": "Bone Sword",
		"harvest_types": [],
		"damage": 25,  # Highest damage
		"range": 3.0,
		"cooldown": 1.0,
		"description": "Best damage. Poor harvesting."
	}
}

# Currently equipped tool
var equipped_tool: Tool = Tool.STONE_AXE

# Tools the player has unlocked/crafted (start with basic tools + spear for testing)
var available_tools: Array[Tool] = [
	Tool.STONE_AXE,
	Tool.STONE_PICKAXE,
	Tool.WOODEN_CLUB,
	Tool.STONE_SPEAR
]

# Signals
signal tool_changed(tool: Tool, tool_data: Dictionary)
signal tool_equipped(tool: Tool)  # Legacy signal for HarvestingSystem compatibility

func _ready():
	# Start with axe equipped
	equip_tool(Tool.STONE_AXE)
	print("[ToolSystem] Initialized with %d tools" % available_tools.size())

func equip_tool(tool: Tool) -> void:
	"""Equip a specific tool"""
	if tool not in available_tools:
		print("[ToolSystem] Tool not available: ", tool)
		return
	
	equipped_tool = tool
	var data = get_tool_data(tool)
	
	emit_signal("tool_changed", tool, data)
	emit_signal("tool_equipped", tool)  # Legacy compatibility
	
	print("[ToolSystem] Equipped: %s (DMG: %d, Range: %.1fm)" % [
		data.name, data.damage, data.range
	])

func cycle_tool() -> void:
	"""Cycle to the next available tool (RB button)"""
	if available_tools.size() == 0:
		return
	
	var current_index = available_tools.find(equipped_tool)
	if current_index == -1:
		current_index = 0
	
	var next_index = (current_index + 1) % available_tools.size()
	equip_tool(available_tools[next_index])

func cycle_tool_reverse() -> void:
	"""Cycle to the previous available tool (LB button)"""
	if available_tools.size() == 0:
		return
	
	var current_index = available_tools.find(equipped_tool)
	if current_index == -1:
		current_index = 0
	
	var prev_index = current_index - 1
	if prev_index < 0:
		prev_index = available_tools.size() - 1
	equip_tool(available_tools[prev_index])

func get_tool_data(tool: Tool = -1) -> Dictionary:
	"""Get data for a tool (defaults to equipped tool)"""
	if tool == -1:
		tool = equipped_tool
	return TOOL_DATA.get(tool, TOOL_DATA[Tool.WOODEN_CLUB])

func get_equipped_tool() -> Tool:
	"""Get currently equipped tool enum"""
	return equipped_tool

func get_tool_name(tool: Tool = -1) -> String:
	"""Get display name of a tool"""
	var data = get_tool_data(tool)
	return data.get("name", "Unknown")

# ============================================================================
# COMBAT INTEGRATION
# ============================================================================

func get_combat_damage() -> int:
	"""Get combat damage of equipped tool"""
	var data = get_tool_data()
	return data.get("damage", 10)

func get_combat_range() -> float:
	"""Get combat range of equipped tool"""
	var data = get_tool_data()
	return data.get("range", 2.5)

func get_attack_cooldown() -> float:
	"""Get attack cooldown of equipped tool"""
	var data = get_tool_data()
	return data.get("cooldown", 1.0)

# ============================================================================
# HARVESTING INTEGRATION (Legacy compatibility with HarvestingSystem)
# ============================================================================

func can_harvest(resource_type: String) -> bool:
	"""Check if equipped tool can harvest a resource type efficiently"""
	var data = get_tool_data()
	var harvest_types = data.get("harvest_types", [])
	
	# If resource requires no specific tool, always allow
	if resource_type == "foliage" or resource_type == "generic":
		return true
	
	# Check if this tool handles this resource type
	return resource_type in harvest_types

func get_required_tool_name(resource_type: String) -> String:
	"""Get name of tool required for a resource type"""
	match resource_type:
		"wood":
			return "Stone Axe"
		"stone", "ore":
			return "Stone Pickaxe"
		_:
			return "Any Tool"

# ============================================================================
# TOOL UNLOCKING (for crafting integration)
# ============================================================================

func unlock_tool(tool: Tool) -> void:
	"""Add a tool to available tools (called when crafted)"""
	if tool not in available_tools:
		available_tools.append(tool)
		print("[ToolSystem] Unlocked: %s" % get_tool_name(tool))

func has_tool(tool: Tool) -> bool:
	"""Check if player has a specific tool"""
	return tool in available_tools

# ============================================================================
# TOOL VISUALS (for FirstPersonWeapon)
# ============================================================================

func get_tool_visual_id() -> String:
	"""Get visual ID for FirstPersonWeapon system"""
	match equipped_tool:
		Tool.STONE_AXE:
			return "stone_axe"
		Tool.STONE_PICKAXE:
			return "stone_pickaxe"
		Tool.WOODEN_CLUB:
			return "wooden_club"
		Tool.STONE_SPEAR:
			return "stone_spear"
		Tool.BONE_SWORD:
			return "bone_sword"
		_:
			return "wooden_club"
