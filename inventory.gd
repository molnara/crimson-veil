extends Node
class_name Inventory

# Simple inventory system for tracking resources
# Items are stored as a dictionary: { "item_name": quantity }
# Stack limits are enforced when adding items

var items: Dictionary = {}

# Stack size limits by item type
const STACK_LIMITS = {
	"wood": 100,
	"stone": 50,
	"strawberry": 20,
	"Small Strawberry": 20,
	"Medium Strawberry": 20,
	"Large Strawberry": 20,
	"mushroom": 20,
	"Small Mushroom": 20,
	"Medium Mushroom": 20,
	"Large Mushroom": 20,
	"stone_pickaxe": 1,
	"stone_axe": 1,
	"campfire": 1,
	"torch": 1,
	"wood_wall": 1
}

const DEFAULT_STACK_LIMIT = 50  # Default for items not in the list
const MAX_ITEM_TYPES = 32  # Maximum different item types

signal item_added(item_name: String, amount: int, new_total: int)
signal item_removed(item_name: String, amount: int, new_total: int)
signal inventory_changed()
signal inventory_full(item_name: String)

func _ready():
	pass

func get_stack_limit(item_name: String) -> int:
	"""Get the maximum stack size for an item type"""
	return STACK_LIMITS.get(item_name, DEFAULT_STACK_LIMIT)

func add_item(item_name: String, amount: int = 1) -> bool:
	"""
	Add items to inventory with stack limits enforced.
	Returns true if all items were added, false if inventory is full.
	"""
	if amount <= 0:
		return true
	
	var stack_limit = get_stack_limit(item_name)
	
	# Check if adding a new item type would exceed slot limit
	if not items.has(item_name):
		if items.size() >= MAX_ITEM_TYPES:
			print("Inventory full! Cannot add new item type: ", item_name)
			emit_signal("inventory_full", item_name)
			return false
		items[item_name] = 0
	
	# Check if adding would exceed stack limit
	var current_count = items[item_name]
	var new_count = current_count + amount
	
	if new_count > stack_limit:
		# Add up to stack limit
		var added = stack_limit - current_count
		items[item_name] = stack_limit
		print("Stack limit reached for ", item_name, " - added ", added, " of ", amount)
		print("Inventory full! Could not add remaining ", amount - added, "x ", item_name)
		
		emit_signal("item_added", item_name, added, items[item_name])
		emit_signal("inventory_changed")
		emit_signal("inventory_full", item_name)
		return false  # Partial add - inventory effectively full
	
	# Can add all items
	items[item_name] = new_count
	
	print("Added ", amount, "x ", item_name, " (Total: ", items[item_name], "/", stack_limit, ")")
	
	emit_signal("item_added", item_name, amount, items[item_name])
	emit_signal("inventory_changed")
	
	return true

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
	print("=== Inventory (%d/%d item types) ===" % [items.size(), MAX_ITEM_TYPES])
	if items.is_empty():
		print("  Empty")
	else:
		for item_name in items:
			var stack_limit = get_stack_limit(item_name)
			print("  ", item_name, ": ", items[item_name], "/", stack_limit)
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
