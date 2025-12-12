extends Node

# AmbientManager - Biome-aware environmental sound system
# Handles layered ambient loops with smart frequency management

# ============================================================================
# CONFIGURATION
# ============================================================================

# Startup delay (seconds before ambient sounds begin)
const STARTUP_DELAY: float = 10.0

# Update frequency (how often to check biome/time changes)
const UPDATE_INTERVAL: float = 2.0

# Sound duration ranges (seconds)
const SOUND_DURATION_MIN: float = 15.0
const SOUND_DURATION_MAX: float = 30.0

# Silence duration ranges (seconds)
const SILENCE_DURATION_MIN: float = 45.0
const SILENCE_DURATION_MAX: float = 90.0

# Volume adjustments per sound type
const VOLUME_ADJUSTMENTS: Dictionary = {
	"wind_light": 0.12,
	"wind_strong": 0.16,
	"ocean_waves": 0.20,
	"crickets_night": 0.14,
	"birds_day": 0.12,
	"frogs_night": 0.10,
	"leaves_rustle": 0.11,
	"thunder_distant": 0.25
}

# ============================================================================
# BIOME AMBIENT CONFIGURATION
# ============================================================================

# Biome ambient sound chances (0.0 = never, 1.0 = always)
const BIOME_AMBIENTS: Dictionary = {
	"GRASSLAND": {
		"sounds": ["wind_light"],
		"frequency": 0.20,  # Rare
		"time_specific": {
			"day": ["birds_day"],
			"night": ["crickets_night"]
		},
		"time_frequency": 0.15
	},
	"FOREST": {
		"sounds": ["wind_light", "leaves_rustle"],
		"frequency": 0.25,  # Rare
		"time_specific": {
			"day": ["birds_day"],
			"night": ["crickets_night", "frogs_night"]
		},
		"time_frequency": 0.15
	},
	"BEACH": {
		"sounds": ["ocean_waves"],
		"frequency": 0.40,  # Occasional
		"time_specific": {},
		"time_frequency": 0.0
	},
	"MOUNTAIN": {
		"sounds": ["wind_strong"],
		"frequency": 0.50,  # Occasional
		"time_specific": {},
		"time_frequency": 0.0
	},
	"DESERT": {
		"sounds": ["wind_light"],
		"frequency": 0.35,  # Occasional
		"time_specific": {},
		"time_frequency": 0.0
	},
	"SNOW": {
		"sounds": ["wind_strong"],
		"frequency": 0.60,  # Frequent
		"time_specific": {},
		"time_frequency": 0.0
	}
}

# ============================================================================
# STATE
# ============================================================================

# System state
var is_initialized: bool = false
var update_timer: float = 0.0

# Current state
var current_biome: String = ""
var current_time_period: String = "day"  # "day" or "night"

# Active ambient sounds
var active_ambients: Dictionary = {}  # sound_name -> {timer: float, duration: float, is_playing: bool}

# Player and world references
var player: Node3D = null
var day_night_cycle: Node3D = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("[AmbientManager] Initializing ambient sound system...")
	
	# Wait for startup delay
	await get_tree().create_timer(STARTUP_DELAY).timeout
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("[AmbientManager] Player not found! Ambient system disabled.")
		return
	
	# Find day/night cycle
	day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if not day_night_cycle:
		push_warning("[AmbientManager] Day/night cycle not found - time-based ambients disabled")
	
	# Initialize ambient tracking
	_initialize_ambient_system()
	
	is_initialized = true
	print("[AmbientManager] Ambient sound system initialized!")

func _initialize_ambient_system():
	"""Set up initial ambient sound state"""
	
	# Determine starting biome
	current_biome = _get_player_biome()
	
	# Determine starting time period
	if day_night_cycle:
		current_time_period = "day" if _is_daytime() else "night"
	
	print("[AmbientManager] Starting in biome: %s, period: %s" % [current_biome, current_time_period])

# ============================================================================
# UPDATE LOOP
# ============================================================================

func _process(delta):
	if not is_initialized or not player:
		return
	
	# Update timer
	update_timer += delta
	
	# Check for biome/time changes periodically
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		_update_ambient_state()
	
	# Update active ambient timers
	_update_ambient_timers(delta)

func _update_ambient_state():
	"""Check for biome/time changes and update ambient sounds"""
	
	# Check biome change
	var new_biome = _get_player_biome()
	if new_biome != current_biome:
		_on_biome_changed(new_biome)
	
	# Check time period change
	if day_night_cycle:
		var new_period = "day" if _is_daytime() else "night"
		if new_period != current_time_period:
			_on_time_period_changed(new_period)

func _on_biome_changed(new_biome: String):
	"""Handle biome transition"""
	
	print("[AmbientManager] Biome changed: %s → %s" % [current_biome, new_biome])
	
	# Stop all current ambients
	_stop_all_ambients()
	
	# Update state
	current_biome = new_biome
	
	# Clear active tracking
	active_ambients.clear()

func _on_time_period_changed(new_period: String):
	"""Handle day/night transition"""
	
	print("[AmbientManager] Time period changed: %s → %s" % [current_time_period, new_period])
	
	# Stop time-specific ambients from previous period
	_stop_time_specific_ambients()
	
	# Update state
	current_time_period = new_period

# ============================================================================
# AMBIENT TIMER MANAGEMENT
# ============================================================================

func _update_ambient_timers(delta: float):
	"""Update all active ambient sound timers"""
	
	# Get biome config
	if not BIOME_AMBIENTS.has(current_biome):
		return
	
	var biome_config = BIOME_AMBIENTS[current_biome]
	
	# Process base ambient sounds
	for sound_name in biome_config["sounds"]:
		_update_sound_timer(sound_name, delta, biome_config["frequency"])
	
	# Process time-specific sounds
	if biome_config["time_specific"].has(current_time_period):
		for sound_name in biome_config["time_specific"][current_time_period]:
			_update_sound_timer(sound_name, delta, biome_config["time_frequency"])

func _update_sound_timer(sound_name: String, delta: float, frequency: float):
	"""Update timer for a specific ambient sound"""
	
	# Initialize tracking if needed
	if not active_ambients.has(sound_name):
		active_ambients[sound_name] = {
			"timer": randf_range(0.0, SILENCE_DURATION_MAX),  # Random start
			"duration": 0.0,
			"is_playing": false
		}
	
	var ambient = active_ambients[sound_name]
	ambient["timer"] += delta
	
	# Check if should start playing
	if not ambient["is_playing"]:
		# In silence period - check if should start
		if ambient["timer"] >= ambient["duration"]:
			# Roll chance to play
			if randf() <= frequency:
				_start_ambient_sound(sound_name, ambient)
			else:
				# Didn't pass chance - reset silence timer
				ambient["timer"] = 0.0
				ambient["duration"] = randf_range(SILENCE_DURATION_MIN, SILENCE_DURATION_MAX)
	else:
		# Currently playing - check if should stop
		if ambient["timer"] >= ambient["duration"]:
			_stop_ambient_sound(sound_name, ambient)

func _start_ambient_sound(sound_name: String, ambient: Dictionary):
	"""Start playing an ambient sound"""
	
	# Get volume for this sound
	var volume = VOLUME_ADJUSTMENTS.get(sound_name, 0.25)
	
	# Start playing
	AudioManager.play_ambient_loop(sound_name, volume)
	
	# Update state
	ambient["is_playing"] = true
	ambient["timer"] = 0.0
	ambient["duration"] = randf_range(SOUND_DURATION_MIN, SOUND_DURATION_MAX)
	
	# Debug
	# print("[AmbientManager] Started: %s (duration: %.1fs)" % [sound_name, ambient["duration"]])

func _stop_ambient_sound(sound_name: String, ambient: Dictionary):
	"""Stop playing an ambient sound"""
	
	# Stop playing
	AudioManager.stop_ambient_loop(sound_name, 2.0)  # 2 second fade out
	
	# Update state
	ambient["is_playing"] = false
	ambient["timer"] = 0.0
	ambient["duration"] = randf_range(SILENCE_DURATION_MIN, SILENCE_DURATION_MAX)
	
	# Debug
	# print("[AmbientManager] Stopped: %s (silence: %.1fs)" % [sound_name, ambient["duration"]])

# ============================================================================
# AMBIENT CONTROL
# ============================================================================

func _stop_all_ambients():
	"""Stop all currently playing ambient sounds"""
	
	for sound_name in active_ambients.keys():
		if active_ambients[sound_name]["is_playing"]:
			AudioManager.stop_ambient_loop(sound_name, 2.0)

func _stop_time_specific_ambients():
	"""Stop ambients that are specific to time of day"""
	
	var time_sounds = ["birds_day", "crickets_night", "frogs_night"]
	
	for sound_name in time_sounds:
		if active_ambients.has(sound_name) and active_ambients[sound_name]["is_playing"]:
			AudioManager.stop_ambient_loop(sound_name, 2.0)
			active_ambients[sound_name]["is_playing"] = false

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func _get_player_biome() -> String:
	"""Get current biome at player position"""
	
	if not player:
		return "GRASSLAND"
	
	# Get player's chunk position
	var player_pos = player.global_position
	var chunk_x = int(floor(player_pos.x / 32.0))
	var chunk_z = int(floor(player_pos.z / 32.0))
	
	# Access chunk manager's biome noise
	var chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
	if not chunk_manager:
		return "GRASSLAND"
	
	# Get biome from chunk manager's noise
	var noise_value = chunk_manager.biome_noise.get_noise_2d(chunk_x * 100.0, chunk_z * 100.0)
	
	# Determine biome (same logic as chunk.gd)
	if noise_value < -0.4:
		return "SNOW"
	elif noise_value < -0.2:
		return "MOUNTAIN"
	elif noise_value < 0.1:
		return "GRASSLAND"
	elif noise_value < 0.3:
		return "FOREST"
	elif noise_value < 0.5:
		return "DESERT"
	else:
		return "BEACH"

func _is_daytime() -> bool:
	"""Check if it's currently daytime"""
	
	if not day_night_cycle:
		return true
	
	var time = day_night_cycle.time_of_day
	# Day = 6 AM to 6 PM (0.25 to 0.75)
	return time >= 0.25 and time < 0.75

# ============================================================================
# PUBLIC API
# ============================================================================

func force_ambient_check():
	"""Manually trigger ambient update (for testing)"""
	
	if not is_initialized:
		push_warning("[AmbientManager] System not initialized")
		return
	
	_update_ambient_state()
	print("[AmbientManager] Forced ambient check")

func get_current_biome() -> String:
	"""Get current biome name"""
	return current_biome

func get_active_ambients() -> Array[String]:
	"""Get list of currently playing ambient sounds"""
	
	var playing: Array[String] = []
	for sound_name in active_ambients.keys():
		if active_ambients[sound_name]["is_playing"]:
			playing.append(sound_name)
	
	return playing

# ============================================================================
# DEBUG
# ============================================================================

func print_status():
	"""Print current ambient system status"""
	
	print("\n[AmbientManager] Status:")
	print("  Initialized: %s" % is_initialized)
	print("  Current Biome: %s" % current_biome)
	print("  Current Period: %s" % current_time_period)
	
	var playing = get_active_ambients()
	print("  Active Ambients: %d" % playing.size())
	for sound in playing:
		var ambient = active_ambients[sound]
		print("    - %s (%.1fs remaining)" % [sound, ambient["duration"] - ambient["timer"]])
	
	print("  Tracked Ambients: %d" % active_ambients.size())
	print("")
