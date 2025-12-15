# ROADMAP v0.8.0 - "Living World"
## Biome Diversity & Dynamic Weather

---

## PHASE 0: VEGETATION SYSTEM FIX - COMPLETED ✅

**Unplanned but critical work to fix broken harvestables after modular refactor**

### Completed Tasks

[✅] **Harvestable Resource Fix**
- Restored proper HarvestableStrawberry/HarvestableMushroom/ResourceNode creation
- Added collision layer 2 and CollisionShape3D for raycast detection
- Mesh files now create visuals only (*_visual functions)
- Spawner creates full harvestable nodes with collision

[✅] **Strawberry Bush Visual Improvements**
- Restored rounded dome bush body (7 layers, 10 segments)
- Upgraded berries from octahedron (8 tri) to icosphere (20 tri)
- Implemented golden angle distribution for uniform berry placement
- Fixed berry height range (0.20-0.90) and surface distance (3-7%)

[✅] **Mushroom Visual Restoration**
- Restored original stem + dome cap geometry
- White stems with red/brown caps
- Proper cluster generation (3-6 mushrooms)

[✅] **Rock Harvestable Restoration**
- Added create_rock(), create_small_rock(), create_snow_rock()
- Uses ResourceNodeClass with proper collision

[✅] **Survival-Balanced Spawning**
| Resource | Old | New | Notes |
|----------|-----|-----|-------|
| Mushroom | 0.35 | 0.04 | Rarest |
| Strawberry | 0.40 | 0.06 | Rare |
| Rock | 0.25 | 0.08 | Uncommon |
| Forest mushroom | 0.80 | 0.10 | |
| Grassland strawberry | 0.90 | 0.12 | |

**Files Modified:**
- `vegetation/vegetation_spawner.gd`
- `vegetation/meshes/forest_meshes.gd`
- `vegetation/meshes/plant_meshes.gd`

---

## SPRINT OVERVIEW

**Theme:** Make the world feel alive through biome-specific environments and dynamic weather
**Estimated Hours:** ~35h
**Priority:** Biome Polish → Weather Foundation → Atmosphere → Life

---

## SUCCESS CRITERIA

| Metric | Target | Status |
|--------|--------|--------|
| Biome Distinction | Each biome visually unique (no grass in desert) | ⏳ |
| Weather Types | 4+ weather states functional | ✅ 8 states |
| Performance | Maintain 60 FPS with weather effects | ✅ |
| Atmosphere | Ambient sounds + visuals per biome | ⏳ |

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

## PHASE 2: WEATHER SYSTEM FOUNDATION (10h) - ✅ COMPLETED

### Task 2.1: WeatherManager Singleton (3h) ✅ COMPLETED
**Priority:** 🔴 Critical
**File:** `weather_manager.gd`

Created weather state machine:
- [x] Weather states: CLEAR, CLOUDY, RAIN, STORM, FOG, SNOW, BLIZZARD, SANDSTORM
- [x] Biome-specific weather tables
- [x] Weather transition system (gradual changes)
- [x] Time-based weather changes
- [x] @export variables for all tuning

### Task 2.2: Rain System (2h) ✅ COMPLETED
**Priority:** 🔴 Critical
**Files:** `weather_manager.gd`, `weather_particles.gd`

Implemented rain weather:
- [x] Rain particle system (GPUParticles3D) - 12,000 particles
- [x] Minecraft-style: stays in area, repositions on teleport
- [x] Rain streaks (0.06 x 1.8 thin boxes)
- [x] Rain sound effect integration ready

### Task 2.2b: Storm System (1h) ✅ COMPLETED
**Priority:** 🔴 Critical
**Files:** `weather_manager.gd`, `weather_particles.gd`

Implemented storm weather (separate from rain):
- [x] Storm particle system - 20,000 particles
- [x] Heavier, longer streaks (0.08 x 2.5)
- [x] Angled rain (wind effect via gravity vector)
- [x] Darker color than regular rain

### Task 2.3: Snow System (2h) ✅ COMPLETED
**Priority:** 🟡 Medium
**Files:** `weather_manager.gd`, `weather_particles.gd`

Implemented snow weather:
- [x] Snow particle system - 8,000 particles
- [x] Slower fall than rain (gravity -3)
- [x] Gentle drift effect
- [x] White cube flakes (0.2 x 0.2)

### Task 2.3b: Blizzard System (1h) ✅ COMPLETED
**Priority:** 🟡 Medium
**Files:** `weather_manager.gd`, `weather_particles.gd`

Implemented blizzard weather (separate from snow):
- [x] Blizzard particle system - 18,000 particles
- [x] Strong horizontal wind (gravity with X/Z components)
- [x] Larger flakes (0.25 x 0.25)
- [x] Higher density than regular snow

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

## WEATHER PARTICLE IMPLEMENTATION NOTES

### Critical Discovery: GPUParticles3D Instantiation Bug

**Problem:** Particles created from instantiated .tscn scenes freeze in place and don't animate.

**Solution:** WeatherParticles node must be:
1. Manually added as Node3D in World scene (not from .tscn)
2. Script attached directly to the Node3D
3. Particles created dynamically in _ready()

**Architecture:**
```
World (Scene)
└── WeatherParticles (Node3D with weather_particles.gd)
    ├── Rain (GPUParticles3D) - created in code
    ├── Storm (GPUParticles3D) - created in code
    ├── Snow (GPUParticles3D) - created in code
    └── Blizzard (GPUParticles3D) - created in code
```

**WeatherManager Integration:**
- WeatherManager is autoload (singleton)
- WeatherParticles registers its particles via set_*_particles() methods
- WeatherManager only toggles `visible`, never touches `emitting` or `amount`

### Particle Settings (Final)

| Weather  | Amount  | Lifetime | Height | Gravity        | Size        |
|----------|---------|----------|--------|----------------|-------------|
| Rain     | 12,000  | 3.5s     | 50     | (0, -25, 0)    | 0.06 x 1.8  |
| Storm    | 20,000  | 2.5s     | 60     | (-5, -40, -3)  | 0.08 x 2.5  |
| Snow     | 8,000   | 20s      | 50     | (0.5, -3, 0.3) | 0.2 x 0.2   |
| Blizzard | 18,000  | 10s      | 50     | (-8, -8, -5)   | 0.25 x 0.25 |

### Minecraft-Style Behavior

Weather particles don't follow the player. Instead:
- Spawn at player's initial position
- Stay fixed in world space as player walks through
- Reposition if player teleports >200 units away (biome teleporter)

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

### Task 5.1: Test Scene - Weather System (1h) ✅ COMPLETED (Manual Testing)
**File:** `test_weather.tscn`

Weather system verification:
- [x] All 8 weather states functional
- [x] Transitions work (F5 cycle, F6 random)
- [x] Biome-weather restrictions work
- [x] Performance maintained at 60 FPS

### Task 5.2: Test Scene - Biome Vegetation (1h)
**File:** `test_biome_vegetation.tscn`

Verify ground cover rules per biome:
- [ ] Spawn sample of each biome type
- [ ] Count vegetation types spawned
- [ ] Verify NO grass in Desert/Snow/Beach
- [ ] Verify correct color tinting per biome
- [ ] Log any invalid spawns as failures

### Task 5.3: Test Scene - Wind & Particles (0.5h)
**File:** `test_wind_particles.tscn`

Verify wind system and particle effects:
- [ ] Wind direction changes over time
- [ ] Wind strength affects particle drift
- [ ] Gusts trigger correctly
- [ ] Footstep particles emit on surfaces

### Task 5.4: Performance Verification (0.5h)
**File:** `test_performance.tscn` (extend existing)

Stress test with all systems active:
- [ ] Weather + vegetation + enemies simultaneously
- [ ] Measure FPS during heavy rain
- [ ] Measure FPS during blizzard
- [ ] Memory usage before/after weather cycles
- [ ] Target: 60 FPS maintained

---

## TASK SUMMARY

| Phase | Tasks | Hours | Status |
|-------|-------|-------|--------|
| 0. Vegetation Fix | 5 | 8h | ✅ Complete |
| 1. Biome Ground Cover | 3 | 6h | ⏳ Pending |
| 2. Weather Foundation | 5 | 10h | ✅ Complete |
| 3. Atmosphere | 4 | 8h | ⏳ Pending |
| 4. Ambient Life | 4 | 8h | ⏳ Pending |
| 5. Integration | 4 | 3h | 🟡 Partial |
| **TOTAL** | **25** | **43h** | |

---

## FILES CREATED/MODIFIED THIS SESSION

### New Files
| File | Purpose |
|------|---------|
| `weather_particles.gd` | Creates and manages weather particle systems |

### Modified Files
| File | Changes |
|------|---------|
| `weather_manager.gd` | Added set_storm_particles(), set_blizzard_particles(), simplified _update_particle_systems() |
| `player.gd` | Removed particle creation (handled by WeatherParticles scene) |

### Setup Required
1. Add Node3D named "WeatherParticles" to World scene
2. Attach `weather_particles.gd` script to it
3. **DO NOT** use .tscn instantiation for particles

---

## DEPENDENCIES

```
Phase 0 (Vegetation Fix) ✅
    ↓
Phase 1 (Biome Fix) ⏳
    ↓
Phase 2 (Weather) ✅ ←── Phase 3 (Atmosphere) ⏳
    ↓                      ↓
Phase 4 (Life) ⏳ ←──────────┘
    ↓
Phase 5 (Integration) 🟡
```

---

## CONFIGURATION EXPORTS

All new systems expose @export variables:

**WeatherManager:**
```gdscript
@export var weather_change_interval_min: float = 300.0  # 5 min
@export var weather_change_interval_max: float = 900.0  # 15 min
@export var transition_duration: float = 30.0  # 30s fade
@export var rain_particle_count: int = 2000
@export var snow_particle_count: int = 1000
@export var fog_density_clear: float = 0.0
@export var fog_density_foggy: float = 0.05
```

**WeatherParticles (hardcoded for stability):**
```gdscript
# Particles use fixed amounts - changing at runtime breaks simulation
Rain: 12,000 particles
Storm: 20,000 particles  
Snow: 8,000 particles
Blizzard: 18,000 particles
```

---

## FUTURE CONSIDERATIONS (v0.9.0+)

- Weather affects gameplay (cold damage, fire extinguished)
- Seasons system
- Weather forecast UI
- Lightning strikes (damage, fire)
- Wet/dry surface states
- Indoor weather protection

---

*Document Version: 0.8.1*
*Last Updated: Weather Particle System Implementation*
