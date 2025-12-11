extends Node
class_name HealthHungerSystem

# Health/Hunger system for player
# - Hunger depletes over time (~8 minutes to empty)
# - Health regenerates ONLY when hunger > 70 (well-fed)
# - Low hunger (< 30) reduces movement speed by 30%

signal health_changed(new_health: float, max_health: float)
signal hunger_changed(new_hunger: float, max_hunger: float)
signal hunger_low()  # Emitted when hunger drops below 30
signal hunger_critical()  # Emitted when hunger reaches 0
signal well_fed_status_changed(is_well_fed: bool)

# Stats
@export var max_health: float = 100.0
@export var max_hunger: float = 100.0

# Depletion/Regeneration rates
@export var hunger_depletion_rate: float = 0.2  # Per second (~8.3 minutes to deplete)
@export var health_regen_rate: float = 1.0  # Per second when well-fed
@export var well_fed_threshold: float = 70.0  # Hunger level required for health regen

# Current values
var current_health: float = 100.0
var current_hunger: float = 100.0

# Status tracking
var is_well_fed: bool = true
var was_hunger_low: bool = false

func _ready():
	current_health = max_health
	current_hunger = max_hunger

func _process(delta: float):
	# Deplete hunger over time
	if current_hunger > 0:
		modify_hunger(-hunger_depletion_rate * delta)
	
	# Regenerate health if well-fed (hunger > 70)
	if current_hunger > well_fed_threshold and current_health < max_health:
		modify_health(health_regen_rate * delta)

# Modify health (clamped to 0-max)
func modify_health(amount: float):
	var old_health = current_health
	current_health = clampf(current_health + amount, 0, max_health)
	
	if current_health != old_health:
		health_changed.emit(current_health, max_health)

# Modify hunger (clamped to 0-max)
func modify_hunger(amount: float):
	var old_hunger = current_hunger
	current_hunger = clampf(current_hunger + amount, 0, max_hunger)
	
	if current_hunger != old_hunger:
		hunger_changed.emit(current_hunger, max_hunger)
		
		# Check well-fed status change
		var new_well_fed = current_hunger > well_fed_threshold
		if new_well_fed != is_well_fed:
			is_well_fed = new_well_fed
			well_fed_status_changed.emit(is_well_fed)
		
		# Check hunger thresholds
		if current_hunger < 30 and not was_hunger_low:
			was_hunger_low = true
			hunger_low.emit()
		elif current_hunger >= 30 and was_hunger_low:
			was_hunger_low = false
		
		if current_hunger <= 0:
			hunger_critical.emit()

# Eat food (called from inventory system)
func eat_food(hunger_restore: float) -> bool:
	if current_hunger >= max_hunger:
		return false  # Already full
	
	modify_hunger(hunger_restore)
	return true

# Take damage (for future combat system)
func take_damage(amount: float):
	modify_health(-amount)

# Heal (for future healing items)
func heal(amount: float):
	modify_health(amount)

# Get movement speed multiplier based on hunger
func get_movement_speed_multiplier() -> float:
	if current_hunger < 30:
		return 0.7  # 30% slower when hungry
	return 1.0

# Check if player is alive
func is_alive() -> bool:
	return current_health > 0

# Get hunger percentage (for UI)
func get_hunger_percent() -> float:
	return current_hunger / max_hunger

# Get health percentage (for UI)
func get_health_percent() -> float:
	return current_health / max_health

# Check if well-fed (for UI indicators)
func is_player_well_fed() -> bool:
	return is_well_fed
