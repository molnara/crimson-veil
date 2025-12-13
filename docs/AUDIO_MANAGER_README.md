# AudioManager - Implementation Documentation

**Task:** Priority 1.1 - Audio Manager Architecture  
**Status:** ✅ COMPLETE  
**Files Created:** 
- `audio_manager.gd` (393 lines)
- `audio_manager_test.gd` (test suite)
- `project_godot_autoload_patch.txt` (setup instructions)

---

## What Was Built

A centralized audio management system that handles all game sounds with:
- **Sound pooling** (prevents audio spam)
- **Volume categories** (Master, SFX, Music, Ambient, UI)
- **Pitch/volume variation** (natural sound feel)
- **Music crossfading** (smooth track transitions)
- **Ambient loop management** (environmental sounds)

---

## Setup Instructions

### 1. Copy Files to Project

```bash
# Copy AudioManager to project root
cp audio_manager.gd /path/to/crimson-veil/

# Optional: Copy test script
cp audio_manager_test.gd /path/to/crimson-veil/
```

### 2. Add AutoLoad to project.godot

Open `project.godot` and add under `[autoload]` section:

```gdscript
[autoload]

AudioManager="*res://audio_manager.gd"
```

**If no [autoload] section exists:**
1. Find `[application]` section
2. Add new `[autoload]` section after it
3. Add the AudioManager line

### 3. Test the Implementation

**Option A: Automated Tests**
1. Create test scene in Godot
2. Add Node root
3. Attach `audio_manager_test.gd` script
4. Run scene - all tests should pass

**Option B: Manual Verification**
1. Run any existing scene
2. Open Godot debug console
3. Look for: `[AudioManager] Audio system ready!`
4. Verify sound pool created (10 players)

---

## API Reference

### Sound Effects

```gdscript
# Play a sound effect
AudioManager.play_sound("axe_chop", "sfx")

# Play with pitch variation disabled
AudioManager.play_sound("ui_click", "ui", false)

# Play random variant from set (e.g., footstep_grass_1, _2, _3)
AudioManager.play_sound_variant("footstep_grass", 3, "sfx")
```

### Music Control

```gdscript
# Play music with 2-second crossfade
AudioManager.play_music("ambient_day", 2.0)

# Switch to night music
AudioManager.play_music("ambient_night", 2.0)

# Stop music with fade out
AudioManager.stop_music(2.0)
```

### Ambient Loops

```gdscript
# Start ambient loop
AudioManager.play_ambient_loop("wind_light")

# Start with custom volume
AudioManager.play_ambient_loop("ocean_waves", 0.5)

# Stop with fade out
AudioManager.stop_ambient_loop("wind_light", 1.0)
```

### Volume Control

```gdscript
# Set master volume (0.0 - 1.0)
AudioManager.set_master_volume(0.8)

# Set category volumes
AudioManager.set_sfx_volume(0.9)
AudioManager.set_music_volume(0.5)
AudioManager.set_ambient_volume(0.3)
AudioManager.set_ui_volume(0.7)

# Generic setter (for settings menu)
AudioManager.set_category_volume("sfx", 0.9)
```

### Utility Functions

```gdscript
# Check if sound is playing
var playing = AudioManager.is_sound_playing("axe_chop")

# Get active sound count
var count = AudioManager.get_active_sound_count()

# Emergency stop everything
AudioManager.stop_all_sounds()

# Debug status
AudioManager.print_status()
```

---

## Volume Categories Explained

### Master Volume (Default: 1.0)
- Affects ALL audio globally
- User's main volume control
- Multiplied with category volumes

### SFX Volume (Default: 0.75 / 75%)
- Harvesting sounds (axe, pickaxe)
- Building sounds (place, remove)
- Movement sounds (footsteps)
- Container sounds (open, close)
- **Louder than ambient** - punchy action feedback

### Music Volume (Default: 0.35 / 35%)
- Background music tracks
- Day/night ambient drones
- **Quieter than SFX** - stays in background

### Ambient Volume (Default: 0.25 / 25%)
- Environmental loops (wind, ocean, crickets)
- Wildlife sounds (birds, frogs)
- **Quietest** - subtle atmosphere

### UI Volume (Default: 0.60 / 60%)
- Inventory sounds (pickup, toggle)
- Crafting sounds (complete, unavailable)
- Settings clicks
- **Moderate** - clear feedback without overwhelming

**Final Volume Formula:**
```
Final Volume = Master × Category × Sound Base × Random Variation
```

---

## Sound Pooling Behavior

### The Problem
Without pooling, playing 100 footsteps simultaneously creates audio chaos and performance issues.

### The Solution
Pool of 10 reusable AudioStreamPlayer nodes:

```
1. Request sound playback
2. Check pool for available player
   - Available? Use it, mark as active
   - Full? Cut off oldest sound
3. Sound finishes → player returns to pool
4. Players are reused (no create/destroy overhead)
```

### Results
- Maximum 10 concurrent sounds
- Natural "oldest sound cuts off" behavior
- No performance hit from node creation
- Footsteps won't stack infinitely

---

## Pitch/Volume Variation

### Why Variation Matters
Same exact sound repeated = robotic, artificial feeling  
Slight variation each time = organic, natural feeling

### Pitch Variation (Default: ON)
```gdscript
player.pitch_scale = randf_range(0.9, 1.1)  # ±10%
```

**Effect:**
- 3 footstep variants × pitch variation = feels like 30+ sounds
- Axe chops sound slightly different each hit
- Natural, organic audio

### Volume Variation (Default: OFF)
```gdscript
final_volume *= randf_range(0.9, 1.0)  # -10% to 0%
```

**When to use:**
- Environmental sounds (wind gusts, distant thunder)
- NOT for UI sounds (consistency needed)

---

## Music Crossfading

### How It Works
```
Current Track:  [████████░░] Fade out...
                           [░░████████] New track fades in
New Track:      [░░████████]
```

### Implementation
```gdscript
# Smooth 2-second crossfade
AudioManager.play_music("ambient_night", 2.0)

# Instant switch (no fade)
AudioManager.play_music("ambient_day", 0.0)
```

### Use Cases
- Day → Night music transition
- Biome change music
- Combat → Peaceful transitions (future)

---

## Integration Examples

### Example 1: Harvesting System
```gdscript
# In harvesting_system.gd

func _on_harvest_hit(resource: HarvestableResource):
    # Determine which sound based on resource type
    var sound_name = ""
    if resource is HarvestableTree:
        sound_name = "axe_chop"
    elif resource.resource_name.contains("Rock"):
        sound_name = "pickaxe_hit"
    elif resource.resource_name.contains("Mushroom"):
        sound_name = "mushroom_pick"
    elif resource.resource_name.contains("Strawberry"):
        sound_name = "strawberry_pick"
    
    # Play sound with pitch variation
    AudioManager.play_sound(sound_name, "sfx")

func _on_harvest_complete(resource: HarvestableResource):
    # Play completion sound
    AudioManager.play_sound("resource_break", "sfx")
```

### Example 2: Building System
```gdscript
# In building_system.gd

func place_block(block_type: String, position: Vector3):
    # Place block logic...
    
    # Play placement sound
    AudioManager.play_sound("block_place", "sfx")

func remove_block(block: Node3D):
    # Remove block logic...
    
    # Play removal sound
    AudioManager.play_sound("block_remove", "sfx")
```

### Example 3: Footsteps (Player Movement)
```gdscript
# In player.gd

var footstep_timer: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.5  # Every 0.5 seconds when moving

func _physics_process(delta):
    if velocity.length() > 0.1:  # Player is moving
        footstep_timer += delta
        
        if footstep_timer >= FOOTSTEP_INTERVAL:
            footstep_timer = 0.0
            _play_footstep()

func _play_footstep():
    # Determine surface type from current biome
    var surface = _get_surface_type()
    
    # Play random variant (1, 2, or 3)
    AudioManager.play_sound_variant("footstep_" + surface, 3, "sfx")

func _get_surface_type() -> String:
    var chunk_pos = ChunkManager.world_to_chunk(global_position)
    var biome = ChunkManager.get_biome_at(chunk_pos)
    
    match biome:
        Chunk.Biome.GRASSLAND, Chunk.Biome.FOREST:
            return "grass"
        Chunk.Biome.MOUNTAIN, Chunk.Biome.DESERT:
            return "stone"
        Chunk.Biome.BEACH:
            return "sand"
        Chunk.Biome.SNOW:
            return "snow"
        _:
            return "grass"
```

### Example 4: Day/Night Music
```gdscript
# In day_night_cycle.gd

func _on_time_changed(time_of_day: float):
    # Crossfade music at dawn and dusk
    if time_of_day >= 0.25 and time_of_day < 0.26 and current_music != "day":
        # Dawn (6 AM) - switch to day music
        AudioManager.play_music("ambient_day", 3.0)
        current_music = "day"
    
    elif time_of_day >= 0.75 and time_of_day < 0.76 and current_music != "night":
        # Dusk (6 PM) - switch to night music
        AudioManager.play_music("ambient_night", 3.0)
        current_music = "night"
```

### Example 5: Settings Menu
```gdscript
# In settings_menu.gd

func _on_master_slider_changed(value: float):
    AudioManager.set_master_volume(value)
    # Play test sound for immediate feedback
    AudioManager.play_sound("setting_click", "ui", false)

func _on_sfx_slider_changed(value: float):
    AudioManager.set_sfx_volume(value)
    AudioManager.play_sound("axe_chop", "sfx")  # Demo SFX volume

func _on_music_slider_changed(value: float):
    AudioManager.set_music_volume(value)
    # Music volume updates immediately on active track
```

---

## Testing Checklist

Before moving to Task 1.2 (Sound Generation), verify:

- [ ] AudioManager appears in AutoLoad list in project settings
- [ ] Console shows initialization messages on game start
- [ ] Sound pool created (10 players)
- [ ] Music player created
- [ ] All volume defaults correct
- [ ] Can call `AudioManager.play_sound()` from any script
- [ ] Warnings appear for non-existent sounds (expected until Task 1.2)
- [ ] `AudioManager.print_status()` shows correct info

---

## Next Steps (Task 1.2)

With AudioManager complete, next session will:

1. **Generate 43 audio files** using AI tools:
   - 22 SFX (harvesting, movement, building, UI, containers)
   - 2 Music tracks (day/night ambient)
   - 8 Ambient loops (wind, ocean, wildlife)
   - 9 UI sounds (warnings, feedback)

2. **Import to Godot:**
   - Create `res://audio/` directory structure
   - Import all WAV/MP3 files
   - Update `_load_sound_library()` in AudioManager

3. **Test sound playback:**
   - Verify all sounds load correctly
   - Test pitch variation
   - Test volume categories
   - Ensure loop points work on ambient/music

---

## Architecture Benefits

✅ **Centralized** - All audio logic in one place  
✅ **Flexible** - Easy to add new sounds later  
✅ **Performant** - Sound pooling prevents overhead  
✅ **Modular** - Each category independent  
✅ **Maintainable** - Simple API, clear structure  
✅ **Future-proof** - Supports 3D spatial audio (not implemented yet)  
✅ **Testable** - Complete test suite included

---

## File Size & Performance

**audio_manager.gd:** 393 lines  
**Memory footprint:** ~1-2 KB (before audio files loaded)  
**CPU impact:** Minimal (pooling prevents node creation overhead)  
**Expected with all sounds:** ~50-100 MB (43 audio files)

---

## Known Limitations

1. **No 3D spatial audio yet** - All sounds are 2D  
   - Can be added later when needed
   - Architecture supports it (`play_sound_3d` stub exists)

2. **No volume persistence** - Settings don't save yet  
   - Will be added in Task 3.1 (Settings Menu)
   - Easy to add with ConfigFile

3. **No sound priority system** - All sounds equal priority  
   - Could add priority levels if needed
   - Currently uses "oldest first" for pool exhaustion

4. **No reverb/effects** - Pure sound playback only  
   - Godot AudioEffects could be added to bus
   - Outside scope of v0.5.0

---

## Commit Message (When Ready)

```
feat: implement audio manager with sound pooling

- [MAJOR] Created audio_manager.gd AutoLoad singleton (393 lines)
- [FEATURE] Sound pooling system (max 10 concurrent sounds)
- [FEATURE] Volume categories: Master, SFX, Music, Ambient, UI
- [FEATURE] Pitch variation (0.9-1.1x) for natural sound feel
- [FEATURE] Music crossfade system with Tween
- [FEATURE] Ambient loop management (multiple concurrent)
- [FEATURE] Complete API: play_sound(), play_music(), volume controls
- [MINOR] Created audio_manager_test.gd test suite
- [DOC] Created comprehensive implementation documentation

Task 1.1 complete - Foundation for all audio features
Next: Task 1.2 - Generate 43 AI audio files
```

---

**Status:** ✅ Ready for testing and Task 1.2 (AI Sound Generation)
