# Crimson Veil - Development Guide

## Project Statistics

| Metric | Value |
|--------|-------|
| **Development Started** | December 7, 2025 |
| **Total Commits** | 85+ |
| **Current Version** | v0.4.0 (Released Dec 12, 2025) |
| **Code Quality Grade** | A (Opus 4.5 review, Dec 11, 2025) |
| **Primary Dev Model** | Claude Sonnet 4.5 |
| **Architecture Style** | Modular, signal-based, component systems |

---

## Session Start Checklist

**At the beginning of EVERY development session, Claude should:**

1. **Read this DEVELOPMENT_GUIDE.md** - Understand project vision and architecture
2. **Read ROADMAP.txt** - Check current sprint and planned features
3. **Read CHANGELOG.txt** - Review recent changes (last 5-10 entries)
4. **Display a session summary** with:
   - Current sprint items (from ROADMAP.txt "CURRENT SPRINT" section)
   - Recent changes (last 3-5 CHANGELOG entries)
   - Known issues (from ROADMAP.txt "BUGS / FIXES" section)
   - Brief reminder of next priorities
5. **Show the quick commands list below**
6. **Assess feature complexity** - Decide Sonnet vs Opus:
   - Implementation work, bug fixes, single-file changes â†’ **Sonnet**
   - Architecture decisions, code reviews, multi-system refactoring â†’ **Opus**

---

## AI Model Usage & Capacity Planning

### Model Selection Strategy

| Model | Best For | Weekly Capacity | Usage Per Session |
|-------|----------|-----------------|-------------------|
| **Sonnet** | Implementation, bug fixes, features | 45-55 sessions | ~2% |
| **Opus** | Architecture, reviews, complex refactoring | 3-4 sessions | ~25% |

### When to Use Each Model

**Sonnet (Primary Workhorse):**
- Single-file changes and bug fixes
- New feature implementation
- UI/UX modifications
- Balance tweaks and tuning
- Documentation updates
- Most day-to-day development

**Opus (Strategic Use Only):**
- Comprehensive code reviews
- Major architectural decisions
- Multi-system refactoring
- Complex debugging across many files
- Design pattern recommendations

### Feature Size Estimation

| Feature Size | Sessions Needed | Sonnet Usage | Examples |
|-------------|-----------------|--------------|----------|
| **Small** | 1 | ~2% | Bug fix, tweak, small UI change |
| **Medium** | 2 | ~4% | New system, new resource type |
| **Large** | 3 | ~6% | Multi-file feature, UI overhaul |

### Weekly Capacity Planning

With a fresh weekly reset, you can complete approximately:
- **25-30 small features** (bug fixes, tweaks)
- **12-15 medium features** (new systems)
- **8-10 large features** (multi-file implementations)

### Session Efficiency Tips

1. **Always upload DEVELOPMENT_GUIDE.md first** - Provides full context
2. **Request specific files before suggesting code** - Prevents integration issues
3. **One feature per session** - Clean commits, focused work
4. **Use commit preparation checklist at session end** - Ensures nothing is missed
5. **Track changes mentally during session** - Update docs only at commit time

### Development Velocity (Actual Data)

Based on project history (Dec 7-11, 2025):
- **81 commits in 4 days** with 43% Sonnet usage
- **~20 major features** implemented
- **Average: 1-3 sessions per feature**
- **Efficiency improved** as workflow was refined

For detailed capacity calculations, feature-to-session mapping, and weekly tracking templates, see **AI_USAGE_ANALYSIS.md**.

---

## Quick Commands

### ROADMAP Management
```
Add [feature] to roadmap under [priority/section]
Move [feature] from backlog to current sprint
Mark [feature] as completed
Add design question: [question]
Show roadmap priorities
What should I work on next?
```

**Example Session Start Output:**
```
ðŸŽ¯ CURRENT SPRINT: Storage & Organization
- Priority 1: Storage Containers âœ“ (complete)
- Priority 2: Inventory Improvements âœ“ (complete)
- Priority 3: Workbench Foundation (next up) [Sonnet]

ðŸ“ RECENT CHANGES:
[2025-12-12 05:50] [DOC] Added AI model annotations to ROADMAP.txt
[2025-12-12 05:45] [DOC] Created AI_USAGE_ANALYSIS.md
[2025-12-11 21:00] [MAJOR] Container UI Phase 2 complete

ðŸ› KNOWN ISSUES:
- Tree falling physics occasionally glitches on steep terrain
- Potential: Race condition if container destroyed while UI open

Ready to continue development!
```

This ensures every session starts with full context.

---

## Feature Implementation Workflow

**CRITICAL: When the user requests a new feature or modification, Claude should ALWAYS:**

1. **Consult the File Index** (see "Quick Reference" section below)
   - Identify which files are relevant to the feature
   - Determine which systems will be affected

2. **Request File Uploads BEFORE suggesting code**
   - Ask user to upload the specific files needed
   - Example: "To implement [feature], I'll need to see: `player.gd`, `inventory.gd`, and `crafting_system.gd`. Could you upload these files?"

3. **Analyze Existing Code**
   - Read uploaded files to understand current implementation
   - Check for existing patterns, naming conventions, architecture
   - Identify integration points and dependencies

4. **Only THEN suggest implementation**
   - Provide concrete code that integrates with existing systems
   - Follow established patterns from the codebase
   - Preserve existing functionality

5. **Update Documentation when creating NEW files**
   - If implementation adds new files, update the "File Index & Location Map" section
   - Add new files to appropriate category (Player Systems, UI Systems, etc.)
   - Include file descriptions
   - Update "When to upload" guidance for the new files
   - This keeps the guide accurate for future development sessions

### Examples:

**âŒ BAD - Suggesting code immediately:**
```
User: "Add a sleep system"
Claude: "Here's a sleep system implementation..."
```

**âœ… GOOD - Request files first:**
```
User: "Add a sleep system"
Claude: "To implement a sleep system, I'll need to analyze:
- player.gd (to add sleep input handling)
- day_night_cycle.gd (to skip time forward)
- health_hunger_system.gd (to restore stats on sleep)

Could you upload these three files so I can see how they're currently structured?"
```

**Why this matters:**
- Prevents code that doesn't integrate with existing systems
- Avoids breaking existing functionality
- Follows project conventions and patterns
- Produces working code on first try
- Keeps documentation up-to-date for future sessions

**âœ… GOOD - Including documentation update:**
```
User: "Add a sleep system"
Claude: 
[After analyzing files and implementing the system]

"I've created a new file: sleep_system.gd

I'm also updating the File Index in DEVELOPMENT_GUIDE.md to add:
- sleep_system.gd to the 'Player Systems' section
- Upload guidance for sleep-related features

This ensures future development sessions can easily find and work with the sleep system."
```

---

## Project Overview
- **Genre**: Open-world survival/crafting with exploration and base-building
- **Core Pillars**: 
  - Progression through biome exploration and resource gathering
  - Satisfying crafting loops (gather â†’ craft â†’ unlock new areas/tools)
  - Environmental storytelling through procedural world generation
  - Cozy base-building with functional purpose
- **Visual Style**: 
  - Low-poly geometric shapes with 16x16 pixel textures
  - Valheim-inspired: natural color palettes, soft lighting, atmospheric fog
  - Readable silhouettes - players should instantly recognize resources/threats
  - Handcrafted feel despite procedural generation
- **Inspiration**: 
  - Valheim: Viking survival, boss progression, build-anywhere freedom
  - Minecraft: Blocky aesthetic, chunk-based world, creative building
  - Don't Starve: Resource scarcity, seasonal challenges
  - Terraria: Biome variety, discovery-driven progression
- **Tone**: 
  - Mysterious but inviting - world feels ancient and full of secrets
  - Meditative gathering with moments of danger
  - Accomplishment-focused: every milestone feels earned
  - Cozy loneliness - peaceful solo experience
- **Target Experience**: 
  - "One more trip" gameplay loop (just need a few more resources...)
  - Calm exploration punctuated by discovery moments
  - Pride in building something functional AND beautiful
  - Sense of taming/understanding a wild world over time

## Game State & Systems

### Currently Implemented
- **World Generation**: Chunk-based terrain with 7 biomes, seamless edges, multi-layered noise
- **Harvesting System**: Raycast-based resource gathering with progress bars and visual feedback
- **Resources**: Trees (oak/pine/palm), rocks (3 sizes), mushrooms (3 variants), strawberries (3 sizes)
- **Physics**: Tree falling with log spawning, particle effects on harvest
- **Building System**: Grid-snapped block placement (stone/wood blocks, walls, floors, chests)
- **Environment**: Day/night cycle, clouds, fog, sun/moon, time-based wildlife (fireflies/butterflies)
- **Vegetation**: Procedural spawning with density controls, MultiMesh grass, biome-specific distributions
- **Settings**: Runtime graphics adjustments (view distance, fog, shadows, cloud count)
- **Crafting**: Recipe-based crafting system with 5 starter recipes
- **Inventory**: Grid-based UI with 32 slots, visual item display, item stacking with limits
- **Item Stacking**: Stack limits enforced (wood: 100, stone: 50, food: 20, tools: 1) with visual feedback
- **Tools**: Axe and pickaxe with requirement checking
- **Input**: Full Xbox controller support with analog stick movement/camera, button mappings for all actions, D-Pad dedicated to building
- **Health/Hunger**: Stat management, regeneration when well-fed, movement penalties, eating system
- **Storage Containers**: Placeable chests (10 wood) with independent 32-slot inventories, 3m interaction range, green highlight, removal warnings
- **Container UI**: Dual-panel interface with click/shift-click transfers, centered layout, UI suppression, ESC/B button to close, auto-close at 5m

### Currently In Development (Storage & Organization Sprint)
- **Workbench System**: Crafting station with proximity detection for recipe gating (Priority 3 - next up)

### Technical Debt (From Code Review - 2025-12-11)
HIGH PRIORITY:
- **Critter visual extraction**: Extract critter visuals to separate files following tree_visual.gd pattern
- **ITEM_COLORS consolidation**: Move duplicated dictionary from inventory_ui.gd and container_ui.gd to shared location
- **Container null safety**: Add validity checks if container destroyed while UI open

MEDIUM PRIORITY:
- **Input handling consolidation**: Use only Input Actions in player.gd (currently mixes methods)
- **Cloud system extraction**: Extract from day_night_cycle.gd to separate cloud_manager.gd
- **Debug output toggle**: Add debug flag to control print() statements

### Planned/Incomplete
- Boss encounters and progression milestones
- Base defense mechanics
- Advanced building pieces (roofs, windows, doors)
- Tool progression (pickaxe, axe tiers)
- Save/load system
- Weather systems beyond day/night
- Combat system
- UI navigation with controller (D-Pad inventory/crafting navigation)

### Known Issues
- Tree falling physics occasionally glitches on steep mountain terrain
- Building collision detection needs refinement for complex structures
- Chunk unloading can cause vegetation pop-in if view distance changes rapidly
- **Potential**: Race condition if container destroyed while UI open
- **Potential**: Input blocking too broad in player.gd (blocks ALL input when container open)

### Performance Considerations
- Target: 60 FPS on mid-range hardware
- Current bottlenecks: Vegetation spawning (mitigated by chunk caching), grass rendering (MultiMesh helps)
- View distance default: 3 chunks (configurable in settings)
- Material caching critical for glow effects (duplicate ONCE in _ready())

## Design Patterns & Architecture

### Core Architecture
- **Chunk-based world**: ChunkManager orchestrates terrain generation, VegetationSpawner populates
- **Component systems**: Player has child nodes for HarvestingSystem, BuildingSystem, Inventory
- **Resource inheritance**: HarvestableResource base class â†’ HarvestableTree/Mushroom/Strawberry
- **Signal-driven communication**: Harvest completion signals trigger inventory updates and particle spawning
- **Modular visual generators**: Tree creation delegated to separate visual generator classes (TreeVisual, PineTreeVisual, PalmTreeVisual)
- **Container architecture**: StorageContainer extends Node3D, has own Inventory instance, emits interaction signals

### Naming Conventions
- **Scripts**: snake_case (harvestable_tree.gd, chunk_manager.gd, storage_container.gd)
- **Classes**: PascalCase (HarvestableResource, ChunkManager, TreeVisual, StorageContainer)
- **Enums**: PascalCase for enum name, SCREAMING_SNAKE for values (Biome.GRASSLAND, TreeType.PINE)
- **Variables**: snake_case (tree_density, current_block_type, container_inventory)
- **Constants**: SCREAMING_SNAKE_CASE (TEXTURE_SIZE, MAX_HEIGHT, MAX_STACK_SIZE)

### Signal Patterns
```gdscript
# Resource systems emit signals for UI/feedback
signal harvest_started(resource: HarvestableResource)
signal harvest_completed(resource: HarvestableResource, drops: Dictionary)
signal harvest_cancelled()

# Player systems connect to these
harvesting_system.harvest_completed.connect(_on_harvest_completed)

# Container interaction signals
signal container_opened(container: StorageContainer)
signal container_closed(container: StorageContainer)
signal container_inventory_changed(container: StorageContainer)

# Player connects to container signals
storage_container.container_opened.connect(_on_container_opened)
```

### Performance Patterns
- **Material caching**: Duplicate materials ONCE in _ready(), store references, never per-frame
- **MultiMesh for repetition**: Grass uses MultiMesh (100+ instances), not individual nodes
- **Chunk population caching**: Dictionary tracks populated_chunks to prevent respawning
- **Deferred collision**: Always `call_deferred("create_collision")` after mesh generation
- **Raycast optimization**: Use calculated terrain height to narrow raycast window (+5/-5m vs +50/-50m)
- **Container queries**: Cache nearby containers list, only refresh on container placement/removal

### Collision Layer Architecture
- **Layer 1**: Terrain (player walks on this, buildings snap to this)
- **Layer 2**: Harvestable resources (player raycasts detect this)
- **Layer 3**: Interactive objects (containers, workbenches - player raycasts detect these)
- **Layer 8**: Critters (player passes through, purely visual)

### Code Organization Philosophy
- **Modular visual generators**: Large procedural mesh generators (300+ lines) should be extracted to separate files
- **Single responsibility**: Each file should have one primary purpose
- **AI-friendly file sizes**: Keep files under 500 lines when possible for better AI context window usage
- **Shared utilities**: Common mesh operations belong in `core/mesh_builder.gd`
- **Container pattern**: Interactable objects (chests, workbenches) follow similar structure to HarvestableResource

## Gameplay Balance Values

### Current Tuning (Base Values)
```gdscript
# Vegetation Density (0.0 = none, 1.0 = maximum)
tree_density = 0.35          # Forests feel full but navigable
rock_density = 0.25          # Natural scatter, not overwhelming
mushroom_density = 0.15      # Rare finds encourage exploration
strawberry_density = 0.20    # Common enough to sustain gathering
grass_density = 0.8          # Lush ground cover for atmosphere
flower_density = 0.15        # Colorful accents, not distracting

# Harvest Times (seconds to fully gather)
tree_harvest = 3.0           # Substantial but not tedious
mushroom_harvest = 0.5       # Quick pickups
strawberry_small = 0.5       # Quick
strawberry_medium = 0.8      # Standard
strawberry_large = 1.2       # Worthwhile for higher yield
rock_harvest = 2.0           # Medium effort

# Drop Rates
tree_wood = 8-15             # Enough for basic building
small_rock_stone = 1         # Tiny contributions
rock_stone = 3-5             # Decent haul
boulder_stone = 10-15        # Big payoff
mushroom = 1 (or 2-4 cluster) # Consumable resource
strawberry = 1-7 (size dependent) # Food resource

# Movement & Interaction
player_walk_speed = 5.0      # Feels grounded and deliberate
player_sprint_speed = 10.0   # Useful for exploration
player_fly_speed = 15.0      # Debug/creative mode
raycast_distance = 5.0       # Arm's reach for harvesting
placement_range = 5.0        # Same as raycast for consistency

# Storage & Crafting Balance
container_slot_count = 32    # Same as player inventory (small chest)
large_container_slots = 64   # Double capacity (future upgrade)
container_interaction_range = 3.0  # Must be closer than harvesting
workbench_radius = 5.0       # Recipe unlock proximity
workbench_placement_limit = 1 # Only one workbench initially

# Item Stack Sizes
wood_stack_size = 100        # Common building material
stone_stack_size = 50        # Common building material
food_stack_size = 20         # Consumables
tool_stack_size = 1          # Tools don't stack
```

### Biome Temperature & Moisture Ranges
```gdscript
# Temperature (-1.0 to 1.0, lower = colder)
SNOW: < -0.3
MOUNTAIN: -0.3 to 0.0
GRASSLAND: 0.0 to 0.4
FOREST: 0.0 to 0.4 (wetter than grassland)
DESERT: > 0.4
BEACH: Special case (near water)
OCEAN: Special case (below sea level)

# Moisture (-1.0 to 1.0, higher = wetter)
DESERT: < -0.2
GRASSLAND: -0.2 to 0.3
FOREST: > 0.3
```

## Biome System Details

### Biome-Specific Vegetation
```gdscript
OCEAN: None
BEACH: Palm trees, small rocks
GRASSLAND: Oak trees, grass, wildflowers, strawberries, rabbits
FOREST: Oak trees (dense), mushrooms, grass, strawberries, deer, foxes
DESERT: Cacti, small rocks, lizards
MOUNTAIN: Pine trees, boulders, rocks, eagles
SNOW: Pine trees (sparse), rocks, arctic foxes
```

## Feature Request Format

When suggesting new features, always include:

### Required Information
1. **Motivation**: Why does this feature support the core pillars?
2. **Player Experience**: What does this add to the "one more trip" loop?
3. **Scope**: Small/Medium/Large implementation
4. **Dependencies**: What systems need to exist first?
5. **Balance Considerations**: How does this affect progression/economy?

### Good Example
"Add stone walls for base building. Players want protection from future threats (base-building pillar). Like Valheim's walls but snapped to grid. Medium scope - needs collision, placement validation, cost balancing. Should require significant stone investment to prevent trivializing defense."

### Bad Example
"Add walls" â†’ Missing motivation, scope, balance considerations

## Quick Reference

### File Index & Location Map

This index helps you find and upload the right files for your task. Files are organized by system/purpose.

#### Core Systems (Always Needed)
```
res://
â”œâ”€â”€ DEVELOPMENT_GUIDE.md          [This file - architecture & conventions]
â”œâ”€â”€ ROADMAP.txt                   [Features, priorities, completed items]
â”œâ”€â”€ CHANGELOG.txt                 [Session-by-session change history]
â”œâ”€â”€ CODE_REVIEW.md                [Codebase analysis from Opus 4.5 review]
â”œâ”€â”€ AI_USAGE_ANALYSIS.md          [AI capacity planning & usage tracking]
â”œâ”€â”€ world.gd                      [Scene root, system initialization]
â”œâ”€â”€ player.gd                     [Input, movement, camera, controller support, UI state management]
â”œâ”€â”€ player.tscn                   [Player scene with health system, camera, collision]
â””â”€â”€ project.godot                 [Godot project config]
```

**When to upload:**
- Starting any session â†’ DEVELOPMENT_GUIDE.md (always)
- Sprint planning â†’ ROADMAP.txt + AI_USAGE_ANALYSIS.md
- Checking recent work â†’ CHANGELOG.txt
- Capacity planning â†’ AI_USAGE_ANALYSIS.md
- Code quality concerns â†’ CODE_REVIEW.md
- Adding controller support â†’ project.godot (for input actions)
- Modifying input mappings â†’ project.godot
- Player input/movement â†’ player.gd

#### World Generation
```
res://
â”œâ”€â”€ chunk_manager.gd              [Terrain generation, chunk loading]
â”œâ”€â”€ chunk.gd                      [Individual chunk meshes, biomes]
â””â”€â”€ water_plane.gd                [Infinite ocean plane]
```

#### Vegetation System (Modular - Upload Only What You Need)
```
res://
â”œâ”€â”€ vegetation_spawner.gd         [Large - main spawner, delegates to visuals]
â””â”€â”€ vegetation/visuals/
    â”œâ”€â”€ tree_visual.gd            [Oak/deciduous trees]
    â”œâ”€â”€ pine_tree_visual.gd       [Pine/conifer trees]
    â””â”€â”€ palm_tree_visual.gd       [Palm trees]
```

**When to upload:**
- Modifying oak trees â†’ `tree_visual.gd` only
- Adding new tree type â†’ Pick one as template + `vegetation_spawner.gd` + `mesh_builder.gd`
- Adjusting density â†’ `vegetation_spawner.gd` only
- Understanding system â†’ `DEVELOPMENT_GUIDE.md` has full explanation

#### Harvestable Resources
```
res://
â”œâ”€â”€ harvestable_resource.gd       [Base class for all collectibles]
â”œâ”€â”€ harvestable_tree.gd           [Tree physics, falling, log spawning]
â”œâ”€â”€ harvestable_mushroom.gd       [Mushroom variants, glow effects]
â”œâ”€â”€ harvestable_strawberry.gd     [Strawberry bushes, size variants]
â”œâ”€â”€ log_piece.gd                  [Log physics debris, timed despawn, particles]
â””â”€â”€ resource_node.gd              [Generic resource node]
```

**When to upload:**
- Adding new resource type â†’ `harvestable_resource.gd` (base class)
- Modifying tree behavior/physics â†’ `harvestable_tree.gd`
- Changing log despawn/particles â†’ `log_piece.gd`
- Bug with mushrooms â†’ `harvestable_mushroom.gd` only

#### Player Systems
```
res://
â”œâ”€â”€ harvesting_system.gd          [Raycast, progress, harvesting, container detection]
â”œâ”€â”€ building_system.gd            [Block placement, preview, container placement]
â”œâ”€â”€ tool_system.gd                [Tool management, requirements]
â”œâ”€â”€ inventory.gd                  [Item storage, signals, stacking logic]
â”œâ”€â”€ crafting_system.gd            [Recipe management]
â””â”€â”€ health_hunger_system.gd       [Stats, regeneration, hunger depletion, movement penalties]
```

**When to upload:**
- Adding new tool â†’ `tool_system.gd`
- New building block â†’ `building_system.gd`
- New recipe â†’ `crafting_system.gd`
- Health/hunger mechanics â†’ `health_hunger_system.gd`
- Food system â†’ `health_hunger_system.gd` + `inventory_ui.gd`
- Item stacking â†’ `inventory.gd` + `inventory_ui.gd`

#### Storage & Interaction Systems
```
res://
â”œâ”€â”€ storage_container.gd          [Container logic, inventory management, interaction]
â”œâ”€â”€ storage_container.tscn        [Container scene with collision and mesh]
â”œâ”€â”€ container_warning_ui.gd       [Destruction warning dialog for full containers]
â”œâ”€â”€ container_ui.gd               [Dual-panel container interface, scene-based]
â”œâ”€â”€ container_ui.tscn             [Container UI scene - centered layout]
â”œâ”€â”€ workbench.gd                  [Workbench proximity detection, recipe gating - PLANNED]
â””â”€â”€ workbench.tscn                [Workbench scene - PLANNED]
```

**When to upload:**
- Adding container features â†’ `storage_container.gd`
- Container visuals â†’ `storage_container.gd` + `pixel_texture_generator.gd`
- Container UI modifications â†’ `container_ui.gd` + `container_ui.tscn`
- Container removal â†’ `building_system.gd` + `container_warning_ui.gd`
- Workbench features â†’ `workbench.gd`
- Proximity detection â†’ `workbench.gd` + `crafting_system.gd`

#### UI Systems
```
res://
â”œâ”€â”€ harvest_ui.gd                 [Progress bar, target display]
â”œâ”€â”€ harvest_ui.tscn               [Harvest UI scene]
â”œâ”€â”€ inventory_ui.gd               [Grid inventory display, stacking UI, full notifications]
â”œâ”€â”€ inventory_ui.tscn             [Inventory UI scene - proper rendering structure]
â”œâ”€â”€ container_ui.gd               [Dual-panel container interface, scene-based]
â”œâ”€â”€ container_ui.tscn             [Container UI scene - centered layout]
â”œâ”€â”€ crafting_ui.gd                [Recipe UI, crafting interface, workbench requirements]
â”œâ”€â”€ health_ui.gd                  [Health/hunger bars, well-fed indicator]
â”œâ”€â”€ health_ui.tscn                [UI scene for health display]
â””â”€â”€ settings_menu.gd              [Graphics/game settings]
```

**When to upload:**
- Inventory features/eating â†’ `inventory_ui.gd` + `inventory_ui.tscn`
- Container UI modifications â†’ `container_ui.gd` + `container_ui.tscn`
- Crafting UI changes â†’ `crafting_ui.gd`

#### Environment & Visuals
```
res://
â”œâ”€â”€ day_night_cycle.gd            [Large - time, sun/moon, clouds, lighting]
â”œâ”€â”€ critter_spawner.gd            [Large - wildlife spawning, behavior - candidate for refactoring]
â””â”€â”€ pixel_texture_generator.gd    [16x16 texture generation]
```

**When to upload:**
- Day/night adjustments â†’ `day_night_cycle.gd`
- New critter type â†’ `critter_spawner.gd`
- Texture changes â†’ `pixel_texture_generator.gd`

#### Utilities & Shared Code
```
res://
â””â”€â”€ core/
    â”œâ”€â”€ mesh_builder.gd           [Shared mesh utilities (add_box, create_cylinder, finalize_mesh)]
    â””â”€â”€ settings_manager.gd       [Save/load settings, apply runtime changes]
```

**When to upload:**
- Creating procedural meshes â†’ `mesh_builder.gd`
- New tree/critter visual â†’ `mesh_builder.gd` (for utilities)
- Container/workbench meshes â†’ `mesh_builder.gd` + specific file

---

### Upload Strategy by Task

**Adding Storage Container System:**
```
Upload:
1. DEVELOPMENT_GUIDE.md (this file)
2. building_system.gd (for placement pattern)
3. inventory.gd (for container inventory logic)
4. inventory_ui.gd (for UI reference/pattern)
5. player.gd (for interaction input)
```

**Adding Item Stacking:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. inventory.gd (core stacking logic)
3. inventory_ui.gd (stack count display)
```

**Adding Workbench System:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. building_system.gd (for placement)
3. crafting_system.gd (for proximity checks)
4. crafting_ui.gd (for UI updates)
```

**Container UI Implementation:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. inventory_ui.gd (as reference pattern)
3. storage_container.gd (for signal integration)
4. player.gd (for input handling)
```

**Adding New Tree Type:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. vegetation/visuals/tree_visual.gd (as template)
3. core/mesh_builder.gd (utilities)
4. vegetation_spawner.gd (to wire it up)
```

**Modifying Existing Trees:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. vegetation/visuals/[specific_tree]_visual.gd (only the one you're changing)
```

**New Harvestable Resource:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. harvestable_resource.gd (base class)
3. vegetation_spawner.gd (spawning logic)
```

**UI/UX Changes:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. [specific_ui_file].gd (only what you're changing)
```

**Bug Fixes:**
```
Upload:
1. DEVELOPMENT_GUIDE.md (for context)
2. [file_with_bug].gd (specific file only)
```

**General Questions/Planning:**
```
Upload:
1. DEVELOPMENT_GUIDE.md only
   (Has all architecture, systems, patterns explained)
```

---

### Common Tasks Guide

**Add new harvestable resource:**
1. Create new script extending HarvestableResource
2. Override _ready() to set properties (health, harvest_time, drops)
3. Add to VegType enum in vegetation_spawner.gd
4. Add spawning logic in spawn_large_vegetation_for_biome()
5. Create visual mesh generation function (consider extracting to separate file if >300 lines)

**Add new tree type:**
1. Create new visual generator in `vegetation/visuals/[tree_name]_visual.gd`
2. Extend from Node with static `create(mesh_instance, spawner)` function
3. Access spawner parameters via `spawner.tree_height_min` etc.
4. Add to VegType enum in vegetation_spawner.gd
5. Add preload and case in create_vegetation_mesh()
6. Add spawning logic in spawn_large_vegetation_for_biome()

**Add new biome:**
1. Add to Chunk.Biome enum
2. Update get_biome() logic in chunk.gd with temperature/moisture thresholds
3. Add biome-specific modifiers in get_biome_height_modifier()
4. Add vegetation spawning cases in vegetation_spawner.gd
5. Create biome-specific colors/textures if needed

**Tune resource density:**
1. Open vegetation_spawner.gd
2. Adjust @export_range values (tree_density, rock_density, etc.)
3. Test in-game, watch for overcrowding or sparseness
4. Balance against "one more trip" loop feeling

**Change terrain height:**
1. Modify height_multiplier in chunk_manager.gd (higher = more dramatic)
2. Adjust biome height modifiers in chunk.gd (per-biome control)
3. Test mountain/ocean transitions for smoothness

**Add new building block:**
1. Add entry to block_types dictionary in building_system.gd
2. Define cost, size, material_color
3. Add to block type cycling in player.gd input handling
4. Test placement and collision

**Modify day/night cycle:**
1. Adjust day_length_seconds in day_night_cycle.gd
2. Modify sun/moon positions in update_sun_moon_position()
3. Change lighting colors in update_environment_lighting()
4. Test shadow transitions and visibility

**Add storage container:**
1. Create storage_container.gd extending Node3D
2. Add own Inventory instance for container storage
3. Implement interaction raycast detection (similar to HarvestableResource)
4. Create visual mesh (low-poly chest with 16x16 texture)
5. Emit signals for open/close/inventory changes
6. Add collision for raycasting (Layer 3)
7. Wire up to building_system.gd for placement

**Add workbench:**
1. Create workbench.gd extending Node3D
2. Implement proximity detection (Area3D checking for player)
3. Emit signals when player enters/exits radius
4. Add to building_system.gd as placeable
5. Update crafting_system.gd to check for nearby workbench
6. Update crafting_ui.gd to show "Requires Workbench" indicator

**Implement item stacking:**
1. Add max_stack_size property to inventory items
2. Update inventory.gd add_item() to merge with existing stacks
3. Update inventory_ui.gd to display stack counts
4. Handle stack splitting (future: shift+click)

**Refactor large file (>800 lines):**
1. Identify the largest self-contained functions (usually mesh generators)
2. Create new file in appropriate subdirectory (e.g., `vegetation/visuals/`)
3. Extract function to static class method
4. Update original file to call new class
5. Test thoroughly to ensure identical behavior

## Response Style Guidelines

### Keep responses concise and focused
- Get straight to the solution
- No markdown documentation files unless explicitly requested
- No diagrams or visual aids unless asked
- Skip explanatory preambles

### File Handling
- Always create actual files in /mnt/user-data/outputs/ for any code changes
- Provide direct download links using computer:// format
- Use "View your file" links, not "Download"
- Never just show code snippets - always create the actual file

### Code Changes
- Read relevant files from project knowledge before making changes
- Make targeted modifications without refactoring unrelated code
- Preserve existing code style and patterns
- Test logic mentally before implementing
- Follow existing naming conventions and architecture

### What NOT to do
- Don't generate README updates unless requested
- Don't create documentation files unless requested
- Don't suggest file organization changes unless file is >800 lines
- Don't add comments explaining obvious code
- Don't create architecture diagrams unless requested

## Change Tracking

### CHANGELOG.txt Format
```
[YYYY-MM-DD HH:MM] [IMPACT] Description (gameplay notes if relevant)

IMPACT levels:
- CRITICAL: Breaks save compatibility, major system overhaul
- MAJOR: New system, significant feature addition, major refactoring
- FIX: Bug fixes, performance improvements
- MINOR: Tweaks, balance adjustments, small additions
- DOC: Documentation updates
- PLANNING: Roadmap/sprint planning changes
```

### Examples
```
[2024-01-15 14:30] [MINOR] Reduced tree_density 0.45->0.35 (forests felt too crowded)
[2024-01-15 15:45] [MAJOR] Added strawberry bushes with 3 size variants
[2024-01-15 16:20] [FIX] Fixed material duplication memory leak in HarvestableResource
[2024-01-16 10:00] [CRITICAL] Refactored chunk loading system - old saves incompatible
[2024-12-11 02:00] [MAJOR] Refactored vegetation_spawner.gd - extracted tree generators
```

### Session Workflow
1. **During development**: Track changes mentally (no file updates yet)
2. **When user says "ready to commit" / "prepare commit" / "push to GitHub"**:
   - Read current CHANGELOG.txt from /mnt/project/
   - Add new entries at top under "Recent Changes" for ALL changes made this session
   - **Use current timestamp** in format [YYYY-MM-DD HH:MM]
   - Also add to v0.X.0 feature list if it's a new feature
   - Update ROADMAP.txt if completing items or adding to technical debt section
   - **Update DEVELOPMENT_GUIDE.md:**
     - Update "Currently Implemented" section with new features
     - Add new files to "File Index & Location Map" section
     - Add upload strategies for new systems
   - Copy updated CHANGELOG.txt to /mnt/user-data/outputs/
   - Copy updated ROADMAP.txt to /mnt/user-data/outputs/ (if modified)
   - Copy updated DEVELOPMENT_GUIDE.md to /mnt/user-data/outputs/
   - **For large files (>800 lines)**: Create separate `[filename]_patch_[number].gd` files for each code block change
   - **For small/medium files (<800 lines)**: Copy all modified .gd files to /mnt/user-data/outputs/
   - Copy all modified .tscn files to /mnt/user-data/outputs/
   - Copy all new .gd files to /mnt/user-data/outputs/ (with proper folder structure)
   - Copy project.godot if modified
   - Provide suggested commit message based on changes
3. **At start of new sessions**: Read CHANGELOG.txt to see what's been done previously

**Important**: CHANGELOG.txt, ROADMAP.txt, and DEVELOPMENT_GUIDE.md are only modified when preparing a commit, not during development. This keeps files clean and only shows "official" committed changes.

### CHANGELOG â†” Git Sync

Each commit should correspond to one development session. This keeps CHANGELOG and git history aligned.

**Workflow:**
1. During session: Track changes mentally
2. At commit time: Add session entries to CHANGELOG.txt
3. Use those same entries as commit message body:
   ```
   feat: [Brief summary - 50 chars max]

   - [MAJOR] First significant change
   - [MINOR] Second change
   - [FIX] Bug that was fixed
   ```
4. After pushing: Note commit hash in Version History when creating releases

**Release tagging:**
```bash
git tag -a v0.X.0 -m "Version 0.X.0 - Brief description"
git push origin v0.X.0
```

Then update CHANGELOG.txt Version History with the commit hash.

### Commit Preparation Checklist
When user says they want to commit:
- [ ] Read /mnt/project/CHANGELOG.txt
- [ ] Read /mnt/project/ROADMAP.txt
- [ ] Read /mnt/project/DEVELOPMENT_GUIDE.md
- [ ] Add entries for all changes this session (newest first) **with current timestamp**
- [ ] Update ROADMAP.txt (mark completions, add to technical debt if refactoring)
- [ ] **Update DEVELOPMENT_GUIDE.md** (add new files, update features)
- [ ] **If new files were created**: Update DEVELOPMENT_GUIDE.md "File Index & Location Map" section
- [ ] Copy CHANGELOG.txt to outputs
- [ ] Copy ROADMAP.txt to outputs (if modified)
- [ ] Copy DEVELOPMENT_GUIDE.md to outputs
- [ ] **For large files (>800 lines)**: Create separate `[filename]_patch_[number].gd` files
- [ ] **For small/medium files (<800 lines)**: Copy all modified .gd files to outputs
- [ ] Copy all new .gd files to outputs (with proper folder structure)
- [ ] Copy all modified .tscn files to outputs
- [ ] Copy project.godot if modified
- [ ] **Use CHANGELOG entries as commit message body** (keeps git history in sync)
- [ ] Provide git commit message suggestion
- [ ] List all files that need to be committed

### Commit Message Format
```
Brief summary (50 chars or less)

- Bullet point of change 1
- Bullet point of change 2
- Bullet point of change 3

Closes #issue_number (if applicable)
```

### Patch File Format (for Large Files >800 lines)
When a large file is modified, create separate numbered files for each change block.

**Naming convention**: `[filename]_patch_[number].gd`

**File format**: Each file contains only the new code with a header showing the line range.

Example files for changes to `vegetation_spawner.gd`:

**File: `vegetation_spawner_patch_1.gd`**
```
# PATCH 1 for vegetation_spawner.gd
# Lines 245-250: Added biome parameter to tree spawning

func spawn_large_vegetation_for_biome(chunk_pos: Vector2i, biome: Chunk.Biome):
    match biome:
        Chunk.Biome.FOREST:
            for i in range(tree_count):
                var pos = get_random_position_in_chunk(chunk_pos)
                spawn_tree(pos, TreeType.OAK, biome)  # Pass biome to tree
```

**File: `vegetation_spawner_patch_2.gd`**
```
# PATCH 2 for vegetation_spawner.gd
# Lines 892-895: Updated tree density for mountains

    # Mountain biome spawning
    if biome == Chunk.Biome.MOUNTAIN:
        var pine_density = 0.25  # Reduced for sparser feel
        var rock_density = 0.45
```

This allows easy copy-paste of each code block directly into the source file at the specified line numbers.

## Design Philosophy Reminders

### Core Experience
- **"One more trip"**: Player should always feel like they need just a bit more of something
- **Meditative gathering**: Combat is minimal, focus is on peaceful resource collection
- **Discovery-driven**: Exploration reveals new biomes, resources, and opportunities
- **Earned accomplishment**: Every milestone should feel like an achievement
- **Base building**: Storage and organization enable longer play sessions and bigger projects

### Visual Consistency
- Everything uses 16x16 pixel textures (no exceptions)
- Low-poly geometry with clear silhouettes
- Natural color palettes (avoid neon, keep grounded)
- Handcrafted feel despite procedural generation

### Tone Maintenance
- Mysterious but welcoming (never threatening or hostile)
- Ancient world with secrets (encourage curiosity)
- Cozy loneliness (solo experience is intentional)
- Atmospheric without being oppressive

### Avoid These Anti-Patterns
- âœ— Punishing difficulty (not Dark Souls, not survival horror)
- âœ— Overwhelming UI/systems (keep it simple and clean)
- âœ— Tedious grinding (gathering should feel satisfying, not repetitive)
- âœ— Complex crafting trees (Valheim-simple, not Factorio-complex)
- âœ— Time pressure mechanics (let player explore at their own pace)

## Version Control Notes

- Project files are synced to GitHub manually
- Not using Git LFS currently
- .tscn files are text-based, safe to merge
- Be cautious with binary assets (textures, models if added later)
- Always test after pulling changes from remote

## AI-Assisted Development Best Practices

### File Size Management
- **Target**: Keep files under 500 lines when possible
- **Warning threshold**: 800+ lines (consider refactoring)
- **Critical threshold**: 1500+ lines (definitely refactor)
- **Extraction pattern**: Large mesh generators (300+ lines) â†’ separate visual generator files

### Context Window Optimization
- Prefer reading focused files over large monoliths
- When modifying trees: read tree_visual.gd not full vegetation_spawner.gd
- Use modular architecture to minimize required context

### Large Files in Project (candidates for future refactoring)
- `vegetation_spawner.gd` - Main spawner, delegates to visuals
- `critter_spawner.gd` - Wildlife spawning (candidate for visual extraction like trees)
- `day_night_cycle.gd` - Time, sun/moon, clouds (cloud system could be extracted)

### Refactoring Guidelines
- Only refactor when files exceed 800 lines
- Extract self-contained functions first (procedural generators, visual creators)
- Create appropriate folder structure (e.g., `vegetation/visuals/`, `critters/visuals/`)
- Use static class methods for stateless generators
- Pass parent object reference for parameter access

---

*This guide should be read by Claude at the start of each development session to maintain consistency with project vision and technical architecture.*
