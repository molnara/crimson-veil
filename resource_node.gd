extends HarvestableResource
class_name ResourceNode

# Specific resource node implementation
# This can be used directly or extended for specific types

enum NodeType {
	ROCK,
	STONE_DEPOSIT,
	COPPER_ORE,
	IRON_ORE,
	TREE,
	BUSH
}

@export var node_type: NodeType = NodeType.ROCK

func _ready():
	# Set properties based on node type FIRST
	match node_type:
		NodeType.ROCK:
			resource_name = "Rock"
			resource_type = "stone"
			max_health = 50.0
			harvest_time = 2.0
			drop_item = "stone"
			drop_amount_min = 2
			drop_amount_max = 4
			mining_tool_required = "none"
			
		NodeType.STONE_DEPOSIT:
			resource_name = "Stone Deposit"
			resource_type = "stone"
			max_health = 100.0
			harvest_time = 4.0
			drop_item = "stone"
			drop_amount_min = 5
			drop_amount_max = 10
			mining_tool_required = "pickaxe"
			
		NodeType.COPPER_ORE:
			resource_name = "Copper Ore"
			resource_type = "ore"
			max_health = 150.0
			harvest_time = 5.0
			drop_item = "copper"
			drop_amount_min = 3
			drop_amount_max = 6
			mining_tool_required = "pickaxe"
			
		NodeType.IRON_ORE:
			resource_name = "Iron Ore"
			resource_type = "ore"
			max_health = 200.0
			harvest_time = 6.0
			drop_item = "iron"
			drop_amount_min = 2
			drop_amount_max = 5
			mining_tool_required = "pickaxe"
			
		NodeType.TREE:
			resource_name = "Tree"
			resource_type = "wood"
			max_health = 100.0
			harvest_time = 4.0
			drop_item = "wood"
			drop_amount_min = 5
			drop_amount_max = 8
			mining_tool_required = "axe"
			
		NodeType.BUSH:
			resource_name = "Bush"
			resource_type = "plant"
			max_health = 20.0
			harvest_time = 1.0
			drop_item = "fiber"
			drop_amount_min = 1
			drop_amount_max = 3
			mining_tool_required = "none"
	
	# NOW call parent _ready which will use these properties
	super._ready()

# Helper function to create a simple rock node programmatically
static func create_rock_node(pos: Vector3) -> ResourceNode:
	var node = ResourceNode.new()
	node.node_type = NodeType.ROCK
	node.position = pos
	return node

# Helper function to create an ore deposit
static func create_ore_node(pos: Vector3, ore_type: NodeType) -> ResourceNode:
	var node = ResourceNode.new()
	node.node_type = ore_type
	node.position = pos
	return node
