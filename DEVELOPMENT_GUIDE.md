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

**Example Session Start Output:**
```
📋 CURRENT SPRINT:
- Tool system ✓ (completed)
- Crafting system (next up)
- Inventory UI (planned)

🔨 RECENT CHANGES:
[2024-12-10 16:00] [MAJOR] Added minimal tool system
[2024-12-10 16:30] [MINOR] Added visual tool feedback

🐛 KNOWN ISSUES:
- Trees occasionally clip through terrain on slopes
- Fullscreen only works in exported builds

Ready to continue development!
```

This ensures every session starts with full context.

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
- **Building System**: Grid-snapped block placement (stone/wood blocks, walls, floors)
- **Environment**: Day/night cycle, clouds, fog, sun/moon, time-based wildlife (fireflies/butterflies)
- **Vegetation**: Procedural spawning with density controls, MultiMesh grass, biome-specific distributions
- **Settings**: Runtime graphics adjustments (view distance, fog, shadows, cloud count)

### Planned/Incomplete
- Crafting recipes and progression gates
- Boss encounters and progression milestones
- Base defense mechanics
- Advanced building pieces (roofs, windows, doors)
- Tool progression (pickaxe, axe tiers)
- Inventory UI expansion
- Save/load system
- Weather systems beyond day/night

### Known Issues
- Tree falling physics occasionally glitches on steep mountain terrain
- Building collision detection needs refinement for complex structures
- Chunk unloading can cause vegetation pop-in if view distance changes rapidly
- Material duplication warnings in console (performance optimization needed)

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

### Naming Conventions
- **Scripts**: snake_case (harvestable_tree.gd, chunk_manager.gd)
- **Classes**: PascalCase (HarvestableResource, ChunkManager)
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

### Design Rationale
- **Tree density 0.35**: Lowered from 0.45 because forests felt too crowded for navigation
- **Harvest times**: Tuned for "meditative but not boring" - player should feel engaged, not waiting
- **Drop rates**: Balanced for "one more trip" loop - never quite enough, always want a bit more
- **Sprint speed 2x walk**: Significant enough to feel useful, not so fast it trivializes exploration

### Progression Targets (Planned)
- Early game: Player needs ~50 wood, ~30 stone for first shelter
- Mid game: Tool upgrades require rare biome materials
- Late game: Boss summons need significant resource investment

## Code Documentation Standards

### File-Level Docstrings (Required for non-trivial files)
```gdscript
"""
FileName - Brief purpose

ARCHITECTURE:
- System role and responsibilities
- What creates/manages this class

DEPENDENCIES:
- Required nodes/groups (with integration details)
- External systems this depends on

PERFORMANCE NOTES:
- Critical optimizations (why they matter)
- Known bottlenecks avoided

LIFECYCLE/STATE MACHINE:
- State transitions (for stateful classes)
- Creation -> Usage -> Destruction flow
"""
```

### Inline Comments - When to Use
- **Integration points**: Document required collision layers, groups, signals
- **Performance decisions**: Explain why something is done a certain way
- **Non-obvious "why"**: Complex algorithms need reasoning, not just description
- **State transitions**: Mark when objects change behavior/type
- **Calculated values**: Flag derived values that shouldn't be set directly
- **Balance tuning**: Flag values that affect game feel
- **Proc-gen decisions**: Explain randomization choices
- **Player feedback hooks**: Mark where UX/juice happens

### What NOT to Comment
- Self-explanatory code (`var player: Player  # The player` â† bad)
- Obvious getters/setters
- Standard Godot patterns everyone knows

### Examples of Good Comments

```gdscript
# INTEGRATION: Must be on layer 2 so player raycasts detect
collision_layer = 2

# PERFORMANCE: Duplicate materials ONCE here, not per-frame (previous bottleneck)
prepare_materials_for_glow()

# STATE TRANSITION: Standing (StaticBody3D) -> Falling (RigidBody3D)
convert_to_physics_body()

# CALCULATED: Do not set directly, derived from spawn_radius_chunks * chunk_size
var despawn_distance: float

# BALANCE: 0.5s feels responsive, 1.0s too sluggish (playtested)
harvest_time = 0.5

# PROCGEN: 15% mushrooms feels natural in forests (not too sparse/dense)
if rand > (1.0 - mushroom_density * 0.15):

# PLAYER FEEDBACK: Shake on hit makes harvesting feel impactful
apply_hit_shake()
```

## Godot 4.5 Specific Guidelines

### Project Structure
- **Engine**: Godot 4.5 with GDScript
- **Main scene**: world.tscn (orchestrates all systems)
- **Global classes**: PixelTextureGenerator (no preload needed)
- **Version control**: Files linked to GitHub (manual sync workflow)

### Scene Structure
```
World (Node3D)
â”œâ”€â”€ ChunkManager (Node3D)
â”œâ”€â”€ Player (CharacterBody3D)
â”‚   â”œâ”€â”€ SpringArm3D
â”‚   â”‚   â””â”€â”€ Camera3D
â”‚   â”œâ”€â”€ HarvestingSystem (Node)
â”‚   â”œâ”€â”€ BuildingSystem (Node3D)
â”‚   â””â”€â”€ Inventory (Node)
â”œâ”€â”€ VegetationSpawner (Node3D)
â”œâ”€â”€ CritterSpawner (Node3D)
â”œâ”€â”€ DayNightCycle (Node3D)
â””â”€â”€ SettingsMenu (Control)

Harvestable Resource Structure (spawned at runtime):
HarvestableTree/Mushroom/Strawberry (StaticBody3D)
â”œâ”€â”€ MeshInstance3D (visual)
â””â”€â”€ CollisionShape3D (interaction)
```

### Common Godot Gotchas in This Project
1. **Material duplication**: MUST duplicate in _ready(), NEVER per-frame
   ```gdscript
   # CORRECT - in _ready():
   material = material.duplicate()
   mesh_instance.set_surface_override_material(0, material)
   
   # WRONG - in _process():
   var mat = material.duplicate()  # Memory leak!
   ```

2. **Collision setup**: Always deferred after mesh generation
   ```gdscript
   func _ready():
       generate_mesh()
       call_deferred("create_collision")  # Must be deferred
   ```

3. **MultiMesh limitations**: Cannot be modified after creation, must recreate
   ```gdscript
   # To change grass: recreate entire MultiMesh, don't try to modify instances
   ```

4. **Collision layers**: Must be set correctly or systems break
   ```gdscript
   # Terrain
   collision_layer = 1
   collision_mask = 0
   
   # Harvestables
   collision_layer = 2
   collision_mask = 0
   
   # Player
   collision_layer = 1
   collision_mask = 1  # Only terrain
   ```

5. **Node references**: Use get_node() or @onready, never assume tree structure
   ```gdscript
   @onready var camera = $SpringArm3D/Camera3D  # Validates at ready
   # NOT: var camera = get_node("Camera3D")  # Fragile
   ```

6. **Signal connections**: Always check if callable exists
   ```gdscript
   if harvesting_system.has_signal("harvest_completed"):
	   harvesting_system.harvest_completed.connect(_on_harvest_completed)
   ```

## Testing & Iteration

### Debug Tools Available
- **Fly mode**: Press F to toggle noclip (flies at 15 m/s)
- **Inventory print**: Press I to dump inventory contents to console
- **Settings menu**: ESC to access runtime graphics adjustments
- **Collision visualization**: Enable in Godot editor â†’ Debug â†’ Visible Collision Shapes

### Quick Testing Workflows
1. **Test specific biome**: Modify player spawn position in world.gd
2. **Test resource spawn**: Adjust density sliders in VegetationSpawner inspector
3. **Test harvest times**: Change @export values in HarvestableResource subclasses
4. **Test building costs**: Modify block_types dictionary in BuildingSystem

### Performance Profiling
- Enable Godot profiler: Debug â†’ Profiler
- Watch for: Vegetation spawning spikes, material duplication warnings, chunk load stutters
- Target frame time: ~16.67ms (60 FPS)

### Scene Testing
- Individual resources can't be tested in isolation (need ChunkManager for terrain height)
- Use minimal world: Reduce view_distance to 1 chunk for faster iteration
- Building blocks: Can test in empty scene with just Player + BuildingSystem

## Iteration Priorities

When making changes, evaluate in this order:

1. **Does it serve the core pillars?**
   - Exploration? Crafting? Base-building?
   - If it doesn't support at least one pillar, reconsider

2. **Does it maintain the aesthetic?**
   - Can it work with 16x16 pixel textures?
   - Does it fit low-poly geometric style?
   - Readable silhouettes?

3. **Does it respect "one more trip" loop?**
   - Does it create satisfying micro-goals?
   - Is reward timing right (not too fast/slow)?

4. **Is it meditative or disruptive?**
   - Does it add stress or calm?
   - Accomplishment-focused or frustration-focused?

5. **Technical feasibility?**
   - Can Godot 4.5 handle it performantly?
   - Does it fit existing architecture or require refactor?

## Feature Request Template

When requesting new features, provide:

1. **Player motivation**: Why would player want this?
   - Example: "Players want to mark discovered locations so they can return"

2. **Fits which pillar**: Exploration? Crafting? Base-building?
   - Example: "Exploration - helps navigate large world"

3. **Inspiration example**: Reference game + modification
   - Example: "Like Valheim's map markers but simpler, no full map UI"

4. **Scope estimate**: Small tweak? New system? Content addition?
   - Small: Single-session implementation
   - Medium: 2-3 sessions
   - Large: Week+ of work

5. **Balance consideration**: How does this affect difficulty/progression?
   - Example: "Makes navigation easier, might reduce exploration tension"

### Good Example
"Add stone walls for base building. Players want protection from future threats (base-building pillar). Like Valheim's walls but snapped to grid. Medium scope - needs collision, placement validation, cost balancing. Should require significant stone investment to prevent trivializing defense."

### Bad Example
"Add walls" â† Missing motivation, scope, balance considerations

## Quick Reference

### Key Files
- `world.gd` - Scene orchestration, system initialization, settings application
- `chunk_manager.gd` - Terrain generation, biome logic, chunk loading/unloading
- `chunk.gd` - Individual chunk mesh generation, biome determination
- `vegetation_spawner.gd` - Procedural resource placement, biome-specific spawning
- `player.gd` - Input handling, movement, system integration
- `harvestable_resource.gd` - Base class for all collectible resources
- `harvestable_tree.gd` - Tree-specific: falling physics, log spawning
- `harvestable_mushroom.gd` - Mushroom variants with glow effects
- `harvestable_strawberry.gd` - Strawberry bush size variants
- `harvesting_system.gd` - Raycast detection, progress tracking, harvest logic
- `building_system.gd` - Block placement, preview rendering, resource costs
- `inventory.gd` - Item storage, signal emissions for UI updates
- `harvest_ui.gd` - Progress bar, target display, inventory list
- `pixel_texture_generator.gd` - Global class, generates all 16x16 textures
- `day_night_cycle.gd` - Time progression, sun/moon, clouds, lighting
- `critter_spawner.gd` - Time-based wildlife (fireflies, butterflies)
- `settings_manager.gd` - Save/load settings, apply runtime changes
- `settings_menu.gd` - UI for graphics/game settings

### Common Tasks

**Add new harvestable resource:**
1. Create new script extending HarvestableResource
2. Override _ready() to set properties (health, harvest_time, drops)
3. Add to VegType enum in vegetation_spawner.gd
4. Add spawning logic in spawn_large_vegetation_for_biome()
5. Create visual mesh generation function

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
- Don't suggest file organization changes
- Don't add comments explaining obvious code
- Don't create architecture diagrams unless requested

## Change Tracking

### CHANGELOG.txt Format
```
[YYYY-MM-DD HH:MM] [IMPACT] Description (gameplay notes if relevant)

IMPACT levels:
- CRITICAL: Breaks save compatibility, major system overhaul
- MAJOR: New system, significant feature addition
- MINOR: Tweaks, balance adjustments, small additions
- FIX: Bug fixes, performance improvements
```

### Examples
```
[2024-01-15 14:30] [MINOR] Reduced tree_density 0.45->0.35 (forests felt too crowded for navigation)
[2024-01-15 15:45] [MAJOR] Added strawberry bushes with 3 size variants (small/medium/large)
[2024-01-15 16:20] [FIX] Fixed material duplication memory leak in HarvestableResource
[2024-01-16 10:00] [CRITICAL] Refactored chunk loading system - old saves incompatible
```

### Session Workflow
1. **During development**: Track changes mentally (no file updates yet)
2. **When user says "ready to commit" / "prepare commit" / "push to GitHub"**:
   - Read current CHANGELOG.txt from /mnt/project/
   - Add new entries at top under "Recent Changes" for ALL changes made this session
   - Also add to v0.X.0 feature list if it's a new feature
   - Copy updated CHANGELOG.txt to /mnt/user-data/outputs/
   - Copy all modified files to /mnt/user-data/outputs/
   - Provide suggested commit message based on changes
3. **At start of new sessions**: Read CHANGELOG.txt to see what's been done previously

**Important**: CHANGELOG.txt is only modified when preparing a commit, not during development. This keeps the file clean and only shows "official" committed changes.

### Commit Preparation Checklist
When user says they want to commit:
- [ ] Read /mnt/project/CHANGELOG.txt
- [ ] Add entries for all changes this session (newest first)
- [ ] Copy CHANGELOG.txt to outputs
- [ ] Copy all modified .gd files to outputs
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
- âŒ Punishing difficulty (not Dark Souls, not survival horror)
- âŒ Overwhelming UI/systems (keep it simple and clean)
- âŒ Tedious grinding (gathering should feel satisfying, not repetitive)
- âŒ Complex crafting trees (Valheim-simple, not Factorio-complex)
- âŒ Time pressure mechanics (let player explore at their own pace)

## Version Control Notes

- Project files are synced to GitHub manually
- Not using Git LFS currently
- .tscn files are text-based, safe to merge
- Be cautious with binary assets (textures, models if added later)
- Always test after pulling changes from remote

---

*This guide should be read by Claude at the start of each development session to maintain consistency with project vision and technical architecture.*
