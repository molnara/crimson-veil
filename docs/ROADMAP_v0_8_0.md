# ROADMAP v0.8.0 - "Living World"
## Biome Diversity & Dynamic Weather

---

## SPRINT OVERVIEW

**Theme:** Make the world feel alive through biome-specific environments and dynamic weather
**Estimated Hours:** ~35h
**Priority:** Biome Polish → Weather Foundation → Atmosphere → Life

---

## SUCCESS CRITERIA

| Metric | Target |
|--------|--------|
| Biome Distinction | Each biome visually unique (no grass in desert) |
| Weather Types | 4+ weather states functional |
| Performance | Maintain 60 FPS with weather effects |
| Atmosphere | Ambient sounds + visuals per biome |

---

## PHASE 1: BIOME GROUND COVER FIX (6h)

### Task 1.1: Remove Invalid Ground Cover (2h)
**Priority:** 🔴 Critical
**File:** `vegetation_spawner.gd`

Remove grass/flowers from biomes where they don't belong:
- [ ] Desert: No grass, no flowers
- [ ] Snow: No grass, no flowers  
- [ ] Beach: No grass, no flowers
- [ ] Ocean: No vegetation

**Acceptance Criteria:**
- Walking through desert shows only sand, rocks, dead shrubs
- Snow biome has only snow mounds, ice, sparse pine
- Beach has sand, shells, driftwood only

### Task 1.2: Biome-Specific Ground Cover (2h)
**Priority:** 🔴 Critical
**File:** `vegetation_spawner.gd`

Add appropriate ground cover per biome:
- [ ] Desert: Dead shrubs, rocks, bones, dry grass tufts
- [ ] Snow: Snow mounds, ice patches, frozen shrubs
- [ ] Beach: Shells, pebbles, seaweed, driftwood
- [ ] Mountain: Rocks, gravel, sparse alpine grass

### Task 1.3: Vegetation Color Tinting (2h)
**Priority:** 🟡 Medium
**Files:** `vegetation_spawner.gd`, `pixel_texture_generator.gd`

Tint vegetation colors per biome:
- [ ] Grassland: Bright green (0.4, 0.7, 0.3)
- [ ] Forest: Dark green (0.2, 0.5, 0.2)
- [ ] Mountain: Gray-green (0.5, 0.6, 0.4)
- [ ] Snow: Frosted white-green (0.7, 0.8, 0.7)

---

## PHASE 2: WEATHER SYSTEM FOUNDATION (10h)

### Task 2.1: WeatherManager Singleton (3h)
**Priority:** 🔴 Critical
**File:** `weather_manager.gd` (NEW)

Create weather state machine:
- [ ] Weather states: CLEAR, CLOUDY, RAIN, STORM, FOG, SNOW, SANDSTORM
- [ ] Biome-specific weather tables
- [ ] Weather transition system (gradual changes)
- [ ] Time-based weather changes
- [ ] @export variables for all tuning

```gdscript
# Weather probability per biome
const BIOME_WEATHER = {
    "GRASSLAND": {CLEAR: 0.5, CLOUDY: 0.25, RAIN: 0.15, STORM: 0.05, FOG: 0.05},
    "FOREST": {CLEAR: 0.3, CLOUDY: 0.25, RAIN: 0.25, FOG: 0.15, STORM: 0.05},
    "DESERT": {CLEAR: 0.7, CLOUDY: 0.15, SANDSTORM: 0.15},
    "SNOW": {CLEAR: 0.2, CLOUDY: 0.3, SNOW: 0.4, BLIZZARD: 0.1},
    "BEACH": {CLEAR: 0.6, CLOUDY: 0.2, RAIN: 0.1, STORM: 0.1},
    "MOUNTAIN": {CLEAR: 0.3, CLOUDY: 0.3, FOG: 0.2, STORM: 0.15, SNOW: 0.05}
}
```

### Task 2.2: Rain System (2h)
**Priority:** 🔴 Critical
**File:** `weather_manager.gd`

Implement rain weather:
- [ ] Rain particle system (GPUParticles3D)
- [ ] Rain follows player (world-space particles)
- [ ] Rain intensity levels (light, medium, heavy)
- [ ] Rain sound effect (looping)
- [ ] Puddle spawning (optional visual)

### Task 2.3: Snow System (2h)
**Priority:** 🟡 Medium
**File:** `weather_manager.gd`

Implement snow weather:
- [ ] Snow particle system
- [ ] Slower fall than rain
- [ ] Snow accumulation visual (optional)
- [ ] Blizzard variant (heavy + wind)

### Task 2.4: Fog System (1.5h)
**Priority:** 🟡 Medium
**File:** `weather_manager.gd`

Implement fog weather:
- [ ] Adjust WorldEnvironment fog density
- [ ] Fog color per biome
- [ ] Gradual fog roll-in/out
- [ ] Reduced visibility range

### Task 2.5: Sandstorm System (1.5h)
**Priority:** 🟡 Medium
**File:** `weather_manager.gd`

Implement sandstorm (desert only):
- [ ] Sand particle system (horizontal movement)
- [ ] Screen tint overlay (tan/orange)
- [ ] Reduced visibility
- [ ] Wind sound effect

---

## PHASE 3: ENVIRONMENTAL ATMOSPHERE (8h)

### Task 3.1: Biome Fog Colors (1h)
**Priority:** 🟡 Medium
**File:** `day_night_cycle.gd` or `weather_manager.gd`

Set fog color per biome:
- [ ] Grassland: Light blue
- [ ] Forest: Dark green
- [ ] Desert: Sandy tan
- [ ] Snow: White
- [ ] Beach: Light cyan
- [ ] Mountain: Gray/purple

### Task 3.2: Biome Ambient Lighting (2h)
**Priority:** 🟢 Low
**File:** `day_night_cycle.gd`

Subtle lighting tint per biome:
- [ ] Grassland: Warm yellow
- [ ] Forest: Green tint
- [ ] Desert: Hot orange
- [ ] Snow: Cool blue
- [ ] Beach: Bright white
- [ ] Mountain: Gray/purple

### Task 3.3: Wind System (3h)
**Priority:** 🟡 Medium
**File:** `wind_system.gd` (NEW)

Create wind that affects vegetation:
- [ ] Wind direction (changes over time)
- [ ] Wind strength (calm, breezy, gusty, strong)
- [ ] Grass/flower sway shader
- [ ] Tree rustle animation
- [ ] Wind affects weather particles (rain angle)
- [ ] Increases before storms

### Task 3.4: Footstep Particles (2h)
**Priority:** 🟢 Low
**File:** `player.gd`

Kick up particles when walking:
- [ ] Snow: White puff
- [ ] Sand/Desert: Tan dust
- [ ] Dirt: Brown dust
- [ ] Water: Splash
- [ ] Grass: Subtle green particles (optional)

---

## PHASE 4: AMBIENT LIFE (8h)

### Task 4.1: Particle Effects - Falling Leaves (2h)
**Priority:** 🟡 Medium
**File:** `vegetation_spawner.gd` or `biome_effects.gd` (NEW)

Forest atmosphere:
- [ ] Falling leaf particles near trees
- [ ] Leaves drift with wind
- [ ] Autumn color variation (optional)

### Task 4.2: Tumbleweeds (2h)
**Priority:** 🟡 Medium
**File:** `tumbleweed.gd` (NEW)

Desert atmosphere:
- [ ] Tumbleweed RigidBody3D
- [ ] Spawns randomly in desert
- [ ] Rolls with wind direction
- [ ] Despawns when far from player

### Task 4.3: Additional Ambient Critters (2h)
**Priority:** 🟢 Low
**File:** `critter_spawner.gd`

Add variety:
- [ ] Deer (grassland/forest) - grazes, flees
- [ ] Seagulls (beach) - circles, lands
- [ ] Snake (desert) - slithers, flees

### Task 4.4: Biome Ambient Sound Polish (2h)
**Priority:** 🟡 Medium
**File:** `ambient_manager.gd`

Enhance audio per biome:
- [ ] Desert: Wind, silence, distant coyote
- [ ] Snow: Ice cracking, wind howl
- [ ] Beach: Waves (varying intensity)
- [ ] Mountain: Wind gusts, echo effect
- [ ] Storm sounds: Thunder, heavy rain

---

## PHASE 5: INTEGRATION & TESTING (3h)

### Task 5.1: Test Scene - Weather System (1h)
**File:** `test_weather.tscn`

Automated weather system verification:
- [ ] Create minimal test scene with WeatherManager
- [ ] Auto-cycle through all 9 weather states
- [ ] Verify transitions complete without errors
- [ ] Log particle counts and performance
- [ ] Test biome-weather restrictions (no rain in desert)

**Console Output Format:**
```
[TEST] Weather System Tests
[TEST] ✅ CLEAR → CLOUDY transition (30.0s)
[TEST] ✅ CLOUDY → RAIN transition (30.0s)
[TEST] ✅ Rain particles active: 2000
[TEST] ✅ RAIN → STORM transition (30.0s)
[TEST] ✅ DESERT biome: RAIN blocked correctly
[TEST] ✅ SNOW biome: SANDSTORM blocked correctly
[TEST] ────────────────────────────
[TEST] Weather Tests: 6/6 PASSED
```

### Task 5.2: Test Scene - Biome Vegetation (1h)
**File:** `test_biome_vegetation.tscn`

Verify ground cover rules per biome:
- [ ] Spawn sample of each biome type
- [ ] Count vegetation types spawned
- [ ] Verify NO grass in Desert/Snow/Beach
- [ ] Verify correct color tinting per biome
- [ ] Log any invalid spawns as failures

**Console Output Format:**
```
[TEST] Biome Vegetation Tests
[TEST] Testing GRASSLAND...
[TEST]   ✅ Grass spawned: 45
[TEST]   ✅ Flowers spawned: 12
[TEST] Testing DESERT...
[TEST]   ✅ Grass spawned: 0 (correct)
[TEST]   ✅ Dead shrubs spawned: 8
[TEST]   ✅ Bones spawned: 3
[TEST] Testing SNOW...
[TEST]   ✅ Grass spawned: 0 (correct)
[TEST]   ✅ Snow mounds spawned: 15
[TEST] ────────────────────────────
[TEST] Biome Tests: 7/7 PASSED
```

### Task 5.3: Test Scene - Wind & Particles (0.5h)
**File:** `test_wind_particles.tscn`

Verify wind system and particle effects:
- [ ] Wind direction changes over time
- [ ] Wind strength affects particle drift
- [ ] Gusts trigger correctly
- [ ] Footstep particles emit on surfaces

**Console Output Format:**
```
[TEST] Wind & Particle Tests
[TEST] ✅ Wind direction changed: (1,0,0) → (0.7,0,0.7)
[TEST] ✅ Wind strength range: 0.15 - 0.45
[TEST] ✅ Gust triggered (2.0x strength)
[TEST] ✅ Rain particles affected by wind
[TEST] ✅ Footstep particles: snow (white)
[TEST] ✅ Footstep particles: sand (tan)
[TEST] ────────────────────────────
[TEST] Wind Tests: 6/6 PASSED
```

### Task 5.4: Performance Verification (0.5h)
**File:** `test_performance.tscn` (extend existing)

Stress test with all systems active:
- [ ] Weather + vegetation + enemies simultaneously
- [ ] Measure FPS during heavy rain
- [ ] Measure FPS during blizzard
- [ ] Memory usage before/after weather cycles
- [ ] Target: 60 FPS maintained

**Console Output Format:**
```
[TEST] Performance Tests
[TEST] Baseline FPS: 62
[TEST] Heavy Rain + 10 enemies: 58 FPS ✅
[TEST] Blizzard + 10 enemies: 55 FPS ✅
[TEST] Sandstorm + 10 enemies: 57 FPS ✅
[TEST] Memory: 245MB → 248MB (stable) ✅
[TEST] ────────────────────────────
[TEST] Performance: 4/4 PASSED (min 55 FPS)
```

---

## TEST SCENES

| Scene | Purpose | Auto-Run Time |
|-------|---------|---------------|
| `test_weather.tscn` | Weather state machine | ~3 min |
| `test_biome_vegetation.tscn` | Ground cover rules | ~30 sec |
| `test_wind_particles.tscn` | Wind + particles | ~1 min |
| `test_performance.tscn` | FPS stress test | ~2 min |

**Workflow:**
1. Claude creates `test_*.tscn` files
2. You run scenes in Godot
3. You upload console output, screenshots, videos
4. Claude reviews and fixes issues

---

## TASK SUMMARY

| Phase | Tasks | Hours | Priority |
|-------|-------|-------|----------|
| 1. Biome Ground Cover | 3 | 6h | 🔴 Critical |
| 2. Weather Foundation | 5 | 10h | 🔴 Critical |
| 3. Atmosphere | 4 | 8h | 🟡 Medium |
| 4. Ambient Life | 4 | 8h | 🟢 Low |
| 5. Integration | 3 | 3h | 🟡 Medium |
| **TOTAL** | **19** | **35h** | |

---

## DEPENDENCIES

```
Phase 1 (Biome Fix)
    ↓
Phase 2 (Weather) ←── Phase 3 (Atmosphere)
    ↓                      ↓
Phase 4 (Life) ←──────────┘
    ↓
Phase 5 (Integration)
```

---

## CONFIGURATION EXPORTS

All new systems should expose @export variables:

**WeatherManager:**
```gdscript
@export var weather_change_interval_min: float = 300.0  # 5 min
@export var weather_change_interval_max: float = 900.0  # 15 min
@export var transition_duration: float = 30.0  # 30s fade
@export var rain_particle_count: int = 1000
@export var snow_particle_count: int = 500
@export var fog_density_clear: float = 0.0
@export var fog_density_foggy: float = 0.05
```

**WindSystem:**
```gdscript
@export var wind_change_interval: float = 60.0
@export var wind_strength_min: float = 0.0
@export var wind_strength_max: float = 1.0
@export var grass_sway_amount: float = 0.1
```

---

## FILES TO CREATE

| File | Type | Purpose |
|------|------|---------|
| `weather_manager.gd` | Autoload | Weather state machine |
| `wind_system.gd` | Node | Wind direction/strength |
| `tumbleweed.gd` | RigidBody3D | Desert prop |
| `biome_effects.gd` | Node3D | Falling leaves, etc. |
| `weather_particles.tscn` | Scene | Rain/snow/sand particles |

---

## FILES TO MODIFY

| File | Changes |
|------|---------|
| `vegetation_spawner.gd` | Biome ground cover rules, color tinting |
| `day_night_cycle.gd` | Fog colors, ambient lighting per biome |
| `ambient_manager.gd` | Weather sounds, enhanced biome audio |
| `player.gd` | Footstep particles |
| `world.gd` | Initialize WeatherManager, WindSystem |
| `project.godot` | Add WeatherManager autoload |

---

## FUTURE CONSIDERATIONS (v0.9.0+)

- Weather affects gameplay (cold damage, fire extinguished)
- Seasons system
- Weather forecast UI
- Lightning strikes (damage, fire)
- Wet/dry surface states
- Indoor weather protection

---

*Document Version: 0.8.0*
*Created: Sprint Planning*
