extends Control

"""
InventoryUI - Grid-based inventory display

Shows items in a visual grid with icons and counts
Press Tab to toggle visibility
"""

var inventory: Inventory
var health_hunger_system: HealthHungerSystem

# UI elements
var background: Panel
var grid_container: GridContainer
var title_label: Label

# Grid settings
const GRID_COLUMNS = 8
const SLOT_SIZE = 64
const SLOT_SPACING = 4

# Food values for eating system
const FOOD_VALUES = {
	"strawberry": 20,  # Generic strawberry (medium-sized)
	"Small Strawberry": 10,
	"Medium Strawberry": 20,
	"Large Strawberry": 35,
	"mushroom": 20,  # Generic mushroom (medium-sized)
	"Small Mushroom": 15,
	"Medium Mushroom": 25,
	"Large Mushroom": 40
}

# Item icon colors (simple colored squares for now)
const ITEM_COLORS = {
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.5, 0.5, 0.5),
	"mushroom": Color(0.8, 0.3, 0.3),
	"strawberry": Color(0.9, 0.2, 0.2),
	"stone_pickaxe": Color(0.4, 0.4, 0.4),
	"stone_axe": Color(0.5, 0.4, 0.3),
	"campfire": Color(0.8, 0.5, 0.2),
	"torch": Color(0.9, 0.7, 0.3),
	"wood_wall": Color(0.5, 0.35, 0.2)
}

func _ready():
	name = "InventoryUI"
	
	# Create semi-transparent background panel
	background = Panel.new()
	background.set_anchors_preset(Control.PRESET_CENTER)
	background.custom_minimum_size = Vector2(600, 450)
	background.position = Vector2(
		get_viewport().size.x / 2 - 300,
		get_viewport().size.y / 2 - 225
	)
	add_child(background)
	
	# Style background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(0.4, 0.4, 0.4)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	background.add_theme_stylebox_override("panel", style)
	
	# Title
	title_label = Label.new()
	title_label.text = "INVENTORY (Press Tab to close)"
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 2)
	title_label.position = Vector2(20, 15)
	background.add_child(title_label)
	
	# Grid container
	grid_container = GridContainer.new()
	grid_container.columns = GRID_COLUMNS
	grid_container.position = Vector2(20, 60)
	grid_container.size = Vector2(560, 370)
	grid_container.add_theme_constant_override("h_separation", SLOT_SPACING)
	grid_container.add_theme_constant_override("v_separation", SLOT_SPACING)
	background.add_child(grid_container)
	
	# Start hidden
	visible = false

func set_inventory(inv: Inventory):
	"""Connect to inventory system"""
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(refresh_grid)
		refresh_grid()

func set_health_system(health_sys: HealthHungerSystem):
	"""Connect to health/hunger system for eating"""
	health_hunger_system = health_sys
	print("DEBUG: Health system set in inventory UI: ", health_hunger_system != null)

func refresh_grid():
	"""Update the inventory grid display"""
	if not inventory:
		return
	
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	var items = inventory.get_all_items()
	
	# Create slots for each item
	for item_name in items:
		var count = items[item_name]
		create_item_slot(item_name, count)
	
	# Fill remaining slots with empty placeholders (up to 32 total slots)
	var total_slots = 32
	var filled_slots = items.size()
	for i in range(total_slots - filled_slots):
		create_empty_slot()

func create_item_slot(item_name: String, count: int):
	"""Create a visual slot for an item"""
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# Make slot clickable
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Slot background
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	slot_style.border_color = Color(0.5, 0.5, 0.5)
	slot_style.border_width_left = 2
	slot_style.border_width_right = 2
	slot_style.border_width_top = 2
	slot_style.border_width_bottom = 2
	
	# Check if item is food - add green tint
	var is_food = item_name in FOOD_VALUES
	if is_food:
		slot_style.bg_color = Color(0.2, 0.25, 0.2, 0.9)  # Slight green tint for food
	
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Container for icon and count
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through to slot
	slot.add_child(vbox)
	
	# Item icon (colored square)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.color = ITEM_COLORS.get(item_name, Color.WHITE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
	vbox.add_child(icon)
	
	# Count label
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
	vbox.add_child(count_label)
	
	# Item name on hover (tooltip)
	if is_food:
		var food_value = FOOD_VALUES[item_name]
		slot.tooltip_text = "%s\n🍖 Restores %d hunger\n[Click to eat]" % [item_name.capitalize(), food_value]
	else:
		slot.tooltip_text = item_name.capitalize()
	
	# Connect click event for eating
	if is_food:
		slot.gui_input.connect(func(event): _on_slot_clicked(event, item_name))
	
	grid_container.add_child(slot)

func create_empty_slot():
	"""Create an empty inventory slot"""
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	
	# Empty slot style (darker)
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.15, 0.15, 0.15, 0.7)
	slot_style.border_color = Color(0.3, 0.3, 0.3)
	slot_style.border_width_left = 1
	slot_style.border_width_right = 1
	slot_style.border_width_top = 1
	slot_style.border_width_bottom = 1
	slot.add_theme_stylebox_override("panel", slot_style)
	
	grid_container.add_child(slot)

func toggle_visibility():
	"""Show/hide the inventory"""
	visible = !visible
	if visible:
		refresh_grid()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_slot_clicked(event: InputEvent, item_name: String):
	"""Handle clicking on an inventory slot"""
	print("DEBUG: Slot clicked for item: ", item_name)
	if event is InputEventMouseButton and event.pressed:
		print("DEBUG: Mouse button event - button: ", event.button_index)
		# Left or right-click to eat food
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			print("DEBUG: Click detected!")
			try_eat_item(item_name)

func try_eat_item(item_name: String) -> bool:
	"""Try to eat a food item"""
	print("DEBUG: Trying to eat item: ", item_name)
	print("DEBUG: Health system exists: ", health_hunger_system != null)
	print("DEBUG: Inventory exists: ", inventory != null)
	print("DEBUG: Is food: ", item_name in FOOD_VALUES)
	
	if not health_hunger_system or not inventory:
		print("ERROR: Missing health_hunger_system or inventory!")
		return false
	
	if item_name not in FOOD_VALUES:
		print("ERROR: Item is not food!")
		return false
	
	var hunger_restore = FOOD_VALUES[item_name]
	
	# Try to eat the food
	if health_hunger_system.eat_food(hunger_restore):
		# Successfully ate - remove from inventory
		inventory.remove_item(item_name, 1)
		print("Ate %s, restored %d hunger" % [item_name, hunger_restore])
		
		# Refresh the grid
		refresh_grid()
		return true
	else:
		print("Already at full hunger!")
		return false
