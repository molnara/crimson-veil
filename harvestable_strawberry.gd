extends HarvestableResource
class_name HarvestableStrawberry

# Strawberry bush properties

func _ready():
	# Set strawberry bush properties
	resource_name = "Strawberry Bush"
	resource_type = "foliage"
	max_health = 15.0
	harvest_time = 0.8
	drop_item = "strawberry"
	drop_amount_min = 2
	drop_amount_max = 5
	mining_tool_required = "none"
	
	# Set custom glow color for strawberries (pinkish-red)
	glow_color = Color(0.8, 0.3, 0.4, 1.0)  # Darker pinkish-red glow
	glow_strength = 0.2  # Much more subtle (was 0.35)
	glow_fade_delay = 0.18  # Glow starts ~10:20 PM (very late, only in deep darkness), ends ~1:40 AM
	
	# Call parent _ready
	super._ready()

func apply_harvest_visual_feedback():
	"""Override to add subtle wobble when harvesting"""
	# Gentle wobble effect
	var wobble = sin(harvest_progress * PI * 10.0) * 0.1
	rotation.z = original_rotation.z + wobble
	rotation.x = original_rotation.x + wobble * 0.5
