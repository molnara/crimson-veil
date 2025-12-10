extends Control

# References to UI elements
@onready var progress_bar = $CenterContainer/VBoxContainer/ProgressBar
@onready var target_label = $CenterContainer/VBoxContainer/TargetLabel
@onready var inventory_display = $InventoryDisplay/ItemList
@onready var time_label = $TimeDisplay/TimeLabel
@onready var tool_label = $ToolDisplay/ToolLabel

var inventory: Inventory = null
var day_night_cycle: DayNightCycle = null
var tool_system: ToolSystem = null

func _ready():
	# Hide progress elements initially
	progress_bar.visible = false
	target_label.visible = false
	
	# Find DayNightCycle for time display
	call_deferred("find_day_night_cycle")

func find_day_night_cycle():
	"""Find the DayNightCycle node using groups (efficient)"""
	var cycles = get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.size() > 0:
		day_night_cycle = cycles[0]
		return
	
	# Fallback: direct search if not in group
	var root = get_tree().root
	for child in root.get_children():
		if child.get_script() and child.get_script().get_global_name() == "DayNightCycle":
			day_night_cycle = child
			return

func find_node_by_type(node: Node, type_name: String) -> Node:
	"""Recursively search for a node by class name"""
	if node.get_class() == type_name or (node.get_script() and node.get_script().get_global_name() == type_name):
		return node
	
	for child in node.get_children():
		var result = find_node_by_type(child, type_name)
		if result:
			return result
	
	return null

func _process(_delta):
	# Update time display
	if day_night_cycle and time_label:
		var time_of_day = day_night_cycle.get_time_of_day()
		
		# Convert to 24-hour time
		var hour_24 = int(time_of_day * 24.0)
		var minute = int((time_of_day * 24.0 - hour_24) * 60.0)
		
		# Convert to 12-hour format
		var am_pm = "AM"
		var hour_12 = hour_24
		
		if hour_24 >= 12:
			am_pm = "PM"
			if hour_24 > 12:
				hour_12 = hour_24 - 12
		
		if hour_24 == 0:
			hour_12 = 12  # Midnight is 12 AM
		
		# Format time string
		var time_string = "%d:%02d %s" % [hour_12, minute, am_pm]
		
		time_label.text = time_string

func set_inventory(inv: Inventory):
	"""Connect to an inventory to display its contents"""
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
		_on_inventory_changed()

func set_tool_system(tools: ToolSystem):
	"""Connect to tool system to display equipped tool"""
	tool_system = tools
	if tool_system:
		tool_system.tool_equipped.connect(_on_tool_equipped)
		_on_tool_equipped(tool_system.get_equipped_tool())

func _on_tool_equipped(tool: int):
	"""Update tool display when tool is equipped"""
	if tool_label and tool_system:
		var tool_name = tool_system.get_tool_name(tool)
		tool_label.text = "Tool: " + tool_name

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
