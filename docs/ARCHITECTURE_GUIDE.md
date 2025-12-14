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
RumbleManager    → res://rumble_manager.gd
SettingsManager  → res://settings_manager.gd
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

### 3.2 Vegetation System

**VegetationSpawner** (`vegetation_spawner.gd`)
- Populates chunks with vegetation as player explores
- Two-pass: large vegetation (trees/rocks) then ground cover (grass/flowers)
- Uses MultiMesh for grass (1 draw call per chunk)
- Cleans up when chunks unload via `chunk_unloaded` signal

```gdscript
# Key exports
@export var grass_density: float = 0.35
@export var spawn_radius: int = 2
@export var ground_cover_samples_per_chunk: int = 25

# Vegetation types
enum VegType {
    TREE, PINE_TREE, PALM_TREE,
    ROCK, SMALL_ROCK, BOULDER,
    GRASS_TUFT, GRASS_PATCH,
    MUSHROOM_RED, MUSHROOM_BROWN,
    STRAWBERRY_BUSH_SMALL/MEDIUM/LARGE,
    WILDFLOWER_YELLOW/PURPLE/WHITE
}

# Key tracking
var populated_chunks: Dictionary = {}  # chunk_pos -> Array of nodes
```

**Tree Visuals** (separate files):
- `tree_visual.gd` - Deciduous trees
- `pine_tree_visual.gd` - Coniferous trees
- `palm_tree_visual.gd` - Tropical trees

---

### 3.3 Critter & Enemy Spawner

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

### 3.4 Player Systems

**Player** (`player.gd`)
- CharacterBody3D with first-person camera
- Manages all player subsystems
- Handles input routing (movement, UI, interaction)
- Death/respawn system

```gdscript
# Key systems (created at runtime)
var inventory: Inventory
var health_hunger_system: HealthHungerSystem
var harvesting_system: HarvestingSystem
var building_system: BuildingSystem
var crafting_system: CraftingSystem
var tool_system: ToolSystem
var combat_system: CombatSystem

# Key methods
func take_damage(amount: int)
func _on_player_died()
func _on_respawn_requested()
```

**HealthHungerSystem** (`health_hunger_system.gd`)
- Tracks health and hunger
- Hunger drains over time, causes damage at 0
- Emits signals for UI updates

```gdscript
signal health_changed(current, max_val)
signal hunger_changed(current, max_val)
signal player_died

func take_damage(amount: float)
func heal(amount: float)
func eat_food(hunger_amount: int) -> bool
func get_movement_speed_multiplier() -> float
```

**Inventory** (`inventory.gd`)
- Dictionary-based item storage
- Stack limits per item type
- Signals for UI updates

```gdscript
signal inventory_changed
signal inventory_full(item_name: String)

func add_item(item_name: String, amount: int) -> bool
func remove_item(item_name: String, amount: int) -> bool
func has_item(item_name: String, amount: int) -> bool
func get_item_count(item_name: String) -> int
```

---

### 3.4 Tool & Weapon System

**ToolSystem** (`tool_system.gd`)
- Unified tool/weapon management
- Tools serve both harvesting AND combat purposes
- Cycle with RB/LB buttons

```gdscript
enum Tool {
    STONE_AXE,      # Chops wood, 18 dmg
    STONE_PICKAXE,  # Mines stone, 12 dmg
    WOODEN_CLUB,    # Combat only, 15 dmg
    STONE_SPEAR,    # Combat, 20 dmg, 3.5m reach
    BONE_SWORD      # Best combat, 25 dmg
}

# Key methods
func cycle_tool()
func get_combat_damage() -> int
func get_combat_range() -> float
func can_harvest(resource_type: String) -> bool
```

---

### 3.5 Harvesting System

**HarvestingSystem** (`harvesting_system.gd`)
- Raycast-based target detection
- Tool requirement checking
- Visual highlighting (shader-based outline)
- Progress bar for harvest duration

```gdscript
signal harvest_completed(resource: HarvestableResource, drops: Dictionary)
signal harvest_started(resource: HarvestableResource)
signal harvest_cancelled

# Key methods
func start_harvest()
func cancel_harvest()
func is_looking_at_resource() -> bool
```

**HarvestableResource** (base class in `resource_node.gd`)
- Extended by: HarvestableTree, HarvestableMushroom, HarvestableStrawberry
- Collision layer 2 for raycast detection
- Emits `harvested` signal with drops

---

### 3.6 Combat System

**CombatSystem** (`combat_system.gd` - node on Player)
- Raycast-based enemy targeting
- Uses ToolSystem for damage/range
- Camera shake on hit
- Attack cooldown

```gdscript
func initialize(player, camera, health_system)
func attack()  # RT trigger
func shake_camera(intensity, duration)
```

**Enemy** (`enemy.gd`)
- Base class for all enemies
- State machine: IDLE → CHASE → ATTACK → DEATH
- Detection/deaggro ranges
- Loot drop table
- Virtual methods for customization:

```gdscript
# Override in subclasses
func create_enemy_visual()
func on_attack_telegraph()
func on_attack_execute()
func on_hit()
func on_death()
```

---

### 3.7 Crafting System

**CraftingSystem** (`crafting_system.gd`)
- Recipe-based crafting
- Checks inventory for ingredients
- Consumes inputs, produces outputs

```gdscript
# Recipe format
var recipes = {
    "stone_pickaxe": {
        "inputs": {"wood": 3, "stone": 5},
        "output_count": 1
    }
}

func can_craft(recipe_name: String) -> bool
func craft(recipe_name: String) -> bool
func get_missing_ingredients(recipe_name: String) -> Dictionary
```

---

### 3.8 Audio System

**AudioManager** (autoload singleton)
- Bus-based volume control (Master, SFX, Music, Ambient, UI)
- Sound variants support (footstep_grass_1, footstep_grass_2, etc.)
- Crossfade for music transitions
- Ambient loop management

```gdscript
func play_sound(name, bus, spatial, random_pitch)
func play_sound_variant(base_name, count, bus, spatial, random_pitch)
func play_music(track_name, fade_duration)
func play_ambient_loop(name, volume)
func stop_ambient_loop(name, fade_duration)
```

**MusicManager** (`music_manager.gd`)
- Day/night music rotation
- Crossfade transitions at dawn/dusk
- Track variety (avoids repeats)

**AmbientManager** (`ambient_manager.gd`)
- Biome-aware ambient sounds
- Time-of-day specific (birds day, crickets night)
- Frequency-based playback (not constant)

---

### 3.9 Settings System

**SettingsManager** (autoload singleton)
- Persists to user://settings.cfg
- Categories: display, graphics, performance, audio
- Quality presets (Low/Medium/High/Ultra)

**SettingsMenu** (`settings_menu.gd`)
- Tabbed UI (Display, Graphics, Performance, Audio)
- Apply/Cancel/Reset workflow
- Runtime setting application

---

## 4. SIGNAL FLOW

### Resource Harvesting Flow
```
Player Input (A/LMB)
    ↓
HarvestingSystem.start_harvest()
    ↓
HarvestableResource.start_harvest()
    ↓
[Progress over time]
    ↓
HarvestableResource.complete_harvest()
    ↓
HarvestableResource.harvested.emit(drops)
    ↓
Inventory.add_item()
    ↓
Inventory.inventory_changed.emit()
    ↓
InventoryUI.refresh_grid()
```

### Combat Flow
```
Player Input (RT)
    ↓
CombatSystem.attack()
    ↓
Raycast for enemies
    ↓
Enemy.take_damage(amount)
    ↓
Enemy.flash_white()
    ↓
[If health <= 0]
    ↓
Enemy.die()
    ↓
Enemy.drop_loot()
    ↓
Enemy.fade_out()
    ↓
Enemy.queue_free()
```

### Chunk Lifecycle Flow
```
Player moves
    ↓
ChunkManager.update_chunks()
    ↓
[New chunk needed]
    ↓
ChunkManager.load_chunk()
    ↓
Chunk.generate_mesh()
    ↓
VegetationSpawner.populate_chunk()
    ↓
[Player moves away]
    ↓
ChunkManager.unload_chunk()
    ↓
ChunkManager.chunk_unloaded.emit()
    ↓
VegetationSpawner._on_chunk_unloaded()
    ↓
[Cleanup vegetation nodes]
```

---

## 5. FILE ORGANIZATION

```
res://
├── project.godot
├── world.tscn / world.gd          # Main scene
├── player.tscn / player.gd        # Player scene
│
├── # CORE SYSTEMS
├── chunk_manager.gd               # Terrain management
├── chunk.gd                       # Individual chunk
├── vegetation_spawner.gd          # Vegetation system
├── critter_spawner.gd             # Critters AND enemies
│
├── # PLAYER SYSTEMS
├── health_hunger_system.gd
├── inventory.gd
├── harvesting_system.gd
├── crafting_system.gd
├── tool_system.gd
├── combat_system.gd
├── building_system.gd
│
├── # RESOURCES
├── resource_node.gd               # Base harvestable
├── harvestable_tree.gd
├── harvestable_mushroom.gd
├── harvestable_strawberry.gd
│
├── # ENEMIES
├── enemy.gd                       # Base enemy class
├── corrupted_rabbit.tscn / .gd    # Forest enemy
├── forest_goblin.tscn / .gd       # Forest enemy
├── desert_scorpion.tscn / .gd     # Desert enemy
├── ice_wolf.tscn / .gd            # Snow enemy (pack)
├── stone_golem.tscn / .gd         # Mountain enemy
├── shadow_wraith.tscn / .gd       # Night enemy (all biomes)
│
├── # AUDIO
├── audio_manager.gd               # Autoload
├── music_manager.gd
├── ambient_manager.gd
├── rumble_manager.gd              # Controller haptics
│
├── # UI
├── inventory_ui.tscn / .gd
├── crafting_ui.tscn / .gd
├── harvest_ui.tscn / .gd
├── health_ui.tscn / .gd
├── settings_menu.tscn / .gd
├── performance_hud.gd
│
├── # VISUALS
├── pixel_texture_generator.gd     # Procedural textures
├── vegetation/
│   └── visuals/
│       ├── tree_visual.gd
│       ├── pine_tree_visual.gd
│       └── palm_tree_visual.gd
│
├── # ASSETS
├── music/                         # .ogg/.mp3 files
├── sfx/                           # .wav files
└── shaders/
    └── resource_outline.gdshader
```

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

### 6.5 Procedural Mesh Pattern
```gdscript
func create_mesh() -> Mesh:
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Add vertices
    surface_tool.set_uv(Vector2(0, 0))
    surface_tool.add_vertex(Vector3(0, 0, 0))
    # ... more vertices
    
    surface_tool.generate_normals()
    return surface_tool.commit()
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

### Current Targets (v0.7.0 achieved)
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

*Document Version: 0.7.0*
*Last Updated: Post-Performance Sprint*
