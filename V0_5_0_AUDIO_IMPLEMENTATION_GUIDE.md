# v0.5.0 "Atmosphere & Audio" - Complete Implementation Guide

**Sprint Duration:** 7-10 days (12-15 sessions)  
**Budget:** $22 actual ($8 SFX Engine + $14 Mubert - saved $12)  
**Status:** Priority 1 COMPLETE - Priority 2 in progress (4/13 tasks complete - 31%)

---

## 🎯 Design Decisions Summary

### Decision 1: Music Style
**Choice:** Pure Ambient Drone  
**Rationale:** Minimal, atmospheric, non-intrusive - fits "cozy loneliness" and meditative gathering  
**Implementation:** 8 tracks (4 day + 4 night), 2 minutes each, seamless loops

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
**Choice:** $22 investment  
**Tools:** SFX Engine ($8) + Mubert ($14 for 1 month)  
**Alternative:** Free tier for testing, upgrade when satisfied
**Result:** Saved $12 from $34 target

### Decision 5: Music Variety
**Choice:** Day/Night Variation (8 tracks: 4 day + 4 night)  
**Rationale:** Good middle ground - reinforces day/night cycle without over-complexity

---

## 🎵 Complete AI Generation Prompts

### PART 1: Sound Effects (40 files)

#### Harvesting Sounds (6 files) ✅ COMPLETE

**1. axe_chop.wav**
```
Prompt: "Wood axe chopping into oak tree trunk, dull satisfying thunk, single hit sound, short duration"
Duration: 0.5-1 second
Tool: SFX Engine
Notes: Primary harvesting sound - impactful
```

**2. pickaxe_hit.wav**
```
Prompt: "Stone pickaxe striking granite boulder, sharp crack sound, metal on stone, single hit"
Duration: 0.5-1 second
Tool: SFX Engine
Notes: Higher pitch than axe, more "crack" than "thunk"
```

**3. mushroom_pick.wav**
```
Prompt: "Hand picking mushroom from ground, soft pop and gentle crunch, quiet delicate sound"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Subtle - mushrooms are small
```

**4. strawberry_pick.wav**
```
Prompt: "Picking strawberry from bush, gentle rustle of leaves, soft plant movement"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Softer than mushroom, more leafy rustle
```

**5. resource_break.wav**
```
Prompt: "Resource completely harvested, satisfying crunch and snap, completion sound"
Duration: 0.5-1 second
Tool: SFX Engine
Notes: Plays when resource fully depleted - rewarding
```

**6. wrong_tool.wav**
```
Prompt: "Dull thud sound, unsuccessful hit, wrong tool on resource, negative feedback"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Should feel "wrong" - dull and unsatisfying
```

---

#### Movement Sounds (12 files) ✅ COMPLETE

**7-9. footstep_grass_1/2/3.wav**
```
Prompt: "Soft footstep on grass, gentle plant rustle, outdoor step on lawn"
Duration: 0.2-0.4 seconds each
Tool: SFX Engine
Notes: 3 variants for variety - prevent repetition
```

**10-12. footstep_stone_1/2/3.wav**
```
Prompt: "Boot step on stone floor, hard surface footstep, slight echo"
Duration: 0.2-0.4 seconds each
Tool: SFX Engine
Notes: Harder, more resonant than grass
```

**13-15. footstep_sand_1/2/3.wav**
```
Prompt: "Footstep on sandy beach, soft granular sound, beach walking"
Duration: 0.2-0.4 seconds each
Tool: SFX Engine
Notes: Muffled, grainy texture
```

**16-18. footstep_snow_1/2/3.wav**
```
Prompt: "Walking on fresh snow, soft crunch, muffled winter footstep"
Duration: 0.2-0.4 seconds each
Tool: SFX Engine
Notes: Crispy but muffled, distinct from sand
```

---

#### Building Sounds (3 files)

**19. block_place.wav**
```
Prompt: "Wood block being placed down, gentle thud, construction sound"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Satisfying placement feedback
```

**20. block_remove.wav**
```
Prompt: "Wood block being removed, quick pop, deconstruction sound"
Duration: 0.2-0.4 seconds
Tool: SFX Engine
Notes: Slightly higher pitch than placement
```

**21. build_mode_toggle.wav**
```
Prompt: "UI mode switch, soft mechanical click, toggle sound"
Duration: 0.1-0.2 seconds
Tool: SFX Engine
Notes: Clean, simple toggle feedback
```

---

#### UI Sounds (9 files)

**22. inventory_toggle.wav**
```
Prompt: "Inventory menu opens, soft whoosh, UI transition"
Duration: 0.2-0.3 seconds
Tool: SFX Engine
Notes: Non-intrusive, quick feedback
```

**23. craft_complete.wav**
```
Prompt: "Crafting success, satisfying ding, item created sound"
Duration: 0.5-0.8 seconds
Tool: SFX Engine
Notes: Should feel rewarding and complete
```

**24. item_pickup.wav**
```
Prompt: "Item collected, quick pop, satisfying pickup"
Duration: 0.2-0.3 seconds
Tool: SFX Engine
Notes: Frequent sound - keep it pleasant
```

**25. click_UI.wav**
```
Prompt: "Button click, soft tap, UI interaction"
Duration: 0.1-0.2 seconds
Tool: SFX Engine
Notes: Subtle, won't get annoying
```

**26. warning_hunger.wav**
```
Prompt: "Low hunger warning, soft bell or chime, attention sound"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Noticeable but not alarming
```

**27. warning_health.wav**
```
Prompt: "Low health warning, urgent but not harsh, danger alert"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: More urgent than hunger warning
```

**28. health_regen.wav**
```
Prompt: "Health regenerating, soft sparkle, restoration sound"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Positive, healing feeling
```

**29. eat_food.wav**
```
Prompt: "Eating food, quick munch, consumption sound"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Satisfying bite/chew
```

**30. tool_switch.wav**
```
Prompt: "Tool equip sound, soft metallic handling, equipment change"
Duration: 0.2-0.3 seconds
Tool: SFX Engine
Notes: Mechanical but not harsh
```

---

#### Container Sounds (2 files)

**31. chest_open.wav**
```
Prompt: "Wooden chest opening, creaky hinges, container access"
Duration: 0.5-0.8 seconds
Tool: SFX Engine
Notes: Classic chest sound - slight creak
```

**32. chest_close.wav**
```
Prompt: "Wooden chest closing, solid thud, secure latch"
Duration: 0.3-0.5 seconds
Tool: SFX Engine
Notes: Satisfying closure sound
```

---

#### Ambient Loops (8 files)

**33. ambient_wind.wav**
```
Prompt: "Gentle wind blowing through trees, soft whoosh, outdoor breeze"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Layer for grassland/forest biomes
```

**34. ambient_ocean.wav**
```
Prompt: "Ocean waves lapping at shore, rhythmic water, beach ambience"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Beach biome atmosphere
```

**35. ambient_crickets.wav**
```
Prompt: "Night crickets chirping, natural evening sounds, rhythmic insects"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Night time ambience
```

**36. ambient_birds.wav**
```
Prompt: "Forest birds chirping, distant songbirds, daytime wildlife"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Forest/grassland day ambience
```

**37. ambient_frogs.wav**
```
Prompt: "Frogs croaking near water, swamp sounds, night wildlife"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Near water at night
```

**38. ambient_leaves.wav**
```
Prompt: "Leaves rustling in gentle breeze, forest foliage, nature sounds"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Forest atmosphere
```

**39. ambient_thunder.wav**
```
Prompt: "Distant thunder rumbling, storm approaching, ominous weather"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Optional weather layer
```

**40. ambient_desert.wav**
```
Prompt: "Desert wind, sand blowing, hot dry air movement"
Duration: 2 minutes (seamless loop)
Tool: SFX Engine
Notes: Desert biome atmosphere
```

---

### PART 2: Music (8 files) ✅ COMPLETE

All music generated via Mubert Creator

#### Day Music (4 tracks)

**41. music_day_1.wav**
```
Mubert Prompt: "Ambient drone, peaceful morning atmosphere, soft synthesizer pads, no melody, meditative, cozy, slow tempo, seamless loop"
Duration: 2 minutes
Style: Ambient Drone
Mood: Peaceful, Morning
```

**42. music_day_2.wav**
```
Mubert Prompt: "Ambient drone, midday calm, warm atmospheric pads, minimal texture, no percussion, ethereal, seamless loop"
Duration: 2 minutes
Style: Ambient Drone
Mood: Calm, Warm
```

**43. music_day_3.wav**
```
Mubert Prompt: "Ambient drone, afternoon tranquility, gentle soundscape, no rhythm, meditative exploration, cozy loneliness, seamless loop"
Duration: 2 minutes
Style: Ambient Drone
Mood: Tranquil, Gentle
```

**44. music_day_4.wav**
```
Mubert Prompt: "Ambient drone, late afternoon warmth, soft ambient textures, no beat, peaceful gathering, atmospheric, seamless loop"
Duration: 2 minutes
Style: Ambient Drone
Mood: Warm, Peaceful
```

#### Night Music (4 tracks)

**45. music_night_1.wav**
```
Mubert Prompt: "Ambient drone, evening mystery, dark atmospheric pads, no melody, slightly ominous, cozy darkness, seamless loop"
Duration: 2 minutes
Style: Dark Ambient
Mood: Mysterious, Evening
```

**46. music_night_2.wav**
```
Mubert Prompt: "Ambient drone, midnight calm, deep soundscape, no rhythm, lonely exploration, quiet reflection, seamless loop"
Duration: 2 minutes
Style: Dark Ambient
Mood: Lonely, Calm
```

**47. music_night_3.wav**
```
Mubert Prompt: "Ambient drone, late night atmosphere, ethereal darkness, no percussion, meditative solitude, seamless loop"
Duration: 2 minutes
Style: Dark Ambient
Mood: Solitude, Ethereal
```

**48. music_night_4.wav**
```
Mubert Prompt: "Ambient drone, pre-dawn quiet, subtle dark textures, no beat, contemplative loneliness, atmospheric, seamless loop"
Duration: 2 minutes
Style: Dark Ambient
Mood: Contemplative, Quiet
```

---

## 📋 Implementation Checklist

### Phase 1: Audio Manager ✅ COMPLETE (2025-12-11)
- [X] Create audio_manager.gd singleton
- [X] Implement sound pooling (max 10 concurrent)
- [X] Add volume categories (Master/SFX/Music/Ambient/UI)
- [X] Create pitch variation system (0.9-1.1x)
- [X] Add music crossfade support
- [X] Create ambient loop manager
- [X] Write audio_manager_test.gd
- [X] Test in-game, verify singleton works

**Files Created:**
- `audio_manager.gd` (393 lines)
- `audio_manager_test.gd` (test suite)
- `audio_manager_test.tscn` (test scene)
- `AUDIO_MANAGER_README.md` (documentation)

---

### Phase 2: AI Sound Generation ✅ COMPLETE (2025-12-12)
- [X] Generate 40 SFX via SFX Engine ($8)
- [X] Generate 8 music tracks via Mubert ($14)
- [X] Import all audio to res://audio/ folder
- [X] Configure loop settings on music/ambient
- [X] Update _load_sound_library() in audio_manager.gd
- [X] Test all sounds play correctly

**Files Generated:**
- 40 SFX files (harvesting: 6, movement: 12, building: 3, UI: 9, container: 2, ambient: 8)
- 8 music files (4 day + 4 night)
- Budget: $22 actual (under target by $12)

---

### Phase 3: SFX Integration - Harvesting ✅ COMPLETE (2025-12-12)
- [X] Add harvesting sound hooks to harvesting_system.gd
- [X] Wire axe_chop and pickaxe_hit sounds
- [X] Add wrong_tool feedback sound
- [X] Add resource_break completion sound
- [X] Add tool_switch sound on equipment change
- [X] Add log despawn "poof" sound to log_piece.gd
- [X] Test all harvesting audio in-game

**Files Modified:**
- `harvesting_system.gd` (added 4 audio hooks)
- `harvestable_resource.gd` (added resource_break on completion)
- `harvestable_tree.gd` (added resource_break for tree-specific)
- `log_piece.gd` (added despawn sound)

---

### Phase 4: Movement Sounds - Footsteps ✅ COMPLETE (2025-12-12)
- [X] Add footstep timer system to player.gd
- [X] Create _get_terrain_surface() biome detection method
- [X] Integrate footstep playback in _physics_process()
- [X] Implement walk/sprint interval timing (0.45s/0.28s)
- [X] Add velocity-based steep slope detection
- [X] Tune biome transition buffer zones (0.03)
- [X] Test footsteps on all terrain types
- [X] Fix beach spawn zone override issue
- [X] Fix steep slope silence issue
- [X] Test across all biomes and slopes

**Files Modified:**
- `player.gd` (+78 lines)

**Features Implemented:**
- Biome-aware surface detection (grass, stone, sand, snow)
- Dual ground detection (floor + velocity)
- Smooth biome transitions (0.03 buffer = 2-4m)
- Walk: 0.45s, Sprint: 0.28s intervals
- Works on slopes up to 80° (beyond floor_max_angle)

**Bugs Fixed During Testing:**
- Beach spawn zone override (removed spawn check from audio)
- Steep slope detection (velocity thresholds: y < 3.5, length > 0.3)
- Biome transition feel (reduced buffer 0.05 → 0.03)

---

### Phase 5: Building Sounds (NOT STARTED)
- [ ] Add sound hooks to building_system.gd
- [ ] Wire block_place on block placement
- [ ] Wire block_remove on block destruction
- [ ] Wire build_mode_toggle on Tab press
- [ ] Test building audio in-game

**Files to Modify:**
- `building_system.gd`

---

### Phase 6: UI Sounds (NOT STARTED)
- [ ] Add inventory_toggle sound to inventory UI
- [ ] Add craft_complete sound to crafting system
- [ ] Add item_pickup sound to inventory adds
- [ ] Wire warning sounds to health/hunger system
- [ ] Add click_UI to settings menu
- [ ] Test all UI audio

**Files to Modify:**
- `inventory_ui.gd`
- `crafting_system.gd`
- `health_hunger_system.gd`
- `settings_menu.gd` (if exists)

---

### Phase 7: Container Sounds (NOT STARTED)
- [ ] Add chest_open sound to container opening
- [ ] Add chest_close sound to container closing
- [ ] Test container audio

**Files to Modify:**
- `container_ui.gd` or `player.gd` (container interaction)

---

### Phase 8: Music System (NOT STARTED)
- [ ] Create music manager (or extend audio_manager)
- [ ] Wire day/night cycle to music playback
- [ ] Implement crossfade between tracks
- [ ] Add random track selection per day/night
- [ ] Test music transitions at dawn/dusk

**Files to Modify/Create:**
- `day_night_cycle.gd` (add music integration)
- Possibly create `music_manager.gd`

---

### Phase 9: Ambient Environmental Sounds (NOT STARTED)
- [ ] Create ambient manager
- [ ] Layer ambient sounds by biome
- [ ] Add biome detection for ambient switching
- [ ] Implement volume ducking for overlapping ambients
- [ ] Test ambient transitions when moving between biomes

**Files to Create:**
- `ambient_manager.gd`

---

### Phase 10: Settings Menu - Audio Controls (NOT STARTED)
- [ ] Add volume sliders to settings UI
- [ ] Wire sliders to AudioManager volume functions
- [ ] Add mute toggles for each category
- [ ] Add audio test buttons
- [ ] Save/load audio settings

**Files to Modify:**
- `settings_menu.gd`
- `settings_menu.tscn`

---

### Phase 11: Polish & Balance (NOT STARTED)
- [ ] Adjust volume levels across all sounds
- [ ] Test audio in various gameplay scenarios
- [ ] Ensure no audio spam or overlap issues
- [ ] Fine-tune pitch variation ranges
- [ ] Optional: Add controller rumble

---

## 🎮 Integration Patterns

### Pattern 1: Simple Sound Trigger
```gdscript
# For one-off sounds
AudioManager.play_sound("axe_chop", "sfx", true, false)
# Arguments: sound_name, category, pitch_variation, volume_variation
```

### Pattern 2: Random Variant Selection
```gdscript
# For sounds with multiple variants (footsteps, etc)
AudioManager.play_sound_variant("footstep_grass", 3, "sfx", true, false)
# Plays footstep_grass_1, footstep_grass_2, or footstep_grass_3 randomly
```

### Pattern 3: Music Crossfade
```gdscript
# For transitioning between music tracks
AudioManager.play_music("music_day_1", true, 2.0)
# Crossfades with 2-second fade duration
```

### Pattern 4: Ambient Loop
```gdscript
# For background environmental sounds
AudioManager.play_ambient("ambient_wind", 0.3)
# Plays looped with 30% volume
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Sound Not Playing
**Symptoms:** AudioManager.play_sound() called but no audio
**Causes:**
- Sound not loaded in _load_sound_library()
- Wrong sound name (typo)
- Volume at 0% in category
- Sound pool maxed out (10 concurrent limit)

**Solutions:**
1. Check print() output for "ERROR: Sound X not found"
2. Verify sound name matches dictionary key
3. Check volume levels in audio_manager.gd
4. Reduce concurrent sounds if pool is full

### Issue 2: Music Doesn't Loop
**Symptoms:** Music plays once then stops
**Causes:**
- Loop not enabled in Godot import settings
- Music not marked as looping in audio_manager

**Solutions:**
1. Select music file in FileSystem
2. Go to Import tab
3. Enable "Loop" checkbox
4. Click "Reimport"

### Issue 3: Footsteps Too Fast/Slow
**Symptoms:** Walking sounds unnatural
**Causes:**
- Footstep interval timing off
- Not respecting sprint state

**Solutions:**
1. Adjust WALK_FOOTSTEP_INTERVAL in player.gd
2. Adjust SPRINT_FOOTSTEP_INTERVAL
3. Verify sprint detection working

### Issue 4: Footsteps Don't Match Terrain
**Symptoms:** Wrong surface sounds playing
**Causes:**
- Biome detection logic incorrect
- Transition buffer too large/small

**Solutions:**
1. Check _get_terrain_surface() return values
2. Adjust TRANSITION_BUFFER constant
3. Verify chunk_manager noise thresholds

---

## 📊 Budget Breakdown

| Item | Cost | Notes |
|------|------|-------|
| SFX Engine | $8 | Pay-per-credit, ~$0.20 per sound |
| Mubert Creator | $14 | 1-month subscription |
| **Total** | **$22** | Under $34 target by $12 |

---

## ✅ Acceptance Criteria

**Sprint is complete when:**

**Phase 1-3:** ✅ COMPLETE
- [X] Audio manager functional with sound pooling
- [X] All 48 audio files generated and imported
- [X] Harvesting sounds integrated and tested
- [X] Footsteps integrated with biome detection

**Phase 4-7:** IN PROGRESS (Task 2.1 complete)
- [X] Footstep sounds play with correct timing
- [X] Footsteps change based on biome
- [X] Footsteps work on steep slopes
- [ ] Building sounds trigger on placement/removal
- [ ] UI sounds provide feedback on actions
- [ ] Container sounds play on open/close

**Phase 8-9:** NOT STARTED
- [ ] Music crossfades between day/night
- [ ] Ambient sounds layer by biome
- [ ] No audio spam or overlap issues

**Phase 10-11:** NOT STARTED
- [ ] Settings menu has working audio controls
- [ ] Volume levels feel balanced
- [ ] All sounds tested in gameplay context

**Technical Requirements:**
- [X] No console errors related to audio
- [X] Sound pool prevents audio spam
- [X] Music loops seamlessly
- [X] All sounds have proper licensing

---

## 🚀 Next Steps After v0.5.0

Once audio sprint is complete, prioritize:
1. **Save/load system** [Opus] - High priority, complex
2. **Workbench & advanced crafting** [Sonnet] - Deferred from v0.5.0
3. **Inventory organization** [Sonnet] - Sort, quick-stack, animations
4. **Combat system** [Opus] - New major system

---

## 📈 Progress Tracking

**Overall Sprint Progress: 4/13 tasks (31%)**

**Priority 1:** ✅ COMPLETE (3/3 tasks)
- Audio Manager Architecture
- AI Sound Generation
- Harvesting SFX Integration

**Priority 2:** 🔄 IN PROGRESS (1/6 tasks)
- ✅ Movement Sounds (Footsteps)
- ⏳ Building Sounds
- ⏳ UI Sounds
- ⏳ Container Sounds
- ⏳ Music System
- ⏳ Ambient Sounds

**Priority 3:** ⏳ NOT STARTED (0/4 tasks)

---

*Last Updated: 2025-12-12 04:45 AM EST*
*Sprint Status: Active (Day 2 of 7-10)*
