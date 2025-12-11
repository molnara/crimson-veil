# Crimson Veil - Development Guide

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
ÃƒÂ°Ã…Â¸Ã¢â‚¬Å“Ã¢â‚¬Â¹ CURRENT SPRINT:
- Tool system ÃƒÂ¢Ã…â€œÃ¢â‚¬Å“ (completed)
- Crafting system (next up)
- Inventory UI (planned)

ÃƒÂ°Ã…Â¸Ã¢â‚¬ÂÃ‚Â¨ RECENT CHANGES:
[2024-12-10 16:00] [MAJOR] Added minimal tool system
[2024-12-10 16:30] [MINOR] Added visual tool feedback

ÃƒÂ°Ã…Â¸Ã‚ÂÃ¢â‚¬Âº KNOWN ISSUES:
- Trees occasionally clip through terrain on slopes
- Fullscreen only works in exported builds

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
   - Include file descriptions and line counts
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
  - Satisfying crafting loops (gather ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ craft ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ unlock new areas/tools)
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
- **Building System**: Grid-snapped block placement (stone/wood blocks, walls, floors)
- **Environment**: Day/night cycle, clouds, fog, sun/moon, time-based wildlife (fireflies/butterflies)
- **Vegetation**: Procedural spawning with density controls, MultiMesh grass, biome-specific distributions
- **Settings**: Runtime graphics adjustments (view distance, fog, shadows, cloud count)
- **Crafting**: Recipe-based crafting system with 5 starter recipes
- **Inventory**: Grid-based UI with 32 slots, visual item display
- **Tools**: Axe and pickaxe with requirement checking

### Planned/Incomplete
- Boss encounters and progression milestones
- Base defense mechanics
- Advanced building pieces (roofs, windows, doors)
- Tool progression (pickaxe, axe tiers)
- Save/load system
- Weather systems beyond day/night
- Combat system
- Health/hunger mechanics

### Known Issues
- Tree falling physics occasionally glitches on steep mountain terrain
- Building collision detection needs refinement for complex structures
- Chunk unloading can cause vegetation pop-in if view distance changes rapidly

### Performance Considerations
- Target: 60 FPS on mid-range hardware
- Current bottlenecks: Vegetation spawning (mitigated by chunk caching), grass rendering (MultiMesh helps)
- View distance default: 3 chunks (configurable in settings)
- Material caching critical for glow effects (duplicate ONCE in _ready())

## Design Patterns & Architecture

### Core Architecture
- **Chunk-based world**: ChunkManager orchestrates terrain generation, VegetationSpawner populates
- **Component systems**: Player has child nodes for HarvestingSystem, BuildingSystem, Inventory
- **Resource inheritance**: HarvestableResource base class ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ HarvestableTree/Mushroom/Strawberry
- **Signal-driven communication**: Harvest completion signals trigger inventory updates and particle spawning
- **Modular visual generators**: Tree creation delegated to separate visual generator classes (TreeVisual, PineTreeVisual, PalmTreeVisual)

### Naming Conventions
- **Scripts**: snake_case (harvestable_tree.gd, chunk_manager.gd)
- **Classes**: PascalCase (HarvestableResource, ChunkManager, TreeVisual)
- **Enums**: PascalCase for enum name, SCREAMING_SNAKE for values (Biome.GRASSLAND, TreeType.PINE)
- **Variables**: snake_case (tree_density, current_block_type)
- **Constants**: SCREAMING_SNAKE_CASE (TEXTURE_SIZE, MAX_HEIGHT)

### Signal Patterns
```gdscript
# Resource systems emit signals for UI/feedback
signal harvest_started(resource: HarvestableResource)
signal harvest_completed(resource: HarvestableResource, drops: Dictionary)
signal harvest_cancelled()

# Player systems connect to these
harvesting_system.harvest_completed.connect(_on_harvest_completed)
```

### Performance Patterns
- **Material caching**: Duplicate materials ONCE in _ready(), store references, never per-frame
- **MultiMesh for repetition**: Grass uses MultiMesh (100+ instances), not individual nodes
- **Chunk population caching**: Dictionary tracks populated_chunks to prevent respawning
- **Deferred collision**: Always `call_deferred("create_collision")` after mesh generation
- **Raycast optimization**: Use calculated terrain height to narrow raycast window (+5/-5m vs +50/-50m)

### Collision Layer Architecture
- **Layer 1**: Terrain (player walks on this, buildings snap to this)
- **Layer 2**: Harvestable resources (player raycasts detect this)
- **Layer 8**: Critters (player passes through, purely visual)

### Code Organization Philosophy
- **Modular visual generators**: Large procedural mesh generators (300+ lines) should be extracted to separate files
- **Single responsibility**: Each file should have one primary purpose
- **AI-friendly file sizes**: Keep files under 500 lines when possible for better AI context window usage
- **Shared utilities**: Common mesh operations belong in `core/mesh_builder.gd`

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
"Add walls" ÃƒÂ¢Ã‚ÂÃ…â€™ Missing motivation, scope, balance considerations

## Quick Reference

### File Index & Location Map

This index helps you find and upload the right files for your task. Files are organized by system/purpose.

#### Core Systems (Always Needed)
```
res://
â”œâ”€ DEVELOPMENT_GUIDE.md          [This file - architecture & conventions]
â”œâ”€ ROADMAP.txt                    [Features, priorities, completed items]
â”œâ”€ CHANGELOG.txt                  [Session-by-session change history]
â”œâ”€ world.gd                       [Scene root, system initialization]
â”œâ”€ world.tscn                     [Main world scene]
â”œâ”€ player.gd                      [Input, movement, camera, system integration (323 lines)]
â”œâ”€ player.tscn                    [Player scene with health system, camera, collision]
â””â”€ project.godot                  [Godot project config]
```

#### World Generation
```
res://
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ chunk_manager.gd               [Terrain generation, chunk loading (249 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ chunk.gd                       [Individual chunk meshes, biomes (428 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ water_plane.gd                 [Infinite ocean plane]
```

#### Vegetation System (Modular - Upload Only What You Need)
```
res://
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ vegetation_spawner.gd          [Main spawner, delegates to visuals (1,457 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ vegetation/
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬Å¡   ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ visuals/
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬Å¡       ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ tree_visual.gd         [Oak/deciduous trees (338 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬Å¡       ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ pine_tree_visual.gd    [Pine/conifer trees (181 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬Å¡       ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ palm_tree_visual.gd    [Palm trees (188 lines)]
```

**When to upload:**
- Modifying oak trees ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `tree_visual.gd` only
- Adding new tree type ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Pick one as template + `vegetation_spawner.gd` + `mesh_builder.gd`
- Adjusting density ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `vegetation_spawner.gd` only
- Understanding system ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `DEVELOPMENT_GUIDE.md` has full explanation

#### Harvestable Resources
```
res://
├─ harvestable_resource.gd        [Base class for all collectibles (324 lines)]
├─ harvestable_tree.gd            [Tree physics, falling, log spawning (577 lines)]
├─ harvestable_mushroom.gd        [Mushroom variants, glow effects]
├─ harvestable_strawberry.gd      [Strawberry bushes, size variants]
├─ log_piece.gd                   [Log physics debris, timed despawn, particles (99 lines)]
└─ resource_node.gd               [Generic resource node]
```

**When to upload:**
- Adding new resource type → `harvestable_resource.gd` (base class)
- Modifying tree behavior/physics → `harvestable_tree.gd`
- Changing log despawn/particles → `log_piece.gd`
- Bug with mushrooms → `harvestable_mushroom.gd` only
#### Player Systems
```
res://
â”œâ”€ harvesting_system.gd           [Raycast, progress, harvesting (338 lines)]
â”œâ”€ building_system.gd             [Block placement, preview (313 lines)]
â”œâ”€ tool_system.gd                 [Tool management, requirements]
â”œâ”€ inventory.gd                   [Item storage, signals]
â”œâ”€ crafting_system.gd             [Recipe management (134 lines)]
â””â”€ health_hunger_system.gd        [Stats, regeneration, hunger depletion, movement penalties (113 lines)]
```

**When to upload:**
- Adding new tool â†’ `tool_system.gd`
- New building block â†’ `building_system.gd`
- New recipe â†’ `crafting_system.gd`
- Health/hunger mechanics â†’ `health_hunger_system.gd`
- Food system â†’ `health_hunger_system.gd` + `inventory_ui.gd`

#### UI Systems
```
res://
â”œâ”€ harvest_ui.gd                  [Progress bar, target display (213 lines)]
â”œâ”€ inventory_ui.gd                [Grid inventory display, food eating (254 lines)]
â”œâ”€ crafting_ui.gd                 [Recipe UI, crafting interface (159 lines)]
â”œâ”€ health_ui.gd                   [Health/hunger bars, well-fed indicator (60 lines)]
â”œâ”€ health_ui.tscn                 [UI scene for health display]
â””â”€ settings_menu.gd               [Graphics/game settings (329 lines)]
```

**When to upload:**
- UI layout changes â†’ Specific UI file only
- Inventory features/eating â†’ `inventory_ui.gd`
- Health bar customization â†’ `health_ui.gd` + `health_ui.tscn`
#### Health & Survival Systems
```
res://
â”œâ”€ health_hunger_system.gd        [Stats, regeneration, hunger depletion, movement penalties (113 lines)]
â”œâ”€ health_ui.gd                   [Health/hunger bars, well-fed indicator (60 lines)]
â””â”€ health_ui.tscn                 [UI scene for health display]
```

**When to upload:**
- Modifying hunger/health mechanics â†’ `health_hunger_system.gd`
- Changing food values â†’ `inventory_ui.gd` (has FOOD_VALUES dictionary)
- Sleep/rest systems â†’ `health_hunger_system.gd` + `day_night_cycle.gd` + `player.gd`
- Health UI changes â†’ `health_ui.gd` + `health_ui.tscn`
- Integration with day/night â†’ `health_hunger_system.gd` + `day_night_cycle.gd`
#### Environment & Visuals
```
res://
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ day_night_cycle.gd             [Time, sun/moon, clouds, lighting (828 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ critter_spawner.gd             [Wildlife spawning, behavior (1,142 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ pixel_texture_generator.gd     [16x16 texture generation (392 lines)]
```

**When to upload:**
- Day/night adjustments ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `day_night_cycle.gd`
- New critter type ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `critter_spawner.gd`
- Texture changes ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `pixel_texture_generator.gd`

#### Utilities & Shared Code
```
res://
ÃƒÂ¢Ã¢â‚¬ÂÃ…â€œÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ core/
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬Å¡   ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ mesh_builder.gd            [Shared mesh utilities (78 lines)]
ÃƒÂ¢Ã¢â‚¬ÂÃ¢â‚¬ÂÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ settings_manager.gd            [Save/load settings (324 lines)]
```

**When to upload:**
- Creating procedural meshes ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `mesh_builder.gd`
- New tree/critter visual ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `mesh_builder.gd` (for utilities)

---

### Upload Strategy by Task

**Adding New Tree Type:**
```
Upload:
1. DEVELOPMENT_GUIDE.md (this file)
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

**Sleep/Rest System:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. health_hunger_system.gd (to restore stats)
3. day_night_cycle.gd (to skip time)
4. player.gd (for input handling)
```

**Food/Eating Modifications:**
```
Upload:
1. DEVELOPMENT_GUIDE.md
2. health_hunger_system.gd (hunger mechanics)
3. inventory_ui.gd (FOOD_VALUES and eating logic)
4. inventory.gd (if adding new food items)
```

**General Questions/Planning:**
```
Upload:
1. DEVELOPMENT_GUIDE.md only
   (Has all architecture, systems, patterns explained)
```

---

### File Size Reference

After refactoring, all files are easily uploadable:

**Large Files (still manageable):**
- vegetation_spawner.gd: 1,457 lines (~50KB) - reduced from 2,075!
- critter_spawner.gd: 1,142 lines (~40KB) - candidate for future refactoring
- day_night_cycle.gd: 828 lines (~30KB)
- DEVELOPMENT_GUIDE.md: ~650 lines (~30KB)

**Medium Files (very manageable):**
- harvestable_tree.gd: 563 lines (~20KB)
- chunk.gd: 428 lines (~15KB)
- pixel_texture_generator.gd: 392 lines (~14KB)
- tree_visual.gd: 338 lines (~12KB)
- harvesting_system.gd: 338 lines (~12KB)

**Small Files (always easy):**
- All other visual generators: <200 lines
- UI files: <200 lines
- Most system files: <300 lines

**Tip:** The refactoring broke the 2,075-line monolith into focused pieces. Now you typically upload 1-3 small files instead of one giant file!

---

### Quick File Descriptions

**Note:** Full file index with locations is above. This section provides one-line descriptions.

**Core Systems:**
- `world.gd` - Scene orchestration, system initialization, settings application
- `chunk_manager.gd` - Terrain generation, biome logic, chunk loading/unloading
- `chunk.gd` - Individual chunk mesh generation, biome determination
- `player.gd` - Input handling, movement, system integration

**Vegetation System:**
- `vegetation_spawner.gd` - Procedural resource placement, biome-specific spawning, delegates to visual generators
- `vegetation/visuals/tree_visual.gd` - Oak/deciduous tree procedural mesh generation
- `vegetation/visuals/pine_tree_visual.gd` - Pine/conifer tree procedural mesh generation
- `vegetation/visuals/palm_tree_visual.gd` - Palm tree procedural mesh generation

**Harvestable Resources:**
- `harvestable_resource.gd` - Base class for all collectible resources
- `harvestable_tree.gd` - Tree-specific: falling physics, log spawning
- `harvestable_mushroom.gd` - Mushroom variants with glow effects
- `harvestable_strawberry.gd` - Strawberry bush size variants

**Player Systems:**
- `harvesting_system.gd` - Raycast detection, progress tracking, harvest logic
- `building_system.gd` - Block placement, preview rendering, resource costs
- `tool_system.gd` - Tool management and requirement checking
- `inventory.gd` - Item storage, signal emissions for UI updates
- `crafting_system.gd` - Recipe management and crafting logic

**UI Systems:**
- `harvest_ui.gd` - Progress bar, target display, inventory list
- `inventory_ui.gd` - Grid-based inventory display
- `crafting_ui.gd` - Recipe display and crafting interface
- `settings_menu.gd` - UI for graphics/game settings

**Environment:**
- `day_night_cycle.gd` - Time progression, sun/moon, clouds, lighting
- `critter_spawner.gd` - Time-based wildlife (fireflies, butterflies, critters)
- `water_plane.gd` - Infinite ocean plane

**Utilities:**
- `core/mesh_builder.gd` - Shared mesh creation utilities (add_box, create_cylinder, finalize_mesh)
- `pixel_texture_generator.gd` - Global class, generates all 16x16 textures
- `settings_manager.gd` - Save/load settings, apply runtime changes

### Common Tasks

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

**Refactor large file (>1000 lines):**
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
- Don't suggest file organization changes unless file is >1000 lines
- Don't add comments explaining obvious code
- Don't create architecture diagrams unless requested

## Change Tracking

### CHANGELOG.txt Format
```
[YYYY-MM-DD HH:MM] [IMPACT] Description (gameplay notes if relevant)

IMPACT levels:
- CRITICAL: Breaks save compatibility, major system overhaul
- MAJOR: New system, significant feature addition, major refactoring
- MINOR: Tweaks, balance adjustments, small additions
- FIX: Bug fixes, performance improvements
```

### Examples
```
[2024-01-15 14:30] [MINOR] Reduced tree_density 0.45->0.35 (forests felt too crowded for navigation)
[2024-01-15 15:45] [MAJOR] Added strawberry bushes with 3 size variants (small/medium/large)
[2024-01-15 16:20] [FIX] Fixed material duplication memory leak in HarvestableResource
[2024-01-16 10:00] [CRITICAL] Refactored chunk loading system - old saves incompatible
[2024-12-11 02:00] [MAJOR] Refactored vegetation_spawner.gd - extracted tree generators (reduced from 2,075 to 1,457 lines)
```

### Session Workflow
1. **During development**: Track changes mentally (no file updates yet)
2. **When user says "ready to commit" / "prepare commit" / "push to GitHub"**:
   - Read current CHANGELOG.txt from /mnt/project/
   - Add new entries at top under "Recent Changes" for ALL changes made this session
   - **Use current timestamp** in format [YYYY-MM-DD HH:MM] (e.g., [2024-12-10 14:30])
   - Also add to v0.X.0 feature list if it's a new feature
   - Update ROADMAP.txt if completing items or adding to technical debt section
   - Copy updated CHANGELOG.txt to /mnt/user-data/outputs/
   - Copy updated ROADMAP.txt to /mnt/user-data/outputs/ (if modified)
   - **For large files (>1000 lines)**: Create separate `[filename]_patch_[number].gd` files for each code block change
   - **For small/medium files (<1000 lines)**: Copy all modified .gd files to /mnt/user-data/outputs/
   - Copy all modified .tscn files to /mnt/user-data/outputs/
   - Copy all new .gd files to /mnt/user-data/outputs/ (with proper folder structure)
   - Copy project.godot if modified
   - Provide suggested commit message based on changes
3. **At start of new sessions**: Read CHANGELOG.txt to see what's been done previously

**Important**: CHANGELOG.txt and ROADMAP.txt are only modified when preparing a commit, not during development. This keeps files clean and only shows "official" committed changes.

### Commit Preparation Checklist
When user says they want to commit:
- [ ] Read /mnt/project/CHANGELOG.txt
- [ ] Read /mnt/project/ROADMAP.txt
- [ ] Add entries for all changes this session (newest first) **with current timestamp**
- [ ] Update ROADMAP.txt (mark completions, add to technical debt if refactoring)
- [ ] **If new files were created**: Update DEVELOPMENT_GUIDE.md "File Index & Location Map" section
- [ ] Copy CHANGELOG.txt to outputs
- [ ] Copy ROADMAP.txt to outputs (if modified)
- [ ] Copy DEVELOPMENT_GUIDE.md to outputs (if file index was updated)
- [ ] **For large files (>1000 lines)**: Create separate `[filename]_patch_[number].gd` files for each change block
- [ ] **For small/medium files (<1000 lines)**: Copy all modified .gd files to outputs
- [ ] Copy all new .gd files to outputs (with proper folder structure)
- [ ] Copy all modified .tscn files to outputs
- [ ] Copy project.godot if modified
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

### Patch File Format (for Large Files >1000 lines)
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
- ÃƒÂ¢Ã‚ÂÃ…â€™ Punishing difficulty (not Dark Souls, not survival horror)
- ÃƒÂ¢Ã‚ÂÃ…â€™ Overwhelming UI/systems (keep it simple and clean)
- ÃƒÂ¢Ã‚ÂÃ…â€™ Tedious grinding (gathering should feel satisfying, not repetitive)
- ÃƒÂ¢Ã‚ÂÃ…â€™ Complex crafting trees (Valheim-simple, not Factorio-complex)
- ÃƒÂ¢Ã‚ÂÃ…â€™ Time pressure mechanics (let player explore at their own pace)

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
- **Extraction pattern**: Large mesh generators (300+ lines) ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ separate visual generator files

### Context Window Optimization
- Prefer reading focused files over large monoliths
- When modifying trees: read tree_visual.gd (338 lines) not full vegetation_spawner.gd (1,457 lines)
- Use modular architecture to minimize required context

### Refactoring Guidelines
- Only refactor when files exceed 1000 lines
- Extract self-contained functions first (procedural generators, visual creators)
- Create appropriate folder structure (e.g., `vegetation/visuals/`, `critters/visuals/`)
- Use static class methods for stateless generators
- Pass parent object reference for parameter access

---

*This guide should be read by Claude at the start of each development session to maintain consistency with project vision and technical architecture.*
