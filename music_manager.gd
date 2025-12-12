extends Node

# MusicManager - Smart day/night music rotation system
# Handles ambient music playback with track variety and smooth transitions

# ============================================================================
# CONFIGURATION
# ============================================================================

# Startup delay (seconds before first track plays)
const STARTUP_DELAY: float = 8.0

# Transition timing (in-game hours)
const DAWN_START: float = 5.5 / 24.0      # 5:30 AM
const DAWN_END: float = 6.5 / 24.0        # 6:30 AM
const DUSK_START: float = 17.5 / 24.0     # 5:30 PM
const DUSK_END: float = 18.5 / 24.0       # 6:30 PM

# Crossfade duration (seconds)
const CROSSFADE_DURATION: float = 30.0

# Track lists
const DAY_TRACKS: Array[String] = [
	"ambient_day_1",
	"ambient_day_2",
	"ambient_day_3",
	"ambient_day_4"
]

const NIGHT_TRACKS: Array[String] = [
	"ambient_night_1",
	"ambient_night_2",
	"ambient_night_3",
	"ambient_night_4"
]

# ============================================================================
# STATE
# ============================================================================

# System state
var is_initialized: bool = false
var is_transitioning: bool = false

# Current playback state
var current_period: String = ""  # "day" or "night"
var current_track_index: int = -1
var last_played_indices: Array[int] = []

# Day/night cycle reference
var day_night_cycle: Node3D = null

# Transition tracking
var transition_start_time: float = 0.0
var pending_period: String = ""

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("[MusicManager] Initializing music system...")
	
	# Wait for startup delay before beginning music
	await get_tree().create_timer(STARTUP_DELAY).timeout
	
	# Find day/night cycle
	day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	
	if not day_night_cycle:
		push_error("[MusicManager] Day/night cycle not found! Music system disabled.")
		return
	
	# Start music based on current time
	_initialize_music()
	
	is_initialized = true
	print("[MusicManager] Music system initialized!")

func _initialize_music():
	"""Start music based on current time of day"""
	
	var time = day_night_cycle.time_of_day
	
	# Determine if it's day or night
	if _is_daytime(time):
		current_period = "day"
		_play_next_track(DAY_TRACKS)
		print("[MusicManager] Started with day music (time: %.2f)" % time)
	else:
		current_period = "night"
		_play_next_track(NIGHT_TRACKS)
		print("[MusicManager] Started with night music (time: %.2f)" % time)

# ============================================================================
# UPDATE LOOP
# ============================================================================

func _process(_delta):
	if not is_initialized or not day_night_cycle:
		return
	
	var time = day_night_cycle.time_of_day
	
	# Check for dawn transition (night → day)
	if current_period == "night" and _is_dawn_transition(time) and not is_transitioning:
		_start_transition("day")
	
	# Check for dusk transition (day → night)
	elif current_period == "day" and _is_dusk_transition(time) and not is_transitioning:
		_start_transition("night")

# ============================================================================
# TRANSITION LOGIC
# ============================================================================

func _start_transition(new_period: String):
	"""Begin crossfade transition to new period"""
	
	if is_transitioning:
		return
	
	is_transitioning = true
	pending_period = new_period
	transition_start_time = Time.get_ticks_msec() / 1000.0
	
	print("[MusicManager] Starting transition: %s → %s" % [current_period, new_period])
	
	# Get next track for new period
	var new_tracks = DAY_TRACKS if new_period == "day" else NIGHT_TRACKS
	var next_track = _get_next_track(new_tracks)
	
	# Start crossfade
	AudioManager.play_music(next_track, CROSSFADE_DURATION)
	
	# Wait for crossfade to complete, then finalize transition
	await get_tree().create_timer(CROSSFADE_DURATION).timeout
	
	_finalize_transition(new_period)

func _finalize_transition(new_period: String):
	"""Complete transition to new period"""
	
	current_period = new_period
	is_transitioning = false
	pending_period = ""
	
	print("[MusicManager] Transition complete - now in %s period" % new_period)

# ============================================================================
# TRACK SELECTION
# ============================================================================

func _play_next_track(track_list: Array[String]):
	"""Play next track from list with smart rotation"""
	
	var track_name = _get_next_track(track_list)
	AudioManager.play_music(track_name, 0.0)  # No fade for initial track
	
	print("[MusicManager] Playing: %s" % track_name)

func _get_next_track(track_list: Array[String]) -> String:
	"""Get next track, avoiding recent repeats"""
	
	# If we haven't played enough tracks yet, just pick randomly
	if last_played_indices.size() < 2:
		current_track_index = randi() % track_list.size()
		last_played_indices.append(current_track_index)
		return track_list[current_track_index]
	
	# Get available indices (not recently played)
	var available_indices: Array[int] = []
	for i in range(track_list.size()):
		if not last_played_indices.has(i):
			available_indices.append(i)
	
	# If all tracks recently played, clear history except last one
	if available_indices.is_empty():
		var last_index = last_played_indices[-1]
		last_played_indices.clear()
		last_played_indices.append(last_index)
		
		# Rebuild available list
		for i in range(track_list.size()):
			if i != last_index:
				available_indices.append(i)
	
	# Pick random from available
	current_track_index = available_indices[randi() % available_indices.size()]
	
	# Update history (keep last 2)
	last_played_indices.append(current_track_index)
	if last_played_indices.size() > 2:
		last_played_indices.pop_front()
	
	return track_list[current_track_index]

# ============================================================================
# TIME CHECKING
# ============================================================================

func _is_daytime(time: float) -> bool:
	"""Check if given time is during daytime"""
	# Day = 6 AM to 6 PM (0.25 to 0.75)
	return time >= 0.25 and time < 0.75

func _is_dawn_transition(time: float) -> bool:
	"""Check if we're in dawn transition window"""
	return time >= DAWN_START and time < DAWN_END

func _is_dusk_transition(time: float) -> bool:
	"""Check if we're in dusk transition window"""
	return time >= DUSK_START and time < DUSK_END

# ============================================================================
# PUBLIC API
# ============================================================================

func force_track_change():
	"""Manually trigger next track in current period (for testing)"""
	
	if not is_initialized:
		push_warning("[MusicManager] System not initialized")
		return
	
	var tracks = DAY_TRACKS if current_period == "day" else NIGHT_TRACKS
	_play_next_track(tracks)
	
	print("[MusicManager] Forced track change")

func set_period(period: String):
	"""Manually set music period (for testing)"""
	
	if period != "day" and period != "night":
		push_warning("[MusicManager] Invalid period: %s" % period)
		return
	
	if period == current_period:
		return
	
	_start_transition(period)

func get_current_track() -> String:
	"""Get name of currently playing track"""
	return AudioManager.current_music_track

func is_day_music() -> bool:
	"""Check if day music is currently playing"""
	return current_period == "day"

func is_night_music() -> bool:
	"""Check if night music is currently playing"""
	return current_period == "night"

# ============================================================================
# DEBUG
# ============================================================================

func print_status():
	"""Print current music system status"""
	
	print("\n[MusicManager] Status:")
	print("  Initialized: %s" % is_initialized)
	print("  Current Period: %s" % current_period)
	print("  Current Track: %s" % get_current_track())
	print("  Track Index: %d" % current_track_index)
	print("  Transitioning: %s" % is_transitioning)
	
	if day_night_cycle:
		print("  Time of Day: %.3f (%.1f hours)" % [
			day_night_cycle.time_of_day,
			day_night_cycle.time_of_day * 24.0
		])
	
	print("  Recent Tracks: %s" % str(last_played_indices))
	print("")
