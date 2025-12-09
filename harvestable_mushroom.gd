extends HarvestableResource
class_name HarvestableMushroom

# Mushroom-specific properties
enum MushroomType {
	RED,      # Red cap mushroom
	BROWN,    # Brown cap mushroom
	CLUSTER   # Multiple small mushrooms
}

@export var mushroom_type: MushroomType = MushroomType.BROWN

func _ready():
	# Set properties based on mushroom type
	match mushroom_type:
		MushroomType.RED:
			resource_name = "Mushroom"
			resource_type = "foliage"
			max_health = 10.0
			harvest_time = 0.5
			drop_item = "mushroom"
			drop_amount_min = 1
			drop_amount_max = 1
			mining_tool_required = "none"
			
		MushroomType.BROWN:
			resource_name = "Mushroom"
			resource_type = "foliage"
			max_health = 10.0
			harvest_time = 0.5
			drop_item = "mushroom"
			drop_amount_min = 1
			drop_amount_max = 1
			mining_tool_required = "none"
			
		MushroomType.CLUSTER:
			resource_name = "Mushrooms"
			resource_type = "foliage"
			max_health = 15.0
			harvest_time = 0.7
			drop_item = "mushroom"
			drop_amount_min = 2
			drop_amount_max = 4
			mining_tool_required = "none"
	
	# Call parent _ready
	super._ready()

func apply_harvest_visual_feedback():
	"""Override to add subtle wobble when harvesting"""
	# Gentle wobble effect
	var wobble = sin(harvest_progress * PI * 10.0) * 0.1
	rotation.z = original_rotation.z + wobble
	rotation.x = original_rotation.x + wobble * 0.5
