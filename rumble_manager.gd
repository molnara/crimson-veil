extends Node

# RumbleManager - Centralized controller haptic feedback system
# Provides tactile responses to gameplay actions with intelligent cooldowns
# 
# Features:
#   - 4 rumble presets (light/medium/heavy/impact)
#   - Per-type cooldown system to prevent spam
#   - Settings integration (enable/disable + intensity)
#   - Master volume scaling for audio/haptic consistency
#   - Automatic controller detection

# ============================================================================
# SETTINGS
# ============================================================================

var rumble_enabled: bool = true  # Master enable/disable
var rumble_intensity: float = 1.0  # 0.0 - 1.0 multiplier
var footstep_rumble_enabled: bool = false  # Optional footstep rumble

# Settings defaults (for reset functionality)
const RUMBLE_ENABLED_DEFAULT: bool = true
const RUMBLE_INTENSITY_DEFAULT: float = 1.0
const FOOTSTEP_RUMBLE_DEFAULT: bool = false

# ============================================================================
# RUMBLE PRESETS
# ============================================================================

# Rumble profiles: {weak_magnitude, strong_magnitude, duration_seconds}
# weak = left motor (high frequency), strong = right motor (low frequency)
const RUMBLE_PRESETS = {
	"light": {"weak": 0.15, "strong": 0.10, "duration": 0.12},      # UI, pickups, tool switch
	"medium": {"weak": 0.35, "strong": 0.25, "duration": 0.25},     # Harvesting, building
	"heavy": {"weak": 0.55, "strong": 0.45, "duration": 0.40},      # Resource breaks, damage
	"impact": {"weak": 0.20, "strong": 0.60, "duration": 0.15},     # Wrong tool, hard hits
	"footstep": {"weak": 0.08, "strong": 0.05, "duration": 0.08},   # Very subtle steps
	# Combat presets
	"attack_light": {"weak": 0.25, "strong": 0.20, "duration": 0.15},     # Light melee attack
	"attack_heavy": {"weak": 0.50, "strong": 0.60, "duration": 0.35},     # Heavy charged attack
	"dodge": {"weak": 0.30, "strong": 0.25, "duration": 0.20},            # Dodge dash
	"player_hit": {"weak": 0.45, "strong": 0.55, "duration": 0.30},       # Taking damage
	"enemy_death": {"weak": 0.40, "strong": 0.40, "duration": 0.25},      # Enemy killed
	"bow_release": {"weak": 0.15, "strong": 0.10, "duration": 0.12},      # Bow fired (light)
}

# ============================================================================
# COOLDOWN SYSTEM
# ============================================================================

# Per-type cooldowns (prevents spam from rapid actions)
var cooldown_timers: Dictionary = {}

# Cooldown durations (in seconds)
const COOLDOWNS = {
	"light": 0.15,       # UI interactions
	"medium": 0.20,      # Harvesting/building
	"heavy": 0.30,       # Heavy impacts
	"impact": 0.30,      # Wrong tool
	"footstep": 0.25,    # Footsteps (longer to prevent spam while walking)
	# Combat cooldowns
	"attack_light": 0.20,     # Light attacks
	"attack_heavy": 0.35,     # Heavy attacks
	"dodge": 0.25,            # Dodge
	"player_hit": 0.40,       # Taking damage
	"enemy_death": 0.30,      # Enemy killed
	"bow_release": 0.15,      # Bow shots
}

# Emergency brake - global rate limit
var last_rumble_time: float = 0.0
const GLOBAL_COOLDOWN: float = 0.05  # Minimum 50ms between ANY rumbles

# ============================================================================
# CONTROLLER TRACKING
# ============================================================================

var active_controller_device: int = -1  # -1 = none, 0+ = joypad device ID

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("[RumbleManager] Initializing rumble system...")
	
	# Detect controller
	_detect_controller()
	
	# Connect to input events for controller detection
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	print("[RumbleManager] Rumble system ready!")
	print("  - Enabled: %s" % rumble_enabled)
	print("  - Intensity: %.2f" % rumble_intensity)
	print("  - Footstep rumble: %s" % footstep_rumble_enabled)
	print("  - Controller detected: %s (device %d)" % [
		"Yes" if active_controller_device >= 0 else "No",
		active_controller_device
	])

func _process(delta):
	# Update cooldown timers
	for preset in cooldown_timers.keys():
		if cooldown_timers[preset] > 0:
			cooldown_timers[preset] -= delta

# ============================================================================
# CONTROLLER DETECTION
# ============================================================================

func _detect_controller():
	"""Detect if a controller is connected"""
	var joypads = Input.get_connected_joypads()
	if joypads.size() > 0:
		active_controller_device = joypads[0]  # Use first controller
		print("[RumbleManager] Controller detected: %s (device %d)" % [
			Input.get_joy_name(active_controller_device),
			active_controller_device
		])
	else:
		active_controller_device = -1
		print("[RumbleManager] No controller detected")

func _on_joy_connection_changed(device: int, connected: bool):
	"""Called when a controller is connected or disconnected"""
	if connected:
		print("[RumbleManager] Controller connected: %s (device %d)" % [
			Input.get_joy_name(device),
			device
		])
		if active_controller_device < 0:
			active_controller_device = device
	else:
		print("[RumbleManager] Controller disconnected (device %d)" % device)
		if active_controller_device == device:
			# Active controller disconnected - find another or set to -1
			var joypads = Input.get_connected_joypads()
			if joypads.size() > 0:
				active_controller_device = joypads[0]
			else:
				active_controller_device = -1

func has_controller() -> bool:
	"""Check if a controller is currently connected"""
	return active_controller_device >= 0

# ============================================================================
# RUMBLE PLAYBACK
# ============================================================================

func play(preset_name: String) -> void:
	"""
	Play a rumble preset
	
	Args:
		preset_name: One of "light", "medium", "heavy", "impact", "footstep"
	"""
	# Check if rumble is enabled
	if not rumble_enabled:
		return
	
	# Check if controller is connected
	if not has_controller():
		return
	
	# Special case: footstep rumble (optional setting)
	if preset_name == "footstep" and not footstep_rumble_enabled:
		return
	
	# Check if preset exists
	if not RUMBLE_PRESETS.has(preset_name):
		push_warning("[RumbleManager] Unknown preset: %s" % preset_name)
		return
	
	# Check global cooldown (emergency brake)
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_rumble_time < GLOBAL_COOLDOWN:
		return
	
	# Check preset-specific cooldown
	if cooldown_timers.has(preset_name) and cooldown_timers[preset_name] > 0:
		return
	
	# Get preset settings
	var preset = RUMBLE_PRESETS[preset_name]
	
	# Scale by intensity and master volume
	var intensity_scale = rumble_intensity
	if AudioManager:
		intensity_scale *= AudioManager.master_volume
	
	var weak = preset["weak"] * intensity_scale
	var strong = preset["strong"] * intensity_scale
	var duration = preset["duration"]
	
	# Play rumble
	Input.start_joy_vibration(active_controller_device, weak, strong, duration)
	
	# Set cooldowns
	last_rumble_time = current_time
	cooldown_timers[preset_name] = COOLDOWNS.get(preset_name, 0.2)

func play_custom(weak: float, strong: float, duration: float) -> void:
	"""
	Play a custom rumble effect
	
	Args:
		weak: Left motor magnitude (0.0-1.0)
		strong: Right motor magnitude (0.0-1.0)
		duration: Duration in seconds
	"""
	# Check if rumble is enabled
	if not rumble_enabled:
		return
	
	# Check if controller is connected
	if not has_controller():
		return
	
	# Check global cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_rumble_time < GLOBAL_COOLDOWN:
		return
	
	# Scale by intensity and master volume
	var intensity_scale = rumble_intensity
	if AudioManager:
		intensity_scale *= AudioManager.master_volume
	
	weak = clamp(weak * intensity_scale, 0.0, 1.0)
	strong = clamp(strong * intensity_scale, 0.0, 1.0)
	
	# Play rumble
	Input.start_joy_vibration(active_controller_device, weak, strong, duration)
	
	# Update last rumble time
	last_rumble_time = current_time

func stop() -> void:
	"""Stop all rumble immediately"""
	if has_controller():
		Input.stop_joy_vibration(active_controller_device)

# ============================================================================
# SETTINGS CONTROL
# ============================================================================

func set_rumble_enabled(enabled: bool) -> void:
	"""Enable or disable rumble"""
	rumble_enabled = enabled
	if not enabled:
		stop()  # Stop any active rumble
	print("[RumbleManager] Rumble enabled: %s" % enabled)

func set_rumble_intensity(intensity: float) -> void:
	"""Set rumble intensity multiplier (0.0 - 1.0)"""
	rumble_intensity = clamp(intensity, 0.0, 1.0)
	print("[RumbleManager] Rumble intensity: %.2f" % rumble_intensity)

func set_footstep_rumble(enabled: bool) -> void:
	"""Enable or disable footstep rumble"""
	footstep_rumble_enabled = enabled
	print("[RumbleManager] Footstep rumble: %s" % enabled)

func reset_settings() -> void:
	"""Reset all rumble settings to defaults"""
	rumble_enabled = RUMBLE_ENABLED_DEFAULT
	rumble_intensity = RUMBLE_INTENSITY_DEFAULT
	footstep_rumble_enabled = FOOTSTEP_RUMBLE_DEFAULT
	stop()
	print("[RumbleManager] Settings reset to defaults")

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func is_rumbling() -> bool:
	"""Check if any rumble is currently active"""
	# Note: Godot doesn't provide a way to check this directly
	# We approximate by checking if a recent rumble was triggered
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - last_rumble_time) < 0.5

func get_preset_info(preset_name: String) -> Dictionary:
	"""Get information about a rumble preset"""
	if RUMBLE_PRESETS.has(preset_name):
		var preset = RUMBLE_PRESETS[preset_name].duplicate()
		preset["cooldown"] = COOLDOWNS.get(preset_name, 0.2)
		return preset
	return {}

func print_status() -> void:
	"""Print current rumble system status (for debugging)"""
	print("\n[RumbleManager Status]")
	print("  Enabled: %s" % rumble_enabled)
	print("  Intensity: %.2f" % rumble_intensity)
	print("  Footstep rumble: %s" % footstep_rumble_enabled)
	print("  Controller: %s (device %d)" % [
		"Connected" if has_controller() else "Disconnected",
		active_controller_device
	])
	print("  Active cooldowns:")
	for preset in cooldown_timers.keys():
		if cooldown_timers[preset] > 0:
			print("    %s: %.2fs remaining" % [preset, cooldown_timers[preset]])
	print("")

# ============================================================================
# INTEGRATION HELPERS
# ============================================================================

func play_harvest_hit() -> void:
	"""Helper: Play rumble for harvest hit"""
	play("medium")

func play_harvest_complete() -> void:
	"""Helper: Play rumble for harvest completion"""
	play("heavy")

func play_build_place() -> void:
	"""Helper: Play rumble for block placement"""
	play("medium")

func play_build_remove() -> void:
	"""Helper: Play rumble for block removal"""
	play("light")

func play_ui_click() -> void:
	"""Helper: Play rumble for UI interaction"""
	play("light")

func play_wrong_tool() -> void:
	"""Helper: Play rumble for wrong tool"""
	play("impact")

func play_craft_success() -> void:
	"""Helper: Play rumble for successful craft"""
	play("medium")

func play_craft_fail() -> void:
	"""Helper: Play rumble for failed craft"""
	play("impact")

func play_item_pickup() -> void:
	"""Helper: Play rumble for item pickup"""
	play("light")

func play_warning() -> void:
	"""Helper: Play rumble for warning (health/hunger)"""
	play("heavy")

func play_footstep() -> void:
	"""Helper: Play rumble for footstep (if enabled)"""
	play("footstep")

# ============================================================================
# COMBAT RUMBLE HELPERS
# ============================================================================

func play_light_attack() -> void:
	"""Helper: Play rumble for light attack"""
	play("attack_light")

func play_heavy_attack() -> void:
	"""Helper: Play rumble for heavy attack"""
	play("attack_heavy")

func play_dodge_dash() -> void:
	"""Helper: Play rumble for dodge"""
	play("dodge")

func play_player_damage() -> void:
	"""Helper: Play rumble for taking damage"""
	play("player_hit")

func play_enemy_killed() -> void:
	"""Helper: Play rumble for enemy death"""
	play("enemy_death")

func play_bow_shot() -> void:
	"""Helper: Play rumble for bow release"""
	play("bow_release")
