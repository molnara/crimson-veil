# IMPLEMENTATION GUIDE v0.8.0 - "Living World"
## Technical Specifications & Code Patterns

---

## TABLE OF CONTENTS

0. [Phase 0 - Vegetation System Fix (Completed)](#0-phase-0---vegetation-system-fix-completed)
1. [Weather System Architecture](#1-weather-system-architecture)
2. [Weather Particle Implementation](#2-weather-particle-implementation)
3. [Biome Ground Cover System](#3-biome-ground-cover-system)
4. [Wind System](#4-wind-system)
5. [Particle Effects](#5-particle-effects)
6. [Integration Points](#6-integration-points)
7. [Performance Guidelines](#7-performance-guidelines)

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

### 0.3 Survival-Balanced Densities

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

### 1.1 System Overview

The weather system consists of two main components:

1. **WeatherManager** (Autoload Singleton) - State machine, transitions, biome logic
2. **WeatherParticles** (Scene Node) - Creates and manages particle systems

```
┌─────────────────────────────────────────────────────────────┐
│                     WeatherManager                           │
│                    (Autoload Singleton)                      │
│  - Weather state machine                                     │
│  - Biome probability tables                                  │
│  - Transition timing                                         │
│  - Controls particle VISIBILITY only                         │
└──────────────────────┬──────────────────────────────────────┘
                       │ set_*_particles()
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    WeatherParticles                          │
│                  (Node3D in World scene)                     │
│  - Creates GPUParticles3D nodes                              │
│  - Rain, Storm, Snow, Blizzard                               │
│  - Registers with WeatherManager                             │
│  - Repositions on player teleport                            │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 WeatherManager Singleton

**File:** `res://weather_manager.gd`
**Type:** Autoload Singleton

```gdscript
extends Node

## WeatherManager - Dynamic weather state machine
## 
## ARCHITECTURE:
## - Singleton managing global weather state
## - Biome-aware weather probabilities
## - Smooth transitions between weather states
## - Controls particle visibility (NOT creation)
##
## CRITICAL: WeatherManager does NOT create particles!
## Particles must be created by WeatherParticles scene node.

# Weather states
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

# Signals
signal weather_changed(old_weather: Weather, new_weather: Weather)
signal weather_transition_started(from: Weather, to: Weather, duration: float)
signal weather_transition_completed(weather: Weather)

# Particle references (set by WeatherParticles)
var rain_particles: GPUParticles3D = null
var storm_particles: GPUParticles3D = null
var snow_particles: GPUParticles3D = null
var blizzard_particles: GPUParticles3D = null
var sandstorm_particles: GPUParticles3D = null

# Registration methods
func set_rain_particles(particles: GPUParticles3D):
    rain_particles = particles

func set_storm_particles(particles: GPUParticles3D):
    storm_particles = particles

func set_snow_particles(particles: GPUParticles3D):
    snow_particles = particles

func set_blizzard_particles(particles: GPUParticles3D):
    blizzard_particles = particles
```

### 1.3 Particle Visibility Control

**CRITICAL:** Only toggle `visible`. Never change `emitting` or `amount` at runtime.

```gdscript
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
    
    if storm_particles:
        storm_particles.visible = show_storm
    
    if snow_particles:
        snow_particles.visible = show_snow
    
    if blizzard_particles:
        blizzard_particles.visible = show_blizzard
    
    if sandstorm_particles:
        sandstorm_particles.visible = show_sand
```

---

## 2. WEATHER PARTICLE IMPLEMENTATION

### 2.1 CRITICAL: GPUParticles3D Instantiation Bug

**Problem Discovered:** GPUParticles3D created from instantiated .tscn scenes freeze in place and don't animate properly. Particles spawn but remain stuck at their initial positions.

**Root Cause:** Unknown - appears to be a Godot 4.5 quirk with how particle physics simulation initializes when scene is instantiated vs manually added.

**Solution:** WeatherParticles MUST be:
1. A Node3D manually added in the World scene (not from .tscn)
2. Script attached directly to the Node3D
3. Particles created dynamically in `_ready()`

### 2.2 WeatherParticles Script

**File:** `res://weather_particles.gd`

```gdscript
extends Node3D
## Weather particle controller - MUST be manually added as Node3D in editor
## Do NOT use as .tscn - instantiated scenes don't work properly

var rain_particles: GPUParticles3D
var storm_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var blizzard_particles: GPUParticles3D

func _ready():
    print("[WeatherParticles] Initializing...")
    
    # Position at player's starting location
    await get_tree().process_frame
    var player = get_tree().get_first_node_in_group("player")
    if player:
        global_position = player.global_position
        print("[WeatherParticles] Positioned at player: ", global_position)
    
    _create_rain()
    _create_storm()
    _create_snow()
    _create_blizzard()
    
    # Register with WeatherManager after a short delay
    await get_tree().create_timer(0.5).timeout
    if WeatherManager:
        WeatherManager.set_rain_particles(rain_particles)
        WeatherManager.set_storm_particles(storm_particles)
        WeatherManager.set_snow_particles(snow_particles)
        WeatherManager.set_blizzard_particles(blizzard_particles)
        print("[WeatherParticles] Registered with WeatherManager")
```

### 2.3 Rain Particle Creation

```gdscript
func _create_rain():
    rain_particles = GPUParticles3D.new()
    rain_particles.name = "Rain"
    add_child(rain_particles)
    
    rain_particles.position = Vector3(0, 50, 0)
    rain_particles.amount = 12000
    rain_particles.lifetime = 3.5
    rain_particles.preprocess = 0.0
    rain_particles.emitting = true
    rain_particles.visible = false
    rain_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
    
    var mat = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(100, 0.1, 100)
    mat.gravity = Vector3(0, -25, 0)
    rain_particles.process_material = mat
    
    # Rain streaks
    var mesh = BoxMesh.new()
    mesh.size = Vector3(0.06, 1.8, 0.06)
    var mesh_mat = StandardMaterial3D.new()
    mesh_mat.albedo_color = Color(0.6, 0.75, 1.0, 0.5)
    mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mesh_mat
    rain_particles.draw_pass_1 = mesh
    
    print("[WeatherParticles] Rain created")
```

### 2.4 Storm Particle Creation

```gdscript
func _create_storm():
    storm_particles = GPUParticles3D.new()
    storm_particles.name = "Storm"
    add_child(storm_particles)
    
    storm_particles.position = Vector3(0, 60, 0)
    storm_particles.amount = 20000
    storm_particles.lifetime = 2.5
    storm_particles.preprocess = 0.0
    storm_particles.emitting = true
    storm_particles.visible = false
    storm_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
    
    var mat = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(120, 0.1, 120)
    mat.gravity = Vector3(-5, -40, -3)  # Angled rain for stormy effect
    storm_particles.process_material = mat
    
    # Heavy storm rain - thicker and longer
    var mesh = BoxMesh.new()
    mesh.size = Vector3(0.08, 2.5, 0.08)
    var mesh_mat = StandardMaterial3D.new()
    mesh_mat.albedo_color = Color(0.5, 0.6, 0.8, 0.7)
    mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mesh_mat
    storm_particles.draw_pass_1 = mesh
    
    print("[WeatherParticles] Storm created")
```

### 2.5 Snow Particle Creation

```gdscript
func _create_snow():
    snow_particles = GPUParticles3D.new()
    snow_particles.name = "Snow"
    add_child(snow_particles)
    
    snow_particles.position = Vector3(0, 50, 0)
    snow_particles.amount = 8000
    snow_particles.lifetime = 20.0
    snow_particles.preprocess = 0.0
    snow_particles.emitting = true
    snow_particles.visible = false
    snow_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
    
    var mat = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(100, 0.1, 100)
    mat.gravity = Vector3(0.5, -3, 0.3)  # Gentle drift
    snow_particles.process_material = mat
    
    # Snow flakes
    var mesh = BoxMesh.new()
    mesh.size = Vector3(0.2, 0.2, 0.2)
    var mesh_mat = StandardMaterial3D.new()
    mesh_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
    mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mesh_mat
    snow_particles.draw_pass_1 = mesh
    
    print("[WeatherParticles] Snow created")
```

### 2.6 Blizzard Particle Creation

```gdscript
func _create_blizzard():
    blizzard_particles = GPUParticles3D.new()
    blizzard_particles.name = "Blizzard"
    add_child(blizzard_particles)
    
    blizzard_particles.position = Vector3(0, 50, 0)
    blizzard_particles.amount = 18000
    blizzard_particles.lifetime = 10.0
    blizzard_particles.preprocess = 0.0
    blizzard_particles.emitting = true
    blizzard_particles.visible = false
    blizzard_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
    
    var mat = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(120, 0.1, 120)
    mat.gravity = Vector3(-8, -8, -5)  # Strong horizontal wind
    blizzard_particles.process_material = mat
    
    # Blizzard snow - larger, denser
    var mesh = BoxMesh.new()
    mesh.size = Vector3(0.25, 0.25, 0.25)
    var mesh_mat = StandardMaterial3D.new()
    mesh_mat.albedo_color = Color(0.95, 0.95, 1.0, 0.9)
    mesh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material = mesh_mat
    blizzard_particles.draw_pass_1 = mesh
    
    print("[WeatherParticles] Blizzard created")
```

### 2.7 Minecraft-Style Positioning

```gdscript
func _process(_delta):
    # Check if player teleported far away - reposition weather if so
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var distance = global_position.distance_to(player.global_position)
        if distance > 200:
            global_position = player.global_position
            print("[WeatherParticles] Repositioned to player at: ", global_position)
```

### 2.8 Particle Configuration Summary

| Weather  | Amount  | Lifetime | Height | Gravity        | Size        | Color |
|----------|---------|----------|--------|----------------|-------------|-------|
| Rain     | 12,000  | 3.5s     | 50     | (0, -25, 0)    | 0.06 x 1.8  | Light blue |
| Storm    | 20,000  | 2.5s     | 60     | (-5, -40, -3)  | 0.08 x 2.5  | Dark blue-gray |
| Snow     | 8,000   | 20s      | 50     | (0.5, -3, 0.3) | 0.2 x 0.2   | White |
| Blizzard | 18,000  | 10s      | 50     | (-8, -8, -5)   | 0.25 x 0.25 | Off-white |

### 2.9 Setup Instructions

**To add weather particles to your World scene:**

1. Open World.tscn in Godot editor
2. Right-click on World node → Add Child Node → Node3D
3. Rename it to "WeatherParticles"
4. In Inspector, click Script → Load → select `weather_particles.gd`
5. Save scene

**DO NOT:**
- Create a .tscn file for WeatherParticles
- Instantiate WeatherParticles from code
- Add particles as children in the editor

---

## 3. BIOME GROUND COVER SYSTEM

### 3.1 Ground Cover by Biome (TODO)

```gdscript
const BIOME_GROUND_COVER = {
    0: [],  # OCEAN - no ground cover
    1: [VegType.SHELL, VegType.SEAWEED, VegType.DRIFTWOOD],  # BEACH
    2: [VegType.GRASS_TUFT, VegType.WILDFLOWER_YELLOW, VegType.WILDFLOWER_PURPLE],  # GRASSLAND
    3: [VegType.GRASS_TUFT, VegType.FERN, VegType.FALLEN_LOG],  # FOREST
    4: [VegType.DEAD_SHRUB, VegType.BONES, VegType.DRY_GRASS],  # DESERT
    5: [VegType.ALPINE_GRASS, VegType.GRAVEL, VegType.SMALL_ROCK],  # MOUNTAIN
    6: [VegType.SNOW_MOUND, VegType.ICE_PATCH, VegType.FROZEN_SHRUB]  # SNOW
}
```

---

## 4. WIND SYSTEM (TODO)

### 4.1 WindSystem Node

```gdscript
extends Node
class_name WindSystem

## WindSystem - Dynamic wind direction and strength

signal wind_changed(direction: Vector3, strength: float)
signal gust_started(multiplier: float)
signal gust_ended()

@export var direction_change_interval: float = 60.0
@export var strength_min: float = 0.0
@export var strength_max: float = 1.0
@export var gust_chance: float = 0.1
@export var gust_duration: float = 3.0
@export var gust_strength_multiplier: float = 2.0

var wind_direction: Vector3 = Vector3(1, 0, 0)
var wind_strength: float = 0.2
var is_gusting: bool = false

func get_wind_vector() -> Vector3:
    var mult = gust_strength_multiplier if is_gusting else 1.0
    return wind_direction * wind_strength * mult
```

---

## 6. INTEGRATION POINTS

### 6.1 WeatherManager + WeatherParticles Integration

```
Game Start
    │
    ├── WeatherManager._ready() (Autoload)
    │   └── Initializes state machine, starts timer
    │
    └── World scene loads
        │
        └── WeatherParticles._ready()
            ├── Creates particle systems
            ├── await 0.5s
            └── Calls WeatherManager.set_*_particles()
                └── WeatherManager now controls visibility
```

### 6.2 Debug Controls

| Key | Action | Handler |
|-----|--------|---------|
| F4 | Show weather status | WeatherManager._input() |
| F5 | Cycle weather (transition) | WeatherManager._input() |
| F6 | Random weather (instant) | WeatherManager._input() |

---

## 7. PERFORMANCE GUIDELINES

### 7.1 Particle Performance

| Setting | Impact | Recommendation |
|---------|--------|----------------|
| `amount` | High | Don't exceed 20,000 per system |
| `lifetime` | Medium | Longer = more particles visible |
| `visibility_aabb` | High | Set large enough to avoid culling |
| Mesh complexity | Low | Simple boxes are fine |
| Transparency | Medium | ALPHA mode is fine |

### 7.2 GPUParticles3D Best Practices

1. **Never change `amount` at runtime** - breaks simulation
2. **Never toggle `emitting`** - use `visible` instead
3. **Set large `visibility_aabb`** - prevents camera-angle culling
4. **Use simple meshes** - BoxMesh is optimal
5. **Unshaded materials** - no lighting calculations needed

### 7.3 Memory Considerations

- All 4 particle systems always exist and emit
- Only visibility is toggled
- Total particle overhead: ~58,000 particles
- GPU handles all simulation

---

## 8. DEBUG COMMANDS

```gdscript
# weather_manager.gd

func _input(event: InputEvent):
    if not OS.is_debug_build():
        return
    
    if event is InputEventKey and event.pressed:
        match event.keycode:
            KEY_F4:  # Weather status
                print_status()
            KEY_F5:  # Cycle weather (with transition)
                _cycle_weather()
            KEY_F6:  # Random weather (instant)
                _force_random_weather()

func print_status():
    print("\n[WeatherManager] Status:")
    print("  Current: %s" % Weather.keys()[current_weather])
    print("  Transitioning: %s" % is_transitioning)
    print("  Next change in: %.0fs" % (next_weather_change - weather_timer))
```

---

*Document Version: 0.8.1*
*Last Updated: Weather Particle System Implementation*
