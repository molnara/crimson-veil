# AmbientManager - Implementation Documentation

**Task:** Priority 2.3 - Ambient Environmental Sounds  
**Status:** ✅ COMPLETE  
**Files Created:** 
- `ambient_manager.gd` (~400 lines)

---

## What Was Built

A biome-aware environmental sound system that:
- **Occasional ambient loops** - Plays subtle environmental sounds based on player location
- **Biome detection** - Different sounds for each biome (Grassland, Forest, Beach, Mountain, Desert, Snow)
- **Time-based layers** - Birds during day, crickets at night
- **Smart frequency** - "Occasional" and "rare" playback to avoid audio spam
- **Dynamic management** - Starts/stops sounds based on player movement and time
- **Volume tuning** - Each sound type has custom volume for perfect balance

---

## Setup Instructions

### 1. Add to project.godot AutoLoad

Open `project.godot` and add under `[autoload]` section:

```gdscript
[autoload]

AudioManager="*res://audio_manager.gd"
MusicManager="*res://music_manager.gd"
AmbientManager="*res://ambient_manager.gd"
```

### 2. Verify Audio Files

Ensure ambient loop files exist and are configured as loops:

```
res://audio/sfx/ambient/
  - wind_light.wav (loop enabled)
  - wind_strong.wav (loop enabled)
  - ocean_waves.wav (loop enabled)
  - crickets_night.wav (loop enabled)
  - birds_day.wav (loop enabled)
  - frogs_night.wav (loop enabled)
  - leaves_rustle.wav (loop enabled)
  - thunder_distant.wav (loop enabled)
```

**To enable looping:**
1. Select audio file in Godot
2. Go to Import tab
3. Check "Loop" checkbox
4. Click "Reimport"

### 3. Verify Player and Day/Night Cycle

Ensure player is in group "player":

```gdscript
# In player.gd _ready():
add_to_group("player")
```

Ensure day/night cycle is in group "day_night_cycle":

```gdscript
# In day_night_cycle.gd _ready():
add_to_group("day_night_cycle")
```

---

## How It Works

### Startup Sequence

```
0s:   Game launches
0s:   Player spawns
10s:  AmbientManager activates
10s:  Detects player biome
10s:  Begins ambient sound cycles
```

**10-second delay ensures:**
- Player is fully initialized
- Music has started (8s delay)
- Player has time to hear music first
- Avoids audio overload at startup

### Biome Detection

System continuously monitors player position and determines biome:

```gdscript
Player Position → Chunk Coordinates → Biome Noise → Biome Type

Example:
Player at (45, 0, -30)
  → Chunk (1, -1)
  → Noise value: 0.15
  → Biome: FOREST
```

**Updates every 2 seconds** - balances responsiveness with performance

### Ambient Sound Cycle

Each ambient sound follows a cycle:

```
SILENCE (45-90 seconds)
  ↓ (timer expires)
ROLL CHANCE (based on frequency)
  ↓ (passed check)
PLAYING (15-30 seconds)
  ↓ (duration expires)
SILENCE (45-90 seconds)
  ↓ (repeat)
```

**Example Timeline:**
```
0:00 - Silence begins (60 second duration)
1:00 - Check frequency: 25% chance
1:00 - Passed! wind_light plays (20 second duration)
1:20 - wind_light stops
1:20 - Silence begins (75 second duration)
2:35 - Check frequency: 25% chance
2:35 - Failed! Silence continues (80 second duration)
4:05 - Check frequency again...
```

---

## Biome Ambient Configuration

### Grassland
**Base Sounds:**
- `wind_light` - Rare (20% chance)

**Time-Specific:**
- `birds_day` - Rare (15% chance, day only)
- `crickets_night` - Rare (15% chance, night only)

**Atmosphere:** Peaceful, calm, occasional nature sounds

---

### Forest
**Base Sounds:**
- `wind_light` - Rare (25% chance)
- `leaves_rustle` - Rare (25% chance, alternates with wind)

**Time-Specific:**
- `birds_day` - Rare (15% chance, day only)
- `crickets_night` - Rare (15% chance, night only)
- `frogs_night` - Very rare (15% chance, night only)

**Atmosphere:** Rich nature soundscape, more activity than grassland

---

### Beach
**Base Sounds:**
- `ocean_waves` - Occasional (40% chance)

**Time-Specific:** None

**Atmosphere:** Coastal ambience, rhythmic waves

---

### Mountain
**Base Sounds:**
- `wind_strong` - Occasional (50% chance)

**Time-Specific:** None

**Atmosphere:** Windy, exposed, dramatic

---

### Desert
**Base Sounds:**
- `wind_light` - Occasional (35% chance)

**Time-Specific:** None

**Atmosphere:** Sparse, occasional wind gusts, isolation

---

### Snow
**Base Sounds:**
- `wind_strong` - Frequent (60% chance)

**Time-Specific:** None

**Atmosphere:** Cold, howling wind, harsh environment

---

## Volume Configuration

Each sound has custom volume tuning:

```gdscript
const VOLUME_ADJUSTMENTS: Dictionary = {
    "wind_light": 0.18,        # Very subtle
    "wind_strong": 0.22,       # Noticeable but not loud
    "ocean_waves": 0.25,       # Clear coastal presence
    "crickets_night": 0.20,    # Soft night ambience
    "birds_day": 0.18,         # Gentle chirping
    "frogs_night": 0.15,       # Very quiet, distant
    "leaves_rustle": 0.16,     # Subtle rustling
    "thunder_distant": 0.30    # Louder for impact
}
```

**Note:** These volumes are multiplied by:
- Master volume (default: 1.0)
- Ambient category volume (default: 0.25)

**Final Volume Formula:**
```
Final = Master × Ambient × Sound Adjustment
Example: 1.0 × 0.25 × 0.18 = 0.045 (4.5%)
```

**Result:** Very subtle, atmospheric sounds that don't overpower music or SFX

---

## Frequency Terminology

| Term | Percentage | Description |
|------|------------|-------------|
| **Very Rare** | 10-15% | Almost never, very sparse |
| **Rare** | 20-25% | Infrequent, subtle presence |
| **Occasional** | 35-50% | Noticeable but not constant |
| **Frequent** | 60%+ | Regular presence, defines atmosphere |

**Design Philosophy:**
- Silence is part of the ambience
- Subtle is better than overwhelming
- Let music be the primary audio layer
- Ambients provide texture, not melody

---

## Biome Transition Behavior

When player moves between biomes:

```
Player crosses from GRASSLAND to FOREST
  ↓
AmbientManager detects biome change
  ↓
Stop all current ambients (2 second fade)
  ↓
Clear ambient tracking
  ↓
Begin new biome ambient cycles
```

**Result:** Smooth transitions without overlapping biome sounds

---

## Time Period Transition Behavior

When day changes to night (or vice versa):

```
Day → Night transition at 6 PM
  ↓
AmbientManager detects time change
  ↓
Stop time-specific ambients (birds_day fades out)
  ↓
Keep base ambients playing (wind continues)
  ↓
Begin night-specific cycles (crickets_night may start)
```

**Result:** Smooth day/night atmosphere shifts

---

## Public API

### Status Checking

```gdscript
# Get current biome
var biome = AmbientManager.get_current_biome()
# Returns: "GRASSLAND", "FOREST", etc.

# Get list of playing ambients
var playing = AmbientManager.get_active_ambients()
# Returns: ["wind_light", "birds_day"]

# Debug status
AmbientManager.print_status()
```

### Manual Control (Testing/Debug)

```gdscript
# Force immediate biome/time check
AmbientManager.force_ambient_check()

# Check status
AmbientManager.print_status()
```

---

## Console Output Examples

### Successful Initialization

```
[AmbientManager] Initializing ambient sound system...
[AmbientManager] Starting in biome: GRASSLAND, period: day
[AmbientManager] Ambient sound system initialized!
```

### Biome Change

```
[AmbientManager] Biome changed: GRASSLAND → FOREST
[AudioManager] Stopped ambient loop: wind_light
```

### Time Period Change

```
[AmbientManager] Time period changed: day → night
[AudioManager] Stopped ambient loop: birds_day
```

### Status Debug Output

```
[AmbientManager] Status:
  Initialized: true
  Current Biome: FOREST
  Current Period: day
  Active Ambients: 2
    - leaves_rustle (12.3s remaining)
    - birds_day (8.7s remaining)
  Tracked Ambients: 4
```

---

## Integration with Game Systems

### Player Detection

```gdscript
# Automatically finds player in group "player"
player = get_tree().get_first_node_in_group("player")

# Monitors player.global_position every 2 seconds
var player_pos = player.global_position
```

### Chunk Manager Integration

```gdscript
# Uses chunk manager's biome noise for detection
var chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
var noise_value = chunk_manager.biome_noise.get_noise_2d(x, z)

# Determines biome from noise value (same logic as chunk.gd)
```

### Day/Night Cycle Integration

```gdscript
# Finds day/night cycle in group "day_night_cycle"
day_night_cycle = get_tree().get_first_node_in_group("day_night_cycle")

# Monitors time_of_day for day/night detection
var is_day = day_night_cycle.time_of_day >= 0.25 and day_night_cycle.time_of_day < 0.75
```

### AudioManager Integration

```gdscript
# Uses AudioManager for all playback
AudioManager.play_ambient_loop("wind_light", 0.18)
AudioManager.stop_ambient_loop("wind_light", 2.0)
```

---

## Technical Details

### File Size & Performance

**ambient_manager.gd:** ~400 lines  
**Memory footprint:** ~3 KB (before audio loaded)  
**CPU impact:** Minimal (updates every 2 seconds, simple timer logic)  
**Expected with ambients:** +40-60 MB (8 ambient loops)

### Timer System

Each ambient sound has independent timer:

```gdscript
{
    "timer": 45.2,        # Current elapsed time
    "duration": 60.0,     # Target duration
    "is_playing": false   # Current state
}
```

**Timer Logic:**
- Increments every frame with delta
- When timer >= duration, check if should play
- If playing, duration = play time (15-30s)
- If silent, duration = silence time (45-90s)
- Random durations prevent predictable patterns

### Biome Detection Performance

```
Update Interval: 2.0 seconds
Chunk Calculation: O(1) - simple division
Noise Lookup: O(1) - single noise sample
Biome Match: O(1) - switch statement

Total Cost: ~0.1ms every 2 seconds = negligible
```

---

## Troubleshooting

### Ambients Don't Play

**Check:**
1. AmbientManager is in AutoLoad list
2. Player exists and is in group "player"
3. Chunk manager exists and is in group "chunk_manager"
4. Audio files are imported and loop-enabled
5. Console shows initialization messages

**Debug:**
```gdscript
AmbientManager.print_status()
```

### Wrong Biome Detected

**Check:**
1. Player position is correct
2. Chunk manager's biome noise is working
3. Noise values match chunk.gd biome logic

**Manual check:**
```gdscript
print(AmbientManager.get_current_biome())
```

### Ambients Play Too Often/Rarely

**Adjust frequency in ambient_manager.gd:**

```gdscript
const BIOME_AMBIENTS: Dictionary = {
    "FOREST": {
        "sounds": ["wind_light", "leaves_rustle"],
        "frequency": 0.35,  # Change this (0.0 - 1.0)
        ...
    }
}
```

### Ambients Too Loud/Quiet

**Adjust volume in ambient_manager.gd:**

```gdscript
const VOLUME_ADJUSTMENTS: Dictionary = {
    "wind_light": 0.25,  # Change this (0.0 - 1.0)
    ...
}
```

---

## Configuration Guide

### Adding New Ambient Sounds

1. **Import audio file:**
   - Place in `res://audio/sfx/ambient/`
   - Enable loop in Import tab

2. **Add to AudioManager:**
   ```gdscript
   # In audio_manager.gd _load_sound_library():
   sounds["new_sound"] = preload("res://audio/sfx/ambient/new_sound.wav")
   ```

3. **Add to AmbientManager:**
   ```gdscript
   # In ambient_manager.gd VOLUME_ADJUSTMENTS:
   const VOLUME_ADJUSTMENTS: Dictionary = {
       "new_sound": 0.20,
       ...
   }
   
   # Add to biome config:
   const BIOME_AMBIENTS: Dictionary = {
       "GRASSLAND": {
           "sounds": ["wind_light", "new_sound"],
           ...
       }
   }
   ```

### Adjusting Timing

```gdscript
# In ambient_manager.gd:

# How often to check biome (seconds)
const UPDATE_INTERVAL: float = 2.0

# How long sounds play (seconds)
const SOUND_DURATION_MIN: float = 15.0
const SOUND_DURATION_MAX: float = 30.0

# How long silence lasts (seconds)
const SILENCE_DURATION_MIN: float = 45.0
const SILENCE_DURATION_MAX: float = 90.0
```

**Tips:**
- Increase SOUND_DURATION for longer ambient presence
- Decrease SILENCE_DURATION for more frequent sounds
- Increase UPDATE_INTERVAL to reduce CPU usage (at cost of responsiveness)

---

## Design Philosophy

### Why "Occasional" Instead of Constant?

**Immersion reasons:**
- Real nature isn't constantly noisy
- Silence has atmosphere too
- Prevents audio fatigue
- Makes sounds more noticeable when they play
- Creates natural, unpredictable feeling

### Why Biome-Specific?

**Immersion reasons:**
- Each biome has distinct atmosphere
- Reinforces visual environment
- Helps player orient themselves
- Creates memorable locations

### Why Time-Based Layers?

**Immersion reasons:**
- Birds don't chirp at night
- Crickets emerge after dark
- Reinforces day/night cycle
- Adds variety without overwhelming

### Why Low Volume?

**Balance reasons:**
- Music is primary audio layer
- SFX are secondary (player actions)
- Ambients are tertiary (background texture)
- Prevents audio soup
- Keeps focus on gameplay

---

## Future Enhancements

**Possible additions (not currently implemented):**

1. **Weather ambients** - Rain, thunder, snow
2. **3D spatial audio** - Directional ambient sources
3. **Altitude-based layers** - Different sounds at height
4. **Interior ambients** - Cave echoes, indoor reverb
5. **Distance-based mixing** - Fade ocean sounds when moving away from beach
6. **Player activity layers** - Different ambients when building vs. exploring
7. **Seasonal variations** - Spring birds, winter wind
8. **Ambient randomization** - More sound variants per biome

---

## Commit Message (When Ready)

```
feat: implement ambient environmental sound system

- [MAJOR] Created ambient_manager.gd AutoLoad (~400 lines)
- [FEATURE] Biome-aware ambient loops (6 biomes)
- [FEATURE] "Occasional" frequency system (prevents audio spam)
- [FEATURE] Time-based layers (birds day, crickets night)
- [FEATURE] Smart timer system (15-30s play, 45-90s silence)
- [FEATURE] Custom volume per sound type
- [FEATURE] Smooth biome transitions with fade-outs
- [FEATURE] 10-second startup delay
- [FEATURE] Dynamic biome detection every 2 seconds
- [DOC] Created comprehensive ambient system documentation

Task 2.3 complete - Environmental ambient sound system
Sprint progress: 31% → 46%
```

---

**Status:** ✅ Ready for testing and integration with v0.5.0 sprint
