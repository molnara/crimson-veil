# Crimson Veil - Session Start Guide

## 🚨 CRITICAL: COMPLETE FILES ONLY - NO EXCEPTIONS

**BEFORE DOING ANYTHING ELSE, READ THIS:**

When creating or updating files for commit, Claude MUST:

### MANDATORY FILE OUTPUT RULES

**ALWAYS - NO EXCEPTIONS:**
1. ✅ Output the **ENTIRE COMPLETE FILE** from line 1 to the end
2. ✅ Include **EVERY SINGLE LINE** - no truncation, no "...", no abbreviations
3. ✅ Use **EXACT FILENAME** from FILE_INDEX.md (CHANGELOG.txt not CHANGELOG_CLEAN.txt)
4. ✅ Include **ALL UNCHANGED SECTIONS** - even parts that didn't change
5. ✅ Use **UTF-8 ENCODING** (→ not ->, ✅ not x, 🎯 not :target:)

**NEVER - UNDER ANY CIRCUMSTANCES:**
1. ❌ Output partial updates, diffs, or "here's what changed"
2. ❌ Use temporary suffixes (_CLEAN, _NEW, _UPDATED, _FINAL, _V2)
3. ❌ Show "..." or "[rest of file unchanged]" or similar
4. ❌ Say "add these lines to..." without showing complete file
5. ❌ Reference line numbers without outputting full file

### What "COMPLETE FILE" Means

If CHANGELOG.txt is 195 lines:
- ✅ Output all 195 lines in one file
- ❌ Output "lines 1-20 changed, add this..."

If player.gd is 500 lines and you change line 50:
- ✅ Output all 500 lines with the change
- ❌ Output "replace line 50 with..."

### Example: CORRECT File Output

```
User: "Add footstep sounds to player.gd"

Claude:
1. Reads complete player.gd (all 500 lines)
2. Makes the changes internally
3. Outputs COMPLETE player.gd (all 500 lines) to /mnt/user-data/outputs/player.gd
4. Uses present_files tool to share it
5. Done

NOT THIS:
❌ "Add this code to line 50..."
❌ "Insert this function after _physics_process()..."
❌ "Here's the updated section..."
```

### The Only Two Acceptable Outputs

**Option 1: Complete File**
```python
# Output to /mnt/user-data/outputs/player.gd
[entire file from line 1 to end, all 500 lines]
```

**Option 2: Explanation Without Code**
```
"I need to see player.gd first. Please upload it."
```

There is NO option 3. No partial updates exist.

---

## ⚠️ File Location Rules

**Claude can ONLY see these 4 files automatically:**
- SESSION_START.md (this file)
- FILE_INDEX.md (complete file map)
- ROADMAP.txt (feature planning)
- CHANGELOG.txt (change history)

**Everything else is in Git Repo and requires upload.**

When Claude needs files, Claude will say:
```
I need to see:
- scripts/player/player.gd
- docs/ARCHITECTURE.md

Please upload these files.
```

---

## 🎯 Current Sprint: v0.5.0 "Atmosphere & Audio"

**Status:** 6/13 tasks complete (46%)  
**Timeline:** 12-15 sessions (~7-10 days)  
**Budget:** $22 actual (under target by $12)  
**Model:** Sonnet (standard implementation)

### Completed This Sprint ✅
- [x] Audio Manager Architecture (Task 1.1)
- [x] AI Sound Generation & Import - 48 files (Task 1.2)
- [x] Harvesting Sound Integration (Task 1.3)
- [x] Movement Sounds - Footsteps (Task 2.1)
- [x] Music Manager & AI Music System (Task 2.2)
- [x] Ambient Environmental Sounds (Task 2.3)

### Next Up 🎯
- [ ] Building Sounds (block_place, block_remove, build_toggle)
- [ ] UI Sounds (inventory, crafting, pickup, warnings)
- [ ] Container Sounds (chest_open, chest_close)
- [ ] Settings Menu - Audio Controls (volume sliders)
- [ ] Sound Variation System (pitch/volume randomization)
- [ ] Audio Balance Pass (test all scenarios)
- [ ] Controller Rumble (optional haptic feedback)

---

## 🐛 Known Issues

**None currently** - Sprint progressing smoothly!

**Potential Issues** (from code review - not confirmed):
- Race condition if container destroyed while UI open (needs null checks)
- Input blocking too broad in player.gd line 148

---

## 📝 Recent Changes (Last 5)

1. **[2025-12-12 20:30]** Updated file output rules - COMPLETE files mandatory
2. **[2025-12-12 18:45]** Reduced ambient volumes by ~30% for subtler atmosphere
3. **[2025-12-12 18:30]** Task 2.3 complete - Ambient system with biome-aware loops
4. **[2025-12-12 18:00]** Task 2.2 complete - Music Manager with day/night rotation
5. **[2025-12-12 09:15]** Fixed log despawn sound spam (removed audio from despawn)

---

## 🎮 Quick Commands (Testing)

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

## 🤖 Model Selection Guide

**Use Sonnet (this chat) for:**
- Standard feature implementation
- Bug fixes
- Integration work
- Polish & refinement
- Most sprint tasks

**Use Opus for:**
- Complex architecture decisions
- Multi-system refactoring
- Code reviews
- Major design decisions
- Save/load system (future)

**Current capacity:** 45-55 Sonnet sessions/week available

---

## 📊 Project Stats

**Version:** v0.5.0 (in progress)  
**Last Release:** v0.4.0 (Storage & Organization - 73% complete)  
**Commit:** d53049d  
**Code Quality:** A (Excellent) - from Opus 4.5 review

**Audio Assets:**
- 48 files total (40 SFX + 8 music)
- Generated via SFX Engine + Mubert
- All imported and tested

---

## 🔧 Technical Context

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

---

## 📚 Where to Find Things

**Need architecture info?** → Request docs/ARCHITECTURE.md  
**Need coding conventions?** → Request docs/STYLE_GUIDE.md  
**Need implementation details?** → Request docs/TECHNICAL_DETAILS.md  
**Need to see code files?** → Check FILE_INDEX.md, then request specific files

**See FILE_INDEX.md for complete file map!**

---

## 🎯 Commit Preparation - ABSOLUTE REQUIREMENTS

### When User Says "Generate Commit"

Claude MUST follow this exact process:

**Step 1: Identify Changed Files**
```
Example:
- SESSION_START.md (updated sprint progress)
- CHANGELOG.txt (added new entries)
- scripts/building/building_system.gd (added audio hooks)
```

**Step 2: Read Each File Completely**
```
Use view tool to read ENTIRE file:
- view /mnt/project/CHANGELOG.txt (all lines)
- view /mnt/user-data/uploads/building_system.gd (all lines)
```

**Step 3: Create COMPLETE Updated Versions**
```
For each file:
1. Copy ENTIRE original file
2. Make changes
3. Output COMPLETE file to /mnt/user-data/outputs/[EXACT_NAME]
4. File has ALL lines (no truncation)
```

**Step 4: Verify Before Output**
```
Checklist for EACH file:
☑️ Entire file present (line 1 to end)?
☑️ Exact filename (no _CLEAN, _NEW, etc)?
☑️ UTF-8 encoding (→ not ->, ✅ not x)?
☑️ All unchanged sections included?
☑️ No "..." or abbreviations?
```

**Step 5: Output All Files**
```
Use present_files tool with exact filenames:
- CHANGELOG.txt (not CHANGELOG_CLEAN.txt)
- SESSION_START.md (not SESSION_START_UPDATED.md)
```

### Common Mistakes to AVOID

❌ **"Here's what changed in CHANGELOG.txt:"**
→ ✅ Output complete CHANGELOG.txt (all 195 lines)

❌ **"Add these entries to line 15..."**
→ ✅ Output complete file with entries added

❌ **"Updated CHANGELOG_NEW.txt"**
→ ✅ Use exact name: CHANGELOG.txt

❌ **"[rest of file unchanged]"**
→ ✅ Include the entire rest of file

❌ **"Replace lines 50-60 with..."**
→ ✅ Output complete file with replacement

---

## 📋 UTF-8 Encoding Reference

**Always use proper UTF-8:**
```
✅ Arrows: → ← ↑ ↓ ↔️ ⇒ (never ->, =>, <-, etc)
✅ Checkmarks: ✅ ❌ ☑️ ✓ ✗ (never x, check, [x])
✅ Emojis: 🎯 📝 🚀 🎉 🔴 🟡 🟢 (when appropriate)
✅ Degrees: ° (never o, deg)
✅ Math: × ÷ ± ≈ ≠ ≤ ≥ (never x, /, +/-, ~=, !=, <=, >=)
✅ Bullets: • ○ ● (never *, -, +)
```

**Never output corrupted characters:**
```
❌ ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ (should be →)
❌ ÃƒÆ'Ã¢â‚¬â€ (should be ×)
❌ Ãƒâ€šÃ‚Â° (should be °)
```

---

## ⚙️ Important Notes

- Always commit .uid files with their parent .gd/.tscn files
- Audio Manager is AutoLoad singleton (globally accessible)
- All audio files in res://audio/ with proper folder structure
- Music crossfades over 30 seconds during day/night transitions
- Ambient sounds use occasional/rare frequency (20-60% play chance)
- Sprint follows "Core + Polish" approach (complete, polished features)

---

## 💡 Session Start Checklist

When starting a session, Claude should:
1. ✅ Read SESSION_START.md (this file)
2. ✅ Read FILE_INDEX.md (file locations)
3. ✅ Check ROADMAP.txt if planning features
4. ✅ Check CHANGELOG.txt for recent context
5. ✅ Request specific files as needed
6. ✅ Never assume access to files not in Project
7. ✅ **Remember: COMPLETE FILES ONLY when outputting**

---

**Ready to work! Ask me anything or assign a task from the Next Up list.**

**REMINDER: When creating/updating files, Claude outputs COMPLETE files with EXACT names. No partials. No suffixes. Every time.**
