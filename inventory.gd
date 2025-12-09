extends Node
class_name Inventory

# Simple inventory system for tracking resources
# Items are stored as a dictionary: { "item_name": quantity }

var items: Dictionary = {}

signal item_added(item_name: String, amount: int, new_total: int)
signal item_removed(item_name: String, amount: int, new_total: int)
signal inventory_changed()

func _ready():
	# Initialize with some starting items (optional)
	pass

func add_item(item_name: String, amount: int = 1) -> void:
	"""Add items to inventory"""
	if not items.has(item_name):
		items[item_name] = 0
	
	items[item_name] += amount
	
	print("Added ", amount, "x ", item_name, " (Total: ", items[item_name], ")")
	
	emit_signal("item_added", item_name, amount, items[item_name])
	emit_signal("inventory_changed")

func remove_item(item_name: String, amount: int = 1) -> bool:
	"""Remove items from inventory. Returns true if successful."""
	if not has_item(item_name, amount):
		return false
	
	items[item_name] -= amount
	
	# Remove entry if count reaches 0
	if items[item_name] <= 0:
		items.erase(item_name)
	
	emit_signal("item_removed", item_name, amount, get_item_count(item_name))
	emit_signal("inventory_changed")
	
	return true

func has_item(item_name: String, amount: int = 1) -> bool:
	"""Check if inventory contains at least the specified amount of an item"""
	if not items.has(item_name):
		return false
	return items[item_name] >= amount

func get_item_count(item_name: String) -> int:
	"""Get the count of a specific item"""
	if not items.has(item_name):
		return 0
	return items[item_name]

func get_all_items() -> Dictionary:
	"""Get a copy of the entire inventory"""
	return items.duplicate()

func clear():
	"""Clear the entire inventory"""
	items.clear()
	emit_signal("inventory_changed")

func print_inventory():
	"""Debug: Print current inventory contents"""
	print("=== Inventory ===")
	if items.is_empty():
		print("  Empty")
	else:
		for item_name in items:
			print("  ", item_name, ": ", items[item_name])
	print("=================")

# Serialization for save/load
func to_dict() -> Dictionary:
	"""Convert inventory to a dictionary for saving"""
	return {
		"items": items.duplicate()
	}

func from_dict(data: Dictionary):
	"""Load inventory from a dictionary"""
	if data.has("items"):
		items = data["items"].duplicate()
		emit_signal("inventory_changed")
