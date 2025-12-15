# CRIMSON VEIL - ARCHITECTURE GUIDE
## System Overview and Code Patterns

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Core Architecture](#2-core-architecture)
3. [System Breakdown](#3-system-breakdown)
4. [Signal Flow](#4-signal-flow)
5. [File Organization](#5-file-organization)
6. [Code Patterns](#6-code-patterns)
7. [Extension Points](#7-extension-points)
8. [Performance Considerations](#8-performance-considerations)

---

## 1. PROJECT OVERVIEW

### Tech Stack
- **Engine:** Godot 4.5.1
- **Language:** GDScript
- **3D Geometry:** CSG primitives + procedural meshes
- **Input:** Dual support (M+KB and Xbox controller)
- **Audio:** AI-generated (ElevenLabs for voice, procedural for SFX)
- **Textures:** AI-generated (Leonardo.ai) + procedural pixel art

### Game Type
First-person survival game with:
- Procedural terrain generation (chunk-based)
- Biome system (7 biomes)
- Day/night cycle
- Dynamic weather system (rain, storm, snow, blizzard, fog, sandstorm)
- Resource harvesting and crafting
- Combat with enemies
- Inventory and tools

---

## 2. CORE ARCHITECTURE

### Scene Hierarchy
```
World (Node3D)
├── ChunkManager (Node3D)
│   └── [Chunk instances...]
├── VegetationSpawner (Node3D)
├── CritterSpawner (Node3D)
├── DayNightCycle (Node3D)
│   ├── Sun (DirectionalLight3D)
│   ├── Moon (DirectionalLight3D)
│   └── WorldEnvironment
├── WeatherParticles (Node3D)          # NEW - Must be manually added
│   ├── Rain (GPUParticles3D)
│   ├── Storm (GPUParticles3D)
│   ├── Snow (GPUParticles3D)
│   └── Blizzard (GPUParticles3D)
├── Player (CharacterBody3D)
│   ├── SpringArm3D
│   │   └── Camera3D
│   ├── HealthHungerSystem
│   ├── CombatSystem
│   ├── Inventory (runtime)
│   ├── ToolSystem (runtime)
│   ├── HarvestingSystem (runtime)
│   ├── BuildingSystem (runtime)
│   └── CraftingSystem (runtime)
├── SettingsMenu (Control)
└── PerformanceHUD (CanvasLayer)
```

### Autoload Singletons
```
AudioManager     → res://audio_manager.gd
MusicManager     → res://music_manager.gd
AmbientManager   → res://ambient_manager.gd
RumbleManager    → res://rumble_manager.gd
SettingsManager  → res://settings_manager.gd
WeatherManager   → res://weather_manager.gd    # NEW
```

### Class Definitions (class_name)
| Class | File | Purpose |
|-------|------|---------|
| `ChunkManager` | chunk_manager.gd | Terrain chunk loading/unloading |
| `Chunk` | chunk.gd | Individual terrain chunk |
| `VegetationSpawner` | vegetation_spawner.gd | Procedural vegetation |
| `CritterSpawner` | critter_spawner.gd | Critters and enemy spawning |
| `HarvestingSystem` | harvesting_system.gd | Resource gathering |
| `CraftingSystem` | crafting_system.gd | Item crafting |
| `ToolSystem` | tool_system.gd | Tool/weapon management |
| `Inventory` | inventory.gd | Item storage |
| `HealthHungerSystem` | health_hunger_system.gd | Player stats |
| `HarvestableResource` | resource_node.gd | Base resource class |
| `HarvestableTree` | harvestable_tree.gd | Tree resources |
| `HarvestableMushroom` | harvestable_mushroom.gd | Mushroom resources |
| `HarvestableStrawberry` | harvestable_strawberry.gd | Strawberry resources |
| `Enemy` | enemy.gd | Base enemy class |
| `Weapon` | weapon.gd | Weapon resource data |
| `PixelTextureGenerator` | pixel_texture_generator.gd | Procedural textures |

---

## 3. SYSTEM BREAKDOWN

### 3.1 World Generation System

**ChunkManager** (`chunk_manager.gd`)
- Manages chunk loading/unloading based on player position
- Uses FastNoiseLite for terrain height, temperature, moisture
- Emits `chunk_unloaded` signal for cleanup coordination

```gdscript
# Key exports
@export var chunk_size: int = 16
@export var view_distance: int = 4
@export var biome_scale: float = 0.01

# Key signals
signal chunk_unloaded(chunk_pos: Vector2i)

# Key methods
func world_to_chunk(world_pos: Vector3) -> Vector2i
func calculate_terrain_height_at_position(x, z) -> float
func update_view_distance(new_distance: int)
```

**Biomes** (determined in Chunk):
| ID | Name | Conditions |
|----|------|------------|
| 0 | OCEAN | height < ocean_threshold |
| 1 | BEACH | height < beach_threshold |
| 2 | GRASSLAND | default lowland |
| 3 | FOREST | high moisture |
| 4 | DESERT | high temp + low moisture |
| 5 | MOUNTAIN | height > mountain_threshold |
| 6 | SNOW | mountain + cold temp |

---

### 3.2 Weather System (v0.8.0)

**WeatherManager** (`weather_manager.gd`) - Autoload Singleton
- Manages weather state machine with 9 weather types
- Biome-specific weather probabilities
- Controls particle visibility (does NOT create particles)
- Smooth transitions between weather states

```gdscript
# Weather states
enum Weather {
    CLEAR, CLOUDY, RAIN, STORM, FOG, SNOW, BLIZZARD, SANDSTORM
}

# Key signals
signal weather_changed(old_weather, new_weather)
signal weather_transition_started(from, to, duration)

# Key methods
func set_rain_particles(particles: GPUParticles3D)
func set_storm_particles(particles: GPUParticles3D)
func set_snow_particles(particles: GPUParticles3D)
func set_blizzard_particles(particles: GPUParticles3D)
```

**WeatherParticles** (`weather_particles.gd`) - Scene Node
- **CRITICAL:** Must be manually added as Node3D in World scene (NOT .tscn)
- Creates and manages GPUParticles3D for rain, storm, snow, blizzard
- Registers particles with WeatherManager via set_*_particles()
- Minecraft-style: stays in area, repositions on teleport (>200 units)

```gdscript
# Particle configuration
| Weather  | Amount  | Size        | Gravity         | Coverage |
|----------|---------|-------------|-----------------|----------|
| Rain     | 12,000  | 0.06 x 1.8  | -25 (down)      | 200x200  |
| Storm    | 20,000  | 0.08 x 2.5  | -40 + angle     | 240x240  |
| Snow     | 8,000   | 0.2 x 0.2   | -3 + drift      | 200x200  |
| Blizzard | 18,000  | 0.25 x 0.25 | -8 + horiz wind | 240x240  |
```

**IMPORTANT - GPUParticles3D Gotcha:**
- Particles MUST be created as children of manually-added Node3D
- Instantiated .tscn scenes cause particles to freeze
- Never change `amount` at runtime (breaks simulation)
- Only toggle `visible`, never toggle `emitting`
- Set large `visibility_aabb` to prevent culling

---

### 3.3 Vegetation System (v0.7.1 Modular Refactor)

**VegetationSpawner** (`vegetation/vegetation_spawner.gd`)
- Populates chunks with vegetation as player explores
- Two-pass: large vegetation (trees/rocks) then ground cover (grass/flowers)
- Uses MultiMesh for grass (1 draw call per chunk)
- Cleans up when chunks unload via `chunk_unloaded` signal
- **Creates harvestable nodes with proper collision**

**Modular File Structure:**
```
vegetation/
├── vegetation_spawner.gd      # Main spawner + harvestable creation
├── vegetation_types.gd        # VegType enum
├── biome_spawn_rules.gd       # Biome configurations
└── meshes/
    ├── forest_meshes.gd       # create_mushroom_visual()
    ├── plant_meshes.gd        # create_strawberry_visual()
    ├── rock_meshes.gd         # Decorative rocks
    ├── tree_meshes.gd
    ├── ground_cover_meshes.gd
    ├── desert_meshes.gd
    └── snow_meshes.gd
```

**Import Pattern:**
```gdscript
# vegetation_spawner.gd
const VT = preload("res://vegetation/vegetation_types.gd")
const ForestMeshes = preload("res://vegetation/meshes/forest_meshes.gd")
const PlantMeshes = preload("res://vegetation/meshes/plant_meshes.gd")

# Harvestable classes (REQUIRED for proper harvesting)
const HarvestableMushroomClass = preload("res://harvestable_mushroom.gd")
const HarvestableStrawberryClass = preload("res://harvestable_strawberry.gd")
const ResourceNodeClass = preload("res://resource_node.gd")
```

**Harvestable Creation Pattern:**
```gdscript
# Spawner creates full harvestable node
func create_harvestable_strawberry(mesh_instance, bush_size):
    var strawberry = HarvestableStrawberryClass.new()
    strawberry.collision_layer = 2  # REQUIRED for raycast
    
    var visual = MeshInstance3D.new()
    strawberry.add_child(visual)
    PlantMeshes.create_strawberry_visual(visual, size)  # Visual only
    
    # Add CollisionShape3D, register for cleanup...
```

**Key Exports (Survival-Balanced):**
```gdscript
@export var rock_density: float = 0.08       # Rare
@export var mushroom_density: float = 0.04   # Rarest
@export var strawberry_density: float = 0.06 # Rare
@export var forest_mushroom_density: float = 0.10
@export var grassland_strawberry_density: float = 0.12
```

**Vegetation Types (VegType enum):**
```gdscript
enum VegType {
    TREE, PINE_TREE, PALM_TREE,
    ROCK, SMALL_ROCK, BOULDER, SNOW_ROCK,
    GRASS_TUFT, GRASS_PATCH,
    MUSHROOM_RED, MUSHROOM_BROWN, MUSHROOM_CLUSTER,
    STRAWBERRY_BUSH_SMALL, STRAWBERRY_BUSH_MEDIUM, STRAWBERRY_BUSH_LARGE,
    WILDFLOWER_YELLOW, WILDFLOWER_PURPLE, WILDFLOWER_WHITE
}
```

**Tree Visuals** (separate files):
- `tree_visual.gd` - Deciduous trees
- `pine_tree_visual.gd` - Coniferous trees
- `palm_tree_visual.gd` - Tropical trees

---

### 3.4 Critter & Enemy Spawner

**CritterSpawner** (`critter_spawner.gd`)
- Spawns both passive critters AND hostile enemies
- Biome-specific spawn tables
- Day/night awareness (fireflies at night, shadow wraith night-only)
- Pack spawning support (wolf packs)
- Debug hotkeys for testing (1-6 keys)

```gdscript
# Critter types
enum CritterType {
    RABBIT, BUTTERFLY, EAGLE, CRAB,
    LIZARD, FOX, ARCTIC_FOX, FIREFLY
}

# Key exports - Critter density
@export var rabbit_density: float = 0.15
@export var butterfly_density: float = 0.25
@export var firefly_density: float = 0.30
@export var critters_per_chunk: int = 4
@export var spawn_radius_chunks: int = 3

# Key exports - Enemy spawn rates
@export var corrupted_rabbit_spawn_rate: float = 0.15  # Forest
@export var forest_goblin_spawn_rate: float = 0.08     # Forest
@export var desert_scorpion_spawn_rate: float = 0.12   # Desert
@export var ice_wolf_pack_spawn_rate: float = 0.10     # Snow (2-3 wolves)
@export var stone_golem_spawn_rate: float = 0.05       # Mountain
@export var shadow_wraith_spawn_rate: float = 0.08     # Night only (all biomes)

# Key methods
func spawn_enemies_in_chunk(chunk_pos: Vector2i)
func spawn_single_enemy(enemy_type: String, position: Vector3, chunk_pos: Vector2i)
func spawn_wolf_pack(center_pos: Vector3, chunk_pos: Vector2i)
func is_night_time() -> bool
```

**Enemy Scene Files Required:**
- `corrupted_rabbit.tscn` - Fast aggressive rabbit (Forest)
- `forest_goblin.tscn` - Melee ambusher (Forest)
- `desert_scorpion.tscn` - Poison attacks (Desert)
- `ice_wolf.tscn` - Pack hunter (Snow)
- `stone_golem.tscn` - Slow tank (Mountain)
- `shadow_wraith.tscn` - Night-only ghost (All biomes)

---

## 6. CODE PATTERNS

### 6.1 System Initialization Pattern
```gdscript
# Systems are created in Player._ready() and initialized with references
func _ready():
    # Create system
    harvesting_system = HarvestingSystem.new()
    add_child(harvesting_system)
    
    # Initialize with dependencies
    harvesting_system.initialize(self, camera, inventory, tool_system)
```

### 6.2 Signal Connection Pattern
```gdscript
# Connect signals after system creation
if not chunk_manager.chunk_unloaded.is_connected(_on_chunk_unloaded):
    chunk_manager.chunk_unloaded.connect(_on_chunk_unloaded)
```

### 6.3 Resource Cleanup Pattern
```gdscript
# Track nodes for cleanup
var tracked_nodes: Dictionary = {}  # key -> Array of nodes

func spawn_node(key, node):
    if not tracked_nodes.has(key):
        tracked_nodes[key] = []
    tracked_nodes[key].append(node)

func cleanup(key):
    if tracked_nodes.has(key):
        for node in tracked_nodes[key]:
            if is_instance_valid(node):
                node.queue_free()
        tracked_nodes.erase(key)
```

### 6.4 Raycast Pattern
```gdscript
func check_for_target() -> Node:
    var space_state = get_world_3d().direct_space_state
    var from = camera.global_position
    var to = from + camera.global_transform.basis.z * -raycast_distance
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Layer 2 for resources
    
    var result = space_state.intersect_ray(query)
    if result:
        return result.collider
    return null
```

### 6.5 GPUParticles3D Pattern (Weather)
```gdscript
# CRITICAL: Particles must be children of manually-added Node3D
# DO NOT instantiate from .tscn - causes particles to freeze

func _create_rain():
    rain_particles = GPUParticles3D.new()
    rain_particles.name = "Rain"
    add_child(rain_particles)
    
    # Set properties BEFORE first frame
    rain_particles.amount = 12000
    rain_particles.lifetime = 3.5
    rain_particles.emitting = true
    rain_particles.visible = false  # WeatherManager controls this
    rain_particles.visibility_aabb = AABB(Vector3(-150, -80, -150), Vector3(300, 160, 300))
    
    var mat = ParticleProcessMaterial.new()
    mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    mat.emission_box_extents = Vector3(100, 0.1, 100)
    mat.gravity = Vector3(0, -25, 0)
    rain_particles.process_material = mat
    
    # Mesh setup...
```

### 6.6 Visibility Culling Pattern
```gdscript
# Set on MeshInstance3D for GPU-based culling
mesh_instance.visibility_range_end = 80.0
mesh_instance.visibility_range_end_margin = 12.0  # 15% fade margin
mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
```

### 6.7 Controller Input Pattern
```gdscript
# Always check both keyboard and controller
func _process(delta):
    # Movement - combine keyboard and stick input
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    
    # Also check controller sticks
    var stick_x = Input.get_axis("controller_move_left", "controller_move_right")
    if abs(stick_x) > abs(input_dir.x):
        input_dir.x = stick_x
```

---

## 7. EXTENSION POINTS

### Adding a New Biome
1. Add biome ID constant in `chunk.gd`
2. Add threshold exports in `chunk_manager.gd`
3. Add biome detection logic in `Chunk.determine_biome()`
4. Add terrain material in `PixelTextureGenerator.get_biome_terrain_material()`
5. Add vegetation rules in `vegetation_spawner.gd` spawn functions
6. Add ambient sounds in `ambient_manager.gd` BIOME_AMBIENTS
7. Add weather probabilities in `weather_manager.gd` BIOME_WEATHER_WEIGHTS

### Adding a New Weather Type
1. Add to `Weather` enum in `weather_manager.gd`
2. Add to `BIOME_WEATHER_WEIGHTS` dictionary
3. Create particle system in `weather_particles.gd`
4. Add set_*_particles() method in WeatherManager
5. Update `_update_particle_systems()` to show/hide new particles

### Adding a New Resource Type
1. Create new class extending `HarvestableResource`
2. Override `create_visual()`, `get_drops()`, `get_info()`
3. Preload in `vegetation_spawner.gd`
4. Add spawn logic in appropriate biome function
5. Add to VegType enum if needed

### Adding a New Enemy Type
1. Create new class extending `Enemy`
2. Override virtual methods: `create_enemy_visual()`, `on_attack_*()`, `on_hit()`, `on_death()`
3. Set exports: `max_health`, `damage`, `move_speed`, etc.
4. Add spawn logic (likely in a future EnemySpawner)
5. Add to loot drop table

### Adding a New Tool
1. Add to `Tool` enum in `tool_system.gd`
2. Add data to `TOOL_DATA` dictionary
3. Add crafting recipe in `crafting_system.gd`
4. Add visual ID mapping in `get_tool_visual_id()`

### Adding a New Crafting Recipe
```gdscript
# In crafting_system.gd
var recipes = {
    "new_item": {
        "inputs": {"wood": 5, "stone": 3},
        "output_count": 1
    }
}
```

---

## 8. PERFORMANCE CONSIDERATIONS

### Current Targets (v0.8.0)
| Metric | Target | Current |
|--------|--------|---------|
| FPS | 60 | ✅ 60 |
| Draw Calls | <500 | ⚠️ 4,400-6,300 |
| Objects | <2,000 | ⚠️ 4,600-6,500 |
| Nodes | <10,000 | ✅ 8,100-9,900 |

### Performance Patterns

**MultiMesh for Instanced Objects**
- Grass uses chunk-level MultiMesh (1 draw call per chunk)
- Small rocks could use same pattern (if non-harvestable)

**Visibility Culling**
- All vegetation has `visibility_range_end` set
- Flowers: 35m, Small rocks: 40m, Trees: 80-120m
- Uses GPU culling (zero CPU overhead)

**Vegetation Cleanup**
- Chunks emit `chunk_unloaded` signal
- VegetationSpawner tracks nodes per chunk
- Nodes freed when chunk unloads

**Weather Particles**
- Use GPUParticles3D (GPU-accelerated)
- Large visibility_aabb prevents culling issues
- Only toggle visible, never amount or emitting

**Density Controls**
- All vegetation densities are `@export` vars
- Can be tuned without code changes
- Current values reduced from original for performance

### Future Optimization Opportunities
1. **Tree Billboard LOD** - Replace distant trees with 2D sprites
2. **Material Caching** - Reuse materials instead of creating new
3. **Decorative Rock MultiMesh** - Separate decorative from harvestable
4. **Quality Presets** - User-selectable performance tiers

---

## 9. COLLISION LAYERS

| Layer | Name | Usage |
|-------|------|-------|
| 1 | Terrain | Chunk meshes, ground |
| 2 | Resources | Harvestable resources (trees, rocks, mushrooms) |
| 3 | Interactive | Containers, doors |
| 8 | Critters | Passive creatures (player passes through) |
| 9 | Enemies | Hostile creatures |

---

## 10. INPUT ACTIONS

### Keyboard + Mouse
| Action | Key |
|--------|-----|
| Move | WASD |
| Jump | Space |
| Sprint | Shift |
| Look | Mouse |
| Attack | LMB |
| Interact/Harvest | E |
| Inventory | I |
| Crafting | C |
| Settings | F1 |
| Perf HUD | F3 |
| Weather Status | F4 |
| Cycle Weather | F5 |
| Random Weather | F6 |
| Cancel/Back | ESC |

### Xbox Controller
| Action | Button |
|--------|--------|
| Move | Left Stick |
| Look | Right Stick |
| Jump/Interact | A |
| Attack | RT |
| Heavy Attack | LT |
| Sprint | B (hold) |
| Inventory | Y |
| Crafting | X |
| Cycle Tool | RB/LB |
| Cancel/Back | Start/B |

---

*Document Version: 0.8.1*
*Last Updated: Weather Particle System Implementation*
