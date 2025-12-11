extends Control
class_name HealthUI

# Health/Hunger UI - displays bars in top-left corner
# Red health bar with heart icon, orange hunger bar with food icon

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var hunger_bar: ProgressBar = $VBoxContainer/HungerBar
@onready var health_label: Label = $VBoxContainer/HealthBar/HealthLabel
@onready var hunger_label: Label = $VBoxContainer/HungerBar/HungerLabel
@onready var well_fed_indicator: Label = $VBoxContainer/WellFedIndicator

var health_system: HealthHungerSystem

func _ready():
	# Find the health system (should be child of player)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		health_system = player.get_node_or_null("HealthHungerSystem")
		if health_system:
			health_system.health_changed.connect(_on_health_changed)
			health_system.hunger_changed.connect(_on_hunger_changed)
			health_system.well_fed_status_changed.connect(_on_well_fed_changed)
			
			# Initialize display
			_on_health_changed(health_system.current_health, health_system.max_health)
			_on_hunger_changed(health_system.current_hunger, health_system.max_hunger)
			_on_well_fed_changed(health_system.is_well_fed)

func _on_health_changed(current: float, maximum: float):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
		health_label.text = "❤️ %d/%d" % [int(current), int(maximum)]

func _on_hunger_changed(current: float, maximum: float):
	if hunger_bar:
		hunger_bar.max_value = maximum
		hunger_bar.value = current
		hunger_label.text = "🍖 %d/%d" % [int(current), int(maximum)]
		
		# Change bar color based on hunger level
		if current < 30:
			# Low hunger - red tint
			hunger_bar.modulate = Color(1.0, 0.5, 0.5)
		elif current < 70:
			# Medium hunger - normal orange
			hunger_bar.modulate = Color(1.0, 1.0, 1.0)
		else:
			# Well-fed - slight green tint
			hunger_bar.modulate = Color(0.9, 1.0, 0.9)

func _on_well_fed_changed(is_well_fed: bool):
	if well_fed_indicator:
		if is_well_fed:
			well_fed_indicator.text = "✨ Well Fed (Health Regen Active)"
			well_fed_indicator.modulate = Color(0.5, 1.0, 0.5)
			well_fed_indicator.visible = true
		else:
			well_fed_indicator.visible = false
