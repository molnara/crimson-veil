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
| **Minecraft** | Chunk-based world, block building, simple crafting, static weather zones | ✅ Chunks, ⚠️ Building (basic), ✅ Crafting, ✅ Weather |
| **Valheim** | Stamina combat, biome progression, visual style | ⏳ Stamina, ✅ Biomes, ✅ Pixel art style |
| **Dark Souls** | Weighty combat, death penalty, challenge | ⚠️ Combat feel, ✅ Death/respawn, ⏳ Difficulty |
| **New World** | Gathering/crafting depth, world feel | ✅ Harvesting, ⚠️ Crafting depth |

### 2.2 Design Philosophy from Each

**From Minecraft:**
- World should feel infinite and explorable
- Crafting should be intuitive (combine materials → get tools)
- Players create their own goals
- Weather stays in place - you walk through rain/snow zones

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

### 4.4 Weather System ✅ IMPLEMENTED

**Status:** ✅ v0.8.0 Complete

The weather system provides dynamic environmental conditions that vary by biome and affect atmosphere, visibility, and (future) gameplay.

#### Weather States (8 total)

| State | Visual Effect | Audio | Biomes |
|-------|---------------|-------|--------|
| **Clear** | Blue sky, no particles | Ambient only | All |
| **Cloudy** | Gray sky, light fog | Wind | All |
| **Rain** | Rain particles (12k), blue streaks | Rain loop | Grassland, Forest, Beach, Mountain |
| **Storm** | Heavy rain (20k), angled, darker | Heavy rain, thunder | Grassland, Forest, Beach, Mountain |
| **Fog** | Dense fog, low visibility | Muffled sounds | Forest, Mountain, Beach |
| **Snow** | Snow particles (8k), white flakes | Light wind | Mountain, Snow |
| **Blizzard** | Heavy snow (18k), horizontal wind | Strong wind | Snow |
| **Sandstorm** | Sand particles, orange tint | Wind howl | Desert only |

#### Weather Particle Details

| Weather  | Particles | Size        | Fall Speed | Effect |
|----------|-----------|-------------|------------|--------|
| Rain     | 12,000    | 0.06 x 1.8  | Fast (-25) | Vertical streaks |
| Storm    | 20,000    | 0.08 x 2.5  | Very fast (-40) | Angled, wind-blown |
| Snow     | 8,000     | 0.2 x 0.2   | Slow (-3)  | Gentle drift |
| Blizzard | 18,000    | 0.25 x 0.25 | Medium (-8) | Strong horizontal wind |

#### Minecraft-Style Weather Behavior

Weather particles use a **Minecraft-style** approach:
- Particles spawn at player's starting position
- Weather **stays in place** as player walks through it
- If player teleports >200 units away, weather repositions
- Creates natural "weather zones" in the world

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
```

#### Weather Debug Controls

| Key | Action |
|-----|--------|
| F4 | Show weather status |
| F5 | Cycle weather (with transition) |
| F6 | Random weather (instant) |

#### Future Weather Gameplay Effects (v0.9.0+)

| Weather | Effect |
|---------|--------|
| Rain | Extinguishes fires, slippery surfaces |
| Storm | Lightning can strike, start fires |
| Blizzard | Cold damage without warmth |
| Sandstorm | Slow movement, damage over time |
| Fog | Reduced enemy detection range |

### 4.5 Wind System

**Status:** 🟡 v0.8.0 Planned

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

---

## 8. ENEMY SYSTEMS

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
8. **Weather** - Particle counts, timing, biome probabilities

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

6. **Customize Weather:**
   - Adjust BIOME_WEATHER_WEIGHTS in weather_manager.gd
   - Modify particle colors/sizes in weather_particles.gd
   - Add new weather types if needed

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

**WeatherManager:**
- [x] weather_change_interval_min
- [x] weather_change_interval_max
- [x] transition_duration
- [x] fog_density settings
- [x] debug_logging

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
| ✅ Done | Weather System | Complete | ~12h |
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

Weather System ✅
    ↓
├── Temperature System (weather affects temperature)
└── Gameplay Effects (rain extinguishes fire, etc.)
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
| Weather Status | F4 | - |
| Cycle Weather | F5 | - |
| Random Weather | F6 | - |

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
| Modular vegetation | Maintainability | Easier to add/modify vegetation types | v0.7.1 |
| Rare harvestables | Survival feel | Resources feel valuable, encourage exploration | v0.7.1 |
| Icosphere berries | Visual quality | Rounder berries (20 tri) look better than octahedra (8 tri) | v0.7.1 |
| Golden angle distribution | Even spread | Prevents berry clumping on bushes | v0.7.1 |
| Minecraft-style weather | Immersion | Weather feels like world feature, not player attachment | v0.8.0 |
| Manual Node3D for particles | Bug workaround | .tscn instantiation breaks GPUParticles3D | v0.8.0 |
| Separate storm/blizzard | Variety | Different intensity levels feel distinct | v0.8.0 |

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
| GPUParticles3D .tscn bug | Medium | Must use manual Node3D, documented |
| Fog/Sandstorm particles missing | Low | Weather states exist but no particles yet |

---

*Document Version: 0.8.1*
*Framework Version: 1.0*
*Last Updated: Weather Particle System Implementation*
