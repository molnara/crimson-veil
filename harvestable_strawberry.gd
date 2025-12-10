extends HarvestableResource
class_name HarvestableStrawberry

"""
HarvestableStrawberry - Strawberry bushes with three size variants

SIZE VARIANTS:
- SMALL: 0.5-0.7m tall, 1-2 strawberries, quick harvest
- MEDIUM: 0.7-1.0m tall, 2-4 strawberries, standard harvest
- LARGE: 1.0-1.3m tall, 4-7 strawberries, longer harvest

INTEGRATION:
- Spawned by VegetationSpawner.create_harvestable_strawberry()
- Size determined at spawn time via bush_size export variable
"""

enum BushSize {
	SMALL,    # Quick harvest, 1-2 berries
	MEDIUM,   # Standard, 2-4 berries
	LARGE     # Longer harvest, 4-7 berries
}

@export var bush_size: BushSize = BushSize.MEDIUM

func _ready():
	# Set properties based on bush size FIRST
	match bush_size:
		BushSize.SMALL:
			resource_name = "Small Strawberry Bush"
			resource_type = "foliage"
			max_health = 10.0
			harvest_time = 0.5
			drop_item = "strawberry"
			drop_amount_min = 1
			drop_amount_max = 2
			mining_tool_required = "none"
			# Custom glow for small bushes (pinkish-red)
			glow_color = Color(0.8, 0.3, 0.4, 1.0)
			glow_strength = 0.18  # Weaker glow for small bushes
			glow_fade_delay = 0.18
			
		BushSize.MEDIUM:
			resource_name = "Strawberry Bush"
			resource_type = "foliage"
			max_health = 15.0
			harvest_time = 0.8
			drop_item = "strawberry"
			drop_amount_min = 2
			drop_amount_max = 4
			mining_tool_required = "none"
			# Standard glow
			glow_color = Color(0.8, 0.3, 0.4, 1.0)
			glow_strength = 0.2
			glow_fade_delay = 0.18
			
		BushSize.LARGE:
			resource_name = "Large Strawberry Bush"
			resource_type = "foliage"
			max_health = 25.0
			harvest_time = 1.2
			drop_item = "strawberry"
			drop_amount_min = 4
			drop_amount_max = 7
			mining_tool_required = "none"
			# Stronger glow for large bushes
			glow_color = Color(0.8, 0.3, 0.4, 1.0)
			glow_strength = 0.25
			glow_fade_delay = 0.18
	
	# NOW call parent _ready which will use these properties
	super._ready()

func apply_harvest_visual_feedback():
	"""Override to add subtle wobble when harvesting"""
	# Gentle wobble effect
	var wobble = sin(harvest_progress * PI * 10.0) * 0.1
	rotation.z = original_rotation.z + wobble
	rotation.x = original_rotation.x + wobble * 0.5
