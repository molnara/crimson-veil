# v0.5.0 "Atmosphere & Audio" - Complete Implementation Guide

**Sprint Duration:** 7-10 days (12-15 sessions)  
**Budget:** $22 actual ($8 SFX Engine + $14 Mubert - saved $12)  
**Status:** Task 1.1 & 1.2 COMPLETE - 48 audio files generated and imported

---

## ðŸ“Š Design Decisions Summary

### Decision 1: Music Style
**Choice:** Pure Ambient Drone  
**Rationale:** Minimal, atmospheric, non-intrusive - fits "cozy loneliness" and meditative gathering  
**Implementation:** 2 tracks (day/night variation), 3 minutes each, seamless loops

### Decision 2: Footstep Complexity
**Choice:** Biome-aware (4 surface types)  
**Rationale:** Sweet spot between immersion and complexity  
**Surfaces:** Grass, Stone, Sand, Snow  
**Files Needed:** 12 files (3 variants per surface)

### Decision 3: Volume Philosophy
**Choice:** Hybrid (realistic ambient, exaggerated actions)  
**Rationale:** Industry standard for feel-good games (Stardew Valley, Terraria, Valheim)  
**Volume Ratios:**
- Music: 35% of master
- SFX: 75% of master  
- Ambient: 25% of master
- UI: 60% of master

### Decision 4: Budget Approach
**Choice:** $34 investment  
**Tools:** SFX Engine ($20) + Mubert ($14 for 1 month)  
**Alternative:** Free tier for testing, upgrade when satisfied

### Decision 5: Music Variety
**Choice:** Day/Night Variation (2 tracks)  
**Rationale:** Good middle ground - reinforces day/night cycle without over-complexity

---

## ðŸŽµ Complete AI Generation Prompts

### PART 1: Sound Effects (22 files)

#### Harvesting Sounds (6 files)

**1. axe_chop.wav**
```
Prompt: "Wood axe chopping into oak tree trunk, dull satisfying thunk, single hit sound, short duration"
Duration: 0.5-1 second
Tool: ElevenLabs or SFX Engine
Notes: This is the primary harvesting sound - should feel impactful
```

**2. pickaxe_hit.wav**
```
Prompt: "Stone pickaxe striking granite boulder, sharp crack sound, metal on stone, single hit"
Duration: 0.5-1 second
Tool: ElevenLabs or SFX Engine
Notes: Higher pitch than axe, more "crack" than "thunk"
```

**3. mushroom_pick.wav**
```
Prompt: "Hand picking mushroom from ground, soft pop and gentle crunch, quiet delicate sound"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Should be subtle - mushrooms are small
```

**4. strawberry_pick.wav**
```
Prompt: "Picking strawberry from bush, gentle rustle of leaves, soft plant movement"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Softer than mushroom, more leafy rustle
```

**5. resource_break.wav**
```
Prompt: "Resource completely harvested, satisfying crunch and snap, completion sound"
Duration: 0.5-1 second
Tool: ElevenLabs or SFX Engine
Notes: Plays when resource is fully depleted - should feel rewarding
```

**6. wrong_tool.wav**
```
Prompt: "Dull thud sound, unsuccessful hit, wrong tool on resource, negative feedback"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Should feel "wrong" - dull and unsatisfying
```

---

#### Movement Sounds (12 files)

**7-9. footstep_grass_1/2/3.wav**
```
Prompt: "Footstep on grass, natural walking pace, soft vegetation crunch"
Duration: 0.2-0.3 seconds each
Tool: ElevenLabs or SFX Engine
Notes: Generate 3 variations with slightly different tone/pitch
Variation 1: Normal grass step
Variation 2: Slightly lighter, higher pitch
Variation 3: Slightly heavier, lower pitch
```

**10-12. footstep_stone_1/2/3.wav**
```
Prompt: "Footstep on hard stone surface, boot on rock, walking pace"
Duration: 0.2-0.3 seconds each
Tool: ElevenLabs or SFX Engine
Notes: Generate 3 variations
Should sound harder and more echoey than grass
```

**13-15. footstep_sand_1/2/3.wav**
```
Prompt: "Footstep on beach sand, soft crunch, walking on sandy surface"
Duration: 0.2-0.3 seconds each
Tool: ElevenLabs or SFX Engine
Notes: Generate 3 variations
Softer than stone, grittier than grass
```

**16-18. footstep_snow_1/2/3.wav**
```
Prompt: "Footstep on snow, muffled crunch, walking on packed snow"
Duration: 0.2-0.3 seconds each
Tool: ElevenLabs or SFX Engine
Notes: Generate 3 variations
Most muffled of all footsteps, soft compression sound
```

---

#### Building Sounds (3 files)

**19. block_place.wav**
```
Prompt: "Wooden block snapping into place, satisfying click, construction sound"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Should feel satisfying and precise - Minecraft-like snap
```

**20. block_remove.wav**
```
Prompt: "Wood breaking, splintering sound, destruction of wooden structure"
Duration: 0.5-0.8 seconds
Tool: ElevenLabs or SFX Engine
Notes: More aggressive than placement - wood cracking/breaking
```

**21. build_mode_toggle.wav**
```
Prompt: "Soft electronic beep, mode switch sound, UI toggle notification"
Duration: 0.2-0.3 seconds
Tool: ElevenLabs or SFX Engine
Notes: Subtle, not intrusive - just acknowledgment of mode change
```

---

#### Inventory/UI Sounds (5 files)

**22. item_pickup.wav**
```
Prompt: "Coin clink sound, short metallic ting, item collection sound"
Duration: 0.2-0.4 seconds
Tool: ElevenLabs or SFX Engine
Notes: Classic pickup sound - should feel rewarding
```

**23. inventory_toggle.wav**
```
Prompt: "Soft whoosh sound, UI open and close, gentle air movement"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Neutral sound - works for both open and close
```

**24. craft_complete.wav**
```
Prompt: "Success ding, satisfying completion tone, achievement sound"
Duration: 0.5-0.8 seconds
Tool: ElevenLabs or SFX Engine
Notes: Should feel like an accomplishment - positive and clear
```

**25. stack_full.wav**
```
Prompt: "Negative beep, warning sound, inventory full alert"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Not harsh, but clearly indicates "can't do that"
```

**26. tool_switch.wav**
```
Prompt: "Quick click sound, tool change, fast mechanical snap"
Duration: 0.2-0.3 seconds
Tool: ElevenLabs or SFX Engine
Notes: Fast and responsive - confirms tool swap
```

---

#### Container Sounds (2 files)

**27. chest_open.wav**
```
Prompt: "Wooden chest opening, creak and groan, hinges creaking, slow opening"
Duration: 0.8-1.2 seconds
Tool: ElevenLabs or SFX Engine
Notes: Should sound like old wood - slight creak, not too loud
```

**28. chest_close.wav**
```
Prompt: "Chest closing, soft thud and latch click, wooden lid closing"
Duration: 0.5-0.8 seconds
Tool: ElevenLabs or SFX Engine
Notes: Shorter than open - just thud and latch
```

---

### PART 2: Additional UI Sounds (4 files)

**29. craft_unavailable.wav**
```
Prompt: "Negative beep, recipe unavailable sound, subtle error tone"
Duration: 0.3-0.5 seconds
Tool: ElevenLabs or SFX Engine
Notes: Different pitch from stack_full - indicates lack of resources
```

**30. health_low.wav**
```
Prompt: "Heartbeat sound, slow rhythmic thump, health warning loop"
Duration: 1-2 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: This loops when health < 20, should be noticeable but not annoying
```

**31. hunger_warning.wav**
```
Prompt: "Stomach growl, hunger alert sound, organic rumble"
Duration: 1-2 seconds
Tool: ElevenLabs or SFX Engine
Notes: Plays periodically when hunger < 15
```

**32. setting_click.wav**
```
Prompt: "Subtle click for settings menu, soft button press, UI feedback"
Duration: 0.1-0.2 seconds
Tool: ElevenLabs or SFX Engine
Notes: Very subtle - just enough feedback
```

---

### PART 3: Music Tracks (2 files)

**33. ambient_day.mp3**
```
MUBERT PROMPT:
"Meditative ambient drone, peaceful exploration, nature-inspired, 
calm mysterious atmosphere, cozy loneliness, no percussion, 
soft pads and subtle tones, seamless loop"

SETTINGS:
- Genre: Ambient
- Mood: Peaceful, Curious, Meditative
- Duration: 3 minutes (180 seconds)
- Style: Drone, Atmospheric
- Tempo: Slow (60-70 BPM)
- Energy: Low
- Instrumentation: Pads, drones, subtle textures

ALTERNATIVE BEATOVEN.AI PROMPT:
"Create ambient exploration music for peaceful gathering game, 
calm and meditative, nature-inspired atmosphere, 
3 minutes, seamless loop"
- Emotion: Calm
- Pace: Slow
- Genre: Ambient
```

**34. ambient_night.mp3**
```
MUBERT PROMPT:
"Dark ambient drone, mysterious night atmosphere, calm and peaceful, 
slightly darker than day version, no percussion, deep pads and 
distant echoes, cozy loneliness, seamless loop"

SETTINGS:
- Genre: Dark Ambient
- Mood: Mysterious, Calm, Introspective
- Duration: 3 minutes (180 seconds)
- Style: Drone, Atmospheric, Nocturnal
- Tempo: Slower (50-60 BPM)
- Energy: Very Low
- Instrumentation: Deep pads, distant echoes, subtle textures

ALTERNATIVE BEATOVEN.AI PROMPT:
"Create dark ambient music for nighttime exploration, 
mysterious and calm, slightly darker than day version, 
3 minutes, seamless loop"
- Emotion: Mysterious
- Pace: Very Slow
- Genre: Dark Ambient
```

---

### PART 4: Ambient Environmental Sounds (8 files)

**35. wind_light.wav**
```
Prompt: "Light breeze wind sound, gentle air movement, continuous loop, subtle"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Very subtle background layer - almost subliminal
```

**36. wind_strong.wav**
```
Prompt: "Strong mountain wind, howling wind sound, continuous loop"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: More prominent than light wind - should feel like altitude
```

**37. ocean_waves.wav**
```
Prompt: "Ocean waves on beach, rhythmic wave crashes, continuous loop, peaceful"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Should have natural rhythm - crash, retreat, crash
```

**38. crickets_night.wav**
```
Prompt: "Cricket chirping at night, multiple crickets, continuous loop, natural rhythm"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Should sound like actual night crickets - varied timing
```

**39. birds_day.wav**
```
Prompt: "Distant bird calls, various species, daytime ambience, continuous loop"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Multiple bird types, distant not loud, peaceful
```

**40. frogs_night.wav**
```
Prompt: "Frog croaks near water, nighttime ambience, continuous loop, natural"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Should sound like pond frogs - varied croak patterns
```

**41. leaves_rustle.wav**
```
Prompt: "Forest leaves rustling in wind, continuous loop, gentle movement"
Duration: 5-10 seconds (loopable)
Tool: ElevenLabs or SFX Engine
Notes: Subtle - adds forest atmosphere without overwhelming
```

**42. thunder_distant.wav**
```
Prompt: "Distant thunder rumble, atmospheric thunder, single hit, far away"
Duration: 3-5 seconds
Tool: ElevenLabs or SFX Engine
Notes: NOT looping - plays randomly for atmosphere
```

---

## ðŸ› ï¸ AI Tool Setup Instructions

### ElevenLabs (Free Tier)
1. Go to: https://elevenlabs.io/sound-effects
2. Sign up for free account
3. Free tier gives you limited generations per month
4. Enter prompts above in text box
5. Click "Generate"
6. Download as WAV (44.1kHz, stereo)

**Tips:**
- Use free tier for testing quality
- If satisfied, upgrade or switch to SFX Engine for unlimited

### SFX Engine ($20 - Recommended)
1. Go to: https://sfxengine.com/
2. Create account
3. Purchase $20 in credits (one-time purchase)
4. Enter prompts in generation interface
5. Generate and download immediately
6. Commercial license included automatically

**Tips:**
- $20 = 200+ sound effect generations
- No subscription - credits never expire
- Best value for professional quality

### Mubert ($14/month - Music Only)
1. Go to: https://mubert.com
2. Sign up for account
3. Subscribe to $14/month plan
4. Generate tracks using interface
5. Download as MP3
6. **Cancel subscription after generating tracks** (one month is enough)

**Alternative:** Beatoven.ai (~$10-20 for track credits)

---

## ðŸ“‚ Complete File Structure

```
res://audio/
â”œâ”€â”€ sfx/
â”‚   â”œâ”€â”€ harvesting/
â”‚   â”‚   â”œâ”€â”€ axe_chop.wav
â”‚   â”‚   â”œâ”€â”€ pickaxe_hit.wav
â”‚   â”‚   â”œâ”€â”€ mushroom_pick.wav
â”‚   â”‚   â”œâ”€â”€ strawberry_pick.wav
â”‚   â”‚   â”œâ”€â”€ resource_break.wav
â”‚   â”‚   â””â”€â”€ wrong_tool.wav
â”‚   â”œâ”€â”€ movement/
â”‚   â”‚   â”œâ”€â”€ footstep_grass_1.wav
â”‚   â”‚   â”œâ”€â”€ footstep_grass_2.wav
â”‚   â”‚   â”œâ”€â”€ footstep_grass_3.wav
â”‚   â”‚   â”œâ”€â”€ footstep_stone_1.wav
â”‚   â”‚   â”œâ”€â”€ footstep_stone_2.wav
â”‚   â”‚   â”œâ”€â”€ footstep_stone_3.wav
â”‚   â”‚   â”œâ”€â”€ footstep_sand_1.wav
â”‚   â”‚   â”œâ”€â”€ footstep_sand_2.wav
â”‚   â”‚   â”œâ”€â”€ footstep_sand_3.wav
â”‚   â”‚   â”œâ”€â”€ footstep_snow_1.wav
â”‚   â”‚   â”œâ”€â”€ footstep_snow_2.wav
â”‚   â”‚   â””â”€â”€ footstep_snow_3.wav
â”‚   â”œâ”€â”€ building/
â”‚   â”‚   â”œâ”€â”€ block_place.wav
â”‚   â”‚   â”œâ”€â”€ block_remove.wav
â”‚   â”‚   â””â”€â”€ build_mode_toggle.wav
â”‚   â”œâ”€â”€ ui/
â”‚   â”‚   â”œâ”€â”€ item_pickup.wav
â”‚   â”‚   â”œâ”€â”€ inventory_toggle.wav
â”‚   â”‚   â”œâ”€â”€ craft_complete.wav
â”‚   â”‚   â”œâ”€â”€ craft_unavailable.wav
â”‚   â”‚   â”œâ”€â”€ stack_full.wav
â”‚   â”‚   â”œâ”€â”€ tool_switch.wav
â”‚   â”‚   â”œâ”€â”€ health_low.wav
â”‚   â”‚   â”œâ”€â”€ hunger_warning.wav
â”‚   â”‚   â””â”€â”€ setting_click.wav
â”‚   â””â”€â”€ container/
â”‚       â”œâ”€â”€ chest_open.wav
â”‚       â””â”€â”€ chest_close.wav
â”œâ”€â”€ music/
â”‚   â”œâ”€â”€ ambient_day.mp3
â”‚   â””â”€â”€ ambient_night.mp3
â””â”€â”€ ambient/
    â”œâ”€â”€ wind_light.wav
    â”œâ”€â”€ wind_strong.wav
    â”œâ”€â”€ ocean_waves.wav
    â”œâ”€â”€ crickets_night.wav
    â”œâ”€â”€ birds_day.wav
    â”œâ”€â”€ frogs_night.wav
    â”œâ”€â”€ leaves_rustle.wav
    â””â”€â”€ thunder_distant.wav
```

**Total Files:** 43  
**Total Size:** ~50-100 MB (estimated)

---

## ðŸŽ¯ Implementation Code References

### Audio Manager Volume Constants
```gdscript
# audio_manager.gd
const MASTER_VOLUME_DEFAULT: float = 1.0
const SFX_VOLUME_DEFAULT: float = 0.75    # 75% - Punchy actions
const MUSIC_VOLUME_DEFAULT: float = 0.35   # 35% - Background atmosphere
const AMBIENT_VOLUME_DEFAULT: float = 0.25 # 25% - Subtle environmental
const UI_VOLUME_DEFAULT: float = 0.60      # 60% - Clear feedback
```

### Footstep Surface Detection
```gdscript
# player.gd
func _get_terrain_type() -> String:
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
            return "grass"  # Default fallback
```

### Sound Library Loading
```gdscript
# audio_manager.gd
func _load_all_sounds():
    # Harvesting
    sounds["axe_chop"] = load("res://audio/sfx/harvesting/axe_chop.wav")
    sounds["pickaxe_hit"] = load("res://audio/sfx/harvesting/pickaxe_hit.wav")
    sounds["mushroom_pick"] = load("res://audio/sfx/harvesting/mushroom_pick.wav")
    sounds["strawberry_pick"] = load("res://audio/sfx/harvesting/strawberry_pick.wav")
    sounds["resource_break"] = load("res://audio/sfx/harvesting/resource_break.wav")
    sounds["wrong_tool"] = load("res://audio/sfx/harvesting/wrong_tool.wav")
    
    # Movement (all 12 footstep variants)
    for surface in ["grass", "stone", "sand", "snow"]:
        for i in range(1, 4):
            var key = "footstep_%s_%d" % [surface, i]
            var path = "res://audio/sfx/movement/%s.wav" % key
            sounds[key] = load(path)
    
    # Building
    sounds["block_place"] = load("res://audio/sfx/building/block_place.wav")
    sounds["block_remove"] = load("res://audio/sfx/building/block_remove.wav")
    sounds["build_mode_toggle"] = load("res://audio/sfx/building/build_mode_toggle.wav")
    
    # UI
    sounds["item_pickup"] = load("res://audio/sfx/ui/item_pickup.wav")
    sounds["inventory_toggle"] = load("res://audio/sfx/ui/inventory_toggle.wav")
    sounds["craft_complete"] = load("res://audio/sfx/ui/craft_complete.wav")
    sounds["craft_unavailable"] = load("res://audio/sfx/ui/craft_unavailable.wav")
    sounds["stack_full"] = load("res://audio/sfx/ui/stack_full.wav")
    sounds["tool_switch"] = load("res://audio/sfx/ui/tool_switch.wav")
    sounds["health_low"] = load("res://audio/sfx/ui/health_low.wav")
    sounds["hunger_warning"] = load("res://audio/sfx/ui/hunger_warning.wav")
    sounds["setting_click"] = load("res://audio/sfx/ui/setting_click.wav")
    
    # Container
    sounds["chest_open"] = load("res://audio/sfx/container/chest_open.wav")
    sounds["chest_close"] = load("res://audio/sfx/container/chest_close.wav")
    
    # Ambient
    sounds["wind_light"] = load("res://audio/ambient/wind_light.wav")
    sounds["wind_strong"] = load("res://audio/ambient/wind_strong.wav")
    sounds["ocean_waves"] = load("res://audio/ambient/ocean_waves.wav")
    sounds["crickets_night"] = load("res://audio/ambient/crickets_night.wav")
    sounds["birds_day"] = load("res://audio/ambient/birds_day.wav")
    sounds["frogs_night"] = load("res://audio/ambient/frogs_night.wav")
    sounds["leaves_rustle"] = load("res://audio/ambient/leaves_rustle.wav")
    sounds["thunder_distant"] = load("res://audio/ambient/thunder_distant.wav")
```

---

## ðŸ“‹ Generation Workflow Checklist

### Phase 1: SFX Generation (2-3 hours)
- [ ] Sign up for ElevenLabs or SFX Engine
- [ ] Generate harvesting sounds (6 files)
- [ ] Generate movement sounds (12 files)
- [ ] Generate building sounds (3 files)
- [ ] Generate UI sounds (9 files)
- [ ] Generate container sounds (2 files)
- [ ] Generate ambient sounds (8 files)
- [ ] Download all as WAV (44.1kHz, stereo)
- [ ] Organize into folder structure locally

### Phase 2: Music Generation (30-60 minutes)
- [ ] Sign up for Mubert
- [ ] Generate day ambient track (3 minutes)
- [ ] Generate night ambient track (3 minutes)
- [ ] Download as MP3
- [ ] Test loop points (ensure seamless)
- [ ] Cancel Mubert subscription (after downloading)

### Phase 3: Import to Godot (30 minutes)
- [ ] Create res://audio/ directory structure
- [ ] Import all SFX to appropriate folders
- [ ] Import music tracks
- [ ] Import ambient sounds
- [ ] Verify all files imported correctly
- [ ] Check file sizes (should be reasonable)

### Phase 4: Testing (15 minutes)
- [ ] Play each sound in Godot to verify quality
- [ ] Check for clipping or distortion
- [ ] Verify loop points on ambient/music tracks
- [ ] Ensure volume levels are consistent
- [ ] Mark any sounds that need regeneration

---

## ðŸ’° Actual Budget Breakdown

| Item | Tool | Cost | Notes |
|------|------|------|-------|
| 40 SFX files | SFX Engine | $20 | One-time purchase, 200+ credits |
| 2 Music tracks | Mubert Pro | $14 | 1 month subscription (cancel after) |
| **TOTAL** | | **$34** | Professional commercial-licensed audio |

**Free Alternative Path:**
- ElevenLabs free tier: ~10 generations/month (test quality first)
- Mubert free tier: Tracks have watermark (test only)
- Upgrade only when satisfied with results

---

## âœ… Quality Checklist

Before accepting any generated sound:
- [ ] No clipping or distortion
- [ ] Appropriate duration (not too long/short)
- [ ] Clear audio (no background noise)
- [ ] Correct format (WAV 44.1kHz stereo for SFX, MP3 for music)
- [ ] Matches prompt description
- [ ] Sounds professional (not obviously AI-generated)
- [ ] Loops seamlessly (for ambient/music tracks)

If sound doesn't meet quality standards:
1. Regenerate with adjusted prompt
2. Try adding more descriptive keywords
3. Try different AI tool
4. Iterate until satisfied (credits allow multiple attempts)

---

## ðŸ“ Notes for Future Sessions

**When starting Task 1.2 (Sound Generation):**
1. Reference this document for all prompts
2. Generate sounds in batches (harvesting first, then movement, etc.)
3. Test quality before purchasing full SFX Engine credits
4. Save original prompts with generated files (for future iterations)

**When starting Task 2.1 (Music Generation):**
1. Use exact Mubert prompts above
2. Listen to full 3-minute preview before accepting
3. Verify seamless loop points
4. Download immediately (before canceling subscription)

**For all generations:**
- Keep a log of what works/doesn't work
- Save all files with descriptive names
- Back up originals before editing
- Document any manual adjustments needed

---

*This guide should be referenced throughout the entire v0.5.0 sprint for consistent implementation.*
