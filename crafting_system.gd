extends Node
class_name CraftingSystem

"""
CraftingSystem - Simple recipe-based crafting

ARCHITECTURE:
- Checks inventory for required items
- Consumes ingredients and produces result
- Recipes defined as dictionaries (input -> output)

INTEGRATION:
- Requires Inventory reference
- Called from player input (R key)
"""

var inventory: Inventory

# Recipe format: "result_item": { "inputs": { "item": count }, "output_count": count }
var recipes: Dictionary = {
	"stone_pickaxe": {
		"inputs": { "wood": 3, "stone": 5 },
		"output_count": 1
	},
	"stone_axe": {
		"inputs": { "wood": 3, "stone": 5 },
		"output_count": 1
	},
	"campfire": {
		"inputs": { "wood": 10, "stone": 5 },
		"output_count": 1
	},
	"torch": {
		"inputs": { "wood": 2 },
		"output_count": 3
	},
	"wood_wall": {
		"inputs": { "wood": 4 },
		"output_count": 1
	}
}

signal recipe_crafted(item_name: String, amount: int)
signal craft_failed(reason: String)

func initialize(player_inventory: Inventory):
	"""Initialize with inventory reference"""
	inventory = player_inventory
	print("CraftingSystem initialized with ", recipes.size(), " recipes")

func can_craft(recipe_name: String) -> bool:
	"""Check if player has resources to craft an item"""
	if not recipes.has(recipe_name):
		return false
	
	var recipe = recipes[recipe_name]
	var inputs = recipe["inputs"]
	
	# Check each required ingredient
	for item in inputs:
		var required = inputs[item]
		if not inventory.has_item(item, required):
			return false
	
	return true

func craft(recipe_name: String) -> bool:
	"""Attempt to craft an item, consuming resources"""
	if not recipes.has(recipe_name):
		emit_signal("craft_failed", "Unknown recipe")
		return false
	
	if not can_craft(recipe_name):
		emit_signal("craft_failed", "Not enough resources")
		return false
	
	var recipe = recipes[recipe_name]
	var inputs = recipe["inputs"]
	var output_count = recipe["output_count"]
	
	# Consume ingredients
	for item in inputs:
		var amount = inputs[item]
		inventory.remove_item(item, amount)
	
	# Add result
	inventory.add_item(recipe_name, output_count)
	
	emit_signal("recipe_crafted", recipe_name, output_count)
	print("Crafted ", output_count, "x ", recipe_name)
	
	return true

func get_all_recipes() -> Dictionary:
	"""Get all available recipes"""
	return recipes.duplicate()

func get_recipe_info(recipe_name: String) -> Dictionary:
	"""Get detailed info about a specific recipe"""
	if not recipes.has(recipe_name):
		return {}
	
	var recipe = recipes[recipe_name]
	return {
		"name": recipe_name,
		"inputs": recipe["inputs"],
		"output_count": recipe["output_count"],
		"can_craft": can_craft(recipe_name)
	}

func get_craftable_recipes() -> Array:
	"""Get list of recipes the player can currently craft"""
	var craftable = []
	for recipe_name in recipes:
		if can_craft(recipe_name):
			craftable.append(recipe_name)
	return craftable

func get_missing_ingredients(recipe_name: String) -> Dictionary:
	"""Get what ingredients are missing for a recipe"""
	if not recipes.has(recipe_name):
		return {}
	
	var missing = {}
	var recipe = recipes[recipe_name]
	var inputs = recipe["inputs"]
	
	for item in inputs:
		var required = inputs[item]
		var have = inventory.get_item_count(item)
		if have < required:
			missing[item] = required - have
	
	return missing
