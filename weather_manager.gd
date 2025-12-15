extends Node

# WeatherManager - Dynamic weather system with biome-specific weather patterns
# Handles weather state transitions, fog control, and weather particle effects

# ============================================================================
# SIGNALS
# ============================================================================

signal weather_changed(old_weather: int, new_weather: int)
signal weather_transition_started(from_weather: int, to_weather: int)
signal weather_transition_completed(weather: int)
signal intensity_changed(new_intensity: float)

# ============================================================================
# ENUMS
# ============================================================================

enum Weather {
	CLEAR,
	CLOUDY,
	RAIN,
	STORM,
	FOG,
	SNOW,
	BLIZZARD,
	SANDSTORM
}

# ============================================================================
# CONFIGURATION - Export Variables
# ============================================================================

@export_group("Weather Timing")
@export var weather_change_interval_min: float = 300.0  ## Minimum seconds between weather changes (5 min)
@export var weather_change_interval_max: float = 900.0  ## Maximum seconds between weather changes (15 min)
@export var transition_duration: float = 30.0  ## Seconds to transition between weather states

@export_group("Particle Counts")
@export var rain_particle_count: int = 2000  ## Number of rain particles
@export var snow_particle_count: int = 1000  ## Number of snow particles
@export var sandstorm_particle_count: int = 1500  ## Number of sand particles

@export_group("Fog Settings")
@export var fog_density_clear: float = 0.0  ## Fog density for clear weather
@export var fog_density_cloudy: float = 0.005  ## Fog density for cloudy weather
@export var fog_density_rain: float = 0.01  ## Fog density during rain
@export var fog_density_storm: float = 0.02  ## Fog density during storms
@export var fog_density_fog: float = 0.05  ## Fog density for foggy weather
@export var fog_density_snow: float = 0.015  ## Fog density during snow
@export var fog_density_blizzard: float = 0.04  ## Fog density during blizzards
@export var fog_density_sandstorm: float = 0.035  ## Fog density during sandstorms

@export_group("Weather Intensity")
@export var intensity_min: float = 0.3  ## Minimum weather intensity
@export var intensity_max: float = 1.0  ## Maximum weather intensity
@export var intensity_change_speed: float = 0.1  ## How fast intensity changes per second

@export_group("Debug")
@export var debug_logging: bool = false  ## Enable verbose logging

# ============================================================================
# BIOME WEATHER PROBABILITIES
# ============================================================================

# Weather probability per biome (must sum to 1.0 per biome)
const BIOME_WEATHER: Dictionary = {
	"GRASSLAND": {
		Weather.CLEAR: 0.45,
		Weather.CLOUDY: 0.25,
		Weather.RAIN: 0.15,
		Weather.STORM: 0.05,
		Weather.FOG: 0.10
	},
	"FOREST": {
		Weather.CLEAR: 0.25,
		Weather.CLOUDY: 0.25,
		Weather.RAIN: 0.25,
		Weather.FOG: 0.15,
		Weather.STORM: 0.10
	},
	"DESERT": {
		Weather.CLEAR: 0.70,
		Weather.CLOUDY: 0.15,
		Weather.SANDSTORM: 0.15
	},
	"SNOW": {
		Weather.CLEAR: 0.15,
		Weather.CLOUDY: 0.25,
		Weather.SNOW: 0.40,
		Weather.BLIZZARD: 0.10,
		Weather.FOG: 0.10
	},
	"BEACH": {
		Weather.CLEAR: 0.55,
		Weather.CLOUDY: 0.20,
		Weather.RAIN: 0.15,
		Weather.STORM: 0.10
	},
	"MOUNTAIN": {
		Weather.CLEAR: 0.25,
		Weather.CLOUDY: 0.25,
		Weather.FOG: 0.20,
		Weather.STORM: 0.15,
		Weather.SNOW: 0.10,
		Weather.BLIZZARD: 0.05
	},
	"OCEAN": {
		Weather.CLEAR: 0.40,
		Weather.CLOUDY: 0.25,
		Weather.RAIN: 0.20,
		Weather.STORM: 0.10,
		Weather.FOG: 0.05
	}
}

# Fog colors per biome
const BIOME_FOG_COLORS: Dictionary = {
	"GRASSLAND": Color(0.7, 0.8, 0.9),      # Light blue
	"FOREST": Color(0.4, 0.55, 0.45),       # Dark green
	"DESERT": Color(0.85, 0.75, 0.55),      # Sandy tan
	"SNOW": Color(0.9, 0.92, 0.95),         # White
	"BEACH": Color(0.75, 0.88, 0.92),       # Light cyan
	"MOUNTAIN": Color(0.6, 0.58, 0.7),      # Gray/purple
	"OCEAN": Color(0.5, 0.65, 0.8)          # Ocean blue
}

# Weather-specific fog color tints
const WEATHER_FOG_TINTS: Dictionary = {
	Weather.CLEAR: Color(1.0, 1.0, 1.0),
	Weather.CLOUDY: Color(0.85, 0.85, 0.9),
	Weather.RAIN: Color(0.7, 0.75, 0.85),
	Weather.STORM: Color(0.5, 0.55, 0.65),
	Weather.FOG: Color(0.9, 0.9, 0.92),
	Weather.SNOW: Color(0.95, 0.95, 1.0),
	Weather.BLIZZARD: Color(0.85, 0.88, 0.95),
	Weather.SANDSTORM: Color(0.9, 0.75, 0.5)
}

# ============================================================================
# STATE
# ============================================================================

# Current weather state
var current_weather: Weather = Weather.CLEAR
var target_weather: Weather = Weather.CLEAR
var weather_intensity: float = 0.5  # 0.0 to 1.0

# Transition state
var is_transitioning: bool = false
var transition_progress: float = 0.0  # 0.0 to 1.0

# Timing
var weather_timer: float = 0.0
var next_weather_change: float = 0.0

# References
var player: Node3D = null
var day_night_cycle: Node = null
var chunk_manager: Node = null
var world_environment: WorldEnvironment = null

# Particle systems
var rain_particles: GPUParticles3D = null
var snow_particles: GPUParticles3D = null
var sandstorm_particles: GPUParticles3D = null

# Current biome tracking
var current_biome: String = "GRASSLAND"

# Initialization flag
var is_initialized: bool = false

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("[WeatherManager] Initializing weather system...")
	
	# Delay initialization to ensure other systems are ready
	await get_tree().create_timer(1.0).timeout
	
	_find_references()
	# Particles are created by Player and registered via set_rain_particles/set_snow_particles
	_initialize_weather()
	
	is_initialized = true
	print("[WeatherManager] Weather system initialized - Starting weather: %s" % get_weather_name(current_weather))


func _find_references():
	"""Find references to other game systems"""
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("[WeatherManager] Player not found - will retry on update")
	
	# Find day/night cycle
	day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")
	if day_night_cycle:
		world_environment = day_night_cycle.get_node_or_null("WorldEnvironment")
		if debug_logging:
			print("[WeatherManager] Found DayNightCycle and WorldEnvironment")
	else:
		push_warning("[WeatherManager] DayNightCycle not found - fog control disabled")
	
	# Find chunk manager
	var world = get_tree().get_first_node_in_group("world")
	if world:
		chunk_manager = world.get_node_or_null("ChunkManager")
	
	if not chunk_manager:
		# Try alternative method
		for node in get_tree().get_nodes_in_group("chunk_manager"):
			chunk_manager = node
			break
	
	if chunk_manager and debug_logging:
		print("[WeatherManager] Found ChunkManager")


func _initialize_weather():
	"""Set up initial weather state"""
	
	# Get initial biome
	current_biome = _get_player_biome()
	
	# Start with clear weather
	current_weather = Weather.CLEAR
	target_weather = Weather.CLEAR
	weather_intensity = 0.5
	
	# Set initial time until weather change
	next_weather_change = randf_range(weather_change_interval_min, weather_change_interval_max)
	
	# Apply initial fog settings
	_apply_fog_settings(current_weather, current_biome, 1.0)

# ============================================================================
# UPDATE LOOP
# ============================================================================

func _process(delta: float):
	if not is_initialized:
		return
	
	# Retry finding player if not found
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
	
	# Update biome
	var new_biome = _get_player_biome()
	if new_biome != current_biome:
		_on_biome_changed(new_biome)
	
	# Update weather timer
	weather_timer += delta
	
	# Check for weather change
	if weather_timer >= next_weather_change and not is_transitioning:
		_trigger_weather_change()
	
	# Update transition
	if is_transitioning:
		_update_transition(delta)
	
	# Update weather intensity (subtle variation)
	_update_intensity(delta)
	
	# Update particle positions to follow player
	_update_particle_positions()


func _on_biome_changed(new_biome: String):
	"""Handle player entering a new biome"""
	
	var old_biome = current_biome
	current_biome = new_biome
	
	if debug_logging:
		print("[WeatherManager] Biome changed: %s → %s" % [old_biome, new_biome])
	
	# Check if current weather is valid for new biome
	if not _is_weather_valid_for_biome(current_weather, new_biome):
		# Force weather change to something valid
		if debug_logging:
			print("[WeatherManager] Current weather %s invalid for %s - forcing change" % [get_weather_name(current_weather), new_biome])
		_trigger_weather_change()
	else:
		# Just update fog colors for new biome
		_apply_fog_settings(current_weather, new_biome, 1.0)


func _trigger_weather_change():
	"""Start transition to new weather"""
	
	# Select new weather based on biome
	var new_weather = _select_weather_for_biome(current_biome)
	
	# Don't transition to same weather
	if new_weather == current_weather:
		# Reset timer and try again later
		weather_timer = 0.0
		next_weather_change = randf_range(weather_change_interval_min * 0.5, weather_change_interval_max * 0.5)
		return
	
	# Start transition
	target_weather = new_weather
	is_transitioning = true
	transition_progress = 0.0
	
	weather_transition_started.emit(current_weather, target_weather)
	
	if debug_logging:
		print("[WeatherManager] Weather transition: %s → %s" % [get_weather_name(current_weather), get_weather_name(target_weather)])


func _update_transition(delta: float):
	"""Update weather transition progress"""
	
	transition_progress += delta / transition_duration
	
	if transition_progress >= 1.0:
		# Transition complete
		transition_progress = 1.0
		is_transitioning = false
		
		var old_weather = current_weather
		current_weather = target_weather
		
		# Reset timer
		weather_timer = 0.0
		next_weather_change = randf_range(weather_change_interval_min, weather_change_interval_max)
		
		# Update particle systems
		_update_particle_systems()
		
		# Apply final fog settings
		_apply_fog_settings(current_weather, current_biome, 1.0)
		
		# Emit signals
		weather_changed.emit(old_weather, current_weather)
		weather_transition_completed.emit(current_weather)
		
		if debug_logging:
			print("[WeatherManager] Weather transition complete: %s" % get_weather_name(current_weather))
	else:
		# Interpolate fog during transition
		_apply_fog_settings(current_weather, current_biome, 1.0 - transition_progress)
		_apply_fog_settings(target_weather, current_biome, transition_progress)


func _update_intensity(delta: float):
	"""Subtle variation in weather intensity"""
	
	# Random walk for intensity
	var intensity_change = (randf() - 0.5) * 2.0 * intensity_change_speed * delta
	weather_intensity = clamp(weather_intensity + intensity_change, intensity_min, intensity_max)
	
	# Update particle emission rates based on intensity
	_update_particle_intensity()


func _update_particle_positions():
	"""Position updates now handled by WeatherParticles scene"""
	# WeatherParticles.gd follows player in its own _process
	# We don't need to move particles here
	pass

# ============================================================================
# WEATHER SELECTION
# ============================================================================

func _select_weather_for_biome(biome: String) -> Weather:
	"""Select random weather based on biome probabilities"""
	
	if not BIOME_WEATHER.has(biome):
		return Weather.CLEAR
	
	var weather_table = BIOME_WEATHER[biome]
	var roll = randf()
	var cumulative = 0.0
	
	for weather_type in weather_table.keys():
		cumulative += weather_table[weather_type]
		if roll <= cumulative:
			return weather_type
	
	return Weather.CLEAR


func _is_weather_valid_for_biome(weather: Weather, biome: String) -> bool:
	"""Check if weather type is valid for biome"""
	
	if not BIOME_WEATHER.has(biome):
		return weather == Weather.CLEAR
	
	return BIOME_WEATHER[biome].has(weather)

# ============================================================================
# FOG CONTROL
# ============================================================================

func _apply_fog_settings(weather: Weather, biome: String, blend_weight: float):
	"""Apply fog settings for weather and biome"""
	
	if not world_environment or not world_environment.environment:
		return
	
	var env = world_environment.environment
	
	# Get target fog density
	var target_density = _get_fog_density_for_weather(weather)
	
	# Get fog color (biome base + weather tint)
	var biome_fog_color = BIOME_FOG_COLORS.get(biome, Color(0.7, 0.8, 0.9))
	var weather_tint = WEATHER_FOG_TINTS.get(weather, Color(1.0, 1.0, 1.0))
	var target_color = biome_fog_color * weather_tint
	
	# Apply with blend weight for smooth transitions
	if blend_weight >= 1.0:
		env.fog_density = target_density
		env.fog_light_color = target_color
	else:
		env.fog_density = lerp(env.fog_density, target_density, blend_weight)
		env.fog_light_color = env.fog_light_color.lerp(target_color, blend_weight)


func _get_fog_density_for_weather(weather: Weather) -> float:
	"""Get fog density for weather type"""
	
	match weather:
		Weather.CLEAR:
			return fog_density_clear
		Weather.CLOUDY:
			return fog_density_cloudy
		Weather.RAIN:
			return fog_density_rain
		Weather.STORM:
			return fog_density_storm
		Weather.FOG:
			return fog_density_fog
		Weather.SNOW:
			return fog_density_snow
		Weather.BLIZZARD:
			return fog_density_blizzard
		Weather.SANDSTORM:
			return fog_density_sandstorm
	
	return fog_density_clear

# ============================================================================
# PARTICLE SYSTEMS
# ============================================================================
# NOTE: Rain and snow particles are created in player.gd and registered
# with WeatherManager via set_rain_particles() and set_snow_particles().
# This is necessary because particles must be children of a scene node
# (not an autoload) to render and animate properly.

var storm_particles: GPUParticles3D = null
var blizzard_particles: GPUParticles3D = null

func _update_particle_systems():
	"""Enable/disable particle systems based on current weather"""
	
	# Only toggle visibility - don't touch emitting or any other properties!
	# Particles are always emitting, we just show/hide them
	
	var show_rain = current_weather == Weather.RAIN
	var show_storm = current_weather == Weather.STORM
	var show_snow = current_weather == Weather.SNOW
	var show_blizzard = current_weather == Weather.BLIZZARD
	var show_sand = current_weather == Weather.SANDSTORM
	
	if rain_particles:
		rain_particles.visible = show_rain
		if show_rain:
			print("[WeatherManager] Rain ON")
	
	if storm_particles:
		storm_particles.visible = show_storm
		if show_storm:
			print("[WeatherManager] Storm ON")
	
	if snow_particles:
		snow_particles.visible = show_snow
		if show_snow:
			print("[WeatherManager] Snow ON")
	
	if blizzard_particles:
		blizzard_particles.visible = show_blizzard
		if show_blizzard:
			print("[WeatherManager] Blizzard ON")
	
	if sandstorm_particles:
		sandstorm_particles.visible = show_sand
		if show_sand:
			print("[WeatherManager] Sandstorm ON")


func _update_particle_intensity():
	"""Update particle emission rates based on weather intensity"""
	# DISABLED - changing amount may break GPU particle simulation
	# Particles use fixed amount set by weather_particles.gd
	pass


func set_rain_particles(particles: GPUParticles3D):
	"""Set rain particle system reference"""
	rain_particles = particles
	if debug_logging:
		print("[WeatherManager] Rain particles registered")

func set_storm_particles(particles: GPUParticles3D):
	"""Set storm particle system reference"""
	storm_particles = particles
	if debug_logging:
		print("[WeatherManager] Storm particles registered")

func set_snow_particles(particles: GPUParticles3D):
	"""Set snow particle system reference"""
	snow_particles = particles
	if debug_logging:
		print("[WeatherManager] Snow particles registered")

func set_blizzard_particles(particles: GPUParticles3D):
	"""Set blizzard particle system reference"""
	blizzard_particles = particles
	if debug_logging:
		print("[WeatherManager] Blizzard particles registered")


func set_sandstorm_particles(particles: GPUParticles3D):
	"""Set sandstorm particle system reference"""
	sandstorm_particles = particles
	if debug_logging:
		print("[WeatherManager] Sandstorm particles registered")

# ============================================================================
# BIOME DETECTION
# ============================================================================

func _get_player_biome() -> String:
	"""Get current biome at player position"""
	
	if not player:
		return "GRASSLAND"
	
	# Use chunk manager for accurate biome detection
	if chunk_manager:
		var player_pos = player.global_position
		var world_x = player_pos.x
		var world_z = player_pos.z
		
		# Get noise values
		var base_noise = chunk_manager.noise.get_noise_2d(world_x, world_z)
		var temperature = chunk_manager.temperature_noise.get_noise_2d(world_x, world_z)
		var moisture = chunk_manager.moisture_noise.get_noise_2d(world_x, world_z)
		
		# Check spawn zone
		var distance_from_origin = sqrt(world_x * world_x + world_z * world_z)
		if distance_from_origin < chunk_manager.spawn_zone_radius:
			return "GRASSLAND"
		
		# Determine biome using same logic as chunk.gd
		if base_noise < chunk_manager.beach_threshold:
			if base_noise < chunk_manager.ocean_threshold:
				return "OCEAN"
			else:
				return "BEACH"
		elif base_noise > chunk_manager.mountain_threshold:
			if temperature < chunk_manager.snow_temperature:
				return "SNOW"
			else:
				return "MOUNTAIN"
		else:
			if temperature > chunk_manager.desert_temperature and moisture < chunk_manager.desert_moisture:
				return "DESERT"
			elif moisture > chunk_manager.forest_moisture:
				return "FOREST"
			else:
				return "GRASSLAND"
	
	return "GRASSLAND"

# ============================================================================
# PUBLIC API
# ============================================================================

func get_current_weather() -> Weather:
	"""Get current weather state"""
	return current_weather


func get_weather_name(weather: Weather) -> String:
	"""Get human-readable weather name"""
	match weather:
		Weather.CLEAR: return "Clear"
		Weather.CLOUDY: return "Cloudy"
		Weather.RAIN: return "Rain"
		Weather.STORM: return "Storm"
		Weather.FOG: return "Fog"
		Weather.SNOW: return "Snow"
		Weather.BLIZZARD: return "Blizzard"
		Weather.SANDSTORM: return "Sandstorm"
	return "Unknown"


func get_weather_intensity() -> float:
	"""Get current weather intensity (0.0 to 1.0)"""
	return weather_intensity


func is_precipitation_active() -> bool:
	"""Check if any precipitation is active"""
	return current_weather in [Weather.RAIN, Weather.STORM, Weather.SNOW, Weather.BLIZZARD, Weather.SANDSTORM]


func is_severe_weather() -> bool:
	"""Check if severe weather is active"""
	return current_weather in [Weather.STORM, Weather.BLIZZARD, Weather.SANDSTORM]


func get_visibility_modifier() -> float:
	"""Get visibility modifier for current weather (1.0 = full visibility)"""
	match current_weather:
		Weather.CLEAR: return 1.0
		Weather.CLOUDY: return 0.95
		Weather.RAIN: return 0.7
		Weather.STORM: return 0.5
		Weather.FOG: return 0.4
		Weather.SNOW: return 0.6
		Weather.BLIZZARD: return 0.3
		Weather.SANDSTORM: return 0.35
	return 1.0


func force_weather(weather: Weather):
	"""Force immediate weather change (for testing/events)"""
	
	if not _is_weather_valid_for_biome(weather, current_biome):
		push_warning("[WeatherManager] Weather %s not valid for biome %s" % [get_weather_name(weather), current_biome])
		return
	
	var old_weather = current_weather
	current_weather = weather
	target_weather = weather
	is_transitioning = false
	transition_progress = 1.0
	
	_update_particle_systems()
	_apply_fog_settings(current_weather, current_biome, 1.0)
	
	weather_changed.emit(old_weather, current_weather)
	
	print("[WeatherManager] Forced weather: %s" % get_weather_name(weather))


func force_weather_transition(weather: Weather):
	"""Force weather transition (smooth change)"""
	
	if not _is_weather_valid_for_biome(weather, current_biome):
		push_warning("[WeatherManager] Weather %s not valid for biome %s" % [get_weather_name(weather), current_biome])
		return
	
	target_weather = weather
	is_transitioning = true
	transition_progress = 0.0
	
	weather_transition_started.emit(current_weather, target_weather)
	
	print("[WeatherManager] Starting forced transition to: %s" % get_weather_name(weather))

# ============================================================================
# DEBUG
# ============================================================================

func print_status():
	"""Print current weather system status"""
	
	print("\n[WeatherManager] Status:")
	print("  Initialized: %s" % is_initialized)
	print("  Current Biome: %s" % current_biome)
	print("  Current Weather: %s" % get_weather_name(current_weather))
	print("  Weather Intensity: %.2f" % weather_intensity)
	print("  Is Transitioning: %s" % is_transitioning)
	if is_transitioning:
		print("  Target Weather: %s" % get_weather_name(target_weather))
		print("  Transition Progress: %.1f%%" % (transition_progress * 100))
	print("  Time Until Change: %.1fs" % (next_weather_change - weather_timer))
	print("  Visibility Modifier: %.2f" % get_visibility_modifier())
	print("")


func get_debug_info() -> Dictionary:
	"""Get debug information as dictionary"""
	return {
		"weather": get_weather_name(current_weather),
		"biome": current_biome,
		"intensity": weather_intensity,
		"transitioning": is_transitioning,
		"target": get_weather_name(target_weather) if is_transitioning else "",
		"time_until_change": next_weather_change - weather_timer,
		"visibility": get_visibility_modifier()
	}
