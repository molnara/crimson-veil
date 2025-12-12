extends Node

# AudioManager - Centralized audio management system
# Handles all game sounds with pooling, volume control, and variation

# ============================================================================
# VOLUME SETTINGS
# ============================================================================

# Volume levels (0.0 - 1.0)
var master_volume: float = 1.0
var sfx_volume: float = 0.75      # 75% - Punchy actions (harvesting, building)
var music_volume: float = 0.35    # 35% - Background atmosphere
var ambient_volume: float = 0.25  # 25% - Subtle environmental sounds
var ui_volume: float = 0.60       # 60% - Clear UI feedback

# Volume defaults (for reset functionality)
const MASTER_VOLUME_DEFAULT: float = 1.0
const SFX_VOLUME_DEFAULT: float = 0.75
const MUSIC_VOLUME_DEFAULT: float = 0.35
const AMBIENT_VOLUME_DEFAULT: float = 0.25
const UI_VOLUME_DEFAULT: float = 0.60

# ============================================================================
# SOUND POOLING
# ============================================================================

# Sound pool configuration
const MAX_CONCURRENT_SOUNDS: int = 10

# Active sound tracking
var sound_pool: Array[AudioStreamPlayer] = []
var active_sounds: Array[AudioStreamPlayer] = []

# ============================================================================
# MUSIC & AMBIENT SYSTEMS
# ============================================================================

# Dedicated music player (separate from SFX pool)
var music_player: AudioStreamPlayer = null
var current_music_track: String = ""

# Ambient loop players (multiple can play simultaneously)
var ambient_players: Dictionary = {}  # loop_name -> AudioStreamPlayer

# Music crossfade
var music_fade_tween: Tween = null

# ============================================================================
# SOUND LIBRARY
# ============================================================================

# Preloaded sound references (populated in _ready)
var sounds: Dictionary = {}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("[AudioManager] Initializing audio system...")
	
	# Create sound pool
	_create_sound_pool()
	
	# Create dedicated music player
	_create_music_player()
	
	# Load sound library (will be populated when files are imported)
	_load_sound_library()
	
	print("[AudioManager] Audio system ready!")
	print("  - Sound pool: %d players" % MAX_CONCURRENT_SOUNDS)
	print("  - Volume levels: Master=%.2f, SFX=%.2f, Music=%.2f, Ambient=%.2f, UI=%.2f" % [
		master_volume, sfx_volume, music_volume, ambient_volume, ui_volume
	])

# ============================================================================
# POOL CREATION
# ============================================================================

func _create_sound_pool():
	"""Create pool of reusable AudioStreamPlayer nodes"""
	for i in range(MAX_CONCURRENT_SOUNDS):
		var player = AudioStreamPlayer.new()
		player.name = "PooledPlayer_%d" % i
		player.bus = "Master"
		
		# Connect finished signal to return player to pool
		player.finished.connect(_on_sound_finished.bind(player))
		
		add_child(player)
		sound_pool.append(player)
	
	print("[AudioManager] Created sound pool with %d players" % MAX_CONCURRENT_SOUNDS)

func _create_music_player():
	"""Create dedicated music player (not part of pool)"""
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	add_child(music_player)
	
	print("[AudioManager] Created dedicated music player")

# ============================================================================
# SOUND LIBRARY LOADING
# ============================================================================

func _load_sound_library():
	"""Load all sound effects from res://audio/ directory"""
	# NOTE: This will be populated in Task 1.2 when audio files are imported
	# For now, we set up the structure
	
	# Structure will be:
	# sounds["axe_chop"] = preload("res://audio/sfx/harvesting/axe_chop.wav")
	# sounds["footstep_grass_1"] = preload("res://audio/sfx/movement/footstep_grass_1.wav")
	# etc.
	
	print("[AudioManager] Sound library structure ready (files will be loaded in Task 1.2)")

# ============================================================================
# PRIMARY PLAYBACK API
# ============================================================================

func play_sound(sound_name: String, category: String = "sfx", pitch_vary: bool = true, 
                volume_vary: bool = false) -> void:
	"""
	Play a sound effect with automatic pooling and variation
	
	Args:
		sound_name: Name of sound in library (e.g., "axe_chop")
		category: Volume category ("sfx", "ui", "ambient")
		pitch_vary: Apply random pitch variation (0.9-1.1x)
		volume_vary: Apply random volume variation (0.9-1.0x)
	"""
	
	# Check if sound exists in library
	if not sounds.has(sound_name):
		push_warning("[AudioManager] Sound not found: %s" % sound_name)
		return
	
	# Get available player from pool
	var player = _get_available_player()
	if player == null:
		# Pool exhausted - oldest sound will be cut off
		print("[AudioManager] Sound pool full, skipping: %s" % sound_name)
		return
	
	# Configure player
	player.stream = sounds[sound_name]
	
	# Apply volume (Master × Category × Variation)
	var final_volume = master_volume * _get_category_volume(category)
	if volume_vary:
		final_volume *= randf_range(0.9, 1.0)
	player.volume_db = linear_to_db(final_volume)
	
	# Apply pitch variation
	if pitch_vary:
		player.pitch_scale = randf_range(0.9, 1.1)
	else:
		player.pitch_scale = 1.0
	
	# Play sound
	player.play()
	
	# Track as active
	active_sounds.append(player)

func play_sound_variant(base_name: String, variant_count: int, category: String = "sfx",
                        pitch_vary: bool = true, volume_vary: bool = false) -> void:
	"""
	Play a random variant from a set of numbered sounds
	
	Example: play_sound_variant("footstep_grass", 3) 
	         -> plays footstep_grass_1, footstep_grass_2, or footstep_grass_3
	
	Args:
		base_name: Base sound name (e.g., "footstep_grass")
		variant_count: Number of variants (e.g., 3 for _1, _2, _3)
		category: Volume category
		pitch_vary: Apply pitch variation
		volume_vary: Apply volume variation
	"""
	var variant_num = randi_range(1, variant_count)
	var sound_name = "%s_%d" % [base_name, variant_num]
	play_sound(sound_name, category, pitch_vary, volume_vary)

# ============================================================================
# MUSIC CONTROL
# ============================================================================

func play_music(track_name: String, fade_duration: float = 2.0) -> void:
	"""
	Play music track with optional crossfade
	
	Args:
		track_name: Name of music track in library (e.g., "ambient_day")
		fade_duration: Fade transition time in seconds
	"""
	
	# Check if track exists
	if not sounds.has(track_name):
		push_warning("[AudioManager] Music track not found: %s" % track_name)
		return
	
	# If same track is already playing, do nothing
	if current_music_track == track_name and music_player.playing:
		return
	
	# Stop any existing fade tween
	if music_fade_tween:
		music_fade_tween.kill()
	
	# If music is currently playing, crossfade
	if music_player.playing and fade_duration > 0:
		_crossfade_music(track_name, fade_duration)
	else:
		# Direct switch (no fade)
		music_player.stream = sounds[track_name]
		music_player.volume_db = linear_to_db(master_volume * music_volume)
		music_player.play()
		current_music_track = track_name
		
		print("[AudioManager] Playing music: %s" % track_name)

func stop_music(fade_duration: float = 2.0) -> void:
	"""
	Stop currently playing music with optional fade out
	
	Args:
		fade_duration: Fade out time in seconds
	"""
	
	if not music_player.playing:
		return
	
	if fade_duration > 0:
		# Fade out
		if music_fade_tween:
			music_fade_tween.kill()
		
		music_fade_tween = create_tween()
		music_fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
		music_fade_tween.tween_callback(music_player.stop)
		music_fade_tween.tween_callback(func(): current_music_track = "")
	else:
		# Immediate stop
		music_player.stop()
		current_music_track = ""
	
	print("[AudioManager] Stopping music")

func _crossfade_music(new_track: String, fade_duration: float):
	"""Internal: Crossfade from current track to new track"""
	
	# Fade out current track
	music_fade_tween = create_tween()
	music_fade_tween.tween_property(music_player, "volume_db", -80.0, fade_duration)
	
	# Wait for fade out, then switch tracks and fade in
	music_fade_tween.tween_callback(func():
		music_player.stream = sounds[new_track]
		music_player.volume_db = -80.0
		music_player.play()
		current_music_track = new_track
	)
	
	# Fade in new track
	var target_volume = linear_to_db(master_volume * music_volume)
	music_fade_tween.tween_property(music_player, "volume_db", target_volume, fade_duration)
	
	print("[AudioManager] Crossfading to: %s" % new_track)

# ============================================================================
# AMBIENT LOOP CONTROL
# ============================================================================

func play_ambient_loop(loop_name: String, volume_override: float = -1.0) -> void:
	"""
	Play an ambient sound loop (can have multiple playing simultaneously)
	
	Args:
		loop_name: Name of ambient loop in library (e.g., "wind_light")
		volume_override: Optional volume override (0.0-1.0), uses ambient_volume if -1
	"""
	
	# Check if loop exists
	if not sounds.has(loop_name):
		push_warning("[AudioManager] Ambient loop not found: %s" % loop_name)
		return
	
	# Check if already playing
	if ambient_players.has(loop_name):
		print("[AudioManager] Ambient loop already playing: %s" % loop_name)
		return
	
	# Create new player for this loop
	var player = AudioStreamPlayer.new()
	player.name = "AmbientLoop_%s" % loop_name
	player.stream = sounds[loop_name]
	player.bus = "Master"
	
	# Set volume
	var vol = master_volume * ambient_volume if volume_override < 0 else master_volume * volume_override
	player.volume_db = linear_to_db(vol)
	
	# Enable looping (sound file should already be loopable)
	# Note: Godot detects loop points from file metadata
	
	add_child(player)
	player.play()
	
	ambient_players[loop_name] = player
	
	print("[AudioManager] Started ambient loop: %s" % loop_name)

func stop_ambient_loop(loop_name: String, fade_duration: float = 1.0) -> void:
	"""
	Stop an ambient sound loop with optional fade out
	
	Args:
		loop_name: Name of loop to stop
		fade_duration: Fade out time in seconds
	"""
	
	if not ambient_players.has(loop_name):
		return
	
	var player = ambient_players[loop_name]
	
	if fade_duration > 0:
		# Fade out
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(player.queue_free)
		tween.tween_callback(func(): ambient_players.erase(loop_name))
	else:
		# Immediate stop
		player.queue_free()
		ambient_players.erase(loop_name)
	
	print("[AudioManager] Stopped ambient loop: %s" % loop_name)

# ============================================================================
# VOLUME CONTROL
# ============================================================================

func set_master_volume(volume: float) -> void:
	"""Set master volume (affects all audio)"""
	master_volume = clamp(volume, 0.0, 1.0)
	_update_all_volumes()
	print("[AudioManager] Master volume: %.2f" % master_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX category volume"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	print("[AudioManager] SFX volume: %.2f" % sfx_volume)

func set_music_volume(volume: float) -> void:
	"""Set music category volume"""
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player and music_player.playing:
		music_player.volume_db = linear_to_db(master_volume * music_volume)
	print("[AudioManager] Music volume: %.2f" % music_volume)

func set_ambient_volume(volume: float) -> void:
	"""Set ambient category volume"""
	ambient_volume = clamp(volume, 0.0, 1.0)
	# Update all active ambient loops
	for player in ambient_players.values():
		player.volume_db = linear_to_db(master_volume * ambient_volume)
	print("[AudioManager] Ambient volume: %.2f" % ambient_volume)

func set_ui_volume(volume: float) -> void:
	"""Set UI category volume"""
	ui_volume = clamp(volume, 0.0, 1.0)
	print("[AudioManager] UI volume: %.2f" % ui_volume)

func set_category_volume(category: String, volume: float) -> void:
	"""Generic category volume setter (used by settings menu)"""
	match category.to_lower():
		"master":
			set_master_volume(volume)
		"sfx":
			set_sfx_volume(volume)
		"music":
			set_music_volume(volume)
		"ambient":
			set_ambient_volume(volume)
		"ui":
			set_ui_volume(volume)
		_:
			push_warning("[AudioManager] Unknown category: %s" % category)

func _update_all_volumes() -> void:
	"""Update all active audio when master volume changes"""
	# Update music
	if music_player and music_player.playing:
		music_player.volume_db = linear_to_db(master_volume * music_volume)
	
	# Update ambient loops
	for player in ambient_players.values():
		player.volume_db = linear_to_db(master_volume * ambient_volume)

func _get_category_volume(category: String) -> float:
	"""Get volume multiplier for category"""
	match category.to_lower():
		"sfx":
			return sfx_volume
		"music":
			return music_volume
		"ambient":
			return ambient_volume
		"ui":
			return ui_volume
		_:
			push_warning("[AudioManager] Unknown category: %s, using sfx" % category)
			return sfx_volume

# ============================================================================
# SOUND POOL MANAGEMENT
# ============================================================================

func _get_available_player() -> AudioStreamPlayer:
	"""Get an available player from the pool"""
	
	# Try to find an inactive player
	for player in sound_pool:
		if not player.playing:
			return player
	
	# Pool exhausted - all players are active
	# Cut off oldest sound (first in active_sounds array)
	if active_sounds.size() > 0:
		var oldest = active_sounds[0]
		oldest.stop()
		active_sounds.erase(oldest)
		return oldest
	
	# Should never reach here, but just in case
	return null

func _on_sound_finished(player: AudioStreamPlayer) -> void:
	"""Called when a pooled sound finishes playing"""
	# Remove from active sounds
	active_sounds.erase(player)
	
	# Player automatically returns to pool (it's still in sound_pool array)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func is_sound_playing(sound_name: String) -> bool:
	"""Check if a specific sound is currently playing"""
	for player in active_sounds:
		if player.stream == sounds.get(sound_name):
			return true
	return false

func get_active_sound_count() -> int:
	"""Get number of currently playing sounds"""
	return active_sounds.size()

func stop_all_sounds() -> void:
	"""Emergency stop all sounds (SFX, music, ambient)"""
	# Stop all pooled sounds
	for player in active_sounds:
		player.stop()
	active_sounds.clear()
	
	# Stop music
	if music_player:
		music_player.stop()
		current_music_track = ""
	
	# Stop all ambient loops
	for player in ambient_players.values():
		player.stop()
		player.queue_free()
	ambient_players.clear()
	
	print("[AudioManager] All audio stopped")

# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

func print_status() -> void:
	"""Print current audio system status (for debugging)"""
	print("\n[AudioManager Status]")
	print("  Active sounds: %d / %d" % [active_sounds.size(), MAX_CONCURRENT_SOUNDS])
	print("  Current music: %s" % current_music_track)
	print("  Ambient loops: %d" % ambient_players.size())
	print("  Volumes: Master=%.2f, SFX=%.2f, Music=%.2f, Ambient=%.2f, UI=%.2f" % [
		master_volume, sfx_volume, music_volume, ambient_volume, ui_volume
	])
	print("")
