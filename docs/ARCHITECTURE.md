# Crimson Veil - Architecture Guide

**Reference this when working on core systems or making architectural decisions.**

---

## Architecture Overview

Crimson Veil follows a **modular, signal-based architecture** inspired by Godot best practices. Systems communicate through signals rather than direct dependencies, making the codebase maintainable and testable.

### Core Principles

1. **Signal-Based Communication**
   - Systems emit signals for state changes
   - Other systems connect to signals they care about
   - No direct dependencies between major systems

2. **Component Composition**
   - Player has Inventory component (not inheritance)
   - Harvesting system is separate from player movement
   - Building system is independent module

3. **AutoLoad Singletons**
   - Global systems accessible everywhere
   - Examples: AudioManager, MusicManager, AmbientManager
   - Use sparingly - only for truly global state

4. **Procedural Generation**
   - Visual generators are static class methods
   - Stateless where possible
   - Pass parent references for parameters

---

## System Architecture

### 1. Player System (`scripts/player/`)

**Main Files:**
- `player.gd` - Core controller (movement, input, state)
- `player_inventory.gd` - Inventory component (items, stacks)
- `player_camera.gd` - Camera controller (look, zoom)

**Key Signals:**
```gdscript
# Player signals
signal died()
signal respawned()
signal health_changed(old_value, new_value)
signal hunger_changed(old_value, new_value)

# Inventory signals (from player_inventory.gd)
signal item_added(item_type: String, amount: int)
signal item_removed(item_type: String, amount: int)
signal inventory_changed()
```

**Architecture Notes:**
- Player uses composition - has Inventory, not extends Inventory
- Movement code separate from interaction code
- Camera is child node with own controller

---

### 2. Harvesting System (`scripts/resources/`)

**Main Files:**
- `harvesting_system.gd` - Core harvesting logic
- `harvestable_resource.gd` - Base class for resources
- `harvestable_tree.gd` - Tree-specific behavior
- `harvestable_rock.gd` - Rock-specific behavior

**Key Signals:**
```gdscript
# Emitted by harvesting_system.gd
signal resource_harvested(resource_type: String, amount: int, position: Vector3)
signal harvest_started(resource: Node)
signal harvest_completed(resource: Node)
signal wrong_tool_used(resource: Node)

# Emitted by harvestable resources
signal health_changed(new_health: float, max_health: float)
signal destroyed()
```

**Tool Requirements:**
- Trees require axe
- Rocks require pickaxe
- Mushrooms/strawberries require no tool
- Wrong tool = no progress + audio feedback

**Architecture Notes:**
- Resources are RigidBody3D with collision layers
- Health system per resource
- Audio integration through AudioManager
- Particle effects on completion

---

### 3. Building System (`scripts/building/`)

**Main Files:**
- `building_system.gd` - Core building logic
- `placed_block.gd` - Individual block behavior
- `building_preview.gd` - Ghost preview visual

**Key Signals:**
```gdscript
signal block_placed(block_type: String, position: Vector3)
signal block_removed(position: Vector3)
signal build_mode_toggled(enabled: bool)
signal selected_block_changed(block_type: String)
```

**Block Types:**
- Foundation (4 wood) - Structural base
- Wall (3 wood) - Vertical construction
- Floor (2 wood) - Horizontal platform
- Chest (10 wood) - Storage container

**Architecture Notes:**
- Grid-based placement (1m grid)
- Preview shows valid/invalid placement
- D-Pad for block selection
- Containers are special blocks with inventory

---

### 4. Inventory System (`scripts/player/`, `scripts/ui/`)

**Main Files:**
- `player_inventory.gd` - Data model (32 slots)
- `inventory_ui.gd` - Display and interaction
- `inventory.gd` - Reusable inventory class (for containers)

**Item Stacking:**
```gdscript
const STACK_LIMITS = {
    "wood": 100,
    "stone": 50,
    "mushroom": 20,
    "strawberry": 20,
    "axe": 1,
    "pickaxe": 1
}
```

**Key Signals:**
```gdscript
signal item_added(item_type: String, amount: int)
signal item_removed(item_type: String, amount: int)
signal item_picked_up(item_type: String, amount: int)
signal inventory_changed()
```

**Architecture Notes:**
- Dictionary-based storage: `{"slot_index": {"type": "wood", "amount": 50}}`
- Automatic stacking when adding items
- Reusable Inventory class for containers
- Separate UI layer for display

---

### 5. Container System (`scripts/building/`, `scripts/ui/`)

**Main Files:**
- `container.gd` - Container block with inventory
- `container_ui.gd` - Dual-panel UI
- `container_manager.gd` - Global container tracking

**Key Signals:**
```gdscript
signal container_opened(container: Node)
signal container_closed()
signal item_transferred(from_inventory: Inventory, to_inventory: Inventory, item_type: String, amount: int)
```

**Transfer Rules:**
- Click = transfer single item
- Shift+Click = transfer all of type
- B button = close container
- E on container = open (within 3m)

**Architecture Notes:**
- Each container has own Inventory instance (32 slots)
- Dual-panel UI shows player + container side-by-side
- Container highlighting uses Layer 3 collision
- Removal warning if container has items

---

### 6. Audio System (`scripts/autoload/`)

**Main Files:**
- `audio_manager.gd` - Core audio engine (393 lines)
- `music_manager.gd` - Day/night music (250 lines)
- `ambient_manager.gd` - Environmental sounds (400 lines)

**Volume Categories:**
```gdscript
const VOLUME_CATEGORIES = {
    "master": 0.0,    # Overall volume
    "sfx": -5.0,      # Punchy actions (harvesting, building)
    "music": -12.0,   # Background ambient music
    "ambient": -18.0, # Environmental loops (wind, birds)
    "ui": -8.0        # Interface sounds
}
```

**Key Features:**
- Sound pooling (max 10 concurrent sounds)
- Pitch variation (0.9-1.1x for natural feel)
- Music crossfading (30s duration)
- Ambient loops with occasional/rare frequency
- Biome-aware footsteps and ambient sounds

**API:**
```gdscript
AudioManager.play_sound(sound_name: String, pitch_variation: bool = true)
AudioManager.play_sound_variant(base_name: String, variant_count: int, pitch_variation: bool = true)
AudioManager.play_music(track_name: String, crossfade_duration: float = 5.0)
AudioManager.start_ambient_loop(sound_name: String, volume_db: float = 0.0)
AudioManager.stop_ambient_loop(sound_name: String, fade_duration: float = 1.0)
```

**Architecture Notes:**
- AutoLoad singleton pattern
- Sound library loaded on ready
- AudioStreamPlayer pool for sound effects
- Separate music and ambient players
- Integration points: harvesting, movement, building, UI

---

### 7. World Generation (`scripts/world/`)

**Main Files:**
- `world.gd` - Chunk management and loading
- `chunk.gd` - Terrain mesh generation
- `biome.gd` - Biome definitions and blending
- `vegetation_spawner.gd` - Tree/resource placement (1,457 lines)
- `tree_visual.gd` - Tree mesh generation (618 lines)
- `critter_spawner.gd` - Wildlife placement (1,143 lines)

**Biomes:**
- Grassland (central)
- Forest (common)
- Desert (hot, sparse)
- Beach (coastal)
- Mountain (high elevation)
- Snow (cold, high elevation)

**Generation Process:**
1. Noise-based height map
2. Biome assignment by temperature/moisture
3. Terrain mesh generation (vertex colors for tinting)
4. Vegetation spawning (trees, rocks, mushrooms, strawberries)
5. Wildlife spawning (rabbits, crabs)

**Chunk System:**
- 32x32 meter chunks
- Dynamic loading/unloading based on player position
- View distance: 5 chunks (160m radius)
- Collision layers for resources, terrain, buildings

**Architecture Notes:**
- Procedural generation using FastNoiseLite
- Mesh generation with SurfaceTool
- Resource placement uses rejection sampling
- Character trees (5% spawn rate) for atmosphere
- Critters spawn in biome-appropriate locations

---

### 8. Day/Night Cycle (`scripts/world/`)

**Main File:**
- `day_night_cycle.gd` - Time, sun/moon, clouds (829 lines)

**Time System:**
```gdscript
const MINUTES_PER_REAL_SECOND = 2.0  # 1 game day = 12 real minutes
const DAWN = 6.0   # 6:00 AM
const DUSK = 18.0  # 6:00 PM
```

**Key Features:**
- Directional light rotation (sun/moon)
- Sky color transitions (sunrise, day, sunset, night)
- Cloud system with procedural movement
- Ambient light adjustments
- Music transitions at dawn/dusk

**Key Signals:**
```gdscript
signal time_changed(hour: float)
signal day_night_changed(is_day: bool)
```

**Architecture Notes:**
- AutoLoad singleton
- Sun and moon as DirectionalLight3D
- Cloud mesh generation and movement
- Integration with MusicManager for transitions

---

### 9. UI System (`scripts/ui/`)

**Main Files:**
- `inventory_ui.gd` - Inventory display (373 lines)
- `container_ui.gd` - Container interface (424 lines)
- `crafting_ui.gd` - Crafting menu (264 lines)
- `health_hunger_ui.gd` - Status bars
- `tooltip.gd` - Item tooltips

**UI State Management:**
- B button toggles inventory
- E button opens containers
- Tab cycles through inventory tabs
- Crafting available in inventory
- Other UIs suppressed when container open

**Architecture Notes:**
- Scene-based UI components (.tscn files)
- Signal-based communication with game systems
- Controller-friendly navigation
- Visual feedback for invalid actions

---

## Collision Layers

**Layer Assignment:**
```
Layer 1: Terrain (ground)
Layer 2: Resources (trees, rocks, harvestable items)
Layer 3: Buildings (placed blocks, containers)
Layer 4: Player
Layer 5: Wildlife (critters)
```

**Interaction Rules:**
- Player collides with: Terrain (1), Buildings (3)
- Resources collide with: Terrain (1)
- Buildings collide with: Terrain (1), Player (4)
- Wildlife collides with: Terrain (1), Buildings (3)

**Raycasting:**
- Harvesting raycast: Layers 2 (resources)
- Building raycast: Layer 1 (terrain) for placement
- Container interaction: Layer 3 (buildings)

---

## Signal Communication Patterns

### Pattern 1: Resource Collection
```
1. Player harvests tree
2. HarvestingSystem emits resource_harvested(type, amount, position)
3. AudioManager plays sound
4. Inventory adds item
5. InventoryUI updates display
6. Particle effect spawns at position
```

### Pattern 2: Container Interaction
```
1. Player presses E near container
2. Container emits container_opened(container)
3. InventoryUI suppresses itself
4. ContainerUI shows dual-panel view
5. Player transfers items
6. ContainerUI emits item_transferred signal
7. Both inventories update
```

### Pattern 3: Building Placement
```
1. Player presses Q to enter build mode
2. BuildingSystem emits build_mode_toggled(true)
3. BuildingPreview becomes visible
4. Player places block
5. BuildingSystem emits block_placed(type, position)
6. AudioManager plays sound
7. Inventory removes materials
8. PlacedBlock node added to scene
```

---

## File Size Management

### Current Large Files
- `vegetation_spawner.gd` - 1,457 lines (main spawner, delegates to visuals)
- `critter_spawner.gd` - 1,143 lines (candidate for visual extraction)
- `day_night_cycle.gd` - 829 lines (cloud system could be extracted)
- `tree_visual.gd` - 618 lines (acceptable - pure visual generator)

### Refactoring Guidelines
1. **Only refactor when files exceed 800 lines**
2. **Extract self-contained functions first** (procedural generators, visual creators)
3. **Create appropriate folder structure** (e.g., `vegetation/visuals/`, `critters/visuals/`)
4. **Use static class methods for stateless generators**
5. **Pass parent object reference for parameter access**

### Extraction Pattern (from tree refactoring)
```
Before: vegetation_spawner.gd (2,075 lines)
After:
  - vegetation_spawner.gd (1,457 lines) - Placement logic
  - tree_visual.gd (618 lines) - Visual generation

Usage in spawner:
var mesh = TreeVisual.generate_tree_mesh(parent, tree_def, height, seed)
```

---

## AutoLoad Singletons

**Current Singletons:**
- `AudioManager` - Sound effects and music playback
- `MusicManager` - Day/night music rotation
- `AmbientManager` - Environmental sound loops
- `DayNightCycle` - Time progression and lighting
- `ContainerManager` - Global container tracking (future: save/load)

**When to Create a Singleton:**
- System needs global access (audio, time)
- Manages truly global state (containers, save data)
- No owner/parent relationship makes sense

**When NOT to Create a Singleton:**
- System belongs to player (inventory, health)
- System belongs to world (chunk loading)
- Can be a component instead

---

## Performance Considerations

### Optimization Strategies
1. **Object Pooling** - Reuse AudioStreamPlayers, particle systems
2. **Chunk Loading** - Only load chunks near player
3. **LOD System** - Lower detail for distant objects (future)
4. **Collision Optimization** - Disable collision on distant resources
5. **Batch Operations** - Spawn multiple resources in one frame

### Profiling Guidelines
- Monitor FPS (target: 60 FPS)
- Check draw calls (visible in debug overlay)
- Profile physics (RigidBody3D can be expensive)
- Test on lower-end hardware

---

## Testing Strategy

### Manual Testing
- F5 to run project
- F6 to run current scene
- Use debug features (F toggle flying)
- Test with both keyboard+mouse and controller

### Test Scenes
- `audio_manager_test.tscn` - Audio system verification
- Create test scenes for new systems

### Integration Testing
1. Test harvesting → inventory → crafting flow
2. Test building → removal → materials returned
3. Test container → transfer → inventory updates
4. Test day/night → music transitions → ambient changes

---

## Future Architecture Considerations

### Save/Load System (v0.6.0+)
- Serialize world state (chunks, resources, buildings)
- Save player state (inventory, position, health)
- Save container inventories
- Use JSON or binary format
- Consider compression for large worlds

### Combat System (Future)
- Enemy AI and pathfinding
- Weapon system separate from tools
- Health/damage system
- Combat audio and effects

### Multiplayer (Someday)
- Major architecture change
- Consider authoritative server
- State synchronization
- Network optimization

---

**For more details:**
- **Code conventions:** See `docs/STYLE_GUIDE.md`
- **Technical deep dives:** See `docs/TECHNICAL_DETAILS.md`
- **Implementation examples:** See actual source files
