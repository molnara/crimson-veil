# Crimson Veil - Session Start Guide

**Quick context file for Claude at session start**

---

## 📊 Sprint Progress

**Sprint:** v0.5.0 "Atmosphere & Audio"  
**Status:** 8/13 tasks complete (62%)  
**Budget:** $22 / $34 target (under by $12)  
**Timeline:** Session 8 of 12-15 (~7-10 days)  
**Model:** Sonnet (standard implementation)

### ✅ Completed This Sprint
- [x] Audio Manager Architecture (Task 1.1)
- [x] AI Sound Generation & Import - 48 files (Task 1.2)
- [x] Harvesting Sound Integration (Task 1.3)
- [x] Movement Sounds - Footsteps (Task 2.1)
- [x] Music Manager & AI Music System (Task 2.2)
- [x] Ambient Environmental Sounds (Task 2.3)
- [x] Building Sounds (Task 2.4)
- [x] Container Sounds (Task 2.5)

### 🎯 Remaining Tasks
- [ ] UI Sounds (inventory, crafting, pickup, warnings)
- [ ] Settings Menu - Audio Controls (volume sliders)
- [ ] Sound Variation System (pitch/volume randomization)
- [ ] Audio Balance Pass (test all scenarios)
- [ ] Controller Rumble (optional haptic feedback)

---

## 🎯 Next Session Priority

**Recommended:** UI Sounds implementation

**Files needed:**
- `audio_manager.gd` - Add UI sound category
- `inventory_ui.gd` - Play inventory_toggle, item_pickup sounds
- `crafting_ui.gd` - Play craft_complete, craft_fail sounds
- `player.gd` - Play pickup sounds on item collection

**Audio assets ready:**
- `ui/inventory_open.wav`, `ui/inventory_close.wav`
- `ui/craft_complete.wav`, `ui/craft_fail.wav`
- `ui/item_pickup.wav`
- `ui/warning_*.wav` (3 variations)

---

## 📝 Recent Changes (Last 5)

1. **[2025-12-12 22:45]** Task 2.5 complete - Container sounds (chest_open, chest_close)
2. **[2025-12-12 22:45]** Task 2.4 complete - Building sounds (block_place, block_remove, build_toggle)
3. **[2025-12-12 22:45]** Fixed chest collision - Dual-layer (Layer 1 + 3) for blocking AND interaction
4. **[2025-12-12 20:30]** Updated file output rules - COMPLETE files mandatory
5. **[2025-12-12 18:45]** Reduced ambient volumes by ~30% for subtler atmosphere

---

## 🛠️ Known Issues

**Fixed This Session:**
- ✅ Chests couldn't be opened (collision layer mismatch)
- ✅ Chests couldn't be deleted (raycast on wrong layer)
- ✅ Player could walk through chests (no physical collision)

**Potential Issues** (from code review - not confirmed):
- Race condition if container destroyed while UI open (needs null checks)
- Input blocking too broad in player.gd line 148

---

## 🎮 Technical Context

**Engine:** Godot 4.3  
**Language:** GDScript  
**Style:** Low-poly + 16x16 textures (Valheim/Minecraft aesthetic)  
**Tone:** Cozy loneliness with meditative gathering

**Current Systems:**
- ✅ World generation (chunk-based, procedural biomes)
- ✅ Player movement (keyboard + controller, camera)
- ✅ Inventory (32 slots, stacking up to 99)
- ✅ Crafting (recipe system, resource consumption)
- ✅ Building (blocks, rotation, validation)
- ✅ Harvesting (tools, resources, respawn)
- ✅ Containers (chests, 32 slots each)
- ✅ Audio (sound pooling, music, ambient) ← Current Focus
- ❌ Combat (planned v0.9.0)
- ❌ Save/Load (high priority backlog)

**Audio Assets:** 48 files (40 SFX + 8 music)

---

## 📋 File Output Rules (Simplified)

### For Documentation Files
When updating SESSION_START.md, ROADMAP.txt, or creating COMMIT_MESSAGE.txt:
- ✅ Output complete file with all sections
- ✅ Use exact filename (no _NEW, _UPDATED suffixes)
- ✅ UTF-8 encoding (→ not ->, ✅ not x)

### For Code Files
**You handle code files via Git. I only output code when:**
- You explicitly request a complete file
- It's a new file that doesn't exist yet
- You ask me to "show me the updated file"

**Otherwise, I describe changes and you commit via Git.**

---

## 🎯 Commit Process

When you say **"Generate a commit"**, I will:

1. **Create COMMIT_MESSAGE.txt** - Ready-to-use commit message
2. **Update SESSION_START.md** - Sprint progress, recent changes
3. **Update ROADMAP.txt** - Mark tasks complete (if applicable)
4. **Share files** - Use present_files tool

**You then:**
1. Commit your code changes via Git
2. Optionally copy updated docs to your repo
3. Use: `git commit -F COMMIT_MESSAGE.txt`

---

## 📁 File Locations

**See FILE_INDEX.md for complete file map**

**Core files currently in root:**
- `audio_manager.gd` - Sound playback system
- `music_manager.gd` - Music system
- `ambient_manager.gd` - Ambient audio
- `building_system.gd` - Building logic
- `player.gd` - Player input, movement, camera
- `inventory.gd` - Item storage
- `crafting_system.gd` - Recipe system
- `harvesting_system.gd` - Resource gathering

**Documentation:**
- `docs/ARCHITECTURE.md` - System design, signals
- `docs/STYLE_GUIDE.md` - Naming conventions
- `docs/DEVELOPMENT_GUIDE.md` - Complete reference

---

## 🤖 Model Selection

**Use Sonnet (this chat) for:**
- Standard implementation
- Bug fixes
- Integration work
- Polish & refinement

**Use Opus for:**
- Complex architecture decisions
- Multi-system refactoring
- Code reviews
- Save/load system (future)

---

## ⚙️ Quick Commands

**See COMMANDS.md for full reference**

```bash
# Run game
godot --path . world.tscn

# Test audio
godot --path . audio_manager_test.tscn

# Commit workflow
git add .
git commit -F COMMIT_MESSAGE.txt
git push
```

---

## 💡 Session Workflow

**⚠️ CRITICAL RULE: Never start coding until you say "proceed"**

**Starting work:**
1. Upload SESSION_START.md (this file)
2. Upload specific code files you're working on
3. I request any other files I need
4. I discuss the approach, ask clarifying questions
5. **You review the plan and say "proceed"**
6. Only then do I output code or describe changes

**During work:**
- I describe code changes
- You implement via your editor/Git
- Or I output complete files if requested

**Finishing work:**
- Say "Generate a commit"
- I create commit message + update docs
- You commit via Git

---

**Ready to work! What's the task?**
