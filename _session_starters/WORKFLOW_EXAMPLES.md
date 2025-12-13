# Workflow Examples - Crimson Veil

Real-world session patterns with ultra-minimal docs

---

## Session 1: Simple Bug Fix

**Upload:**
- player.gd

**You say:**
"The player can walk through chests. Fix it."

**I do:**
- Ask for building_system.gd and storage_container.gd
- Identify collision layer mismatch
- Describe the fix: "Add Layer 1 to chest collision_layer"
- You implement in your editor
- Done in 2 minutes

**No docs needed** - Simple fix, no sprint context required

---

## Session 2: Implement Next Sprint Task

**Upload:**
- SESSION_START.md
- ROADMAP.txt

**You say:**
"Let's do Task 3.1 - UI sounds"

**I do:**
1. Read SESSION_START → See we're on v0.5.0, 9/13 complete
2. Read ROADMAP → See Task 3.1 is "UI Sounds (inventory, crafting, pickup, warnings)"
3. Ask for: audio_manager.gd, inventory_ui.gd, crafting_system.gd
4. Implement sound calls in each system
5. Describe changes: "Add AudioManager.play_ui_sound() calls in 4 locations"
6. You implement
7. Test works

**You say:**
"Generate a commit"

**I output:**
- COMMIT_MESSAGE.txt
- SESSION_START.md (updated: 10/13 complete, 77%)
- ROADMAP.txt (Task 3.1 marked [X])

**You do:**
```bash
git add .
git commit -F COMMIT_MESSAGE.txt
git push
```

Done in 15 minutes

---

## Session 3: Multi-File Feature

**Upload:**
- SESSION_START.md
- ROADMAP.txt

**You say:**
"Add sound variation system - pitch and volume randomization"

**I do:**
1. Check ROADMAP → Task 3.3
2. Ask for audio_manager.gd
3. Add randomization parameters to play_sound() method
4. Show you the updated function signature
5. Explain: "Now all sounds get ±10% pitch, ±5% volume variation"

**You say:**
"Show me the file"

**I output:**
- Complete audio_manager.gd with changes

**You:**
- Copy/paste into your editor, or
- Apply the changes manually

**You say:**
"Generate a commit"

**I output:**
- Commit files as usual

Done in 10 minutes

---

## Session 4: New System Architecture

**Upload:**
- SESSION_START.md
- ROADMAP.txt
- docs/ARCHITECTURE.md (for signal patterns)

**You say:**
"I want to start save/load system. What's the architecture?"

**I do:**
1. Review ROADMAP → "Save/load (HIGH PRIORITY - complex)"
2. Review ARCHITECTURE → See existing AutoLoad pattern
3. Propose architecture:
   - SaveManager AutoLoad
   - JSON serialization approach
   - What data needs saving (world, player, inventory, containers)
   - Signal integration with existing systems

**You say:**
"Looks good. Create the SaveManager skeleton."

**I output:**
- Complete save_manager.gd with method stubs
- Updated project.godot with AutoLoad

**You say:**
"Not ready to commit yet, I want to implement a few methods first"

**You work on it yourself for a few sessions**

Done in 20 minutes (planning session, no commit)

---

## Session 5: Code Review Request

**Upload:**
- SESSION_START.md
- crafting_system.gd

**You say:**
"Review this file. Is there tech debt?"

**I do:**
1. Scan for common issues (duplicated code, magic numbers, performance)
2. Check against ROADMAP tech debt list
3. Provide 3-5 specific improvements with line numbers
4. Explain impact (readability, performance, maintainability)

**You say:**
"Fix issue #2"

**I do:**
- Describe the refactor
- You implement

**No commit** - Just cleanup work

Done in 10 minutes

---

## Session 6: Emergency Bug During Playtest

**Upload:**
- player.gd
- inventory.gd

**You say:**
"Inventory crashes when I pick up 100th item"

**I do:**
1. Check inventory.gd for bounds checking
2. Find the bug: No check for full inventory
3. Describe fix: "Add `if slots.size() >= 32: return` before adding item"

**You:**
- Fix immediately
- Test
- Works

**You say:**
"Generate a commit"

**I do:**
- Create commit with type: "fix(inventory): Prevent crash on full inventory"
- Update SESSION_START.md "Last 5 Changes"
- Don't update ROADMAP (not a sprint task)

Done in 5 minutes

---

## Session 7: Just Generate Commit

**Upload:**
- SESSION_START.md

**You say:**
"I finished UI sounds myself. Generate a commit for Task 3.1"

**I do:**
1. Read SESSION_START → See recent work
2. Create COMMIT_MESSAGE.txt:
   ```
   feat(audio): Add UI sounds system
   
   Changed files:
   - scripts/audio/audio_manager.gd (added ui_sounds category)
   - scripts/ui/inventory_ui.gd (play inventory_toggle sound)
   - scripts/ui/crafting_ui.gd (play craft_complete sound)
   
   Implements Task 3.1 from v0.5.0 sprint
   ```
3. Update SESSION_START.md (10/13 complete)
4. Update ROADMAP.txt ([X] 3.1)

**You:**
```bash
git commit -F COMMIT_MESSAGE.txt
git push
```

Done in 2 minutes

---

## Session 8: Planning Next Sprint

**Upload:**
- SESSION_START.md
- ROADMAP.txt
- docs/ARCHITECTURE.md

**You say:**
"v0.5.0 is done. Help me plan v0.6.0 sprint."

**I do:**
1. Review ROADMAP backlog
2. Suggest 3-4 task groupings that make sense together
3. Estimate complexity (simple/medium/complex)
4. Recommend Sonnet vs Opus for each

**You:**
- Make decisions
- Update ROADMAP.txt yourself
- Update SESSION_START.md sprint header yourself

**No commit** - Planning only

Done in 15 minutes

---

## Session 9: Refactoring Session

**Upload:**
- SESSION_START.md
- ROADMAP.txt
- critter_spawner.gd (1,143 lines)

**You say:**
"Extract critter visuals like we did with trees"

**I do:**
1. Check ROADMAP tech debt → See this is listed
2. Ask for tree_visual.gd (as reference pattern)
3. Create rabbit_visual.gd, crab_visual.gd, etc.
4. Show you the extraction pattern
5. Update critter_spawner.gd to use new files

**I output:**
- rabbit_visual.gd (complete)
- crab_visual.gd (complete)
- Updated critter_spawner.gd (describe changes)

**You say:**
"Generate a commit"

**I do:**
- Commit with type: "refactor(critters): Extract visual classes"
- Mark tech debt item complete in ROADMAP
- Update SESSION_START.md

Done in 25 minutes

---

## Session 10: Quick Question

**Upload:**
- Nothing

**You say:**
"What's the signal name for when inventory changes?"

**I answer:**
"I need to see your code. Upload inventory.gd"

**You upload:**
- inventory.gd

**I answer:**
"It's `inventory_changed` - emitted on line 47 after add_item()"

Done in 1 minute

---

## Key Patterns

**Minimal uploads:**
- Small fix? Just the buggy file
- Sprint work? SESSION_START + ROADMAP + code files
- Architecture? Add docs/ARCHITECTURE.md
- Planning? SESSION_START + ROADMAP

**My behavior:**
- I ask for files I need
- I describe changes (you implement)
- I output complete files only when you ask
- I always output complete .tscn, project.godot, .md, .txt

**Your workflow:**
- Upload → Tell me what to do → Implement → "Generate a commit" → Git push
- Or: Upload → Tell me what to do → "Show me the file" → Copy/paste → Git push

**Session lengths:**
- Bug fix: 2-5 minutes
- Feature task: 10-20 minutes
- Architecture/refactor: 20-30 minutes
- Planning: 10-15 minutes
- Commit only: 2 minutes

---

**That's the workflow. Simple, fast, Git-native.**
