extends Node
class_name ToolSystem

"""
ToolSystem - Manages player's equipped tools

ARCHITECTURE:
- Simple system that tracks which tool is currently equipped
- Attached to Player node as a child
- Works with HarvestingSystem to check tool requirements

MINIMAL IMPLEMENTATION:
- No durability (infinite use)
- No tool switching UI (just cycles with T key)
- No crafting (start with basic tools)
- Just enforces tool requirements on resources
"""

# Available tools
enum Tool {
	NONE,
	AXE,
	PICKAXE
}

# Current equipped tool
var equipped_tool: Tool = Tool.NONE

# Tool names for display
const TOOL_NAMES = {
	Tool.NONE: "None",
	Tool.AXE: "Axe",
	Tool.PICKAXE: "Pickaxe"
}

signal tool_equipped(tool: Tool)

func _ready():
	# Start with an axe equipped
	equip_tool(Tool.AXE)
	print("ToolSystem initialized - Starting with Axe")

func equip_tool(tool: Tool):
	"""Equip a tool"""
	equipped_tool = tool
	emit_signal("tool_equipped", tool)
	print("Equipped: ", get_tool_name(equipped_tool))

func get_equipped_tool() -> Tool:
	"""Get currently equipped tool"""
	return equipped_tool

func get_tool_name(tool: Tool = -1) -> String:
	"""Get the name of a tool for display"""
	if tool == -1:
		tool = equipped_tool
	return TOOL_NAMES.get(tool, "Unknown")

func cycle_tool():
	"""Cycle between Axe and Pickaxe only (no None)"""
	var tools = [Tool.AXE, Tool.PICKAXE]
	var current_index = tools.find(equipped_tool)
	
	# If somehow not in the list (e.g., Tool.NONE), start with AXE
	if current_index == -1:
		equip_tool(Tool.AXE)
		return
	
	var next_index = (current_index + 1) % tools.size()
	equip_tool(tools[next_index])

func can_harvest(resource_type: String) -> bool:
	"""Check if the equipped tool can harvest a given resource type"""
	# Map resource types to required tools
	var tool_requirements = {
		"wood": Tool.AXE,
		"stone": Tool.PICKAXE,
		"ore": Tool.PICKAXE
	}
	
	var required_tool = tool_requirements.get(resource_type, Tool.NONE)
	
	# If no tool required, always can harvest
	if required_tool == Tool.NONE:
		return true
	
	# Check if we have the right tool
	return equipped_tool == required_tool

func get_required_tool_name(resource_type: String) -> String:
	"""Get the name of the tool required for a resource type"""
	var tool_requirements = {
		"wood": Tool.AXE,
		"stone": Tool.PICKAXE,
		"ore": Tool.PICKAXE
	}
	
	var required_tool = tool_requirements.get(resource_type, Tool.NONE)
	return get_tool_name(required_tool)
