# Crimson Veil - Quick Start

**Minimal session context for fast starts. For full details, use SESSION_START_UPLOAD.md**

---

## 🚨 THE ONE CRITICAL RULE

**ALWAYS output COMPLETE files. Never partial updates.**

If player.gd is 500 lines and line 50 changes:
- ✅ Output all 500 lines with the change
- ❌ "Replace line 50 with..."

If CHANGELOG.txt is 195 lines:
- ✅ Output all 195 lines
- ❌ "Add these 3 lines to line 15..."

**No exceptions. Ever.**

---

## 📊 Project Overview

**Game:** Crimson Veil - Survival crafting (Valheim/Minecraft style)  
**Engine:** Godot 4.3, GDScript  
**Style:** Low-poly + 16x16 textures  
**Tone:** Cozy loneliness with meditative gathering  

**Current Version:** v0.5.0 "Atmosphere & Audio" (in progress)  
**Last Release:** v0.4.0 "Storage & Organization" (commit d53049d)  
**Code Quality:** A (Excellent) - from Opus 4.5 review

---

## 🎯 Current Sprint Status

**Sprint:** v0.5.0 "Atmosphere & Audio"  
**Progress:** 6/13 tasks complete (46%)  
**Timeline:** 12-15 sessions (~7-10 days)  
**Model:** Sonnet (standard implementation)

### ✅ Completed (6 tasks)
- Audio Manager Architecture
- AI Sound Generation & Import (48 files)
- Harvesting Sound Integration
- Movement Sounds (Footsteps)
- Music Manager & AI Music System
- Ambient Environmental Sounds

### 🎯 Next Task: Building Sounds
**Goal:** Add audio feedback to building system  
**Sounds:** block_place, block_remove, build_toggle  
**File:** scripts/building/building_system.gd needs audio hooks  

### 📋 Remaining Tasks (7)
- Building Sounds
- UI Sounds (inventory, crafting, pickup, warnings)
- Container Sounds (chest_open, chest_close)
- Settings Menu - Audio Controls
- Sound Variation System
- Audio Balance Pass
- Controller Rumble (optional)

---

## 🗂️ File Locations (Quick Reference)

**All files in root directory currently (needs reorganization later)**

### Key Files for Current Work
```
building_system.gd         [Building logic - needs audio hooks]
audio_manager.gd           [Sound playback system - reference]
music_manager.gd           [Music system - reference]
ambient_manager.gd         [Ambient audio - reference]
```

### Core Systems
```
player.gd                  [Player input, movement, camera]
inventory.gd               [Item storage, stacking]
crafting_system.gd         [Recipe validation, resource consumption]
harvesting_system.gd       [Resource gathering - has audio example]
```

### Documentation
```
docs/ARCHITECTURE.md       [System design, signals, AutoLoads]
docs/STYLE_GUIDE.md        [Naming conventions, code patterns]
docs/DEVELOPMENT_GUIDE.md  [Complete architecture reference]
```

**See FILE_INDEX.md for complete file map**

---

## 🎮 Technical Stack

**Current Systems:**
- ✅ World generation (chunk-based, procedural biomes)
- ✅ Player movement (keyboard + controller, camera)
- ✅ Inventory (32 slots, stacking up to 99)
- ✅ Crafting (recipe system, resource consumption)
- ✅ Building (blocks, rotation, validation)
- ✅ Harvesting (tools, resources, respawn)
- ✅ Containers (chests, 32 slots each)
- ✅ Audio (sound pooling, music, ambient) ← **Current Focus**
- ❌ Combat (planned v0.9.0)
- ❌ Save/Load (high priority backlog)

**Audio Assets:** 48 files (40 SFX + 8 music)  
**Audio Budget:** $22 actual (under $34 target by $12)  

---

## 🔧 Important Technical Notes

### Audio System
- **Audio Manager** = AutoLoad singleton (globally accessible)
- **Sound Pooling** = Max 10 concurrent sounds to prevent spam
- **Music System** = Day/night rotation with 30s crossfades
- **Ambient System** = Biome-aware loops with frequency control
- **All audio files** in res://audio/ with proper folder structure

### Building System
- **Block placement** via D-Pad Up or Left-Click
- **Block removal** via D-Pad Down or Right-Click
- **Rotation** via D-Pad Left/Right
- **Build mode toggle** via B button or B key

### Code Patterns
- **Signals** for loose coupling between systems
- **AutoLoads** for global managers (AudioManager, MusicManager, AmbientManager)
- **Consistent naming** (snake_case for variables/functions, PascalCase for classes)
- **Always commit .uid files** with their parent .gd/.tscn files

---

## 📝 Recent Changes (Last 5)

1. **[2025-12-12 20:30]** Updated file output rules - COMPLETE files mandatory
2. **[2025-12-12 18:45]** Reduced ambient volumes by ~30% for subtler atmosphere
3. **[2025-12-12 18:30]** Task 2.3 complete - Ambient system with biome-aware loops
4. **[2025-12-12 18:00]** Task 2.2 complete - Music Manager with day/night rotation
5. **[2025-12-12 09:15]** Fixed log despawn sound spam (removed audio from despawn)

---

## 🐛 Known Issues

**None currently** - Sprint progressing smoothly!

**Potential Issues** (from code review - not confirmed):
- Race condition if container destroyed while UI open (needs null checks)
- Input blocking too broad in player.gd line 148

---

## 🤖 Model Selection Guide

**Use Sonnet for:**
- Standard feature implementation ← **Most tasks**
- Bug fixes
- Integration work
- Polish & refinement

**Use Opus for:**
- Complex architecture decisions
- Multi-system refactoring
- Code reviews
- Major design decisions

---

## ⚙️ Quick Commands (Testing)

```bash
# Run game
godot --path . world.tscn

# Test audio system
godot --path . audio_manager_test.tscn

# Press keys in test scene:
# 1-8: Test specific audio categories
# 0: Stop all audio
```

---

## 📦 What to Upload

### For Current Task (Building Sounds)
```
Upload: building_system.gd
Optional: audio_manager.gd (for reference)
```

### For Bug Fixes
```
Upload: [buggy_file.gd]
```

### For New Features
```
Upload: QUICK_START.md or SESSION_START_UPLOAD.md
Upload: [relevant_file.gd]
Upload: docs/ARCHITECTURE.md (if architecture context needed)
```

### For Planning
```
Upload: SESSION_START_UPLOAD.md
Upload: ROADMAP.txt
Upload: docs/ARCHITECTURE.md
```

### For Commits
```
Upload: All modified files
Upload: SESSION_START_UPLOAD.md or QUICK_START.md
Upload: CHANGELOG.txt
```

---

## ✅ File Output Checklist

Before outputting ANY file, verify:
- [ ] Entire file present (line 1 to end)?
- [ ] All unchanged sections included?
- [ ] Exact filename (no _CLEAN, _NEW, etc)?
- [ ] UTF-8 encoding (→ not ->, ✅ not x)?
- [ ] No "..." or abbreviations?

**If ANY checkbox fails → Read original completely, create complete version.**

---

## 📋 UTF-8 Quick Reference

```
✅ Arrows: → ← ↑ ↓        (never ->, <-, etc)
✅ Checkmarks: ✅ ❌       (never x, check)
✅ Math: × ÷ ± ≈          (never x, /, +/-)
✅ Bullets: • ○ ●         (never *, -, +)
```

---

## 🎯 Next Steps

**Ready to work!**

1. **Building Sounds** ← Current task
2. UI Sounds
3. Container Sounds
4. Settings Menu Audio Controls
5. Sound Variation System
6. Audio Balance Pass
7. Controller Rumble (optional)

**For full context, architecture patterns, or detailed planning:**  
→ Use SESSION_START_UPLOAD.md instead of this quick start file

---

**REMINDER: Output COMPLETE files with EXACT names. No partials. No suffixes. Every time.**
