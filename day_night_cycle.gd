extends Node3D
class_name DayNightCycle

# Time settings
@export var day_length_minutes: float = 10.0  # Real minutes for a full day/night cycle
@export var start_time: float = 0.25  # 0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset

# References
@onready var sun: DirectionalLight3D = $SunLight
@onready var moon: DirectionalLight3D = $MoonLight
@onready var world_environment: WorldEnvironment = $WorldEnvironment

# Internal variables
var time_of_day: float = 0.0  # 0.0 to 1.0 (0 = midnight, 0.5 = noon)
var time_scale: float = 1.0

# Sky colors for different times of day
var night_sky_color = Color(0.05, 0.05, 0.15)
var sunrise_sky_color = Color(1.0, 0.5, 0.3)
var day_sky_color = Color(0.5, 0.7, 1.0)
var sunset_sky_color = Color(1.0, 0.4, 0.2)

# Light colors
var night_light_color = Color(0.3, 0.3, 0.4)
var day_light_color = Color(1.0, 0.95, 0.9)
var sunrise_light_color = Color(1.0, 0.7, 0.5)
var sunset_light_color = Color(1.0, 0.6, 0.4)
var moon_light_color = Color(0.6, 0.7, 0.9)  # Soft blue moonlight

func _ready():
	time_of_day = start_time
	setup_environment()
	setup_moon()
	update_lighting()

func _process(delta):
	# Update time of day
	var day_length_seconds = day_length_minutes * 60.0
	time_of_day += (delta * time_scale) / day_length_seconds
	
	# Wrap around after a full day
	if time_of_day >= 1.0:
		time_of_day -= 1.0
	
	update_lighting()

func setup_environment():
	# Create environment if it doesn't exist
	if world_environment.environment == null:
		world_environment.environment = Environment.new()
	
	var env = world_environment.environment
	
	# Setup sky
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky.sky_material = sky_material
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	
	# Setup ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5

func setup_moon():
	# Configure moon light properties
	if moon:
		moon.light_color = moon_light_color
		moon.light_energy = 0.0  # Start invisible
		moon.shadow_enabled = true

func update_lighting():
	# Calculate sun rotation (sun moves in a circle)
	# 0.0 = midnight (sun below horizon), 0.5 = noon (sun overhead)
	var sun_angle = time_of_day * 360.0  # 0-360 degrees
	sun.rotation_degrees.x = sun_angle - 90.0  # Offset so noon is overhead
	
	# Moon is opposite the sun (180 degrees offset)
	if moon:
		moon.rotation_degrees.x = (sun_angle + 180.0) - 90.0
	
	# Get current sky material
	var env = world_environment.environment
	var sky_material = env.sky.sky_material as ProceduralSkyMaterial
	
	# Calculate lighting based on time of day
	if time_of_day < 0.25:  # Night to sunrise (midnight to 6am)
		var t = time_of_day / 0.25
		sun.light_energy = lerp(0.0, 0.5, t)
		sun.light_color = night_light_color.lerp(sunrise_light_color, t)
		sky_material.sky_top_color = night_sky_color.lerp(sunrise_sky_color, t)
		sky_material.sky_horizon_color = night_sky_color.lerp(sunrise_sky_color, t)
		
		# Moon is bright at night, fades at sunrise
		if moon:
			moon.light_energy = lerp(0.3, 0.0, t)
		
	elif time_of_day < 0.5:  # Sunrise to noon (6am to 12pm)
		var t = (time_of_day - 0.25) / 0.25
		sun.light_energy = lerp(0.5, 1.0, t)
		sun.light_color = sunrise_light_color.lerp(day_light_color, t)
		sky_material.sky_top_color = sunrise_sky_color.lerp(day_sky_color, t)
		sky_material.sky_horizon_color = sunrise_sky_color.lerp(day_sky_color, t)
		
		# Moon is off during day
		if moon:
			moon.light_energy = 0.0
		
	elif time_of_day < 0.75:  # Noon to sunset (12pm to 6pm)
		var t = (time_of_day - 0.5) / 0.25
		sun.light_energy = lerp(1.0, 0.5, t)
		sun.light_color = day_light_color.lerp(sunset_light_color, t)
		sky_material.sky_top_color = day_sky_color.lerp(sunset_sky_color, t)
		sky_material.sky_horizon_color = day_sky_color.lerp(sunset_sky_color, t)
		
		# Moon is off during day
		if moon:
			moon.light_energy = 0.0
		
	else:  # Sunset to night (6pm to midnight)
		var t = (time_of_day - 0.75) / 0.25
		sun.light_energy = lerp(0.5, 0.0, t)
		sun.light_color = sunset_light_color.lerp(night_light_color, t)
		sky_material.sky_top_color = sunset_sky_color.lerp(night_sky_color, t)
		sky_material.sky_horizon_color = sunset_sky_color.lerp(night_sky_color, t)
		
		# Moon rises at sunset
		if moon:
			moon.light_energy = lerp(0.0, 0.3, t)
	
	# Ground color (darker at night)
	sky_material.ground_bottom_color = Color(0.2, 0.15, 0.1) * (sun.light_energy + 0.2)
	sky_material.ground_horizon_color = sky_material.sky_horizon_color * 0.7

func get_time_of_day() -> float:
	return time_of_day

func set_time_of_day(new_time: float):
	time_of_day = clamp(new_time, 0.0, 1.0)
	update_lighting()

func get_time_string() -> String:
	var hour = int(time_of_day * 24.0)
	var minute = int((time_of_day * 24.0 - hour) * 60.0)
	return "%02d:%02d" % [hour, minute]

func is_day() -> bool:
	return time_of_day >= 0.25 and time_of_day < 0.75

func is_night() -> bool:
	return !is_day()
