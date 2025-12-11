extends Control

"""
InventoryUI - Grid-based inventory display

Shows items in a visual grid with icons and counts
Press Tab to toggle visibility
"""

var inventory: Inventory

# UI elements
var background: Panel
var grid_container: GridContainer
var title_label: Label

# Grid settings
const GRID_COLUMNS = 8
const SLOT_SIZE = 64
const SLOT_SPACING = 4

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
	
	# Slot background
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.2, 0.2, 0.2, 0.9)
	slot_style.border_color = Color(0.5, 0.5, 0.5)
	slot_style.border_width_left = 2
	slot_style.border_width_right = 2
	slot_style.border_width_top = 2
	slot_style.border_width_bottom = 2
	slot.add_theme_stylebox_override("panel", slot_style)
	
	# Container for icon and count
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	slot.add_child(vbox)
	
	# Item icon (colored square)
	var icon = ColorRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.color = ITEM_COLORS.get(item_name, Color.WHITE)
	vbox.add_child(icon)
	
	# Count label
	var count_label = Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 1)
	vbox.add_child(count_label)
	
	# Item name on hover (tooltip)
	slot.tooltip_text = item_name.capitalize()
	
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
