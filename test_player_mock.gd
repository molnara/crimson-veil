extends CharacterBody3D
class_name TestPlayerMock

## Simple mock player for enemy testing
## Tracks damage taken without requiring full player.gd

var damage_taken: int = 0

func take_damage(amount: int) -> void:
	"""Track damage for testing"""
	damage_taken += amount
	print("[TestPlayer] Took %d damage (total: %d)" % [amount, damage_taken])
