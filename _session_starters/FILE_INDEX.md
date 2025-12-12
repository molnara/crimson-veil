# Crimson Veil - File Index

**Quick reference for file locations**

---

## 📋 Documentation Files

| File | Purpose |
|------|---------|
| SESSION_START.md | Session context (use this most) |
| QUICK_START.md | Ultra-minimal context |
| COMMIT_GUIDE.md | How commits work |
| FILE_INDEX.md | This file |
| ROADMAP.txt | Feature planning & sprint tracking |
| CHANGELOG.txt | Change history (optional) |

---

## 📁 Core Documentation (in /docs/)

| File | Lines | Purpose |
|------|-------|---------|
| DEVELOPMENT_GUIDE.md | 1611 | Complete architecture reference |
| ARCHITECTURE.md | 300 | System design, signals, AutoLoads |
| STYLE_GUIDE.md | 250 | Naming conventions, code patterns |
| TECHNICAL_DETAILS.md | 600 | History, optimization strategies |
| CODE_REVIEW.md | 500 | Code quality analysis |

---

## 🎮 Code Files (Root Directory)

**Note:** Most files currently in root, will reorganize later

### Core Systems
```
world.gd                   [Scene root, initialization]
chunk_manager.gd           [Terrain generation]
chunk.gd                   [Individual chunks, biomes]
player.gd                  [Player input, movement, camera]
inventory.gd               [Item storage, stacking]
crafting_system.gd         [Recipe validation]
building_system.gd         [Block placement, rotation]
harvesting_system.gd       [Resource gathering]
```

### Audio Systems (Current Focus)
```
audio_manager.gd           [AutoLoad: sound pooling, volume]
music_manager.gd           [AutoLoad: day/night rotation]
ambient_manager.gd         [AutoLoad: biome-aware loops]
audio_manager_test.gd      [Test suite]
```

### Storage
```
storage_container.gd       [Chest functionality]
container_ui.gd            [Chest UI interface]
```

---

## 🎵 Audio Assets

**Directory:** res://audio/

```
sfx/
├── harvesting/       [6 files: axe, pickaxe, mushroom, etc]
├── movement/         [12 files: footsteps on 4 surfaces]
├── building/         [3 files: place, remove, toggle]
├── ui/               [9 files: inventory, crafting, warnings]
└── container/        [2 files: chest_open, chest_close]

music/                [8 tracks: 4 day + 4 night ambient]
ambient/              [8 files: wind, ocean, crickets, etc]
```

**Total:** 48 audio files

---

## 📦 When to Upload What

### Quick Bug Fix
```
Upload: [buggy_file.gd]
```

### Feature Implementation
```
Upload: SESSION_START.md + [feature_file.gd]
```

### Architecture Planning
```
Upload: SESSION_START.md + ROADMAP.txt + docs/ARCHITECTURE.md
```

### Commit Preparation
```
Upload: SESSION_START.md
Say: "Generate a commit"
```

---

## 🎯 File Request Examples

**"I need to add UI sounds"**
→ I'll ask for: audio_manager.gd, inventory_ui.gd

**"Fix player movement bug"**
→ I'll ask for: player.gd

**"Add new crafting recipe"**
→ I'll ask for: crafting_system.gd, recipe_database.gd

**"Optimize chunk loading"**
→ I'll ask for: chunk_manager.gd, chunk.gd

---

## 🚫 Files I Won't Request

These are handled by Godot/Git:
- .import files
- .godot/ folder
- .git/ folder
- .gitignore, .gitattributes
- .uid files (you commit with parent)

---

## 📝 UTF-8 Reference

**Use these:**
```
→ ← ↑ ↓        (arrows)
✅ ❌ ☑️        (checkmarks)
🎯 📝 🚀 🎉    (emojis)
× ÷ ± ≈        (math)
• ○ ●          (bullets)
```

**Not these:**
```
-> <- => <=    (plain ASCII arrows)
[x] [ ]        (plain checkmarks)
:target:       (emoji codes)
x / +/-        (plain math)
* - +          (plain bullets)
```

---

**That's it! Simple reference, no walls of rules.**
