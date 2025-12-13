# CRIMSON VEIL - CLAUDE PROJECTS WORKFLOW
## Development Strategy for v0.6.0 "Hunter & Prey"

---

## PROJECT SETUP

### Claude Project Configuration

**Project Name:** Crimson Veil

**Project Knowledge Base (Upload These Files):**
1. `ROADMAP_v0_6_0.txt` - Sprint overview and task breakdown (SIMPLIFIED COMBAT VERSION)
2. `IMPLEMENTATION_GUIDE_v0_6_0.txt` - Technical implementation details (SIMPLIFIED)
3. `project.godot` - Project settings and configurations
4. Key existing scripts:
   - `player.gd`
   - `health_hunger_system.gd`
   - `critter_spawner.gd`
   - `audio_manager.gd`
   - `rumble_manager.gd`
   - `inventory_system.gd`
   - `combat_system.gd` (CREATED - Phase 1 complete)
   - `weapon.gd` (CREATED - Phase 1 complete)
   - `combat_ui.gd` (CREATED - Phase 1 complete)

**Custom Instructions for Project:**
```
You are assisting with development of Crimson Veil, a first-person survival game 
built in Godot 4.5.1. The project uses:
- GDScript for all game logic
- CSG primitives for 3D geometry
- AI-generated assets (audio via SFX Engine, textures via Leonardo.ai)
- Dual input support (M+KB and Xbox controller)

Current sprint: v0.6.0 "Hunter & Prey" - SIMPLIFIED Minecraft-style combat
Status: Phase 1 COMPLETE (Tasks 1.1-1.2 done), Phase 2 starting (Enemy implementation)
Total tasks: 10 remaining (reduced from 12 due to simplification)
Estimated time: ~24 hours remaining (32 hours total, 8 hours completed)

DESIGN PHILOSOPHY:
- Minecraft-style simple click-to-attack (NO charging mechanics)
- NO dodge system (B button = Sprint)
- NO bow & arrow (melee only for v0.6.0)
- Focus on responsive, instant feedback
- Inspector-editable parameters for easy tuning

CRITICAL RULES (MUST FOLLOW):
1. NEVER recreate existing code files from scratch
2. ALWAYS request files to be uploaded from GitHub before modifying them
3. Start each session by identifying which files are needed and requesting upload
4. Ask to "proceed" before implementing any code or making changes
5. Do NOT generate documentation, diagrams, or supplementary materials unless explicitly requested
6. When user says "generate commit", output a brief git commit message summarizing the changes

Always:
1. Focus on production code only
2. Check ROADMAP and IMPLEMENTATION_GUIDE before suggesting implementations
3. Follow established code patterns from existing scripts
4. Respect locked design decisions (SIMPLIFIED COMBAT - no charging, no dodge, no bow)
5. Consider controller support in all input implementations
6. Maintain performance targets (60 FPS, <100 draw calls)
7. Generate complete, production-ready code (not pseudocode)
8. Include error handling and edge case management
9. Use @export parameters for Inspector tuning where appropriate
```

---

## FILE MANAGEMENT WORKFLOW

### Critical Rule: Never Recreate From Scratch

**All existing code files are stored in GitHub. Claude must NEVER attempt to recreate them from scratch.**

### Session Start Protocol:

**Step 1: Identify Required Files**
At the start of each session, Claude should identify:
- Which existing files need to be modified
- Which new files need to be created

**Step 2: Request File Upload**
Claude should output:
```
Before we begin, please upload these existing files from GitHub:

REQUIRED FOR MODIFICATION:
- res://player.gd
- res://health_hunger_system.gd
- res://audio_manager.gd

NEW FILES TO CREATE:
- res://combat_system.gd
- res://weapon.gd

Please upload the existing files so I can modify them properly.
```

**Step 3: Wait for Upload**
- Do not proceed until files are uploaded
- Do not attempt to "remember" or recreate file contents
- User will upload files via Claude's interface

**Step 4: Verify Files**
Once uploaded, Claude should:
- Confirm files are received
- Review current implementation
- Identify integration points

### Example Session Flow:

**User:** "Let's start Task 1.1 - Combat System Foundation"

**Claude:** 
```
Starting Task 1.1 - Combat System Foundation.

Before we begin, please upload these existing files from GitHub:
- res://player.gd (need to integrate combat input handling)
- res://project.godot (need to add input actions)

I'll be creating these new files:
- res://combat_system.gd
- res://weapon.gd

Please upload the existing files.
```

**User:** [uploads player.gd and project.godot]

**Claude:**
```
Files received. I can see player.gd currently handles movement and 
basic interactions. I'll add combat system integration.

IMPLEMENTATION PLAN:
[presents plan]

Shall I proceed?
```

**User:** "Yes, proceed"

**Claude:** [provides code]

---

## SESSION WORKFLOW STRUCTURE

### Phase-Based Development Approach

Each session should focus on **one complete task** from the roadmap to maintain momentum and allow for testing between sessions.

### Session Template

```
SESSION [X]: Task [Y.Z] - [Task Name]
═══════════════════════════════════════════════════

CONTEXT:
- Previous session completed: [Task ID]
- Current task: [Task ID] - [Task Name]
- Estimated time: [X hours]
- Dependencies: [List any required prior tasks]

OBJECTIVES:
1. [Primary objective]
2. [Secondary objective]
3. [Testing objective]

FILES TO MODIFY/CREATE:
- Create: [List new files]
- Modify: [List existing files]

TESTING CRITERIA:
[ ] [Test 1]
[ ] [Test 2]
[ ] [Test 3]

OUTPUT NEEDED:
- Complete implementation files
- Testing instructions
- Integration notes
- Known issues/limitations

WORKFLOW:
1. Identify which existing files need to be modified
2. Request file upload: "Please upload these files from GitHub: [list]"
3. Wait for files to be uploaded
4. Review requirements and ask clarifying questions if needed
5. Present implementation plan
6. Wait for "proceed" confirmation
7. Provide complete code implementations (modifications to uploaded files + new files)
8. Provide testing instructions
```

---

## DETAILED SESSION BREAKDOWN

### ✅ PHASE 1: COMBAT FOUNDATION - COMPLETE

**Tasks 1.1-1.4 completed. The following have been created:**
- `combat_system.gd` (~300 lines, simplified Minecraft-style)
- `weapon.gd` (Resource class with 3 weapons)
- `combat_ui.gd` (Simple 2-state crosshair)
- `combat_ui.tscn` (UI overlay)
- Modified `player.gd` (combat input integration)
- Modified `project.godot` (combat_attack, cycle_weapon inputs)

**Key Features Implemented:**
- Simple click-to-attack (0.5s cooldown)
- Auto-aim cone (30° for controller)
- Weapon switching (RB button)
- Camera shake system
- Controller rumble integration
- Inspector-editable parameters (@export)

**Removed Features (Simplified):**
- ❌ Charging mechanics (was Task 1.2)
- ❌ Dodge system (was Task 1.3)
- ❌ Bow & arrow (was Task 1.5)

---

### 🎯 PHASE 2: ENEMIES (Sessions 1-4) - CURRENT PHASE

#### **SESSION 1: Task 2.1 - Enemy Base Class** 🎯 NEXT

**Prompt Template:**
```
Starting Phase 2. Please implement Task 2.1 - Enemy Base Class.

(Note: Claude will first request you upload critter_spawner.gd before proceeding)

Create the base enemy class that all 6 enemy types will extend:

1. res://enemy.gd (extends CharacterBody3D):
   - State machine: Idle, Chase, Attack, Death
   - Health system (current_health, max_health)
   - Combat integration: take_damage(amount) - simplified, no is_heavy parameter
   - Drop table system (Array[Dictionary] with item/chance)
   - Player detection and targeting
   - Must be in "enemies" group
   - Collision Layer 9 for enemy identification

2. Core systems needed:
   - update_ai(delta) - state machine logic
   - chase_player() - pathfinding toward player
   - attack_player() - telegraph, strike, cooldown pattern
   - take_damage(amount) - reduce health, flash white, check death
   - die() - drop loot, play death effect, queue_free()
   - flash_white() - damage feedback (0.1s white flash)

3. Visual system:
   - create_enemy_visual() - virtual method for subclasses
   - fade_out() - death animation (0.5s dissolve)

4. Inspector parameters (@export):
   - max_health: int
   - damage: int  
   - move_speed: float
   - detection_range: float
   - attack_range: float
   - drop_table: Array[Dictionary]

Reference IMPLEMENTATION_GUIDE section "ENEMY BASE SKELETON" for structure.

Expected deliverables:
- enemy.gd (complete base class)
- Example enemy scene for testing (simple_test_enemy.tscn)
- Integration notes for spawning system
```

**Expected Output:**
- Complete `enemy.gd` base class (~200 lines)
- Test enemy scene
- Documentation on how to extend for specific enemy types
- Integration points with combat_system.gd

---

#### **SESSION 2: Task 2.2A - Enemy Types (Corrupted Rabbit + Forest Goblin)**

**Prompt Template:**
```
Implementing first two enemies: Corrupted Rabbit and Forest Goblin.

(Note: Claude will request you upload enemy.gd before proceeding)

For EACH enemy, create:
1. Script (extends Enemy)
2. Scene (.tscn with CharacterBody3D root)
3. CSG primitive geometry (created in create_enemy_visual())
4. Configured stats from balance table
5. Unique behavior overrides
6. Drop table configuration

CORRUPTED RABBIT:
Stats: 30 HP, 8 DMG, 4.5 speed, 1.5m attack range
Behavior:
- Territorial: Only attacks if player within 5m
- Fast chase: Zigzag pattern toward player
- Quick attack: Short windup, rapid strike (0.3s telegraph)
Visual (CSG):
- CSGSphere body (0.3m radius, brown)
- CSGBox ears (2x, pointed up, pink inside)
- CSGSphere eyes (2x, glowing red, emissive material)
- CSGSphere tail (small, fluffy)
Drop Table:
- Corrupted Leather: 100% chance
- Dark Meat: 40% chance

FOREST GOBLIN:
Stats: 50 HP, 12 DMG, 3.0 speed, 2.0m attack range
Behavior:
- Patrol: Random waypoints when idle
- Flee: When health < 20% (10 HP), run away from player
- Coward: Keeps 3m distance when possible, pokes with stick
Visual (CSG):
- CSGCapsule body (0.4m radius, 1.0m height, green)
- CSGSphere head (0.35m radius, green)
- CSGBox arms (2x, thin, brown)
- CSGBox stick weapon (held in right hand position)
- CSGSphere eyes (2x, yellow, beady)
Drop Table:
- Wood: 80% chance
- Stone: 60% chance
- Goblin Tooth: 30% chance (rare)

Implementation requirements:
- Override create_enemy_visual() to build CSG geometry
- Override update_ai() for unique behaviors
- Set collision Layer 9, Mask 1
- Add to "enemies" group in _ready()
- Placeholder materials (will apply textures in Task 3.2)

Files to create:
- enemies/corrupted_rabbit.gd + corrupted_rabbit.tscn
- enemies/forest_goblin.gd + forest_goblin.tscn

Provide complete implementations with:
- Behavior state machine customizations
- CSG geometry setup code
- Drop table configuration
- Audio integration points (marked with TODOs for Task 3.1)
```

---

#### **SESSION 3: Task 2.2B - Enemy Types (Desert Scorpion + Ice Wolf)**

**Prompt Template:**
```
Implementing enemies 3-4: Desert Scorpion and Ice Wolf.

DESERT SCORPION:
Stats: 60 HP, 15 DMG, 3.0 speed, 2.5m attack range
Behavior:
- Ambush: Start buried (position.y -= 2.0), emerge when player within 8m
- Burrow animation: Tween position.y over 0.5s
- Tail strike: Wind up tail (0.5s telegraph, flash red), strike with damage
- Re-burrow: After attacking, 30% chance to burrow again
Visual (CSG):
- CSGBox body (3 segments, sandy yellow)
- CSGBox pincers (2x, front claws)
- CSGCylinder tail (curved upward, stinger at tip)
- CSGSphere eyes (2x, black, small, stalked)
Drop Table:
- Chitin: 100% chance
- Venom Sac: 25% chance (rare)

ICE WOLF:
Stats: 55 HP, 14 DMG, 4.5 speed, 2.0m attack range
Behavior:
- Pack spawning: Spawns with 1-2 others (handled in Task 2.3)
- Pack coordination: Shares pack_id, waits for howl signal
- Howl: Before first attack, play howl animation (1s)
- Surround: Pack members try to circle player
Visual (CSG):
- CSGCapsule body (0.5m radius, 1.2m height, horizontal, white)
- CSGSphere head (0.4m radius, white with blue tint)
- CSGCylinder legs (4x, white)
- CSGCone tail (bushy, curved)
- CSGSphere eyes (2x, icy blue, glowing)
Drop Table:
- Wolf Pelt: 100% chance
- Fang: 70% chance
- Ice Shard: 15% chance (rare)

Additional features:
- Scorpion: Buried state (invisible until player near)
- Ice Wolf: Pack behavior stubs (full implementation in Task 2.3)
- Both: Telegraph animations for attacks

Files to create:
- enemies/desert_scorpion.gd + desert_scorpion.tscn
- enemies/ice_wolf.gd + ice_wolf.tscn

Include:
- State machine extensions for unique behaviors
- Position tweening for scorpion burrow/emerge
- Pack coordination variables for wolves (pack_id, has_howled)
```

---

#### **SESSION 4: Task 2.2C - Final Enemies + Task 2.3 - AI & Spawning Integration**

**Prompt Template:**
```
Final two enemies + complete AI and spawning integration.

(Note: Claude will request you upload critter_spawner.gd before proceeding)

STONE GOLEM:
Stats: 100 HP, 20 DMG, 1.5 speed, 2.5m attack range
Behavior:
- Tank: Slow movement, high HP, heavy hits
- Ground Slam: Raises arms (1s telegraph), slams ground (3m AoE damage)
- Guard: If near stone nodes, patrols around them
- Stagger: Takes 2s to recover after ground slam
Visual (CSG):
- CSGBox body (large, 1.5m tall, gray stone)
- CSGBox arms (2x, thick, powerful)
- CSGBox legs (2x, sturdy columns)
- CSGSphere eyes (2x, orange glow, emissive)
- Cracks: Use darker material lines (optional detail)
Drop Table:
- Stone: 100% chance (3-5 pieces)
- Iron Ore: 60% chance
- Stone Core: 20% chance (rare, glowing)

SHADOW WRAITH:
Stats: 40 HP, 12 DMG, 4.0 speed, 2.0m attack range
Behavior:
- Night-only: Check time_of_day >= 0.9167 or < 0.25
- Float: position.y = terrain_y + 1.5m (always airborne)
- Phase: collision_mask = 0 (passes through terrain)
- Despawn: Fade out at dawn (6 AM), queue_free()
- Ethereal: Slightly transparent even when alive
Visual (CSG):
- CSGCapsule body (0.6m radius, 1.5m height, dark purple/black)
- CSGSphere head (0.4m radius, no facial features)
- Transparent shader: albedo_color.a = 0.6
- GPUParticles3D trail (wispy dark particles)
Drop Table:
- Shadow Essence: 80% chance
- Ectoplasm: 30% chance (rare, glowing purple)

TASK 2.3 - AI & SPAWNING INTEGRATION:

Modify critter_spawner.gd to add enemy spawning:

1. Enemy spawn function:
   - spawn_enemy(biome_type, position) method
   - Check biome → spawn correct enemy type
   - Spawn rates from balance table (5-15% per chunk)
   - Minimum distance from player: 15m

2. Pack spawning (Ice Wolf):
   - When spawning Ice Wolf, spawn 2-3 in triangle formation
   - Assign shared pack_id (use randi())
   - Position: spawn_point + offset (2-3m apart)
   - Create pack_manager.gd for coordination

3. Night-only spawning (Shadow Wraith):
   - Check DayNightCycle.time_of_day
   - Only spawn if >= 0.9167 or < 0.25
   - Track spawned wraiths, despawn at dawn

4. Biome mapping:
   - Forest: Corrupted Rabbit (15%), Forest Goblin (8%)
   - Desert: Desert Scorpion (12%)
   - Snow: Ice Wolf (10%, pack spawn)
   - Mountain: Stone Golem (5%)
   - All biomes (night): Shadow Wraith (8%)

Files to create:
- enemies/stone_golem.gd + stone_golem.tscn
- enemies/shadow_wraith.gd + shadow_wraith.tscn
- enemies/pack_manager.gd (Ice Wolf coordination)

Files to modify:
- critter_spawner.gd (add enemy spawning integration)

Deliverables:
- Complete enemy implementations
- Full spawning system integration
- Pack behavior for Ice Wolves
- Night cycle integration for Shadow Wraith
```

---

### PHASE 3: AUDIO & VISUAL (Sessions 5-6)

#### **SESSION 5: Task 3.1 - Combat Audio + Task 3.2 - Texture Generation**

**Prompt Template:**
```
Audio and texture generation for combat system.

PART 1: AUDIO GENERATION (Task 3.1)
Generate prompts for SFX Engine - 32 total sounds (8 player + 24 enemy):

PLAYER COMBAT (8 sounds):
1. swing_light.wav: "Quick weapon whoosh, sharp and fast, light melee swing"
2. swing_medium.wav: "Medium weapon swing, moderate speed and weight"
3. swing_heavy.wav: "Heavy powerful swing, deep whoosh with weight, strong attack"
4. hit_flesh.wav: "Meaty impact, flesh hit, satisfying thud"
5. hit_stone.wav: "Rock impact, stone breaking, hard surface hit"
6. player_grunt_1.wav: "Male player damage grunt, short pain sound, taking hit"
7. player_grunt_2.wav: "Male player damage grunt variation, hit sound, different pitch"
8. player_death.wav: "Male player death sound, final gasp, character dying"

ENEMY SOUNDS (4 per enemy × 6 = 24 sounds):
For each enemy type, generate 4 sounds: ambient, attack, hit, death

Example prompts (Corrupted Rabbit):
- "Corrupted animal growl, hostile, low menacing"
- "Rabbit attack hiss, aggressive lunge"
- "Rabbit damage squeak, small animal hurt"
- "Rabbit death squeal, final sound, small creature"

Repeat this pattern for:
- Forest Goblin (guttural, gremlin-like)
- Desert Scorpion (chittering, clicking)
- Ice Wolf (howl, snarl, whimper)
- Stone Golem (grinding rock, deep rumble)
- Shadow Wraith (ethereal whisper, ghostly)

AudioManager Integration:
Add all 32 sounds to audio_manager.gd with:
- Category: "sfx"
- Variation: "moderate" for player, "subtle" for enemies
- Volume adjustments per sound type

PART 2: TEXTURE GENERATION (Task 3.2)
Generate 5 Leonardo.ai prompts for enemy textures:

1. Corrupted Rabbit Fur:
   "Seamless tileable texture, corrupted animal fur, dark red-brown, diseased patches, 
   matted, 512x512, top-down view, game texture, high contrast"

2. Forest Goblin Skin:
   "Seamless tileable texture, green goblin skin, mottled, warts, rough, fantasy game, 
   512x512, top-down view, bumpy surface"

3. Desert Scorpion Chitin:
   "Seamless tileable texture, scorpion chitin, sandy yellow, segmented plates, 
   desert creature, 512x512, top-down view, armored"

4. Ice Wolf Fur:
   "Seamless tileable texture, white wolf fur, icy blue tint, frost patches, winter, 
   512x512, top-down view, game asset, fluffy"

5. Stone Golem Surface:
   "Seamless tileable texture, granite stone, gray rock, orange glowing cracks, 
   magma veins, 512x512, top-down view, volcanic"

Texture Application Instructions:
- Save as PNG in res://textures/enemies/
- Apply to enemy StandardMaterial3D
- texture_filter = TEXTURE_FILTER_NEAREST (pixel art)
- roughness = 0.8-0.9 (no shine)

Deliverables:
1. Complete list of 32 SFX Engine prompts (copy-paste ready)
2. AudioManager.gd sound dictionary additions
3. 5 texture generation prompts (copy-paste ready)
4. Texture application code snippets for each enemy

Note: Actual generation happens outside Claude (manual step).
Code provided should be ready for when assets exist.
```

---

#### **SESSION 6: Task 3.3 - Visual Effects + Task 4.1 - Death System**

**Prompt Template:**
```
Visual effects polish and death/respawn implementation.

(Note: Claude will request you upload health_hunger_system.gd before proceeding)

PART 1: VISUAL EFFECTS (Task 3.3 - Simplified)

Create res://effects/ directory with:

1. Hit Particles (hit_particles.tscn):
   - GPUParticles3D node
   - Amount: 10-15 particles
   - Lifetime: 0.3s
   - Emission: Burst on hit
   - Color: Enemy-specific (red for rabbit, green for goblin, etc.)
   - Size: 0.05m spheres

2. Crosshair feedback enhancements:
   - Flash white on successful hit (0.1s)
   - Already implemented: red when targeting

3. Screen flash on damage:
   - ColorRect overlay (fullscreen, "CanvasLayer" parent)
   - Color: Red, alpha 0.3
   - Animation: Fade in 0.05s, hold 0.1s, fade out 0.2s
   - Trigger: When player takes damage

4. Enemy death fade:
   - Tween material albedo_color.a: 1.0 → 0.0 over 0.5s
   - Call queue_free() when complete

5. Camera shake:
   - Already implemented in combat_system.gd
   - Verify presets: light (0.3), medium (0.5) for weapons

PART 2: DEATH & RESPAWN SYSTEM (Task 4.1)

Implement player death and respawn:

1. Death Detection (modify health_hunger_system.gd):
   - Monitor player health
   - When health <= 0, emit signal: player_died
   - Freeze player movement (disable input)
   - Play death sound: "player_death"

2. Death Screen UI (create res://ui/death_screen.tscn):
   - CanvasLayer root
   - ColorRect background (black, alpha 0.8)
   - Label: "YOU DIED" (large, red, center)
   - Button: "RESPAWN" (center-bottom)
   - Auto-focus button for controller support

3. Death Sequence:
   - Fade to black over 0.5s
   - Show death screen
   - Disable all input except respawn button
   - Stop all sounds except UI

4. Respawn Logic (create res://ui/death_screen.gd):
   - On respawn button pressed:
     * Teleport player to spawn: Vector3(0, 50, 0)
     * Restore health to 100
     * Restore hunger to 100
     * Keep all inventory items (forgiving)
     * Fade from black over 0.5s
     * Re-enable input
     * Hide death screen

5. Integration:
   - Connect health_hunger_system player_died signal
   - Ensure enemies stop chasing after death
   - Clear all combat states
   - Reset attack cooldowns

Files to create:
- effects/hit_particles.tscn
- ui/death_screen.tscn
- ui/death_screen.gd
- ui/damage_flash.tscn (screen flash ColorRect)

Files to modify:
- health_hunger_system.gd (death detection + signal)
- player.gd (freeze on death)
- combat_system.gd (clear state on death)
- enemy.gd (stop chasing dead player)

Deliverables:
- Complete visual effects implementation
- Full death/respawn system
- Testing instructions
```

---

### PHASE 4: FINAL POLISH (Session 7)

#### **SESSION 7: Task 4.2 - Final Polish & Testing**

**Prompt Template:**
```
Final combat polish, balance pass, and comprehensive testing.

PART 1 - Combat Rumble Polish:
Review and finalize rumble presets in rumble_manager.gd:

Existing presets to verify:
- light: {weak: 0.2, strong: 0.0, duration: 0.1} (used for missed attacks)
- medium: {weak: 0.4, strong: 0.2, duration: 0.2} (used for successful hits)
- heavy: {weak: 0.6, strong: 0.4, duration: 0.3} (used for Stone Golem slam)
- impact: {weak: 0.5, strong: 0.5, duration: 0.25} (used for player taking damage)

Integration verification:
- combat_system.gd: Attack hits trigger "medium"
- combat_system.gd: Missed attacks trigger "light"
- enemy.gd: Player damage triggers "impact" on player
- stone_golem.gd: Ground slam triggers "heavy"

PART 2 - Balance Pass:
Review all damage/HP values and adjust if needed:

Current balance (from balance table):
- Player: 100 HP
- Wooden Club: 15 damage (2 hits for rabbit, 4 for goblin, 7 for golem)
- Stone Spear: 20 damage (better than club)
- Bone Sword: 25 damage (best weapon)

Enemy HP verification:
- Corrupted Rabbit: 30 HP (dies in 2 club hits) ✓
- Forest Goblin: 50 HP (dies in 4 club hits) ✓
- Desert Scorpion: 60 HP (dies in 4 club hits) ✓
- Ice Wolf: 55 HP (dies in 4 club hits) ✓
- Stone Golem: 100 HP (dies in 7 club hits) ✓ (tank)
- Shadow Wraith: 40 HP (dies in 3 club hits) ✓

Test with all weapons, adjust if fights feel:
- Too easy: Increase enemy HP by 10-20%
- Too hard: Increase weapon damage by 10-20%
- Document any changes in balance table

PART 3 - Final Testing Checklist:
Run comprehensive testing across all systems:

âœ… PHASE 1 TESTS (Already verified):
[âœ…] Attack works with M+KB (LMB)
[âœ…] Attack works with controller (RT)
[âœ…] Cooldown prevents spam
[âœ…] Crosshair changes to red when targeting
[âœ…] Camera shake on attack
[âœ…] Controller rumble on attack
[âœ…] Weapon switching works (RB)
[âœ…] B button triggers sprint
[âœ…] Combat parameters visible in Inspector

PHASE 2 TESTS (To verify):
[ ] All 6 enemy types spawn in correct biomes
[ ] Enemy AI works (idle, chase, attack, death)
[ ] Enemies take damage from all weapons
[ ] Enemies die at correct HP thresholds
[ ] Enemies drop correct items on death
[ ] Pack behavior works for Ice Wolves (2-3 spawn together)
[ ] Shadow Wraith only spawns at night (time check)
[ ] Shadow Wraith despawns at dawn

PHASE 3 TESTS (To verify):
[ ] All 8 player sounds play correctly
[ ] All 24 enemy sounds play correctly (if generated)
[ ] Enemy textures applied (if generated)
[ ] Hit particles spawn on successful attacks
[ ] Screen flash on player damage
[ ] Enemy death fade animation
[ ] Crosshair flash on hit

PHASE 4 TESTS (To verify):
[ ] Player death detected at 0 HP
[ ] Death screen appears with "YOU DIED"
[ ] Respawn button works (controller + M+KB)
[ ] Player respawns at spawn point (0, 50, 0)
[ ] Health/hunger restored to 100
[ ] Inventory items kept on death
[ ] Enemies stop chasing after player death
[ ] No performance issues with 6+ enemies active
[ ] Maintains 60 FPS target

PART 4 - Known Issues Documentation:
Create a list of any bugs, limitations, or edge cases:

Example format:
```
KNOWN ISSUES (v0.6.0):
- [ ] Ice Wolf pack sometimes spawns too close together
- [ ] Shadow Wraith collision can be wonky when phasing
- [ ] Stone Golem ground slam range might be too large
- [ ] Player can attack while in death screen (need to disable)
```

PART 5 - Performance Check:
Run performance profiling:
- Target FPS: 60 minimum
- With 6 enemies: [measure FPS]
- With 12 enemies: [measure FPS]
- Draw calls: [measure, target <100]
- Memory: [measure, target <500 MB]

If performance issues found:
1. Reduce spawn rates
2. Simplify particle effects
3. Lower texture resolution
4. Implement distance culling

Deliverables:
1. Finalized rumble presets
2. Balance adjustments (if any) with reasoning
3. Complete testing checklist results (✓ or ✗ for each item)
4. Known issues list
5. Performance report
6. v0.6.0 release readiness assessment
```

**Expected Output:**
- Testing results for all checklist items
- Any balance changes needed
- Known issues documented
- Performance benchmarks
- Go/No-Go recommendation for v0.6.0 release

---

## TESTING & ITERATION WORKFLOW

### After Each Session:

1. **Immediate Testing:**
   - Apply code changes to local project
   - Test specific features implemented
   - Note any bugs or issues

2. **Session Summary:**
   - Post a summary of what was completed
   - List any deviations from plan
   - Note any blockers

3. **Next Session Prep:**
   - Update Claude with test results
   - Provide any error messages
   - Clarify requirements if needed

### Testing Template:
```
SESSION [X] TEST RESULTS:
═════════════════════════

Completed Features:
✓ [Feature 1]
✓ [Feature 2]
✗ [Feature 3] - Issue: [description]

Bugs Found:
1. [Bug description]
   - Reproduction steps
   - Expected vs actual behavior
   - Error message (if any)

Performance Notes:
- FPS: [X] (target: 60)
- Draw calls: [X] (target: <100)
- Memory: [X] MB (target: <500)

Questions for Next Session:
1. [Question 1]
2. [Question 2]
```

---

## PROMPT OPTIMIZATION TIPS

### Best Practices:

1. **Always Request File Upload First:**
   - Start every session by identifying needed files
   - Explicitly request upload from GitHub
   - Never assume or recreate existing code
   - Wait for files before proceeding

2. **Always Ask to Proceed:**
   - Present implementation plan first
   - Wait for confirmation before writing code
   - Allows you to course-correct if needed

3. **Code Only (No Docs Unless Requested):**
   - Skip UML diagrams, architecture docs, flowcharts
   - Focus on production-ready GDScript files
   - Only provide implementation code and testing instructions
   - Exception: Inline code comments are always good

4. **Reference Documentation:**
   - Always mention which section of IMPLEMENTATION_GUIDE to follow
   - Point to specific code snippets when available
   - Reference balance tables for numerical values

5. **Complete Specifications:**
   - Include all required properties/functions
   - Specify exact file paths
   - List all integration points

6. **Edge Cases:**
   - Explicitly ask for edge case handling
   - Mention state conflicts (e.g., dodge while charging)
   - Request error handling

7. **Testing Requirements:**
   - Include "how to test" instructions
   - Request test scenarios
   - Ask for performance considerations

8. **Incremental Complexity:**
   - Start with core functionality
   - Add polish in later prompts
   - Don't try to do everything at once

### Sample Good Prompt Structure:
```
TASK: [Clear objective]

CONTEXT:
- Current state: [what exists]
- Dependencies: [what's needed]
- References: [docs sections]

REQUIREMENTS:
1. [Specific requirement]
2. [Specific requirement]
3. [Specific requirement]

DELIVERABLES:
- [Expected file 1]
- [Expected file 2]
- [Expected documentation]

CONSTRAINTS:
- [Performance target]
- [Compatibility requirement]
- [Code style guideline]

TESTING:
How to verify: [specific test steps]
```

### Expected Response Pattern:

**Claude's Initial Response:**
```
I'll implement Task [X.Y] - [Task Name].

First, please upload these existing files from GitHub:
- res://player.gd
- res://audio_manager.gd
- res://project.godot

I'll be creating these new files:
- res://combat_system.gd
- res://weapon.gd

Please upload the existing files so I can review them and integrate properly.
```

**Your Response:**
```
[Upload files via Claude interface]
```

**Claude's Next Response:**
```
Files received. I've reviewed the current implementation.

PLAN:
1. Create combat_system.gd with [features]
2. Modify player.gd to add [integration]
3. Add input actions to project.godot

This will involve:
- [Key implementation detail 1]
- [Key implementation detail 2]
- [Key implementation detail 3]

Shall I proceed with this implementation?
```

**Your Response:**
```
Yes, proceed.
```

**Then Claude provides complete code.**

---

## GIT COMMIT GENERATION

### Quick Commit Command

When you're ready to commit your changes, simply say:
```
generate commit
```

Claude will output a properly formatted git commit message based on the work completed in the session.

### Commit Message Format:

```
v0.6.0: Task [X.Y] - [Brief description]

- [Key change 1]
- [Key change 2]
- [Key change 3]

Tested: [Brief test result]
Ref: Session [X]
```

### Example Usage:

**You:** "generate commit"

**Claude:**
```
v0.6.0: Task 1.1 - Combat system foundation

- Created combat_system.gd with attack/charge/dodge tracking
- Added weapon.gd Resource class with 3 weapon presets
- Integrated combat input handling in player.gd
- Added combat_attack and combat_dodge input actions

Tested: Attack and dodge inputs register correctly
Ref: Session 1
```

**Then you can copy-paste:**
```bash
git add res://combat_system.gd res://weapon.gd res://player.gd project.godot
git commit -m "v0.6.0: Task 1.1 - Combat system foundation

- Created combat_system.gd with attack/charge/dodge tracking
- Added weapon.gd Resource class with 3 weapon presets
- Integrated combat input handling in player.gd
- Added combat_attack and combat_dodge input actions

Tested: Attack and dodge inputs register correctly
Ref: Session 1"
git push
```

---

## GITHUB WORKFLOW INTEGRATION

### Commit Strategy:

**After Each Session:**

**Option 1 - Use "generate commit" command:**
```bash
# In Claude, type: "generate commit"
# Copy the generated commit message

# Review changes
git status
git diff

# Stage files
git add [files changed in session]

# Commit with Claude's generated message
git commit -m "[paste generated message]"

# Push to feature branch
git push origin v0.6.0-combat
```

**Option 2 - Manual commit:**
```bash
# Review changes
git status
git diff

# Stage files
git add [files changed in session]

# Commit with descriptive message
git commit -m "v0.6.0: Task [Y.Z] - [Task Name] implementation

- [Key feature 1]
- [Key feature 2]
- [Key feature 3]

Tested: [Brief test result]
Ref: Session [X]"

# Push to feature branch
git push origin v0.6.0-combat
```

**Branch Strategy:**
```
main (stable releases)
  â"‚
  â""â"€ v0.6.0-combat (current sprint)
       â"‚
       â"œâ"€ phase-1-combat-foundation (Sessions 1-5)
       â"œâ"€ phase-2-enemies (Sessions 6-9)
       â"œâ"€ phase-3-audio-visual (Sessions 10-11)
       â""â"€ phase-4-polish (Sessions 12-13)
```

**Merge Protocol:**
- Complete each phase
- Test thoroughly
- Merge phase branch to v0.6.0-combat
- Only merge v0.6.0-combat to main when ALL tasks complete

---

## CLAUDE PROJECTS BEST PRACTICES

### Knowledge Base Maintenance:

**Update After Major Changes:**
- Regenerate ROADMAP with progress updates
- Add new core scripts to knowledge base
- Remove outdated documentation

**Version Control:**
- Keep separate knowledge bases for each sprint
- Archive completed sprint docs
- Maintain "current state" snapshot document

### Session Continuity:

**Start Each Session:**
```
I'm continuing v0.6.0 development. Previous session completed [Task X.Y].
Here are the test results: [paste results]

Ready to start [Task X.Z]?
```

**Provide Context:**
- Recent changes summary
- Current blockers
- Test results from last session

### Effective Prompting:

1. **Be Specific:** "Implement combat_system.gd with charge tracking" not "add combat"
2. **Reference Docs:** "Follow IMPLEMENTATION_GUIDE section 2 structure"
3. **Include Constraints:** "Ensure 60 FPS with 6 active enemies"
4. **Request Complete Code:** "Provide production-ready, fully commented code"
5. **Ask for Tests:** "Include test instructions and edge cases"

---

## TROUBLESHOOTING GUIDE

### If Claude Produces Incomplete Code:

**Prompt:**
```
The code snippet you provided is incomplete. Please provide the FULL implementation of [file.gd] including:
- All necessary imports
- Complete function bodies
- All edge case handling
- Inline comments explaining logic
- Integration instructions

Do not use placeholders or "..." in the code.
```

### If Implementation Doesn't Match Spec:

**Prompt:**
```
The implementation doesn't match the ROADMAP requirements. Specifically:

Expected: [requirement from ROADMAP]
Received: [what Claude provided]

Please revise to exactly match the specification in IMPLEMENTATION_GUIDE section [X].
Reference balance table for numerical values.
```

### If Code Has Errors:

**Prompt:**
```
The code produces this error:
[paste error message]

File: [file.gd]
Line: [X]
Context: [what you were doing]

Please provide:
1. Root cause analysis
2. Fixed code
3. Explanation of the fix
4. How to prevent similar errors
```

---

## QUALITY ASSURANCE CHECKLIST

### Before Moving to Next Session:

**Code Quality:**
- [ ] All functions have docstrings
- [ ] Variables have meaningful names
- [ ] No magic numbers (use constants)
- [ ] Error handling present
- [ ] Edge cases covered

**Integration:**
- [ ] New code follows existing patterns
- [ ] No duplicate code
- [ ] Proper signal connections
- [ ] Resource paths correct
- [ ] Input actions defined

**Performance:**
- [ ] No unnecessary _process loops
- [ ] Efficient collision detection
- [ ] Proper node pooling
- [ ] Texture sizes optimized
- [ ] Audio streams configured correctly

**Testing:**
- [ ] Manual testing completed
- [ ] No console errors
- [ ] Expected behavior verified
- [ ] Controller tested (if applicable)
- [ ] Performance acceptable

---

## SPRINT COMPLETION PROTOCOL

### When All 10 Tasks Complete:

1. **Final Testing:**
   - Run complete testing checklist (from Session 7)
   - Test all 6 enemy types
   - Verify all sounds play (if generated)
   - Check controller support
   - Performance profiling

2. **Documentation:**
   - Update ROADMAP progress (10/10 tasks - 100%)
   - Create CHANGELOG_v0.6.0.md
   - Document known issues
   - List post-release improvements (v0.6.1 ideas)

3. **Release Preparation:**
   ```
   Please create a v0.6.0 release summary:
   
   1. Feature overview (simplified Minecraft-style combat highlights)
   2. Complete changelog (all 10 tasks)
   3. Design decisions (what was simplified and why)
   4. Known issues and limitations
   5. Post-release roadmap (v0.6.1 improvements)
   6. Testing instructions for users
   7. Credits (AI tools used: SFX Engine, Leonardo.ai)
   
   Format as Markdown for GitHub release notes.
   ```

4. **Git Release:**
   ```bash
   # Final commit
   git add .
   git commit -m "v0.6.0: Simplified combat system complete - All 10 tasks ✓"
   
   # Merge to main
   git checkout main
   git merge v0.6.0-combat
   
   # Tag release
   git tag -a v0.6.0 -m "Release v0.6.0 - Hunter & Prey (Simplified Minecraft-style Combat)"
   git push origin main --tags
   ```

5. **Next Sprint Planning:**
   ```
   v0.6.0 is complete. Help me plan v0.7.0:
   
   Review ROADMAP "NEXT SPRINT IDEAS" section.
   Based on v0.6.0 learnings and simplified combat approach, propose:
   
   1. v0.7.0 scope (which features from backlog)
   2. Should we add back removed features (charging, dodge, bow)?
   3. Task breakdown (similar to v0.6.0 structure)
   4. Estimated timeline
   5. Key technical challenges
   6. Dependencies/prerequisites
   ```

---

## CONCLUSION

This workflow provides:
- **Structure:** Phase-based development with clear sessions
- **Consistency:** Template prompts for each task
- **Quality:** Built-in testing and documentation
- **Efficiency:** Optimized for Claude's capabilities
- **Maintainability:** Version control integration
- **Flexibility:** Simplified from original 12 tasks to 10 based on design decisions

**Current Status:**
- ✅ Phase 1 COMPLETE: Tasks 1.1-1.4 (Simplified combat foundation)
- 🎯 Phase 2 NEXT: Tasks 2.1-2.3 (Enemy implementation)
- ⏳ Phase 3 UPCOMING: Tasks 3.1-3.3 (Audio/visual polish)
- ⏳ Phase 4 UPCOMING: Tasks 4.1-4.2 (Death system & final polish)

**Remember:**
- One task per session = manageable chunks
- Test between sessions = catch issues early
- Reference docs always = avoid ambiguity
- Request file uploads FIRST = work with actual code
- Complete code only = production-ready output
- Ask to proceed = maintain control
- Document everything = future-proof development

**Time Estimate:**
- 7 sessions remaining × 2-4 hours each = ~14-28 hours
- Total sprint: ~24-32 hours (8 hours already completed in Phase 1)
- Realistic timeline: 1-2 weeks solo development

**Simplified Combat Benefits:**
- ✅ Faster implementation (32h vs 48h)
- ✅ Easier to understand for players
- ✅ More responsive feel (no charge delays)
- ✅ Fewer bugs to fix
- ✅ Can add complexity later if desired (bow, dodge, charging)

Good luck with Crimson Veil v0.6.0! 🎮⚔️
