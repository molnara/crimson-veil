extends Control

"""
ContainerUI - Dual-panel interface for container interaction

Shows player inventory (left) and container inventory (right) side-by-side.
Click items to transfer between inventories.
Press ESC to close.
"""

# References
var current_container: Node = null
var player_inventory: Inventory = null
var player_node: Node3D = null

# UI References (from scene tree)
@onready var background: Panel = $Background
@onready var container_panel: Panel = $CenterContainer/HBoxContainer/ContainerPanel
@onready var player_panel: Panel = $CenterContainer/HBoxContainer/PlayerPanel
@onready var container_grid: GridContainer = $CenterContainer/HBoxContainer/ContainerPanel/VBoxContainer/GridContainer
@onready var player_grid: GridContainer = $CenterContainer/HBoxContainer/PlayerPanel/VBoxContainer/GridContainer
@onready var container_title: Label = $CenterContainer/HBoxContainer/ContainerPanel/VBoxContainer/Title
@onready var player_title: Label = $CenterContainer/HBoxContainer/PlayerPanel/VBoxContainer/Title
@onready var hint_label: Label = $HintLabel
@onready var error_notification: Label = $ErrorNotification

# Error notification timer
var error_timer: float = 0.0

# Grid settings
const GRID_COLUMNS = 8
const SLOT_SIZE = 64
const SLOT_SPACING = 4

# Auto-close settings
const MAX_DISTANCE = 5.0  # Close UI if player moves >5m away
var check_distance_timer: float = 0.0
const DISTANCE_CHECK_INTERVAL = 0.5  # Check every 0.5 seconds

# Item icon colors (same as inventory_ui.gd)
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
	# Start hidden
	visible = false
	
	# Apply styles to panels
	apply_panel_styles()
	
	print("ContainerUI ready (scene-based)")

func apply_panel_styles():
	"""Apply visual styles to the panels and background"""
	# Background overlay style
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	background.add_theme_stylebox_override("panel", bg_style)
	
	# Player panel style
	var player_style = StyleBoxFlat.new()
	player_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	player_style.border_color = Color(0.4, 0.4, 0.4)
	player_style.border_width_left = 3
	player_style.border_width_right = 3
	player_style.border_width_top = 3
	player_style.border_width_bottom = 3
	player_style.corner_radius_top_left = 8
	player_style.corner_radius_top_right = 8
	player_style.corner_radius_bottom_left = 8
	player_style.corner_radius_bottom_right = 8
	player_panel.add_theme_stylebox_override("panel", player_style)
	
	# Container panel style (same as player)
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	container_style.border_color = Color(0.4, 0.4, 0.4)
	container_style.border_width_left = 3
	container_style.border_width_right = 3
	container_style.border_width_top = 3
	container_style.border_width_bottom = 3
	container_style.corner_radius_top_left = 8
	container_style.corner_radius_top_right = 8
	container_style.corner_radius_bottom_left = 8
	container_style.corner_radius_bottom_right = 8
	container_panel.add_theme_stylebox_override("panel", container_style)
	
	# Hint label style
	hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	# Error notification style
	error_notification.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _process(delta):
	# Handle error notification timer
	if error_timer > 0:
		error_timer -= delta
		if error_timer <= 0:
			if error_notification:
				error_notification.visible = false
	
	# Check distance to container
	if visible and current_container and player_node:
		check_distance_timer -= delta
		if check_distance_timer <= 0:
			check_distance_timer = DISTANCE_CHECK_INTERVAL
			
			var distance = player_node.global_position.distance_to(current_container.global_position)
			if distance > MAX_DISTANCE:
				print("Player moved too far from container - closing UI")
				close_container()

func show_container(container: Node, player_inv: Inventory, player: Node3D):
	"""Display the container UI with both inventories"""
	current_container = container
	player_inventory = player_inv
	player_node = player
	
	# Connect signals
	if current_container:
		var container_inv = current_container.get_inventory()
		if container_inv and not container_inv.inventory_changed.is_connected(refresh_container_grid):
			container_inv.inventory_changed.connect(refresh_container_grid)
	
	if player_inventory and not player_inventory.inventory_changed.is_connected(refresh_player_grid):
		player_inventory.inventory_changed.connect(refresh_player_grid)
	
	# Update title with container name
	if container_title and current_container:
		container_title.text = current_container.container_name.to_upper()
	
	# Refresh both grids
	refresh_both_grids()
	
	# Show UI
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("Container UI opened: ", container.container_name)

func close_container():
	"""Close the container UI"""
	if not visible:
		return
	
	# Disconnect signals
	if current_container:
		var container_inv = current_container.get_inventory()
		if container_inv and container_inv.inventory_changed.is_connected(refresh_container_grid):
			container_inv.inventory_changed.disconnect(refresh_container_grid)
	
	if player_inventory and player_inventory.inventory_changed.is_connected(refresh_player_grid):
		player_inventory.inventory_changed.disconnect(refresh_player_grid)
	
	# Close container
	if current_container and current_container.has_method("close"):
		current_container.close()
	
	# Hide UI
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	print("Container UI closed")

func refresh_both_grids():
	"""Refresh both inventory grids"""
	refresh_player_grid()
	refresh_container_grid()

func refresh_container_grid():
	"""Update the container inventory grid"""
	if not container_grid or not current_container:
		return
	
	# Clear existing slots
	for child in container_grid.get_children():
		child.queue_free()
	
	var container_inv = current_container.get_inventory()
	if not container_inv:
		return
	
	var items = container_inv.get_all_items()
	
	# Create slots for each item
	for item_name in items:
		var count = items[item_name]
		create_item_slot(container_grid, item_name, count, true)
	
	# Fill remaining slots with empty placeholders
	var total_slots = 32
	var filled_slots = items.size()
	for i in range(total_slots - filled_slots):
		create_empty_slot(container_grid)

func refresh_player_grid():
	"""Update the player inventory grid"""
	if not player_grid or not player_inventory:
		return
	
	# Clear existing slots
	for child in player_grid.get_children():
		child.queue_free()
	
	var items = player_inventory.get_all_items()
	
	# Create slots for each item
	for item_name in items:
		var count = items[item_name]
		create_item_slot(player_grid, item_name, count, false)
	
	# Fill remaining slots with empty placeholders
	var total_slots = 32
	var filled_slots = items.size()
	for i in range(total_slots - filled_slots):
		create_empty_slot(player_grid)

func create_item_slot(grid: GridContainer, item_name: String, count: int, is_container_slot: bool):
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
	
	# Get inventory reference for stack limits
	var inv = current_container.get_inventory() if is_container_slot else player_inventory
	
	# Count label with stack limit
	var count_label = Label.new()
	var stack_limit = inv.get_stack_limit(item_name)
	var is_full = (count >= stack_limit)
	
	if stack_limit > 1:
		if is_full:
			count_label.text = "FULL"
			count_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))  # Red
		else:
			count_label.text = str(count) + "/" + str(stack_limit)
			count_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		count_label.text = str(count)
		count_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Visual feedback for full stacks
	if is_full and stack_limit > 1:
		slot_style.bg_color = Color(0.35, 0.15, 0.15, 0.9)  # Red tint
		slot_style.border_color = Color(1, 0.3, 0.3)  # Red border
	
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 12)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 1)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(count_label)
	
	# Tooltip
	slot.tooltip_text = item_name.capitalize() + "\n[Click to transfer 1]\n[Shift+Click to transfer all]"
	
	# Connect click event
	slot.gui_input.connect(func(event): _on_slot_clicked(event, item_name, is_container_slot))
	
	grid.add_child(slot)

func create_empty_slot(grid: GridContainer):
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
	
	grid.add_child(slot)

func _on_slot_clicked(event: InputEvent, item_name: String, is_container_slot: bool):
	"""Handle clicking on an inventory slot to transfer items"""
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Check if Shift is pressed for full stack transfer
			var transfer_all = event.shift_pressed
			
			if is_container_slot:
				if transfer_all:
					transfer_all_from_container(item_name)
				else:
					transfer_from_container(item_name)
			else:
				if transfer_all:
					transfer_all_from_player(item_name)
				else:
					transfer_from_player(item_name)

func transfer_from_container(item_name: String):
	"""Transfer 1 item from container to player"""
	if not current_container or not player_inventory:
		return
	
	var container_inv = current_container.get_inventory()
	if not container_inv:
		return
	
	# Try to remove from container
	if container_inv.remove_item(item_name, 1):
		# Try to add to player
		if not player_inventory.add_item(item_name, 1):
			# Player inventory full - give it back
			container_inv.add_item(item_name, 1)
			show_error("Player inventory full!")
			print("Transfer failed: Player inventory full")
		else:
			print("Transferred ", item_name, " from container to player")
	else:
		print("Transfer failed: Item not in container")

func transfer_all_from_container(item_name: String):
	"""Transfer entire stack from container to player"""
	if not current_container or not player_inventory:
		return
	
	var container_inv = current_container.get_inventory()
	if not container_inv:
		return
	
	# Get how many we have in container
	var count_in_container = container_inv.get_item_count(item_name)
	if count_in_container <= 0:
		return
	
	# Try to transfer all at once
	var transferred = 0
	for i in range(count_in_container):
		if container_inv.remove_item(item_name, 1):
			if player_inventory.add_item(item_name, 1):
				transferred += 1
			else:
				# Player inventory full - give it back
				container_inv.add_item(item_name, 1)
				show_error("Player inventory full! Transferred %d/%d" % [transferred, count_in_container])
				print("Partial transfer: ", transferred, "/", count_in_container)
				return
	
	print("Transferred all ", count_in_container, "x ", item_name, " from container to player")

func transfer_from_player(item_name: String):
	"""Transfer 1 item from player to container"""
	if not current_container or not player_inventory:
		return
	
	var container_inv = current_container.get_inventory()
	if not container_inv:
		return
	
	# Try to remove from player
	if player_inventory.remove_item(item_name, 1):
		# Try to add to container
		if not container_inv.add_item(item_name, 1):
			# Container inventory full - give it back
			player_inventory.add_item(item_name, 1)
			show_error("Container full!")
			print("Transfer failed: Container full")
		else:
			print("Transferred ", item_name, " from player to container")
	else:
		print("Transfer failed: Item not in player inventory")

func transfer_all_from_player(item_name: String):
	"""Transfer entire stack from player to container"""
	if not current_container or not player_inventory:
		return
	
	var container_inv = current_container.get_inventory()
	if not container_inv:
		return
	
	# Get how many we have in player inventory
	var count_in_player = player_inventory.get_item_count(item_name)
	if count_in_player <= 0:
		return
	
	# Try to transfer all at once
	var transferred = 0
	for i in range(count_in_player):
		if player_inventory.remove_item(item_name, 1):
			if container_inv.add_item(item_name, 1):
				transferred += 1
			else:
				# Container inventory full - give it back
				player_inventory.add_item(item_name, 1)
				show_error("Container full! Transferred %d/%d" % [transferred, count_in_player])
				print("Partial transfer: ", transferred, "/", count_in_player)
				return
	
	print("Transferred all ", count_in_player, "x ", item_name, " from player to container")

func show_error(message: String):
	"""Show error message for 2 seconds"""
	if error_notification:
		error_notification.text = message
		error_notification.visible = true
		error_timer = 2.0
