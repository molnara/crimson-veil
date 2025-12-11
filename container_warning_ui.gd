extends Control

"""
ContainerWarningUI - Modal warning dialog for removing containers with items

Shows when player tries to remove a chest that contains items.
Options: Cancel (keep container) or Remove (items drop to ground)
"""

# UI elements (will be created programmatically)
var panel: Panel
var title_label: Label
var message_label: Label
var cancel_button: Button
var remove_button: Button

# State
var target_container: Node = null
var target_position: Vector3 = Vector3.ZERO

# Signals
signal remove_confirmed(position: Vector3)
signal remove_cancelled()

func _ready():
	# Start hidden
	visible = false
	
	# Create UI elements
	create_ui()
	
	# Connect button signals
	cancel_button.pressed.connect(_on_cancel_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	
	# Center on screen
	anchors_preset = Control.PRESET_CENTER
	position = Vector2.ZERO

func create_ui():
	"""Create the warning dialog UI"""
	# Main panel (dark background)
	panel = Panel.new()
	add_child(panel)
	panel.custom_minimum_size = Vector2(400, 200)
	
	# VBoxContainer for layout
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚠ WARNING"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))  # Orange
	vbox.add_child(title_label)
	
	# Message
	message_label = Label.new()
	message_label.text = "This container has items inside!\n\nRemoving it will drop all items to the ground."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(message_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Button container
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(150, 40)
	hbox.add_child(cancel_button)
	
	# Remove button (warning color)
	remove_button = Button.new()
	remove_button.text = "Remove Anyway"
	remove_button.custom_minimum_size = Vector2(150, 40)
	remove_button.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))  # Red text
	hbox.add_child(remove_button)

func show_warning(container: Node, item_count: int, pos: Vector3):
	"""Show the warning dialog"""
	target_container = container
	target_position = pos
	
	# Update message with item count
	message_label.text = "This container has %d item type(s) inside!\n\nRemoving it will drop all items to the ground." % item_count
	
	# Show dialog
	visible = true
	
	# Show mouse cursor for clicking buttons
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("Container warning shown - %d items" % item_count)

func _on_cancel_pressed():
	"""User chose to keep the container"""
	hide_warning()
	emit_signal("remove_cancelled")
	print("Container removal cancelled")

func _on_remove_pressed():
	"""User confirmed removal - items will drop"""
	hide_warning()
	emit_signal("remove_confirmed", target_position)
	print("Container removal confirmed")

func hide_warning():
	"""Hide the dialog and restore game state"""
	visible = false
	target_container = null
	target_position = Vector3.ZERO
	
	# Restore mouse capture for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
