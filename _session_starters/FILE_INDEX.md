# Crimson Veil - Complete File Index

## 🚨 CRITICAL: COMPLETE FILES ONLY - READ THIS FIRST

### MANDATORY: Every File Output Must Be COMPLETE

**When creating or updating ANY file, Claude MUST:**

1. ✅ **Output ENTIRE file** from line 1 to last line
2. ✅ **Include EVERY line** - changed AND unchanged sections
3. ✅ **Use EXACT filename** from this index (no _CLEAN, _NEW, _UPDATED)
4. ✅ **No truncation** - no "...", no "[rest unchanged]", no abbreviations
5. ✅ **UTF-8 encoding** - proper arrows (→), checkmarks (✅), emojis (🎯)

### What COMPLETE Means

**If CHANGELOG.txt is 195 lines:**
- ✅ Output all 195 lines
- ❌ "Add these 3 lines to line 15..."
- ❌ "Here's lines 1-20, rest unchanged..."

**If player.gd is 500 lines and line 50 changes:**
- ✅ Output all 500 lines with change
- ❌ "Replace line 50 with this code..."
- ❌ "Insert this after _physics_process..."

### The Two Valid Responses

**Option 1: Complete File**
```
Create complete file in /mnt/user-data/outputs/[EXACT_NAME]
Include every single line from original + changes
Use present_files tool to share
```

**Option 2: Request Upload**
```
"I need to see:
- scripts/player/player.gd
Please upload this file."
```

**There is NO Option 3.** Partial updates do not exist.

### Verification Checklist (Every File)

Before outputting any file, verify:
- [ ] File has line 1? (not starting mid-file)
- [ ] File has last line? (not ending early)
- [ ] All unchanged sections included? (not just changes)
- [ ] Exact filename? (no suffixes)
- [ ] UTF-8 encoding? (→ not ->, ✅ not x)

If ANY checkbox fails → Read original completely, create complete version.

---

## ⚠️ How Files Work in This Project

**Claude can ONLY see these 4 files automatically:**
- SESSION_START.md (this session's context)
- ROADMAP.txt (feature planning)
- CHANGELOG.txt (change history)
- FILE_INDEX.md (this file)

**Everything else exists in your Git repo but Claude CANNOT see it unless you upload it.**

When Claude needs a file, Claude will say:
```
I need to see:
- scripts/player/player.gd
- scripts/audio/audio_manager.gd

Please upload these files.
```

Then you upload those specific files to the chat.

---

## 📋 Exact Filenames (Use These EXACTLY)

### Project Root Files
```
✅ CHANGELOG.txt          ❌ CHANGELOG_CLEAN.txt
✅ SESSION_START.md       ❌ SESSION_START_NEW.md
✅ ROADMAP.txt            ❌ ROADMAP_UPDATED.txt
✅ FILE_INDEX.md          ❌ FILE_INDEX_V2.md
```

### Documentation Files
```
✅ docs/DEVELOPMENT_GUIDE.md    ❌ docs/DEVELOPMENT_GUIDE_NEW.md
✅ docs/ARCHITECTURE.md         ❌ docs/ARCHITECTURE_UPDATED.md
✅ docs/STYLE_GUIDE.md          ❌ docs/STYLE_GUIDE_V2.md
```

### Code Files
```
✅ scripts/player/player.gd           ❌ scripts/player/player_fixed.gd
✅ scripts/audio/audio_manager.gd    ❌ scripts/audio/audio_manager_v2.gd
✅ scripts/building/building_system.gd ❌ scripts/building/building_system_new.gd
```

**The ONLY acceptable file extensions:**
- `.md` for Markdown
- `.txt` for plain text  
- `.gd` for GDScript
- `.tscn` for Godot scenes
- `.tres` for Godot resources

---

## 🎯 UTF-8 Encoding Standard

### Characters to USE (proper UTF-8)

**Arrows:**
```
→ ← ↑ ↓ ↔️ ⇒ ⇐ ⇔ ➡️ ⬅️ ⬆️ ⬇️
Never: -> <- => <= <->
```

**Checkmarks:**
```
✅ ❌ ☑️ ✓ ✗
Never: [x] [ ] x check
```

**Emojis (when appropriate):**
```
🎯 📝 🚀 🎉 🔴 🟡 🟢 ⚠️ 🚨 ⭐ 💯
🎮 🎵 🔊 🔇 📊 📈 📉 🏆 ✨
```

**Math/Logic:**
```
× ÷ ± ≈ ≠ ≤ ≥ ∞ √ ∑ ∏
Never: x / +/- ~= != <= >=
```

**Typography:**
```
° § ¶ † ‡ • ○ ● ◆ ◇ ★ ☆
Never: deg, o, *, -
```

### Characters to AVOID (corrupted)

**Never output these corrupted sequences:**
```
❌ ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ (should be →)
❌ ÃƒÆ'Ã¢â‚¬â€ (should be ×)
❌ Ãƒâ€šÃ‚Â° (should be °)
❌ ÃƒÂ¢Ã…â€œÃ¢â‚¬Å" (checkmark corruption)
```

**If you see corrupted characters:**
1. Stop immediately
2. Read original file
3. Regenerate with proper UTF-8
4. Verify characters display correctly

---

## 📁 Documentation Files (in Git Repo)

### Root Documentation
| File | Lines | Purpose |
|------|-------|---------|
| docs/DEVELOPMENT_GUIDE.md | 1611 | Complete development guide, architecture patterns |
| docs/ARCHITECTURE.md | 300 | System design, signals, AutoLoads |
| docs/STYLE_GUIDE.md | 250 | Naming conventions, code patterns |
| docs/TECHNICAL_DETAILS.md | 600 | History, optimization strategies |
| docs/AI_USAGE_ANALYSIS.md | 400 | Token usage, capacity planning |
| docs/CODE_REVIEW.md | 500 | Code quality analysis |

### System Documentation
| File | Purpose |
|------|---------|
| docs/AUDIO_MANAGER_README.md | Audio system reference |
| docs/MUSIC_MANAGER_README.md | Music system reference |
| docs/AMBIENT_MANAGER_README.md | Ambient audio reference |

### Implementation Guides (Future)
- docs/implementation/V0.5.0_AUDIO_IMPLEMENTATION_GUIDE.md
- docs/implementation/V0.6.0_BUILDING_IMPLEMENTATION_GUIDE.md
- etc.

---

## 🎮 Code Files (in Git Repo)

### Core Systems

#### Root Level
```
res://
├── world.gd                     [Scene root, system initialization]
├── audio_manager.gd              [AutoLoad: sound pooling, volume, music/ambient]
├── audio_manager_test.gd         [Audio system test suite]
├── audio_manager_test.tscn       [Test scene]
├── chunk_manager.gd              [Terrain generation, chunk loading]
├── chunk.gd                      [Individual chunk meshes, biomes]
└── project.godot                 [Godot project config]
```

**When to request:**
- System initialization issues → world.gd
- Audio system work → audio_manager.gd
- Audio testing → audio_manager_test.gd
- Terrain generation → chunk_manager.gd, chunk.gd
- Input mappings → project.godot

---

### Player System
```
scripts/player/
├── player.gd                    [Input, movement, camera, controller support, UI state]
├── player.tscn                  [Player scene with health, camera, collision]
└── states/
    ├── player_state.gd          [Base state class]
    ├── idle_state.gd            [Idle behavior]
    ├── walking_state.gd         [Movement behavior]
    └── harvesting_state.gd      [Resource gathering]
```

**When to request:**
- Movement issues → player.gd
- Camera problems → player.gd
- Controller support → player.gd
- State machine bugs → states/*.gd

---

### Inventory & Crafting
```
scripts/inventory/
├── inventory.gd                 [Item storage, stacking (max 99)]
├── inventory_ui.gd              [Hotbar, dragging, highlighting]
├── item_data.gd                 [Item definitions, properties]
└── crafting/
    ├── crafting_system.gd       [Recipe validation, resource consumption]
    ├── crafting_ui.gd           [Recipe display, crafting UI]
    ├── recipe.gd                [Recipe data structure]
    └── recipe_database.gd       [All game recipes]
```

**When to request:**
- Inventory bugs → inventory.gd
- UI issues → inventory_ui.gd
- New items → item_data.gd
- Crafting changes → crafting_system.gd
- New recipes → recipe_database.gd

---

### Building System
```
scripts/building/
├── building_system.gd           [Placement, rotation, validation]
├── building_ui.gd               [Preview, cancel, keyboard hints]
├── block_data.gd                [Block types, properties]
├── built_block.gd               [Placed block instances]
└── storage/
    └── storage_container.gd     [Chest functionality, inventory]
```

**When to request:**
- Placement issues → building_system.gd
- Preview problems → building_ui.gd
- New blocks → block_data.gd
- Chest functionality → storage_container.gd

---

### Harvestable Resources
```
scripts/resources/
├── harvestable_resource.gd      [Base class: health, drops, tools, respawn]
├── vegetation_spawner.gd        [Spawn logic, density, noise-based placement]
└── vegetation/
    ├── resources/
    │   ├── tree.gd              [Tree behavior, multiple hits]
    │   ├── bush.gd              [Bush behavior, single hit]
    │   ├── rock.gd              [Rock behavior, multiple hits]
    │   ├── mushroom.gd          [Mushroom behavior]
    │   └── strawberry.gd        [Strawberry behavior]
    └── visuals/
        ├── tree_visual.gd       [Oak tree mesh generation]
        ├── pine_visual.gd       [Pine tree mesh generation]
        ├── birch_visual.gd      [Birch tree mesh generation]
        └── palm_visual.gd       [Palm tree mesh generation]
```

**When to request:**
- Resource behavior → resources/tree.gd, bush.gd, etc.
- Visual changes → visuals/*_visual.gd
- Spawning logic → vegetation_spawner.gd
- New resource types → harvestable_resource.gd (as template)

---

### UI Systems
```
scripts/ui/
├── game_ui.gd                   [Main UI coordinator]
├── hotbar.gd                    [Hotbar display, slot selection]
├── tooltip.gd                   [Item info display]
├── pause_menu.gd                [Pause, resume, settings, quit]
├── settings_menu.gd             [Audio, graphics, controls]
└── hud/
    ├── health_bar.gd            [Health display]
    ├── hunger_bar.gd            [Hunger display]
    └── stamina_bar.gd           [Stamina display]
```

**When to request:**
- UI coordination → game_ui.gd
- Hotbar issues → hotbar.gd
- Settings changes → settings_menu.gd
- HUD elements → hud/*.gd

---

### Audio Systems
```
scripts/audio/
├── audio_manager.gd             [AutoLoad: sound pooling, volume, pitch variation]
├── music_manager.gd             [AutoLoad: day/night rotation, crossfades]
└── ambient_manager.gd           [AutoLoad: biome-aware loops, frequency control]
```

**When to request:**
- Sound effects → audio_manager.gd
- Music system → music_manager.gd
- Ambient sounds → ambient_manager.gd

---

### Combat (Future - v0.9.0)
```
scripts/combat/
├── combat_system.gd             [Damage calculation, hit detection]
├── enemy.gd                     [Enemy base class]
├── enemy_ai.gd                  [AI behavior]
└── projectile.gd                [Arrow, spell projectiles]
```

**Status:** Not yet implemented - planned for v0.9.0

---

### World & Environment
```
scripts/world/
├── day_night_cycle.gd           [Time progression, lighting]
├── weather_system.gd            [Rain, fog, weather effects]
└── biome_manager.gd             [Biome definitions, transitions]
```

**When to request:**
- Day/night issues → day_night_cycle.gd
- Weather bugs → weather_system.gd
- Biome work → biome_manager.gd

---

### Core Utilities
```
scripts/core/
├── autoloads/
│   ├── game_manager.gd          [AutoLoad: game state, save/load]
│   └── input_manager.gd         [AutoLoad: input remapping]
├── mesh_builder.gd              [Procedural mesh utilities]
└── noise_generator.gd           [Simplex/Perlin noise]
```

**When to request:**
- Save/load → game_manager.gd
- Input remapping → input_manager.gd
- Mesh generation → mesh_builder.gd
- Noise algorithms → noise_generator.gd

---

## 🎵 Audio Assets

### Audio Directory Structure
```
res://audio/
├── sfx/
│   ├── harvesting/              [6 files: axe, pickaxe, mushroom, strawberry, resource_break, wrong_tool]
│   ├── movement/                [12 files: footsteps - grass/stone/sand/snow variants 1-3]
│   ├── building/                [3 files: block_place, block_remove, build_toggle]
│   ├── ui/                      [8 files: inventory, crafting, stack_full, tool_switch, warnings]
│   └── container/               [2 files: chest_open, chest_close]
├── music/                       [Day/night ambient tracks]
└── ambient/                     [Wind, ocean, crickets, birds, frogs, leaves, thunder]
```

**Total:** 48 audio files imported (Task 1.2 complete)

**Note:** Audio files don't need to be uploaded - they're referenced by path in audio_manager.gd

---

## 📦 Asset Files

### Models & Textures
```
res://models/                    [3D models - trees, rocks, items]
res://textures/                  [Block textures, UI textures]
res://sprites/                   [2D UI sprites, icons]
```

**Note:** Asset files rarely need to be uploaded unless debugging visual issues

---

## 🎯 Common Upload Patterns

### Bug Fixes
```
Upload:
1. [file_with_bug].gd            [Only the buggy file]
2. DEVELOPMENT_GUIDE.md          [For context if needed]
```

### New Features
```
Upload:
1. DEVELOPMENT_GUIDE.md          [For architecture patterns]
2. [related_file].gd             [Similar system as reference]
3. [new_file_location]           [Where to create new code]
```

### System Modifications
```
Upload:
1. DEVELOPMENT_GUIDE.md          [For system overview]
2. [system_file].gd              [The system to modify]
3. [dependent_files].gd          [Files that call this system]
```

### UI/UX Changes
```
Upload:
1. [specific_ui_file].gd         [Only what you're changing]
2. game_ui.gd                    [If changing UI coordination]
```

---

## 🚨 Commit Process - Step by Step

### When User Says "Generate Commit"

**Step 1: Identify all changed files**
```
Example output:
Files modified this session:
1. SESSION_START.md (updated sprint progress)
2. CHANGELOG.txt (added 3 new entries)
3. scripts/building/building_system.gd (added audio hooks)
```

**Step 2: Read each file COMPLETELY**
```
Use view tool:
- view /mnt/project/CHANGELOG.txt
  → Read all 195 lines
- view /mnt/user-data/uploads/building_system.gd
  → Read all 350 lines
```

**Step 3: Create COMPLETE updated versions**
```
For each file:
1. Copy ENTIRE original (all lines)
2. Make changes
3. Output COMPLETE file to /mnt/user-data/outputs/[EXACT_NAME]
4. Verify: All lines present? Exact filename? UTF-8 encoding?
```

**Step 4: Output all files**
```
Use present_files tool:
present_files([
  "/mnt/user-data/outputs/SESSION_START.md",      # Complete file
  "/mnt/user-data/outputs/CHANGELOG.txt",         # Complete file
  "/mnt/user-data/outputs/building_system.gd"     # Complete file
])
```

**Step 5: Create commit message**
```
Output COMMIT_MESSAGE.txt with:
- List of changed files (EXACT names)
- What changed in each
- Why it changed
```

---

## ⚠️ Special Files

### Godot .uid Files
- Every .gd and .tscn file has a .uid file (e.g., audio_manager.gd.uid)
- These are Godot's unique asset identifiers
- **ALWAYS commit .uid files with their parent files**
- Missing .uid files can corrupt the Godot project

### Scene Files (.tscn)
- Scene configuration files
- Usually don't need to be uploaded unless debugging scene structure
- Most gameplay code is in .gd files, not .tscn files

---

## 📊 File Request Guidelines

**For simple questions:**
- No files needed - just answer from knowledge

**For bug fixes:**
- Upload the specific buggy file only

**For new features:**
- Upload DEVELOPMENT_GUIDE.md first
- Then upload relevant reference files

**For architecture questions:**
- Upload docs/ARCHITECTURE.md

**For coding style questions:**
- Upload docs/STYLE_GUIDE.md

**For sprint planning:**
- Upload ROADMAP.txt + AI_USAGE_ANALYSIS.md

---

## 🚫 Files Claude Will NEVER Request

These exist but are handled by Godot/Git:
- .import files (Godot's import cache)
- .godot/ folder (Godot metadata)
- .git/ folder (Git history)
- .gitignore, .gitattributes
- .DS_Store, Thumbs.db

---

## ✅ Quick Reference: What to Upload

**"Fix player movement bug"**
→ Upload: player.gd

**"Add new crafting recipe"**
→ Upload: DEVELOPMENT_GUIDE.md, recipe_database.gd

**"Implement new enemy type"**
→ Upload: DEVELOPMENT_GUIDE.md, enemy.gd (as template)

**"Change audio volume controls"**
→ Upload: audio_manager.gd, settings_menu.gd

**"Optimize chunk loading"**
→ Upload: DEVELOPMENT_GUIDE.md, chunk_manager.gd, chunk.gd

**"Design new UI element"**
→ Upload: game_ui.gd, inventory_ui.gd (as reference)

---

## 🎓 Remember - The Golden Rules

1. **Claude only sees 4 files automatically:** SESSION_START.md, FILE_INDEX.md, ROADMAP.txt, CHANGELOG.txt
2. **Everything else must be uploaded** when Claude requests it
3. **Upload specific files, not entire folders**
4. **When outputting files: COMPLETE files ONLY, EXACT names ONLY**
5. **UTF-8 encoding always** (→ not ->, ✅ not x, 🎯 not :target:)
6. **No partial updates ever** - complete files or nothing
7. **No temporary suffixes ever** - exact names from this index

**This system keeps token usage low while ensuring complete, correct file delivery every time.**
