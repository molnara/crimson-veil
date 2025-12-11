extends Control

"""
CraftingUI - Simple crafting menu

Shows available recipes with ingredients and craft button
Press R to toggle visibility
"""

var crafting_system: CraftingSystem
var inventory: Inventory

# UI nodes
var recipe_list: VBoxContainer
var background: Panel

func _ready():
	# Create UI structure
	name = "CraftingUI"
	
	# Semi-transparent background panel
	background = Panel.new()
	background.set_anchors_preset(Control.PRESET_CENTER)
	background.custom_minimum_size = Vector2(400, 500)
	background.position = Vector2(
		get_viewport().size.x / 2 - 200,
		get_viewport().size.y / 2 - 250
	)
	add_child(background)
	
	# Add dark background style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	background.add_theme_stylebox_override("panel", style)
	
	# Title
	var title = Label.new()
	title.text = "CRAFTING (Press R to close)"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 2)
	title.position = Vector2(20, 10)
	background.add_child(title)
	
	# Recipe list container
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, 50)
	scroll.size = Vector2(380, 440)
	background.add_child(scroll)
	
	recipe_list = VBoxContainer.new()
	recipe_list.add_theme_constant_override("separation", 10)
	scroll.add_child(recipe_list)
	
	# Start hidden
	visible = false

func set_crafting_system(system: CraftingSystem):
	"""Connect to crafting system"""
	crafting_system = system
	if crafting_system:
		crafting_system.recipe_crafted.connect(_on_recipe_crafted)
		crafting_system.craft_failed.connect(_on_craft_failed)

func set_inventory(inv: Inventory):
	"""Connect to inventory"""
	inventory = inv
	if inventory:
		inventory.inventory_changed.connect(refresh_recipes)

func refresh_recipes():
	"""Update recipe list display"""
	if not crafting_system:
		return
	
	# Clear existing
	for child in recipe_list.get_children():
		child.queue_free()
	
	var recipes = crafting_system.get_all_recipes()
	
	for recipe_name in recipes:
		var recipe_info = crafting_system.get_recipe_info(recipe_name)
		var can_craft = recipe_info["can_craft"]
		
		# Recipe container
		var recipe_panel = PanelContainer.new()
		var recipe_style = StyleBoxFlat.new()
		recipe_style.bg_color = Color(0.2, 0.2, 0.2, 0.8) if can_craft else Color(0.15, 0.15, 0.15, 0.6)
		recipe_style.border_color = Color(0.3, 0.8, 0.3) if can_craft else Color(0.3, 0.3, 0.3)
		recipe_style.border_width_left = 1
		recipe_style.border_width_right = 1
		recipe_style.border_width_top = 1
		recipe_style.border_width_bottom = 1
		recipe_panel.add_theme_stylebox_override("panel", recipe_style)
		recipe_list.add_child(recipe_panel)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		recipe_panel.add_child(vbox)
		
		# Recipe name
		var name_label = Label.new()
		name_label.text = recipe_name.capitalize() + " x" + str(recipe_info["output_count"])
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", Color.WHITE if can_craft else Color(0.5, 0.5, 0.5))
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.add_theme_constant_override("outline_size", 2)
		vbox.add_child(name_label)
		
		# Ingredients
		var inputs = recipe_info["inputs"]
		for item in inputs:
			var required = inputs[item]
			var have = inventory.get_item_count(item) if inventory else 0
			var has_enough = have >= required
			
			var ingredient_label = Label.new()
			ingredient_label.text = "  " + item.capitalize() + ": " + str(have) + "/" + str(required)
			ingredient_label.add_theme_color_override("font_color", Color.WHITE if has_enough else Color(1.0, 0.4, 0.4))
			ingredient_label.add_theme_color_override("font_outline_color", Color.BLACK)
			ingredient_label.add_theme_constant_override("outline_size", 1)
			vbox.add_child(ingredient_label)
		
		# Craft button
		var button = Button.new()
		button.text = "CRAFT"
		button.disabled = not can_craft
		button.pressed.connect(_on_craft_button_pressed.bind(recipe_name))
		vbox.add_child(button)

func _on_craft_button_pressed(recipe_name: String):
	"""Handle craft button click"""
	if crafting_system:
		crafting_system.craft(recipe_name)

func _on_recipe_crafted(item_name: String, amount: int):
	"""Feedback when crafting succeeds"""
	print("Successfully crafted ", amount, "x ", item_name)
	refresh_recipes()

func _on_craft_failed(reason: String):
	"""Feedback when crafting fails"""
	print("Craft failed: ", reason)

func toggle_visibility():
	"""Show/hide the crafting menu"""
	visible = !visible
	if visible:
		refresh_recipes()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
