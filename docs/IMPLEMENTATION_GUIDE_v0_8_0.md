# IMPLEMENTATION GUIDE v0.8.0 - "Living World"
## Technical Specifications & Code Patterns

---

## TABLE OF CONTENTS

0. [Phase 0 - Vegetation System Fix (Completed)](#0-phase-0---vegetation-system-fix-completed)
1. [Weather System Architecture](#1-weather-system-architecture)
2. [Biome Ground Cover System](#2-biome-ground-cover-system)
3. [Wind System](#3-wind-system)
4. [Particle Effects](#4-particle-effects)
5. [Integration Points](#5-integration-points)
6. [Performance Guidelines](#6-performance-guidelines)

---

## 0. PHASE 0 - VEGETATION SYSTEM FIX (COMPLETED)

### 0.1 Modular Vegetation Architecture

**File Structure:**
```
vegetation/
├── vegetation_spawner.gd      # Main spawner + harvestable creation
├── vegetation_types.gd        # VegType enum
├── biome_spawn_rules.gd       # Biome configurations
└── meshes/
    ├── forest_meshes.gd       # create_mushroom_visual()
    ├── plant_meshes.gd        # create_strawberry_visual()
    └── ...
```

### 0.2 Harvestable Resource Creation

**CRITICAL:** Harvestables require StaticBody3D with collision layer 2.

```gdscript
# vegetation_spawner.gd - Preloads
const HarvestableMushroomClass = preload("res://harvestable_mushroom.gd")
const HarvestableStrawberryClass = preload("res://harvestable_strawberry.gd")
const ResourceNodeClass = preload("res://resource_node.gd")

# Creation pattern
func create_harvestable_strawberry(mesh_instance, bush_size):
    # 1. Create harvestable node
    var strawberry = HarvestableStrawberryClass.new()
    strawberry.collision_layer = 2  # REQUIRED
    strawberry.collision_mask = 0
    
    # 2. Create visual (calls mesh file)
    var visual = MeshInstance3D.new()
    strawberry.add_child(visual)
    PlantMeshes.create_strawberry_visual(visual, size_string)
    
    # 3. Add collision shape
    var collision = CollisionShape3D.new()
    var shape = SphereShape3D.new()
    shape.radius = 0.5
    collision.shape = shape
    strawberry.add_child(collision)
    
    # 4. Replace in scene, register for cleanup
    parent.add_child(strawberry)
    populated_chunks[_current_chunk].append(strawberry)
```

### 0.3 Strawberry Visual Improvements

**Golden Angle Berry Distribution:**
```gdscript
var golden_angle = PI * (3.0 - sqrt(5.0))  # ~137.5°

for i in range(berry_count):
    var berry_angle = i * golden_angle + (randf() - 0.5) * 0.4
    
    # Stratified height (0.20 to 0.90 of bush)
    var height_t = float(i + 1) / float(berry_count + 1)
    var berry_height_t = 0.20 + height_t * 0.70
    
    # Match bush contour
    var radius_mult = sin(berry_height_t * PI)
    var base_radius = bush_radius * (0.5 + radius_mult * 0.5)
    var berry_dist = base_radius * (1.03 + randf() * 0.04)  # 3-7% out
```

**Icosphere Berry Geometry (20 triangles):**
```gdscript
static func _add_berry_icosphere(surface_tool, center, radius, color):
    var t = (1.0 + sqrt(5.0)) / 2.0  # Golden ratio
    # 12 vertices, 20 faces
    # ... (see plant_meshes.gd for full implementation)
```

### 0.4 Survival-Balanced Densities

```gdscript
# vegetation_spawner.gd
@export var rock_density: float = 0.08       # Rare
@export var mushroom_density: float = 0.04   # Rarest
@export var strawberry_density: float = 0.06 # Rare

@export var forest_mushroom_density: float = 0.10
@export var grassland_strawberry_density: float = 0.12
@export var mountain_rock_density: float = 0.15
```

---

## 1. WEATHER SYSTEM ARCHITECTURE

### 1.1 WeatherManager Singleton

**File:** `res://weather_manager.gd`
**Type:** Autoload Singleton

```gdscript
extends Node
class_name WeatherManager

## WeatherManager - Dynamic weather state machine
## 
## ARCHITECTURE:
## - Singleton managing global weather state
## - Biome-aware weather probabilities
## - Smooth transitions between weather states
## - Integrates with DayNightCycle for time-based changes
##
## DEPENDENCIES:
## - DayNightCycle (for time of day)
## - AmbientManager (for weather sounds)
## - Player (for position/biome detection)

# Weather states
enum Weather {
    CLEAR,
    CLOUDY,
    RAIN,
    HEAVY_RAIN,
    STORM,
    FOG,
    SNOW,
    BLIZZARD,
    SANDSTORM
}

# Signals
signal weather_changed(old_weather: Weather, new_weather: Weather)
signal weather_transition_started(from: Weather, to: Weather, duration: float)
signal weather_transition_completed(weather: Weather)

# Current state
var current_weather: Weather = Weather.CLEAR
var target_weather: Weather = Weather.CLEAR
var is_transitioning: bool = false
var transition_progress: float = 0.0

# References
var player: Node3D = null
var day_night_cycle: Node = null
var world_environment: WorldEnvironment = null

# Configuration
@export_group("Timing")
@export var weather_change_interval_min: float = 300.0  ## Minimum seconds between changes
@export var weather_change_interval_max: float = 900.0  ## Maximum seconds between changes
@export var transition_duration: float = 30.0  ## Seconds to transition between states

@export_group("Rain Settings")
@export var rain_particle_count: int = 2000
@export var rain_area_size: Vector3 = Vector3(40, 20, 40)
@export var rain_speed: float = 15.0
@export var heavy_rain_multiplier: float = 2.0

@export_group("Snow Settings")
@export var snow_particle_count: int = 1000
@export var snow_area_size: Vector3 = Vector3(50, 25, 50)
@export var snow_speed: float = 3.0
@export var blizzard_multiplier: float = 3.0

@export_group("Fog Settings")
@export var fog_density_clear: float = 0.0
@export var fog_density_light: float = 0.01
@export var fog_density_heavy: float = 0.05

@export_group("Sandstorm Settings")
@export var sandstorm_particle_count: int = 3000
@export var sandstorm_speed: float = 20.0
@export var sandstorm_visibility: float = 0.08

# Weather probability tables per biome
const BIOME_WEATHER_WEIGHTS: Dictionary = {
    0: {Weather.CLEAR: 50, Weather.CLOUDY: 30, Weather.RAIN: 15, Weather.FOG: 5},  # OCEAN
    1: {Weather.CLEAR: 60, Weather.CLOUDY: 25, Weather.RAIN: 10, Weather.STORM: 5},  # BEACH
    2: {Weather.CLEAR: 50, Weather.CLOUDY: 25, Weather.RAIN: 15, Weather.STORM: 5, Weather.FOG: 5},  # GRASSLAND
    3: {Weather.CLEAR: 30, Weather.CLOUDY: 25, Weather.RAIN: 25, Weather.FOG: 15, Weather.STORM: 5},  # FOREST
    4: {Weather.CLEAR: 70, Weather.CLOUDY: 15, Weather.SANDSTORM: 15},  # DESERT
    5: {Weather.CLEAR: 30, Weather.CLOUDY: 30, Weather.FOG: 20, Weather.STORM: 15, Weather.SNOW: 5},  # MOUNTAIN
    6: {Weather.CLEAR: 20, Weather.CLOUDY: 20, Weather.SNOW: 40, Weather.BLIZZARD: 15, Weather.FOG: 5}  # SNOW
}

# Internal timers
var weather_timer: float = 0.0
var next_weather_change: float = 0.0

# Particle systems (created at runtime)
var rain_particles: GPUParticles3D = null
var snow_particles: GPUParticles3D = null
var sandstorm_particles: GPUParticles3D = null
```

### 1.2 Weather State Transitions

```gdscript
func _ready():
    # Find references
    player = get_tree().get_first_node_in_group("player")
    
    var cycles = get_tree().get_nodes_in_group("day_night_cycle")
    if cycles.size() > 0:
        day_night_cycle = cycles[0]
        if day_night_cycle.has_node("WorldEnvironment"):
            world_environment = day_night_cycle.get_node("WorldEnvironment")
    
    # Initialize weather timer
    next_weather_change = randf_range(weather_change_interval_min, weather_change_interval_max)
    
    # Create particle systems
    _create_particle_systems()
    
    print("[WeatherManager] Initialized - Starting weather: %s" % Weather.keys()[current_weather])

func _process(delta: float):
    # Update weather timer
    weather_timer += delta
    
    if weather_timer >= next_weather_change and not is_transitioning:
        _roll_new_weather()
        weather_timer = 0.0
        next_weather_change = randf_range(weather_change_interval_min, weather_change_interval_max)
    
    # Update transition
    if is_transitioning:
        _update_transition(delta)
    
    # Update particle positions to follow player
    _update_particle_positions()

func _roll_new_weather():
    """Roll for new weather based on current biome"""
    var biome = _get_player_biome()
    var weights = BIOME_WEATHER_WEIGHTS.get(biome, BIOME_WEATHER_WEIGHTS[2])  # Default to grassland
    
    var new_weather = _weighted_random(weights)
    
    if new_weather != current_weather:
        start_transition(new_weather)

func start_transition(new_weather: Weather):
    """Begin transitioning to new weather state"""
    if is_transitioning:
        return
    
    target_weather = new_weather
    is_transitioning = true
    transition_progress = 0.0
    
    emit_signal("weather_transition_started", current_weather, target_weather, transition_duration)
    print("[WeatherManager] Transitioning: %s → %s" % [
        Weather.keys()[current_weather], 
        Weather.keys()[target_weather]
    ])

func _update_transition(delta: float):
    """Update weather transition progress"""
    transition_progress += delta / transition_duration
    
    if transition_progress >= 1.0:
        transition_progress = 1.0
        _complete_transition()
    else:
        _apply_transition_state(transition_progress)

func _complete_transition():
    """Finalize weather transition"""
    var old_weather = current_weather
    current_weather = target_weather
    is_transitioning = false
    
    _apply_weather_state(current_weather, 1.0)
    
    emit_signal("weather_changed", old_weather, current_weather)
    emit_signal("weather_transition_completed", current_weather)
    print("[WeatherManager] Weather now: %s" % Weather.keys()[current_weather])
```

### 1.3 Weather Effect Application

```gdscript
func _apply_weather_state(weather: Weather, intensity: float):
    """Apply visual/audio effects for weather state"""
    match weather:
        Weather.CLEAR:
            _set_fog(fog_density_clear, intensity)
            _set_rain(false, 0)
            _set_snow(false, 0)
            _set_sandstorm(false)
        
        Weather.CLOUDY:
            _set_fog(fog_density_light, intensity)
            _set_rain(false, 0)
        
        Weather.RAIN:
            _set_fog(fog_density_light, intensity)
            _set_rain(true, rain_particle_count)
        
        Weather.HEAVY_RAIN:
            _set_fog(fog_density_light * 1.5, intensity)
            _set_rain(true, int(rain_particle_count * heavy_rain_multiplier))
        
        Weather.STORM:
            _set_fog(fog_density_light * 2.0, intensity)
            _set_rain(true, int(rain_particle_count * heavy_rain_multiplier))
            # Thunder handled separately
        
        Weather.FOG:
            _set_fog(fog_density_heavy, intensity)
            _set_rain(false, 0)
        
        Weather.SNOW:
            _set_fog(fog_density_light, intensity)
            _set_snow(true, snow_particle_count)
        
        Weather.BLIZZARD:
            _set_fog(fog_density_heavy, intensity)
            _set_snow(true, int(snow_particle_count * blizzard_multiplier))
        
        Weather.SANDSTORM:
            _set_fog(sandstorm_visibility, intensity)
            _set_sandstorm(true)

func _set_fog(density: float, intensity: float):
    """Set fog density with intensity multiplier"""
    if world_environment and world_environment.environment:
        var env = world_environment.environment
        env.fog_enabled = density > 0.001
        env.fog_density = lerp(env.fog_density, density * intensity, 0.1)

func _set_rain(enabled: bool, count: int):
    """Enable/disable rain particles"""
    if rain_particles:
        rain_particles.emitting = enabled
        rain_particles.amount = count

func _set_snow(enabled: bool, count: int):
    """Enable/disable snow particles"""
    if snow_particles:
        snow_particles.emitting = enabled
        snow_particles.amount = count

func _set_sandstorm(enabled: bool):
    """Enable/disable sandstorm particles"""
    if sandstorm_particles:
        sandstorm_particles.emitting = enabled
```

---

## 2. BIOME GROUND COVER SYSTEM

### 2.1 Ground Cover Rules

**File:** `vegetation_spawner.gd` - Modify existing

```gdscript
# Add to vegetation_spawner.gd

## Ground cover allowed per biome
const BIOME_GROUND_COVER: Dictionary = {
    Chunk.Biome.OCEAN: [],  # No ground cover
    Chunk.Biome.BEACH: [VegType.SHELL, VegType.SEAWEED, VegType.DRIFTWOOD, VegType.PEBBLES],
    Chunk.Biome.GRASSLAND: [VegType.GRASS_TUFT, VegType.GRASS_PATCH, VegType.WILDFLOWER_YELLOW, VegType.WILDFLOWER_PURPLE, VegType.WILDFLOWER_WHITE],
    Chunk.Biome.FOREST: [VegType.GRASS_TUFT, VegType.FERN, VegType.MOSS, VegType.FALLEN_LOG],
    Chunk.Biome.DESERT: [VegType.DEAD_SHRUB, VegType.DRY_GRASS, VegType.BONES, VegType.DESERT_ROCK],
    Chunk.Biome.MOUNTAIN: [VegType.ALPINE_GRASS, VegType.ROCK_CLUSTER, VegType.LICHEN],
    Chunk.Biome.SNOW: [VegType.SNOW_MOUND, VegType.ICE_CRYSTAL, VegType.FROZEN_SHRUB]
}

## New vegetation types to add to enum
# VegType.SHELL
# VegType.SEAWEED
# VegType.DRIFTWOOD
# VegType.PEBBLES
# VegType.FERN
# VegType.MOSS
# VegType.FALLEN_LOG
# VegType.DEAD_SHRUB
# VegType.DRY_GRASS
# VegType.BONES
# VegType.DESERT_ROCK
# VegType.ALPINE_GRASS
# VegType.ROCK_CLUSTER
# VegType.LICHEN
# VegType.SNOW_MOUND
# VegType.ICE_CRYSTAL
# VegType.FROZEN_SHRUB

func can_spawn_ground_cover(veg_type: VegType, biome: int) -> bool:
    """Check if vegetation type is allowed in biome"""
    if not BIOME_GROUND_COVER.has(biome):
        return false
    return veg_type in BIOME_GROUND_COVER[biome]

func spawn_ground_cover_for_biome(chunk_pos: Vector2i, biome: int):
    """Spawn only appropriate ground cover for biome"""
    var allowed_types = BIOME_GROUND_COVER.get(biome, [])
    if allowed_types.is_empty():
        return
    
    var samples = ground_cover_samples_per_chunk
    for i in range(samples):
        var veg_type = allowed_types[randi() % allowed_types.size()]
        # ... spawn logic
```

### 2.2 Vegetation Color Tinting

```gdscript
# Add to vegetation_spawner.gd

## Grass/foliage color tints per biome
const BIOME_GRASS_TINT: Dictionary = {
    Chunk.Biome.GRASSLAND: Color(0.4, 0.7, 0.3),   # Bright green
    Chunk.Biome.FOREST: Color(0.2, 0.5, 0.2),      # Dark green
    Chunk.Biome.MOUNTAIN: Color(0.5, 0.6, 0.4),    # Gray-green
    Chunk.Biome.SNOW: Color(0.7, 0.8, 0.7),        # Frosted
    Chunk.Biome.BEACH: Color(0.6, 0.7, 0.5),       # Sandy green
    Chunk.Biome.DESERT: Color(0.6, 0.5, 0.3),      # Tan/dead
}

func get_grass_color_for_biome(biome: int) -> Color:
    """Get grass tint color for biome"""
    return BIOME_GRASS_TINT.get(biome, Color.WHITE)

func create_grass_material_for_biome(biome: int) -> StandardMaterial3D:
    """Create grass material with biome-specific tint"""
    var base_texture = PixelTextureGenerator.create_grass_texture()
    var tint = get_grass_color_for_biome(biome)
    return PixelTextureGenerator.create_pixel_material(base_texture, tint)
```

---

## 3. WIND SYSTEM

### 3.1 WindSystem Node

**File:** `res://wind_system.gd`
**Type:** Node (child of World)

```gdscript
extends Node
class_name WindSystem

## WindSystem - Global wind direction and strength
##
## ARCHITECTURE:
## - Provides wind vector for vegetation sway
## - Affects weather particle direction
## - Changes gradually over time
##
## USAGE:
## - Access via: WindSystem.get_wind_vector()
## - Vegetation shaders sample wind for sway

signal wind_changed(direction: Vector3, strength: float)

# Current wind state
var wind_direction: Vector3 = Vector3(1, 0, 0)
var wind_strength: float = 0.3
var target_direction: Vector3 = Vector3(1, 0, 0)
var target_strength: float = 0.3

# Configuration
@export_group("Wind Settings")
@export var direction_change_interval: float = 60.0  ## Seconds between direction changes
@export var strength_change_interval: float = 30.0   ## Seconds between strength changes
@export_range(0.0, 1.0) var strength_min: float = 0.1
@export_range(0.0, 1.0) var strength_max: float = 0.8
@export var transition_speed: float = 0.5  ## How fast wind changes

@export_group("Gust Settings")
@export var gust_chance: float = 0.1  ## Chance per second of gust
@export var gust_strength_multiplier: float = 2.0
@export var gust_duration: float = 2.0

# Timers
var direction_timer: float = 0.0
var strength_timer: float = 0.0
var gust_timer: float = 0.0
var is_gusting: bool = false

func _ready():
    # Randomize initial direction
    _randomize_direction()
    wind_direction = target_direction
    
    print("[WindSystem] Initialized - Direction: %s, Strength: %.2f" % [wind_direction, wind_strength])

func _process(delta: float):
    # Update timers
    direction_timer += delta
    strength_timer += delta
    
    # Change direction periodically
    if direction_timer >= direction_change_interval:
        direction_timer = 0.0
        _randomize_direction()
    
    # Change strength periodically
    if strength_timer >= strength_change_interval:
        strength_timer = 0.0
        _randomize_strength()
    
    # Random gusts
    if not is_gusting and randf() < gust_chance * delta:
        _start_gust()
    
    # Update gust
    if is_gusting:
        gust_timer += delta
        if gust_timer >= gust_duration:
            is_gusting = false
            gust_timer = 0.0
    
    # Smoothly transition to target
    wind_direction = wind_direction.lerp(target_direction, transition_speed * delta)
    wind_direction = wind_direction.normalized()
    
    var effective_target = target_strength
    if is_gusting:
        effective_target *= gust_strength_multiplier
    
    var old_strength = wind_strength
    wind_strength = lerp(wind_strength, effective_target, transition_speed * delta)
    
    # Emit signal if significant change
    if abs(wind_strength - old_strength) > 0.01:
        emit_signal("wind_changed", wind_direction, wind_strength)

func _randomize_direction():
    """Pick new random wind direction (horizontal only)"""
    var angle = randf() * TAU
    target_direction = Vector3(cos(angle), 0, sin(angle))

func _randomize_strength():
    """Pick new random wind strength"""
    target_strength = randf_range(strength_min, strength_max)

func _start_gust():
    """Start a wind gust"""
    is_gusting = true
    gust_timer = 0.0

# Public API
func get_wind_vector() -> Vector3:
    """Get current wind as direction * strength"""
    return wind_direction * wind_strength

func get_wind_direction() -> Vector3:
    """Get normalized wind direction"""
    return wind_direction

func get_wind_strength() -> float:
    """Get current wind strength (0-1+)"""
    return wind_strength

func set_wind_for_weather(weather_type: int):
    """Adjust wind based on weather"""
    match weather_type:
        0:  # CLEAR
            strength_min = 0.05
            strength_max = 0.3
        1:  # CLOUDY
            strength_min = 0.1
            strength_max = 0.4
        2, 3:  # RAIN, HEAVY_RAIN
            strength_min = 0.2
            strength_max = 0.5
        4:  # STORM
            strength_min = 0.5
            strength_max = 0.9
        7:  # BLIZZARD
            strength_min = 0.6
            strength_max = 1.0
        8:  # SANDSTORM
            strength_min = 0.7
            strength_max = 1.0
        _:
            strength_min = 0.1
            strength_max = 0.5
```

---

## 4. PARTICLE EFFECTS

### 4.1 Rain Particle Setup

```gdscript
# In weather_manager.gd

func _create_rain_particles() -> GPUParticles3D:
    """Create rain particle system"""
    var particles = GPUParticles3D.new()
    particles.name = "RainParticles"
    particles.amount = rain_particle_count
    particles.lifetime = 2.0
    particles.explosiveness = 0.0
    particles.randomness = 0.2
    particles.visibility_aabb = AABB(Vector3(-20, -10, -20), Vector3(40, 20, 40))
    
    # Process material
    var process_mat = ParticleProcessMaterial.new()
    process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process_mat.emission_box_extents = rain_area_size / 2.0
    process_mat.direction = Vector3(0, -1, 0)
    process_mat.spread = 5.0
    process_mat.initial_velocity_min = rain_speed * 0.8
    process_mat.initial_velocity_max = rain_speed * 1.2
    process_mat.gravity = Vector3(0, -9.8, 0)
    
    # Affected by wind
    var wind_system = get_node_or_null("/root/WindSystem")
    if wind_system:
        var wind = wind_system.get_wind_vector()
        process_mat.direction = Vector3(wind.x * 0.3, -1, wind.z * 0.3).normalized()
    
    particles.process_material = process_mat
    
    # Draw material (simple stretched quad)
    var draw_mat = StandardMaterial3D.new()
    draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    draw_mat.albedo_color = Color(0.7, 0.8, 1.0, 0.4)
    draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    
    var mesh = QuadMesh.new()
    mesh.size = Vector2(0.02, 0.3)  # Thin, elongated raindrop
    mesh.material = draw_mat
    
    particles.draw_pass_1 = mesh
    particles.emitting = false
    
    return particles
```

### 4.2 Snow Particle Setup

```gdscript
func _create_snow_particles() -> GPUParticles3D:
    """Create snow particle system"""
    var particles = GPUParticles3D.new()
    particles.name = "SnowParticles"
    particles.amount = snow_particle_count
    particles.lifetime = 8.0  # Slower fall
    particles.explosiveness = 0.0
    particles.randomness = 0.5
    particles.visibility_aabb = AABB(Vector3(-25, -12, -25), Vector3(50, 25, 50))
    
    # Process material
    var process_mat = ParticleProcessMaterial.new()
    process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process_mat.emission_box_extents = snow_area_size / 2.0
    process_mat.direction = Vector3(0, -1, 0)
    process_mat.spread = 15.0
    process_mat.initial_velocity_min = snow_speed * 0.5
    process_mat.initial_velocity_max = snow_speed * 1.5
    process_mat.gravity = Vector3(0, -2.0, 0)  # Light gravity
    
    # Turbulence for drifting
    process_mat.turbulence_enabled = true
    process_mat.turbulence_noise_strength = 0.5
    process_mat.turbulence_noise_speed = Vector3(0.5, 0.1, 0.5)
    
    particles.process_material = process_mat
    
    # Draw material (white dot)
    var draw_mat = StandardMaterial3D.new()
    draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    draw_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
    draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
    
    var mesh = QuadMesh.new()
    mesh.size = Vector2(0.05, 0.05)  # Small snowflake
    mesh.material = draw_mat
    
    particles.draw_pass_1 = mesh
    particles.emitting = false
    
    return particles
```

### 4.3 Footstep Particles

**File:** `player.gd` - Add to footstep system

```gdscript
# Add to player.gd

var footstep_particles: GPUParticles3D = null

func _ready():
    # ... existing code ...
    _setup_footstep_particles()

func _setup_footstep_particles():
    """Create particle system for footstep dust/snow"""
    footstep_particles = GPUParticles3D.new()
    footstep_particles.name = "FootstepParticles"
    footstep_particles.amount = 20
    footstep_particles.lifetime = 0.8
    footstep_particles.one_shot = true
    footstep_particles.explosiveness = 1.0
    
    var process_mat = ParticleProcessMaterial.new()
    process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    process_mat.emission_sphere_radius = 0.2
    process_mat.direction = Vector3(0, 1, 0)
    process_mat.spread = 45.0
    process_mat.initial_velocity_min = 1.0
    process_mat.initial_velocity_max = 2.0
    process_mat.gravity = Vector3(0, -5, 0)
    process_mat.scale_min = 0.5
    process_mat.scale_max = 1.0
    
    footstep_particles.process_material = process_mat
    
    # Simple quad mesh
    var mesh = QuadMesh.new()
    mesh.size = Vector2(0.1, 0.1)
    footstep_particles.draw_pass_1 = mesh
    
    add_child(footstep_particles)
    footstep_particles.position = Vector3(0, 0.1, 0)

func emit_footstep_particle(surface: String):
    """Emit footstep particle with color based on surface"""
    if not footstep_particles:
        return
    
    var color: Color
    match surface:
        "snow":
            color = Color(1.0, 1.0, 1.0, 0.8)  # White
        "sand", "desert":
            color = Color(0.9, 0.8, 0.6, 0.6)  # Tan
        "dirt":
            color = Color(0.5, 0.4, 0.3, 0.5)  # Brown
        "water":
            color = Color(0.6, 0.8, 1.0, 0.7)  # Blue splash
        _:
            return  # No particles for grass/stone
    
    # Update particle color
    var mesh = footstep_particles.draw_pass_1 as QuadMesh
    if mesh and mesh.material:
        var mat = mesh.material as StandardMaterial3D
        mat.albedo_color = color
    
    # Emit
    footstep_particles.restart()
    footstep_particles.emitting = true
```

---

## 5. INTEGRATION POINTS

### 5.1 World.gd Integration

```gdscript
# Add to world.gd _ready()

# Initialize Wind System
var wind_system_script = load("res://wind_system.gd")
if wind_system_script:
    var wind_system = wind_system_script.new()
    wind_system.name = "WindSystem"
    add_child(wind_system)
    print("Wind System loaded")

# Weather Manager is autoload, just connect signals
if WeatherManager:
    WeatherManager.weather_changed.connect(_on_weather_changed)
    print("Weather Manager connected")

func _on_weather_changed(old_weather, new_weather):
    """Handle weather change events"""
    print("Weather changed: %s → %s" % [old_weather, new_weather])
    
    # Update wind for weather
    var wind_system = get_node_or_null("WindSystem")
    if wind_system:
        wind_system.set_wind_for_weather(new_weather)
    
    # Update ambient sounds
    if AmbientManager:
        AmbientManager.set_weather(new_weather)
```

### 5.2 AmbientManager Integration

```gdscript
# Add to ambient_manager.gd

var current_weather: int = 0  # WeatherManager.Weather.CLEAR

func set_weather(weather: int):
    """Update ambient sounds for weather"""
    current_weather = weather
    
    match weather:
        2, 3:  # RAIN, HEAVY_RAIN
            play_ambient_loop("rain_loop", 0.4)
        4:  # STORM
            play_ambient_loop("rain_loop", 0.6)
            play_ambient_loop("thunder_distant", 0.3)
        6:  # SNOW
            stop_ambient_loop("rain_loop", 2.0)
        7:  # BLIZZARD
            play_ambient_loop("wind_strong", 0.5)
        8:  # SANDSTORM
            play_ambient_loop("wind_strong", 0.6)
        _:  # CLEAR, CLOUDY, FOG
            stop_ambient_loop("rain_loop", 5.0)
            stop_ambient_loop("thunder_distant", 2.0)
```

---

## 6. PERFORMANCE GUIDELINES

### 6.1 Particle Limits

| Effect | Max Particles | Lifetime | Notes |
|--------|---------------|----------|-------|
| Rain | 2000 | 2s | Reduce in blizzard |
| Heavy Rain | 4000 | 2s | Storm only |
| Snow | 1000 | 8s | Slow fall |
| Blizzard | 3000 | 6s | With wind |
| Sandstorm | 3000 | 3s | Horizontal |
| Footsteps | 20 | 0.8s | One-shot |
| Leaves | 50 | 5s | Per tree area |

### 6.2 Update Frequencies

| System | Update Rate | Notes |
|--------|-------------|-------|
| WeatherManager | Every frame | Transition lerping |
| WindSystem | Every frame | Smooth changes |
| Particle positions | Every frame | Follow player |
| Weather roll | 5-15 min | Configurable |
| Biome detection | 2 seconds | Use AmbientManager pattern |

### 6.3 LOD Considerations

```gdscript
# Reduce particle counts based on distance/settings
func get_particle_count_for_quality(base_count: int) -> int:
    var quality = SettingsManager.get_setting("graphics", "particle_quality")
    match quality:
        0:  # Low
            return int(base_count * 0.25)
        1:  # Medium
            return int(base_count * 0.5)
        2:  # High
            return base_count
        3:  # Ultra
            return int(base_count * 1.5)
    return base_count
```

---

## 7. TEST SCENES

### 7.1 Test Weather (test_weather.tscn)

```gdscript
# test_weather.gd
extends Node3D

## Automated Weather System Test Suite
## Run scene to execute all tests automatically
## Results output to console

const TEST_TRANSITION_SPEED: float = 2.0  # Fast transitions for testing

var tests_passed: int = 0
var tests_failed: int = 0
var current_test: String = ""

func _ready():
    print("\n[TEST] ════════════════════════════════════")
    print("[TEST] Weather System Tests")
    print("[TEST] ════════════════════════════════════\n")
    
    # Speed up transitions for testing
    WeatherManager.transition_duration = TEST_TRANSITION_SPEED
    
    # Run test suite
    await run_all_tests()
    
    print_results()

func run_all_tests():
    await test_weather_transitions()
    await test_biome_restrictions()
    await test_particle_systems()

func test_weather_transitions():
    current_test = "Weather Transitions"
    
    var states = [
        WeatherManager.Weather.CLEAR,
        WeatherManager.Weather.CLOUDY,
        WeatherManager.Weather.RAIN,
        WeatherManager.Weather.FOG,
        WeatherManager.Weather.STORM
    ]
    
    for i in range(states.size() - 1):
        var from_state = states[i]
        var to_state = states[i + 1]
        
        WeatherManager.current_weather = from_state
        WeatherManager.start_transition(to_state)
        
        # Wait for transition
        await get_tree().create_timer(TEST_TRANSITION_SPEED + 0.5).timeout
        
        if WeatherManager.current_weather == to_state and not WeatherManager.is_transitioning:
            log_pass("%s → %s transition" % [
                WeatherManager.Weather.keys()[from_state],
                WeatherManager.Weather.keys()[to_state]
            ])
        else:
            log_fail("%s → %s transition" % [
                WeatherManager.Weather.keys()[from_state],
                WeatherManager.Weather.keys()[to_state]
            ])

func test_biome_restrictions():
    current_test = "Biome Restrictions"
    
    # Test: Desert should not allow RAIN
    var desert_weights = WeatherManager.BIOME_WEATHER_WEIGHTS.get(4)  # DESERT
    if not desert_weights.has(WeatherManager.Weather.RAIN):
        log_pass("DESERT biome: RAIN blocked correctly")
    else:
        log_fail("DESERT biome: RAIN should be blocked")
    
    # Test: Snow biome should not allow SANDSTORM
    var snow_weights = WeatherManager.BIOME_WEATHER_WEIGHTS.get(6)  # SNOW
    if not snow_weights.has(WeatherManager.Weather.SANDSTORM):
        log_pass("SNOW biome: SANDSTORM blocked correctly")
    else:
        log_fail("SNOW biome: SANDSTORM should be blocked")
    
    # Test: Only DESERT allows SANDSTORM
    var sandstorm_biomes = []
    for biome_id in WeatherManager.BIOME_WEATHER_WEIGHTS:
        if WeatherManager.BIOME_WEATHER_WEIGHTS[biome_id].has(WeatherManager.Weather.SANDSTORM):
            sandstorm_biomes.append(biome_id)
    
    if sandstorm_biomes == [4]:  # Only DESERT
        log_pass("SANDSTORM restricted to DESERT only")
    else:
        log_fail("SANDSTORM should only be in DESERT, found in: %s" % sandstorm_biomes)

func test_particle_systems():
    current_test = "Particle Systems"
    
    # Test rain particles
    WeatherManager._set_rain(true, 2000)
    await get_tree().process_frame
    
    if WeatherManager.rain_particles and WeatherManager.rain_particles.emitting:
        log_pass("Rain particles active: %d" % WeatherManager.rain_particles.amount)
    else:
        log_fail("Rain particles not emitting")
    
    WeatherManager._set_rain(false, 0)
    
    # Test snow particles
    WeatherManager._set_snow(true, 1000)
    await get_tree().process_frame
    
    if WeatherManager.snow_particles and WeatherManager.snow_particles.emitting:
        log_pass("Snow particles active: %d" % WeatherManager.snow_particles.amount)
    else:
        log_fail("Snow particles not emitting")
    
    WeatherManager._set_snow(false, 0)

func log_pass(message: String):
    tests_passed += 1
    print("[TEST] ✅ %s" % message)

func log_fail(message: String):
    tests_failed += 1
    print("[TEST] ❌ %s" % message)

func print_results():
    var total = tests_passed + tests_failed
    print("\n[TEST] ────────────────────────────────")
    if tests_failed == 0:
        print("[TEST] Weather Tests: %d/%d PASSED ✅" % [tests_passed, total])
    else:
        print("[TEST] Weather Tests: %d/%d PASSED, %d FAILED ❌" % [tests_passed, total, tests_failed])
    print("[TEST] ════════════════════════════════════\n")
```

### 7.2 Test Biome Vegetation (test_biome_vegetation.tscn)

```gdscript
# test_biome_vegetation.gd
extends Node3D

## Automated Biome Vegetation Test Suite
## Verifies ground cover rules per biome

var tests_passed: int = 0
var tests_failed: int = 0
var vegetation_spawner: VegetationSpawner

# Expected vegetation rules
const BIOME_SHOULD_HAVE_GRASS: Dictionary = {
    0: false,  # OCEAN
    1: false,  # BEACH
    2: true,   # GRASSLAND
    3: true,   # FOREST
    4: false,  # DESERT
    5: true,   # MOUNTAIN (sparse)
    6: false   # SNOW
}

const BIOME_NAMES: Array = ["OCEAN", "BEACH", "GRASSLAND", "FOREST", "DESERT", "MOUNTAIN", "SNOW"]

func _ready():
    print("\n[TEST] ════════════════════════════════════")
    print("[TEST] Biome Vegetation Tests")
    print("[TEST] ════════════════════════════════════\n")
    
    # Get or create vegetation spawner
    vegetation_spawner = get_node_or_null("VegetationSpawner")
    if not vegetation_spawner:
        vegetation_spawner = VegetationSpawner.new()
        add_child(vegetation_spawner)
    
    run_all_tests()
    print_results()

func run_all_tests():
    test_grass_restrictions()
    test_biome_specific_vegetation()
    test_color_tinting()

func test_grass_restrictions():
    print("[TEST] Testing grass restrictions...")
    
    for biome_id in range(7):
        var biome_name = BIOME_NAMES[biome_id]
        var should_have_grass = BIOME_SHOULD_HAVE_GRASS[biome_id]
        
        # Check if grass types are in allowed list
        var allowed = vegetation_spawner.BIOME_GROUND_COVER.get(biome_id, [])
        var has_grass = false
        
        for veg_type in allowed:
            if veg_type in [VegetationSpawner.VegType.GRASS_TUFT, VegetationSpawner.VegType.GRASS_PATCH]:
                has_grass = true
                break
        
        if has_grass == should_have_grass:
            if should_have_grass:
                log_pass("%s: Grass allowed (correct)" % biome_name)
            else:
                log_pass("%s: Grass blocked (correct)" % biome_name)
        else:
            if should_have_grass:
                log_fail("%s: Grass should be allowed" % biome_name)
            else:
                log_fail("%s: Grass should be BLOCKED" % biome_name)

func test_biome_specific_vegetation():
    print("\n[TEST] Testing biome-specific vegetation...")
    
    # Desert should have dead shrubs
    var desert_veg = vegetation_spawner.BIOME_GROUND_COVER.get(4, [])
    if VegetationSpawner.VegType.DEAD_SHRUB in desert_veg:
        log_pass("DESERT: Dead shrubs present")
    else:
        log_fail("DESERT: Missing dead shrubs")
    
    # Snow should have snow mounds
    var snow_veg = vegetation_spawner.BIOME_GROUND_COVER.get(6, [])
    if VegetationSpawner.VegType.SNOW_MOUND in snow_veg:
        log_pass("SNOW: Snow mounds present")
    else:
        log_fail("SNOW: Missing snow mounds")
    
    # Beach should have shells
    var beach_veg = vegetation_spawner.BIOME_GROUND_COVER.get(1, [])
    if VegetationSpawner.VegType.SHELL in beach_veg:
        log_pass("BEACH: Shells present")
    else:
        log_fail("BEACH: Missing shells")
    
    # Forest should have ferns
    var forest_veg = vegetation_spawner.BIOME_GROUND_COVER.get(3, [])
    if VegetationSpawner.VegType.FERN in forest_veg:
        log_pass("FOREST: Ferns present")
    else:
        log_fail("FOREST: Missing ferns")

func test_color_tinting():
    print("\n[TEST] Testing vegetation color tinting...")
    
    var grassland_tint = vegetation_spawner.get_grass_color_for_biome(2)
    var forest_tint = vegetation_spawner.get_grass_color_for_biome(3)
    
    # Grassland should be brighter than forest
    if grassland_tint.g > forest_tint.g:
        log_pass("GRASSLAND brighter green than FOREST")
    else:
        log_fail("GRASSLAND should be brighter than FOREST")
    
    # Snow tint should be pale/frosted
    var snow_tint = vegetation_spawner.get_grass_color_for_biome(6)
    if snow_tint.r > 0.6 and snow_tint.g > 0.7:
        log_pass("SNOW: Frosted tint correct")
    else:
        log_fail("SNOW: Tint should be pale/frosted")

func log_pass(message: String):
    tests_passed += 1
    print("[TEST]   ✅ %s" % message)

func log_fail(message: String):
    tests_failed += 1
    print("[TEST]   ❌ %s" % message)

func print_results():
    var total = tests_passed + tests_failed
    print("\n[TEST] ────────────────────────────────")
    if tests_failed == 0:
        print("[TEST] Biome Vegetation: %d/%d PASSED ✅" % [tests_passed, total])
    else:
        print("[TEST] Biome Vegetation: %d/%d PASSED, %d FAILED ❌" % [tests_passed, total, tests_failed])
    print("[TEST] ════════════════════════════════════\n")
```

### 7.3 Test Wind & Particles (test_wind_particles.tscn)

```gdscript
# test_wind_particles.gd
extends Node3D

## Automated Wind System Test Suite

var tests_passed: int = 0
var tests_failed: int = 0
var wind_system: WindSystem

func _ready():
    print("\n[TEST] ════════════════════════════════════")
    print("[TEST] Wind & Particle Tests")
    print("[TEST] ════════════════════════════════════\n")
    
    wind_system = get_node_or_null("/root/WindSystem")
    if not wind_system:
        wind_system = WindSystem.new()
        add_child(wind_system)
    
    await run_all_tests()
    print_results()

func run_all_tests():
    await test_wind_direction_change()
    await test_wind_strength_range()
    await test_wind_gusts()
    test_wind_vector()

func test_wind_direction_change():
    print("[TEST] Testing wind direction changes...")
    
    var initial_dir = wind_system.wind_direction
    
    # Force direction change
    wind_system._randomize_direction()
    wind_system.wind_direction = wind_system.target_direction
    
    var new_dir = wind_system.wind_direction
    
    if initial_dir != new_dir or initial_dir.length() > 0.9:
        log_pass("Wind direction changed: %s → %s" % [initial_dir, new_dir])
    else:
        log_fail("Wind direction did not change")

func test_wind_strength_range():
    print("[TEST] Testing wind strength range...")
    
    # Sample multiple strength values
    var min_found: float = 1.0
    var max_found: float = 0.0
    
    for i in range(10):
        wind_system._randomize_strength()
        var strength = wind_system.target_strength
        min_found = min(min_found, strength)
        max_found = max(max_found, strength)
    
    if min_found >= wind_system.strength_min and max_found <= wind_system.strength_max:
        log_pass("Wind strength range: %.2f - %.2f" % [min_found, max_found])
    else:
        log_fail("Wind strength out of range: %.2f - %.2f" % [min_found, max_found])

func test_wind_gusts():
    print("[TEST] Testing wind gusts...")
    
    # Force a gust
    wind_system._start_gust()
    
    if wind_system.is_gusting:
        log_pass("Gust triggered (%.1fx strength)" % wind_system.gust_strength_multiplier)
    else:
        log_fail("Gust did not trigger")
    
    # Wait for gust to end
    await get_tree().create_timer(wind_system.gust_duration + 0.5).timeout
    
    if not wind_system.is_gusting:
        log_pass("Gust ended correctly")
    else:
        log_fail("Gust did not end")

func test_wind_vector():
    print("[TEST] Testing wind vector API...")
    
    var vector = wind_system.get_wind_vector()
    var direction = wind_system.get_wind_direction()
    var strength = wind_system.get_wind_strength()
    
    # Vector should equal direction * strength
    var expected = direction * strength
    if vector.distance_to(expected) < 0.01:
        log_pass("Wind vector API correct: %s" % vector)
    else:
        log_fail("Wind vector mismatch: got %s, expected %s" % [vector, expected])

func log_pass(message: String):
    tests_passed += 1
    print("[TEST]   ✅ %s" % message)

func log_fail(message: String):
    tests_failed += 1
    print("[TEST]   ❌ %s" % message)

func print_results():
    var total = tests_passed + tests_failed
    print("\n[TEST] ────────────────────────────────")
    if tests_failed == 0:
        print("[TEST] Wind Tests: %d/%d PASSED ✅" % [tests_passed, total])
    else:
        print("[TEST] Wind Tests: %d/%d PASSED, %d FAILED ❌" % [tests_passed, total, tests_failed])
    print("[TEST] ════════════════════════════════════\n")
```

### 7.4 Running Tests

**From Editor:**
1. Open `test_weather.tscn`
2. Press F5 (Run Scene)
3. Check Output panel for results

**From Command Line:**
```bash
godot --headless --path /path/to/project -s test_weather.tscn
```

**Test All:**
```gdscript
# test_all.gd - Run all test suites
extends Node

func _ready():
    print("\n[TEST] ════════════════════════════════════")
    print("[TEST] RUNNING ALL TEST SUITES")
    print("[TEST] ════════════════════════════════════\n")
    
    var test_scenes = [
        "res://test_weather.tscn",
        "res://test_biome_vegetation.tscn",
        "res://test_wind_particles.tscn"
    ]
    
    for scene_path in test_scenes:
        get_tree().change_scene_to_file(scene_path)
        await get_tree().create_timer(10.0).timeout  # Wait for tests
    
    print("\n[TEST] ALL TESTS COMPLETE")
```

---

## 8. DEBUG COMMANDS

```gdscript
# Add to weather_manager.gd

func _input(event: InputEvent):
    if not OS.is_debug_build():
        return
    
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F7:  # Cycle weather
                var next = (current_weather + 1) % Weather.size()
                start_transition(next as Weather)
                print("[DEBUG] Forcing weather: %s" % Weather.keys()[next])
            
            KEY_F8:  # Toggle rain
                if current_weather == Weather.RAIN:
                    start_transition(Weather.CLEAR)
                else:
                    start_transition(Weather.RAIN)
            
            KEY_F9:  # Print weather status
                print_status()

func print_status():
    print("\n[WeatherManager] Status:")
    print("  Current: %s" % Weather.keys()[current_weather])
    print("  Target: %s" % Weather.keys()[target_weather])
    print("  Transitioning: %s (%.1f%%)" % [is_transitioning, transition_progress * 100])
    print("  Next change in: %.0fs" % (next_weather_change - weather_timer))
    print("")
```

---

*Document Version: 0.8.0*
*Technical Specification for Living World Systems*
