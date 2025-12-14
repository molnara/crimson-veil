# CRIMSON VEIL - DESIGN DOCUMENT
## A Configurable Survival Game Framework

---

## DOCUMENT PURPOSE

This document serves two purposes:
1. **Game Design** - Defines Crimson Veil's mechanics, systems, and vision
2. **Framework Design** - Documents the reusable survival game foundation

The goal is a **highly configurable survival framework** that can be reskinned for multiple projects with minimal code changes - just export variable tweaks and asset swaps.

---

## TABLE OF CONTENTS

1. [Vision & Pillars](#1-vision--pillars)
2. [Influences & Inspirations](#2-influences--inspirations)
3. [Core Gameplay Loop](#3-core-gameplay-loop)
4. [World Systems](#4-world-systems)
5. [Player Systems](#5-player-systems)
6. [Combat Systems](#6-combat-systems)
7. [Progression Systems](#7-progression-systems)
8. [Enemy Systems](#8-enemy-systems)
9. [Framework Configuration](#9-framework-configuration)
10. [Future Systems](#10-future-systems)

---

## 1. VISION & PILLARS

### 1.1 Game Vision (Crimson Veil)

> *A first-person survival fantasy where players explore a procedurally generated world, gather resources, craft tools, build shelter, and survive against the dangers that emerge when darkness falls.*

**The Name:** "Crimson Veil" suggests a world where something sinister lurks - perhaps a blood moon, vampiric threats, or a corrupted wilderness. The veil between safety and danger is thin.

### 1.2 Framework Vision

> *A modular, configurable survival game foundation in Godot 4.x that can be adapted for different themes (fantasy, sci-fi, post-apocalyptic) through configuration and asset changes rather than code rewrites.*

### 1.3 Design Pillars

| Pillar | Description | Framework Implication |
|--------|-------------|----------------------|
| **Exploration** | Discovering a vast procedural world | Biome system, chunk loading, POI spawning |
| **Survival** | Managing resources and staying alive | Health, hunger, (future: stamina, temperature) |
| **Progression** | Growing stronger through gear and skills | Tool tiers, crafting trees, (future: skills) |
| **Combat** | Challenging but fair encounters | Stamina-based, souls-like weight |
| **Building** | Creating a home in the wilderness | Placeable structures, storage |
| **Configurability** | Tweak don't rewrite | Export variables for all tunable values |

---

## 2. INFLUENCES & INSPIRATIONS

### 2.1 Primary Influences

| Game | What We Take | Implementation Status |
|------|--------------|----------------------|
| **Minecraft** | Chunk-based world, block building, simple crafting | ✅ Chunks, ⚠️ Building (basic), ✅ Crafting |
| **Valheim** | Stamina combat, biome progression, visual style | ⏳ Stamina, ✅ Biomes, ✅ Pixel art style |
| **Dark Souls** | Weighty combat, death penalty, challenge | ⚠️ Combat feel, ✅ Death/respawn, ⏳ Difficulty |
| **New World** | Gathering/crafting depth, world feel | ✅ Harvesting, ⚠️ Crafting depth |

### 2.2 Design Philosophy from Each

**From Minecraft:**
- World should feel infinite and explorable
- Crafting should be intuitive (combine materials → get tools)
- Players create their own goals

**From Valheim:**
- Biomes gate progression naturally (you CAN go to mountains early, but you'll die)
- Stamina makes every action meaningful
- Co-op enhances but isn't required

**From Dark Souls:**
- Combat should be deliberate, not spammy
- Death should have consequence but not be frustrating
- Enemies should telegraph attacks

**From New World:**
- Gathering should feel satisfying (animations, sounds, feedback)
- Resources should be plentiful but time-consuming
- World should feel alive

---

## 3. CORE GAMEPLAY LOOP

### 3.1 Moment-to-Moment (Seconds)
```
See Resource → Approach → Harvest → Collect
    or
See Enemy → Engage/Flee → Fight → Loot/Survive
```

### 3.2 Short-Term (Minutes)
```
Leave Base → Explore Area → Gather Resources → Return to Base
    ↓
Craft Better Gear → Venture Further → Repeat
```

### 3.3 Session (Hours)
```
Current Tier Gear → Explore New Biome → Find New Materials
    ↓
Unlock New Recipes → Craft Next Tier → Face Harder Enemies
    ↓
Build/Expand Base → Prepare for Night/Events
```

### 3.4 Long-Term (Campaign)
```
[Future] Defeat Biome Bosses → Unlock New Areas → Find Endgame Content
```

---

## 4. WORLD SYSTEMS

### 4.1 Procedural World Generation

**Chunk System:**
| Parameter | Default | Configurable | Purpose |
|-----------|---------|--------------|---------|
| `chunk_size` | 16 | ✅ @export | World unit size per chunk |
| `view_distance` | 4 | ✅ @export | Chunks loaded around player |
| `noise_scale` | 0.01 | ✅ @export | Terrain feature size |
| `height_multiplier` | 10.0 | ✅ @export | Terrain height variation |

**Design Intent:** Large, seamless world that loads/unloads efficiently. Player should never see loading screens during normal play.

### 4.2 Biome System

**Current Biomes (7):**

| Biome | Terrain | Vegetation | Enemies | Difficulty |
|-------|---------|------------|---------|------------|
| **Grassland** | Rolling hills | Trees, grass, berries | Passive | ⭐ Starter |
| **Forest** | Dense, hilly | Many trees, mushrooms | Wolves? | ⭐⭐ |
| **Beach** | Flat, sandy | Palm trees, rocks | Crabs? | ⭐ |
| **Desert** | Dunes | Cacti, rocks | Scorpions? | ⭐⭐⭐ |
| **Mountain** | Steep, rocky | Pine trees, boulders | Golems? | ⭐⭐⭐⭐ |
| **Snow** | Peaks | Sparse pines | Wolves? | ⭐⭐⭐⭐ |
| **Ocean** | Underwater | Seaweed? | Fish? | ⭐⭐ |

**Spawn Zone:** 100m radius around origin is always Grassland (safe start).

**Biome Configuration:**
```gdscript
@export var spawn_zone_radius: float = 100.0
@export var ocean_threshold: float = -0.35
@export var beach_threshold: float = -0.2
@export var mountain_threshold: float = 0.4
@export var forest_moisture: float = 0.15
@export var desert_temperature: float = 0.2
```

### 4.3 Day/Night Cycle

| Phase | Time | Duration | Gameplay Effect |
|-------|------|----------|-----------------|
| Dawn | 5:30-6:30 | 1 hour | Transition, enemies retreat |
| Day | 6:30-17:30 | 11 hours | Safe exploration |
| Dusk | 17:30-18:30 | 1 hour | Transition, prepare for night |
| Night | 18:30-5:30 | 11 hours | Dangerous, enemies active |

**[Future]:** Night should be meaningfully more dangerous (more spawns, stronger enemies, visibility reduction).

### 4.4 Weather System

**Status:** 🟡 v0.8.0 Implementation

The weather system provides dynamic environmental conditions that vary by biome and affect atmosphere, visibility, and (future) gameplay.

#### Weather States

| State | Visual Effect | Audio | Biomes |
|-------|---------------|-------|--------|
| **Clear** | Blue sky, no particles | Ambient only | All |
| **Cloudy** | Gray sky, light fog | Wind | All |
| **Rain** | Rain particles, puddles | Rain loop | Grassland, Forest, Beach, Mountain |
| **Heavy Rain** | Dense rain, reduced visibility | Heavy rain | Grassland, Forest, Beach |
| **Storm** | Rain + lightning flashes | Thunder, heavy rain | Grassland, Forest, Beach, Mountain |
| **Fog** | Dense fog, low visibility | Muffled sounds | Forest, Mountain, Beach |
| **Snow** | Snow particles, white fog | Light wind | Mountain, Snow |
| **Blizzard** | Heavy snow, very low visibility | Strong wind | Snow |
| **Sandstorm** | Sand particles, orange tint | Wind howl | Desert only |

#### Weather Probability per Biome

| Biome | Clear | Cloudy | Rain | Storm | Fog | Snow | Special |
|-------|-------|--------|------|-------|-----|------|---------|
| Grassland | 50% | 25% | 15% | 5% | 5% | - | - |
| Forest | 30% | 25% | 25% | 5% | 15% | - | - |
| Desert | 70% | 15% | - | - | - | - | 15% Sandstorm |
| Snow | 20% | 20% | - | - | 5% | 40% | 15% Blizzard |
| Beach | 60% | 25% | 10% | 5% | - | - | - |
| Mountain | 30% | 30% | - | 15% | 20% | 5% | - |

#### Weather Configuration

```gdscript
@export var weather_change_interval_min: float = 300.0  # 5 minutes
@export var weather_change_interval_max: float = 900.0  # 15 minutes
@export var transition_duration: float = 30.0           # 30 second fade
@export var rain_particle_count: int = 2000
@export var snow_particle_count: int = 1000
@export var fog_density_heavy: float = 0.05
```

#### Future Weather Gameplay Effects (v0.9.0+)

| Weather | Effect |
|---------|--------|
| Rain | Extinguishes fires, slippery surfaces |
| Storm | Lightning can strike, start fires |
| Blizzard | Cold damage without warmth |
| Sandstorm | Slow movement, damage over time |
| Fog | Reduced enemy detection range |

### 4.5 Wind System

**Status:** 🟡 v0.8.0 Implementation

Wind affects vegetation sway, weather particles, and atmosphere.

| Parameter | Range | Effect |
|-----------|-------|--------|
| Direction | 360° | Changes every 60s |
| Strength | 0.0-1.0 | Affects sway amount |
| Gusts | Random | Brief 2x strength bursts |

**Wind by Weather:**
| Weather | Wind Strength |
|---------|---------------|
| Clear | 0.05 - 0.3 |
| Cloudy | 0.1 - 0.4 |
| Rain | 0.2 - 0.5 |
| Storm | 0.5 - 0.9 |
| Blizzard | 0.6 - 1.0 |
| Sandstorm | 0.7 - 1.0 |

### 4.6 Biome Ground Cover

**Status:** 🟡 v0.8.0 Implementation

Each biome has specific allowed ground cover types:

| Biome | Allowed | Not Allowed |
|-------|---------|-------------|
| **Grassland** | Grass, flowers, clover | - |
| **Forest** | Dark grass, ferns, moss, fallen logs | Flowers |
| **Desert** | Dead shrubs, dry grass, bones, rocks | Green grass, flowers |
| **Snow** | Snow mounds, ice crystals, frozen shrubs | Grass, flowers |
| **Beach** | Shells, seaweed, driftwood, pebbles | Grass |
| **Mountain** | Alpine grass (sparse), rocks, lichen | Dense grass, flowers |

**Vegetation Color Tinting:**
| Biome | Grass Tint |
|-------|------------|
| Grassland | Bright green (0.4, 0.7, 0.3) |
| Forest | Dark green (0.2, 0.5, 0.2) |
| Mountain | Gray-green (0.5, 0.6, 0.4) |
| Snow | Frosted (0.7, 0.8, 0.7) |

---

## 5. PLAYER SYSTEMS

### 5.1 Health System

| Parameter | Default | Configurable | Notes |
|-----------|---------|--------------|-------|
| `max_health` | 100 | ✅ @export | Player maximum HP |
| `health_regen_rate` | 0 | ✅ @export | HP/second (0 = no regen) |
| `damage_flash_duration` | 0.1 | Hardcoded | Visual feedback |

**Design Intent:** Health is precious. No passive regeneration forces players to use food/healing items.

### 5.2 Hunger System

| Parameter | Default | Configurable | Notes |
|-----------|---------|--------------|-------|
| `max_hunger` | 100 | ✅ @export | Maximum hunger |
| `hunger_drain_rate` | ~0.5/min | ✅ @export | Passive drain |
| `starvation_damage` | 1/tick | ✅ @export | Damage at 0 hunger |
| `low_hunger_threshold` | 20 | ✅ @export | Speed penalty trigger |

**Food Values:**
| Item | Hunger Restored |
|------|-----------------|
| Small Strawberry | 10 |
| Medium Strawberry | 20 |
| Large Strawberry | 35 |
| Small Mushroom | 15 |
| Medium Mushroom | 25 |
| Large Mushroom | 40 |

**Design Intent:** Hunger creates exploration pressure - you can't sit in base forever.

### 5.3 Inventory System

| Parameter | Default | Configurable | Notes |
|-----------|---------|--------------|-------|
| `max_slots` | 32 | Hardcoded | UI grid slots |
| `stack_limits` | varies | Per-item | Wood: 99, Tools: 1 |

**Stack Limits by Category:**
| Category | Limit | Examples |
|----------|-------|----------|
| Raw Materials | 99 | Wood, Stone |
| Food | 50 | Berries, Mushrooms |
| Tools | 1 | Axes, Pickaxes |
| Weapons | 1 | Clubs, Swords |
| Buildables | 20 | Walls, Campfires |

### 5.4 Movement System

| Parameter | Default | Configurable | Notes |
|-----------|---------|--------------|-------|
| `move_speed` | 5.0 | ✅ @export | Walk speed (m/s) |
| `sprint_speed` | 10.0 | ✅ @export | Sprint speed (m/s) |
| `jump_velocity` | 4.5 | ✅ @export | Jump force |
| `mouse_sensitivity` | 0.002 | ✅ @export | Look sensitivity |
| `controller_look_sensitivity` | 3.0 | ✅ @export | Stick sensitivity |

**[Future] Stamina Integration:**
- Sprinting drains stamina
- Jumping drains stamina
- Attacking drains stamina
- Stamina regenerates when not sprinting

### 5.5 Death & Respawn

**Current Implementation:**
- Death triggers on 0 health
- Death screen shows death count
- Respawn at spawn point with full health/hunger
- No item loss (currently)

**[Future] Death Penalty Options (Configurable):**
| Mode | Item Loss | XP Loss | Corpse Run |
|------|-----------|---------|------------|
| Casual | None | None | No |
| Normal | Inventory | None | Yes |
| Hardcore | Inventory | 50% | Yes |
| Permadeath | Everything | 100% | No (new game) |

---

## 6. COMBAT SYSTEMS

### 6.1 Design Philosophy

**Souls-like Principles:**
- Every attack is a commitment
- Stamina limits spam
- Positioning matters
- Enemies telegraph attacks
- Death is a teacher, not a punishment

**Current State vs Target:**
| Aspect | Current | Target |
|--------|---------|--------|
| Attack commitment | ⚠️ Can spam | Locked animation + stamina |
| Enemy telegraph | ✅ Basic | Clear wind-up animations |
| Hit feedback | ⚠️ Basic flash | Screen shake, hitstop, sound |
| Stamina | ❌ Not implemented | Core combat resource |
| Blocking | ❌ Not implemented | Shields, timed blocks |
| Dodging | ❌ Not implemented | I-frames, stamina cost |

### 6.2 Weapon System

**Current Weapons:**

| Weapon | Damage | Range | Cooldown | Harvest Types |
|--------|--------|-------|----------|---------------|
| Stone Axe | 18 | 2.5m | 1.0s | Wood |
| Stone Pickaxe | 12 | 2.5m | 1.2s | Stone, Ore |
| Wooden Club | 15 | 2.5m | 1.0s | None |
| Stone Spear | 20 | 3.5m | 1.2s | None |
| Bone Sword | 25 | 3.0m | 1.0s | None |

**[Future] Weapon Tiers:**
```
Wood Tier → Stone Tier → Bone Tier → Iron Tier → ?
   ↓            ↓            ↓           ↓
 Basic       +50%         +100%       +150%
```

### 6.3 Combat Feel Improvements (Priority)

**Hit Feedback Checklist:**
- [ ] Camera shake on hit (intensity by damage)
- [ ] Hitstop (brief pause on contact) - 50-100ms
- [ ] Hit sound variation (3+ sounds per weapon)
- [ ] Enemy knockback/stagger
- [ ] Damage numbers (optional, configurable)
- [ ] Blood/particle effects (configurable)

**Player Feedback Checklist:**
- [ ] Screen flash on damage
- [ ] Controller rumble (✅ implemented)
- [ ] Directional damage indicator
- [ ] Health bar flash
- [ ] Pain sound

### 6.4 [Future] Stamina System

| Action | Stamina Cost | Notes |
|--------|--------------|-------|
| Light Attack | 15 | Quick, low commitment |
| Heavy Attack | 30 | Slow, high damage |
| Block | 5/hit | Drain on block |
| Dodge/Roll | 25 | I-frames during roll |
| Sprint | 10/sec | Continuous drain |
| Jump | 10 | Per jump |

| Parameter | Default | Notes |
|-----------|---------|-------|
| `max_stamina` | 100 | Maximum stamina |
| `stamina_regen` | 20/sec | Regen when not sprinting |
| `regen_delay` | 1.0s | Delay after action |

---

## 7. PROGRESSION SYSTEMS

### 7.1 Crafting System

**Current Recipes:**
| Item | Ingredients | Category |
|------|-------------|----------|
| Stone Axe | 3 Wood, 5 Stone | Tools |
| Stone Pickaxe | 3 Wood, 5 Stone | Tools |
| Campfire | 10 Wood, 5 Stone | Building |
| Torch | 2 Wood | Building |
| Wood Wall | 4 Wood | Building |

**[Future] Recipe Unlocks:**
- Recipes locked until player finds/harvests required materials
- "Unknown Recipe" shows in crafting menu with ??? ingredients
- Discovering new materials unlocks related recipes

### 7.2 Tool Progression

**Harvest Requirements:**
| Resource | Required Tool | Without Tool |
|----------|---------------|--------------|
| Trees | Axe | Cannot harvest |
| Rocks | Pickaxe | Cannot harvest |
| Mushrooms | Any/Hand | Normal harvest |
| Berries | Any/Hand | Normal harvest |

**[Future] Tool Durability (Optional):**
| Tool | Durability | Repair Cost |
|------|------------|-------------|
| Stone Axe | 100 uses | 2 Stone |
| Stone Pickaxe | 100 uses | 2 Stone |

### 7.3 [Future] Skill System

**Option A: Passive Unlocks**
- Use axe → Get better at chopping → Faster harvest
- Kill enemies → Get better at combat → More damage

**Option B: Skill Points**
- Gain XP from actions
- Spend points in skill trees
- Trees: Combat, Survival, Crafting, Building

**Option C: No Skills**
- All progression is gear-based
- Simpler, more Minecraft-like

---

## 8. ENEMY & CRITTER SYSTEMS

### 8.1 CritterSpawner Overview

The **CritterSpawner** (`critter_spawner.gd`) handles ALL creature spawning - both passive ambient critters and hostile enemies. It uses a chunk-based approach similar to VegetationSpawner.

**Key Features:**
- ✅ Biome-specific spawning
- ✅ Day/night time awareness
- ✅ Pack spawning (wolf packs)
- ✅ All spawn rates configurable via @export
- ✅ Debug hotkeys (1-6) for testing
- ✅ Chunk-based tracking with cleanup
- ✅ Minimum spawn distance from player (15m)

### 8.2 Ambient Critters (Passive)

| Critter | Type | Biomes | Density | Behavior |
|---------|------|--------|---------|----------|
| **Rabbit** | Ground | Grassland, Forest | 15% | Hops, flees player |
| **Fox** | Ground | Forest | 10% | Wanders, hunts rabbits? |
| **Arctic Fox** | Ground | Snow | 12% | Snow variant |
| **Crab** | Ground | Beach | 18% | Sideways scuttle |
| **Lizard** | Ground | Desert | 14% | Skitters, sun-basks |
| **Butterfly** | Flying | Grassland, Forest | 25% | Daytime only |
| **Eagle** | Flying | Mountain, All | 4% | High altitude soaring |
| **Firefly** | Particle | Forest | 30% | Nighttime only |

**Critter Configuration:**
```gdscript
@export var rabbit_density: float = 0.15
@export var butterfly_density: float = 0.25
@export var firefly_density: float = 0.30
@export var critters_per_chunk: int = 4
@export var spawn_radius_chunks: int = 3
```

### 8.3 Enemy Types (Hostile)

| Enemy | Scene File | Biome | Spawn Rate | Behavior |
|-------|------------|-------|------------|----------|
| **Corrupted Rabbit** | `corrupted_rabbit.tscn` | Forest | 15% | Fast, aggressive rabbit |
| **Forest Goblin** | `forest_goblin.tscn` | Forest | 8% | Melee ambusher |
| **Desert Scorpion** | `desert_scorpion.tscn` | Desert | 12% | Poison attacks? |
| **Ice Wolf** | `ice_wolf.tscn` | Snow | 10% (pack) | Pack hunter, 2-3 per pack |
| **Stone Golem** | `stone_golem.tscn` | Mountain | 5% | Slow, heavy hits |
| **Shadow Wraith** | `shadow_wraith.tscn` | All (night) | 8% | Night-only spawns |

**Enemy Spawn Configuration:**
```gdscript
@export var corrupted_rabbit_spawn_rate: float = 0.15
@export var forest_goblin_spawn_rate: float = 0.08
@export var desert_scorpion_spawn_rate: float = 0.12
@export var ice_wolf_pack_spawn_rate: float = 0.10
@export var stone_golem_spawn_rate: float = 0.05
@export var shadow_wraith_spawn_rate: float = 0.08
```

### 8.4 Enemy Base Class Design

**State Machine:**
```
IDLE → [Player in detection_range] → CHASE → [Player in attack_range] → ATTACK
  ↑                                    ↓                                   ↓
  └──── [Player beyond deaggro_range] ─┘                                   │
                                                                           ↓
                                                                         DEATH
```

**Base Parameters (Enemy class, all @export):**
| Parameter | Default | Purpose |
|-----------|---------|---------|
| `max_health` | 50 | Enemy HP |
| `damage` | 10 | Damage per hit |
| `move_speed` | 3.0 | Chase speed (m/s) |
| `detection_range` | 10.0 | Aggro trigger distance |
| `deaggro_range` | 20.0 | Stop chasing distance (0 = never) |
| `attack_range` | 2.0 | Melee attack distance |
| `attack_cooldown_duration` | 1.5s | Time between attacks |
| `attack_telegraph_duration` | 0.3s | Wind-up before damage |
| `drop_table` | [] | Loot on death |

**Virtual Methods (override in subclasses):**
```gdscript
func create_enemy_visual()    # Build the enemy mesh/model
func on_attack_telegraph()    # Wind-up effects
func on_attack_execute()      # Attack effects/sounds
func on_hit()                 # Damage received effects
func on_death()               # Death effects/sounds
```

### 8.5 Pack Behavior (Ice Wolves)

Wolves spawn in packs of 2-3 with shared `pack_id`:
- Spawn in triangle formation (2.5m apart)
- [Future] Alert packmates when one detects player
- [Future] Flanking behavior

```gdscript
func spawn_wolf_pack(center_pos: Vector3, chunk_pos: Vector2i):
    var pack_size = randi_range(2, 3)
    var pack_id = randi()
    for i in range(pack_size):
        var angle = (i / float(pack_size)) * TAU
        var offset = Vector3(cos(angle) * 2.5, 0, sin(angle) * 2.5)
        # ... spawn wolf with pack_id
```

### 8.6 Debug Spawning

**Hotkeys (when `debug_spawn_hotkeys = true`):**
| Key | Enemy |
|-----|-------|
| 1 | Corrupted Rabbit |
| 2 | Forest Goblin |
| 3 | Desert Scorpion |
| 4 | Ice Wolf Pack (3) |
| 5 | Stone Golem |
| 6 | Shadow Wraith |

**Debug Configuration:**
```gdscript
@export var debug_enemy_spawns: bool = false      # Log spawns
@export var debug_spawn_attempts: bool = false    # Log attempts (verbose)
@export var debug_spawn_hotkeys: bool = true      # Enable 1-6 keys
@export var debug_spawn_distance: float = 5.0     # Spawn distance from player
```

### 8.7 Loot System

**Drop Table Format:**
```gdscript
@export var drop_table: Array[Dictionary] = [
    {"item": "bone", "chance": 0.8},
    {"item": "leather", "chance": 0.5},
    {"item": "rare_gem", "chance": 0.05}
]
```

---

## 9. FRAMEWORK CONFIGURATION

### 9.1 Configuration Philosophy

**Rule:** If a value might need tuning, it should be an `@export` variable.

**Categories:**
1. **World Generation** - Biome thresholds, chunk sizes, view distance
2. **Vegetation** - Densities, spawn rates, biome-specific settings
3. **Player Stats** - Health, hunger, movement speeds
4. **Combat** - Damage, ranges, cooldowns
5. **Enemies** - Stats, AI ranges, spawn rates
6. **Audio** - Volumes, frequencies
7. **Graphics** - Quality presets, view distances

### 9.2 Reskinning Guide

**To create a new game from this framework:**

1. **Change Theme:**
   - Replace textures in `PixelTextureGenerator`
   - Swap music/SFX files
   - Update UI colors/fonts

2. **Adjust World:**
   - Rename biomes (Forest → Corrupted Woods)
   - Tune biome thresholds
   - Add/remove vegetation types

3. **Modify Enemies:**
   - Create new Enemy subclasses
   - Swap visuals in `create_enemy_visual()`
   - Adjust stats via exports

4. **Tune Survival:**
   - Adjust hunger drain rate
   - Enable/disable features (thirst, temperature)
   - Set difficulty via death penalty

5. **Change Progression:**
   - Modify crafting recipes
   - Add/remove tool tiers
   - Tune resource spawn rates

### 9.3 Export Variable Checklist

**ChunkManager:**
- [x] chunk_size
- [x] view_distance
- [x] noise_scale
- [x] height_multiplier
- [x] biome_scale
- [x] temperature_scale
- [x] moisture_scale
- [x] All biome thresholds

**VegetationSpawner:**
- [x] tree_density
- [x] rock_density
- [x] mushroom_density
- [x] strawberry_density
- [x] grass_density
- [x] flower_density
- [x] spawn_radius
- [x] All biome-specific densities
- [x] Tree size/shape parameters

**Player:**
- [x] move_speed
- [x] sprint_speed
- [x] jump_velocity
- [x] mouse_sensitivity
- [x] controller_look_sensitivity

**HealthHungerSystem:**
- [x] max_health
- [x] max_hunger
- [x] hunger_drain_rate

**Enemy:**
- [x] max_health
- [x] damage
- [x] move_speed
- [x] detection_range
- [x] deaggro_range
- [x] attack_range
- [x] attack_cooldown
- [x] attack_telegraph_duration

**ToolSystem:**
- [ ] TOOL_DATA should be @export or resource-based

---

## 10. FUTURE SYSTEMS

### 10.1 Priority Roadmap

| Priority | System | Status | Effort |
|----------|--------|--------|--------|
| 🔴 High | Combat Feel (hitstop, feedback) | Not started | ~8h |
| 🔴 High | Stamina System | Not started | ~12h |
| 🔴 High | Enemy Variety (2-3 types) | Not started | ~16h |
| 🟡 Medium | Enemy Spawner (biome-based) | Not started | ~8h |
| 🟡 Medium | Save/Load System | Not started | ~16h |
| 🟡 Medium | Blocking/Parrying | Not started | ~8h |
| 🟢 Low | Dodge Rolling | Not started | ~6h |
| 🟢 Low | Weather System | Not started | ~12h |
| 🟢 Low | Temperature/Cold | Not started | ~8h |
| 🟢 Low | Skill System | Not started | ~20h |

### 10.2 System Dependencies

```
Stamina System
    ↓
├── Combat Feel (attacks cost stamina)
├── Blocking (blocking costs stamina)
└── Dodge Roll (rolling costs stamina)

Enemy Spawner
    ↓
├── Enemy Variety (spawner needs types to spawn)
└── Biome Danger (spawner controls density)

Save/Load
    ↓
├── Player Progress (position, inventory, stats)
├── World State (placed buildings, opened chests)
└── Settings (already saved separately)
```

### 10.3 Optional Systems (Nice to Have)

| System | Description | Adds to |
|--------|-------------|---------|
| **Fishing** | Minigame, food source | Survival variety |
| **Farming** | Plant crops, wait, harvest | Base building |
| **Taming** | Capture and use animals | Exploration |
| **Dungeons** | Hand-crafted POIs | Exploration, loot |
| **Bosses** | Major challenges | Progression gates |
| **Multiplayer** | Co-op survival | Replayability |
| **Modding** | Player-made content | Longevity |

---

## APPENDIX A: QUICK REFERENCE

### Collision Layers
| Layer | Name | Usage |
|-------|------|-------|
| 1 | Terrain | Ground, chunks |
| 2 | Resources | Harvestable objects |
| 3 | Interactive | Containers, doors |
| 8 | Critters | Passive creatures |
| 9 | Enemies | Hostile creatures |

### Input Actions
| Action | Keyboard | Controller |
|--------|----------|------------|
| Move | WASD | Left Stick |
| Look | Mouse | Right Stick |
| Jump | Space | A |
| Sprint | Shift | B (hold) |
| Attack | LMB | RT |
| Interact | E | A |
| Inventory | I | Y |
| Crafting | C | X |
| Tool Cycle | - | RB/LB |

### Audio Buses
| Bus | Purpose | Default Volume |
|-----|---------|----------------|
| Master | Overall | 100% |
| SFX | Sound effects | 100% |
| Music | Background music | 80% |
| Ambient | Environmental loops | 70% |
| UI | Interface sounds | 100% |

---

## APPENDIX B: DESIGN DECISIONS LOG

| Decision | Choice | Rationale | Date |
|----------|--------|-----------|------|
| Chunk size | 16 units | Balance of detail vs performance | v0.1 |
| No passive health regen | Intentional | Encourages resource gathering | v0.3 |
| Tools = Weapons | Unified system | Simpler inventory, realistic | v0.6 |
| Pixel art textures | Procedural | No external assets needed, consistent style | v0.1 |
| Death = respawn only | No item loss | Less punishing during development | v0.6 |
| 60 FPS target | Performance | Smooth gameplay priority | v0.7 |

---

## APPENDIX C: KNOWN ISSUES & TECH DEBT

| Issue | Severity | Notes |
|-------|----------|-------|
| Draw calls still high (~5000) | Low | 60 FPS achieved, billboard LOD would fix |
| No material caching | Low | Works fine, optimization opportunity |
| TOOL_DATA not configurable | Medium | Should be @export or Resource |
| Enemy spawner missing | High | Enemies need spawn system |
| No save system | High | Progress lost on exit |
| Combat feels floaty | Medium | Needs hitstop, stamina, weight |

---

*Document Version: 0.7.0*
*Framework Version: 1.0*
*Last Updated: Post-Performance Sprint*
