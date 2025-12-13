extends Resource
class_name Weapon

# Weapon resource definition for combat system
# Used by CombatSystem to determine damage, range, and cooldowns

@export var weapon_name: String = "Wooden Club"
@export var light_damage: int = 15
@export var heavy_damage: int = 30
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.0

# Weapon definitions (static data)
static func get_weapon(weapon_id: String) -> Weapon:
	var weapon = Weapon.new()
	
	match weapon_id:
		"wooden_club":
			weapon.weapon_name = "Wooden Club"
			weapon.light_damage = 15
			weapon.heavy_damage = 30
			weapon.attack_range = 2.5
			weapon.attack_cooldown = 1.0
		
		"stone_spear":
			weapon.weapon_name = "Stone Spear"
			weapon.light_damage = 20
			weapon.heavy_damage = 40
			weapon.attack_range = 3.5
			weapon.attack_cooldown = 1.2
		
		"bone_sword":
			weapon.weapon_name = "Bone Sword"
			weapon.light_damage = 25
			weapon.heavy_damage = 50
			weapon.attack_range = 3.0
			weapon.attack_cooldown = 1.0
		
		_:
			# Default to wooden club
			weapon.weapon_name = "Wooden Club"
			weapon.light_damage = 15
			weapon.heavy_damage = 30
			weapon.attack_range = 2.5
			weapon.attack_cooldown = 1.0
	
	return weapon

# Get crafting recipe for weapon
static func get_recipe(weapon_id: String) -> Dictionary:
	match weapon_id:
		"wooden_club":
			return {"wood": 5}
		"stone_spear":
			return {"wood": 3, "stone": 2, "leather": 1}
		"bone_sword":
			return {"wood": 2, "bone": 4}
		_:
			return {}
