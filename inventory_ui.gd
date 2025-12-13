extends Control

"""
InventoryUI - Grid-based inventory display

Shows items in a visual grid with icons and counts
Press Tab to toggle visibility
"""

var inventory: Inventory
var health_hunger_system: HealthHungerSystem

# UI elements from scene
@onready var background: Panel = $Background
@onready var grid_container: GridContainer = $Background/GridContainer
@onready var title_label: Label = $Background/TitleLabel

# Full notification
var full_notification: Label = null
var full_timer: float = 0.0

# Grid settings
const GRID_COLUMNS = 8
const SLOT_SIZE = 64
const SLOT_SPACING = 4

# Food values for eating system
const FOOD_VALUES = {
	"strawberry": 20,
	"Small Strawberry": 10,
	"Medium Strawberry": 20,
	"Large Strawberry": 35,
	"mushroom": 20,
	"Small Mushroom": 15,
	"Medium Mushroom": 25,
	"Large Mushroom": 40
}

# Item icon colors
const ITEM_COLORS = {
	"wood": Color(0.6, 0.4, 0.2),
	"stone": Color(0.5, 0.5, 0.5),
	"mushroom": Color(0.8, 0.3, 0.3),
	"strawberry": Color(0.9, 0.2, 0.2),
	"stone_pickaxe": Color(0.4, 0.4, 0.4),
	"stone_axe": Color(0.5, 0.4, 0.3),
	"campfire": Color(0.8, 0.5, 0.2),
	"torch": Color(0.9, 0.7, 0.3),
	"wood_wall": Color(0.5, 0.35, 0.2),
	"Small Strawberry": Color(0.9, 0.2, 0.2),
	"Medium Strawberry": Color(0.9, 0.2, 0.2),
	"Large Strawberry": Color(0.9, 0.2, 0.2),
	"Small Mushroom": Color(0.8, 0.3, 0.3),
	"Medium Mushroom": Color(0.8, 0.3, 0.3),
	"Large Mushroom": Color(0.8, 0.3, 0.3)
}

func _ready():
	# Style the background panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(0.4, 0.4, 0.4)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	background.add_theme_stylebox_override("panel", style)
	
	# Create full notification label
	full_notification = Label.new()
	full_notification.text = "INVENTORY FULL!"
	full_notification.add_theme_font_size_override("font_size", 32)
	full_notification.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	full_notification.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	full_notification.add_theme_constant_override("outline_size", 4)
	full_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	full_notification.position = Vector2(0, 100)
	full_notification.size = Vector2(get_viewport().size.x, 50)
	full_notification.visible = false
	add_child(full_notification)
	
	# Start hidden
	visible = false
	print("InventoryUI ready from scene")

func _process(delta):
	# Handle full notification timer
	if full_timer > 0:
		full_timer -= delta
		if full_timer <= 0:
			if full_notification:
				full_notification.visible = false

func show_full_notification():
	"""Show the INVENTORY FULL notification for 2 seconds"""
	if full_notification:
		full_notification.visible = true
		full_timer = 2.0

func set_inventory(inv: Inventory):
	"""Connect to inventory system"""
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(refresh_grid)
		inventory.inventory_full.connect(_on_inventory_full)
		refresh_grid()
		print("Inventory connected to UI")

func _on_inventory_full(item_name: String):
	"""Called when inventory is full"""
	show_full_notification()
	# Play stack full warning sound
	AudioManager.play_sound("stack_full", "ui", false, false)
	# RUMBLE: Warning feedback
	RumbleManager.play_warning()

func set_health_system(health_sys: HealthHungerSystem):
	"""Connect to health/hunger system for eating"""
	health_hunger_system = health_sys

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
		slot_style.bg_color = Color(0.2, 0.25, 0.2, 0.9)
	
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Container for icon and count
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(vbox)
	
	# Item icon (colored square)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.color = ITEM_COLORS.get(item_name, Color.WHITE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
	
	# Count label with stack limit
	var count_label = Label.new()
	var stack_limit = inventory.get_stack_limit(item_name)
	var is_full = (count >= stack_limit)
	
	if stack_limit > 1:
		if is_full:
			count_label.text = "FULL"
			count_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red text
		else:
			count_label.text = str(count) + "/" + str(stack_limit)
			count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = str(count)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Visual feedback for full stacks - red tint
	if is_full and stack_limit > 1:
		slot_style.bg_color = Color(0.35, 0.15, 0.15, 0.9)  # Reddish tint
		slot_style.border_color = Color(1, 0.3, 0.3)  # Red border
	
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		# Play inventory open sound
		AudioManager.play_sound("inventory_toggle", "ui", false, false)
		# RUMBLE: Inventory toggle feedback
		RumbleManager.play_ui_click()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# Play inventory close sound
		AudioManager.play_sound("inventory_toggle", "ui", false, false)
		# RUMBLE: Inventory toggle feedback
		RumbleManager.play_ui_click()

func _on_slot_clicked(event: InputEvent, item_name: String):
	"""Handle clicking on an inventory slot"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			try_eat_item(item_name)

func try_eat_item(item_name: String) -> bool:
	"""Try to eat a food item"""
	if not health_hunger_system or not inventory:
		return false
	
	if item_name not in FOOD_VALUES:
		return false
	
	var hunger_restore = FOOD_VALUES[item_name]
	
	# Try to eat the food
	if health_hunger_system.eat_food(hunger_restore):
		inventory.remove_item(item_name, 1)
		print("Ate %s, restored %d hunger" % [item_name, hunger_restore])
		refresh_grid()
		return true
	else:
		print("Already at full hunger!")
		return false
