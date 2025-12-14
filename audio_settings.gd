extends Node

## AudioSettings - Inspector control for AudioManager
## Add this to your scene to adjust audio settings in the Inspector

@export_group("Combat Audio Volume")
@export_range(0.0, 1.0, 0.05) var combat_sound_volume: float = 0.3:
	set(value):
		combat_sound_volume = value
		if AudioManager:
			AudioManager.combat_sound_volume = value
			print("[AudioSettings] Combat sound volume set to: %.2f" % value)

@export_range(0.0, 100.0, 5.0) var sound_3d_max_distance: float = 30.0:
	set(value):
		sound_3d_max_distance = value
		if AudioManager:
			AudioManager.sound_3d_max_distance = value
			print("[AudioSettings] 3D sound max distance set to: %.1fm" % value)

func _ready() -> void:
	# Sync initial values to AudioManager
	if AudioManager:
		AudioManager.combat_sound_volume = combat_sound_volume
		AudioManager.sound_3d_max_distance = sound_3d_max_distance
		print("[AudioSettings] Initialized:")
		print("  - Combat Volume: %.2f" % combat_sound_volume)
		print("  - Max Distance: %.1fm" % sound_3d_max_distance)
