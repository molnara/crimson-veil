extends Control

# References to UI elements
@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var target_label = $CenterContainer/VBoxContainer/TargetLabel
@onready var inventory_display = $InventoryDisplay/ItemList

var inventory: Inventory = null

func _ready():
	# Hide progress elements initially
	progress_bar.visible = false
	target_label.visible = false

func set_inventory(inv: Inventory):
	"""Connect to an inventory to display its contents"""
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
		_on_inventory_changed()

func _on_inventory_changed():
	"""Update the inventory display"""
	if not inventory:
		return
	
	# Clear existing labels
	for child in inventory_display.get_children():
		child.queue_free()
	
	# Add labels for each item
	var items = inventory.get_all_items()
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "  (empty)"
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		empty_label.add_theme_color_override("font_outline_color", Color.BLACK)
		empty_label.add_theme_constant_override("outline_size", 2)
		inventory_display.add_child(empty_label)
	else:
		for item_name in items:
			var label = Label.new()
			label.text = "  " + item_name + ": " + str(items[item_name])
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
			label.add_theme_constant_override("outline_size", 2)
			label.add_theme_font_size_override("font_size", 16)
			inventory_display.add_child(label)
	
	print("Inventory UI updated: ", items)

func show_progress(visible: bool):
	"""Show or hide the progress bar"""
	progress_bar.visible = visible

func set_progress(value: float):
	"""Set progress bar value (0.0 to 1.0)"""
	progress_bar.value = value * 100.0

func show_target(resource_name: String):
	"""Show the name of the target resource"""
	target_label.text = resource_name
	target_label.visible = true

func hide_target():
	"""Hide the target label"""
	target_label.visible = false

func get_progress_bar() -> ProgressBar:
	return progress_bar

func get_target_label() -> Label:
	return target_label
