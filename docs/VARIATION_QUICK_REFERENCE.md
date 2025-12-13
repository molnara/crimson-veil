# Sound Variation System - Quick Reference

## Presets

```gdscript
"none"     → No variation (1.0x pitch, 1.0x volume)
"subtle"   → ±3% pitch, -5% to 0% volume
"moderate" → ±7% pitch, -10% to 0% volume
"strong"   → ±12% pitch, -15% to 0% volume
```

## Current Configuration (48 sounds)

### Strong Variation (12 sounds)
- `footstep_grass_1/2/3` - Maximum organic feel
- `footstep_stone_1/2/3` - Walking diversity
- `footstep_sand_1/2/3` - Natural movement
- `footstep_snow_1/2/3` - Crunch variety

### Moderate Variation (5 sounds)
- `axe_chop` - Impact diversity
- `pickaxe_hit` - Mining variety
- `resource_break` - Destruction sounds
- `mushroom_pick` - (subtle override)
- `strawberry_pick` - (subtle override)

### Subtle Variation (6 sounds)
- `mushroom_pick` - Gentle variation
- `strawberry_pick` - Soft sounds
- `block_place` - Building consistency
- `block_remove` - Controlled variation
- `chest_open` - Container feedback
- `chest_close` - UI clarity
- `item_pickup` - Pickup satisfaction

### No Variation (17 sounds)
**UI Sounds (9):**
- `inventory_toggle` - Consistent UI
- `craft_complete` - Clear success
- `craft_unavailable` - Clear failure
- `stack_full` - Inventory feedback
- `tool_switch` - Equipment change
- `health_low` - Warning clarity
- `hunger_warning` - Critical alert
- `setting_click` - Menu feedback

**Ambient Loops (8):**
- `wind_light/strong` - Natural loops
- `ocean_waves` - Seamless ambiance
- `crickets_night` - Environmental
- `birds_day` - Background life
- `frogs_night` - Wetland sounds
- `leaves_rustle` - Foliage
- `thunder_distant` - Weather

## Usage Examples

### Basic Usage (Auto-Variation)
```gdscript
# Footsteps automatically get strong variation
AudioManager.play_sound_variant("footstep_grass", 3, "sfx")

# Harvesting gets moderate variation
AudioManager.play_sound("axe_chop", "sfx")

# UI sounds get no variation
AudioManager.play_sound("craft_complete", "ui")
```

### Runtime Customization
```gdscript
# Make axe chops more varied
AudioManager.set_sound_variation("axe_chop", "strong")

# Custom ranges for special sounds
AudioManager.set_sound_variation("boss_roar", {
    "pitch": [0.80, 1.20],  # ±20% pitch
    "volume": [0.85, 1.0]   # -15% to 0% volume
})

# Temporarily disable variation
AudioManager.set_sound_variation("block_place", "none")

# Reset to default
AudioManager.reset_variation("block_place")
```

### Debugging
```gdscript
# Check what variation a sound uses
var settings = AudioManager.get_sound_variation("axe_chop")
print(settings)  # {"pitch": [0.93, 1.07], "volume": [0.90, 1.0]}

# Print all configured sounds
AudioManager.print_variation_info()

# Print specific sound
AudioManager.print_variation_info("footstep_grass_1")
```

## Design Philosophy

**Strong Variation:**
- Repetitive sounds (footsteps, ambient loops with variants)
- Maximum organic feel
- Player shouldn't notice patterns

**Moderate Variation:**
- Impact sounds (tools hitting resources)
- Balance between variety and recognition
- Sound should be identifiable but not robotic

**Subtle Variation:**
- Building/construction sounds
- Containers and interactions
- Enough variety to avoid monotony
- Maintains consistency during rapid use

**No Variation:**
- Critical UI feedback
- Warning sounds
- Menu interactions
- Clarity is more important than variety

## Technical Notes

- Variation happens at playback time (no pre-processing)
- Volume variation is always negative or zero (prevents clipping)
- Pitch variation is symmetric (±X%)
- All presets are const (zero allocation)
- Default preset is "moderate" for unconfigured sounds
