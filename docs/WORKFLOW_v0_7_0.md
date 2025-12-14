# CRIMSON VEIL - CLAUDE PROJECTS WORKFLOW
## Development Strategy for v0.7.0 "Performance"

---

## PROJECT SETUP

### Claude Project Configuration

**Project Name:** Crimson Veil

**Project Knowledge Base (Upload These Files):**
1. `ROADMAP_v0_7_0.txt` - Sprint overview and task breakdown
2. `IMPLEMENTATION_GUIDE_v0_7_0.txt` - Technical implementation details
3. `project.godot` - Project settings and configurations
4. Key existing scripts:
   - `player.gd`
   - `chunk.gd`
   - `chunk_manager.gd`
   - `vegetation_spawner.gd` (PRIMARY TARGET)
   - `pixel_texture_generator.gd`
   - `critter_spawner.gd`
   - `settings_menu.gd`
   - `audio_manager.gd`
   - Files from v0.6.0:
     - `combat_system.gd` (CREATED - v0.6.0)
     - `enemy.gd` (CREATED - v0.6.0)
     - `death_screen.gd` (CREATED - v0.6.0)
     - `first_person_weapon.gd` (CREATED - v0.6.0)
     - `tool_system.gd` (CREATED - v0.6.0)

**Custom Instructions for Project:**
```
You(Claude) are assisting the Game Director(Xzarian) with development of Crimson Veil, a first-person survival game built in Godot 4.5.1. The project uses:
- GDScript for all game logic
- CSG primitives for 3D geometry
- AI-generated assets (audio via ElevenLabs, textures via Leonardo.ai)
- Dual input support (M+KB and Xbox controller)

** VERY IMPORTANT: Project file structure res://, res://music, res://sfx **

Current sprint: v0.7.0 "Performance" - Optimization and performance improvements
Total tasks: 12 (grouped into 4 phases over ~41 hours)

PERFORMANCE TARGETS:
- 60 FPS minimum (currently 25)
- <500 draw calls (currently 17,141)
- <2,000 objects drawn (currently 17,220)
- <10,000 nodes (currently 61,439)

CRITICAL RULES (MUST FOLLOW):
1. NEVER recreate existing code files from scratch
2. ALWAYS request files to be uploaded from GitHub before modifying them
3. Start each session by identifying which files are needed and requesting upload
4. Ask to "proceed" before implementing any code or making changes
5. Do NOT generate instructions, documentation, diagrams, or supplementary materials unless explicitly requested
6. When user says "generate commit", output a brief git commit message summarizing the changes
7. ALWAYS test performance impact after each change
8. Measure before AND after each optimization

Always:
1. Focus on production code only
2. Check ROADMAP and IMPLEMENTATION_GUIDE before suggesting implementations
3. Follow established code patterns from existing scripts
4. Respect locked design decisions
5. Maintain visual quality at High/Ultra settings
6. Use MultiMesh for instanced objects (grass, small rocks)
7. Implement proper cleanup when chunks unload
8. Cache materials instead of recreating them
```

---

## FILE MANAGEMENT WORKFLOW

### Critical Rule: Never Recreate From Scratch

**All existing code files are stored in GitHub. Claude must NEVER attempt to recreate them from scratch.**

### Session Start Protocol:

**Step 1: Identify Required Files**
At the start of each session, Claude should identify:
- Which existing files need to be modified
- Which new files need to be created

**Step 2: Request File Upload**
Claude should output:
```
Before we begin, please upload these existing files from GitHub:

REQUIRED FOR MODIFICATION:
- res://vegetation_spawner.gd
- res://chunk_manager.gd

NEW FILES TO CREATE:
- res://material_cache.gd

Please upload the existing files so I can modify them properly.
```

**Step 3: Wait for Upload**
- Do not proceed until files are uploaded
- Do not attempt to "remember" or recreate file contents
- User will upload files via Claude's interface

**Step 4: Verify Files**
Once uploaded, Claude should:
- Confirm files are received
- Review current implementation
- Identify integration points

### Example Session Flow:

**User:** "Let's start Task 1.1 - Reduce Vegetation Density"

**Claude:** 
```
Starting Task 1.1 - Reduce Vegetation Density.

Before we begin, please upload this file from GitHub:
- res://vegetation_spawner.gd (need to modify @export density values)

This is a quick configuration change - I'll be modifying the @export variables.

Please upload the file.
```

**User:** [uploads file]

**Claude:**
```
File received. I can see vegetation_spawner.gd has these current values:
- ground_cover_samples_per_chunk = 75
- grass_density = 0.75
- spawn_radius = 3

IMPLEMENTATION PLAN:
1. Reduce ground_cover_samples_per_chunk: 75 → 25
2. Reduce grass_density: 0.75 → 0.35
3. Reduce spawn_radius: 3 → 2
4. Reduce large_vegetation_samples_per_chunk: 18 → 10

Expected impact: ~70% reduction in vegetation objects

Shall I proceed?
```

**User:** "Yes, proceed"

**Claude:** [provides code modifications]

---

## SESSION WORKFLOW STRUCTURE

### Phase-Based Development Approach

Each session should focus on **one complete task** from the roadmap to maintain momentum and allow for testing between sessions.

### Session Template

```
SESSION [X]: Task [Y.Z] - [Task Name]
═══════════════════════════════════════════════════

CONTEXT:
- Previous session completed: [Task ID]
- Current task: [Task ID] - [Task Name]
- Estimated time: [X hours]
- Dependencies: [List any required prior tasks]

OBJECTIVES:
1. [Primary objective]
2. [Secondary objective]
3. [Testing objective]

FILES TO MODIFY/CREATE:
- Create: [List new files]
- Modify: [List existing files]

PERFORMANCE TARGETS:
- Before: [Expected metrics]
- After: [Target metrics]

TESTING CRITERIA:
[ ] Performance metrics improved
[ ] No visual regression
[ ] No gameplay bugs introduced

OUTPUT NEEDED:
- Complete implementation files
- Performance comparison (before/after)
- Testing instructions

WORKFLOW:
1. Identify which existing files need to be modified
2. Request file upload: "Please upload these files from GitHub: [list]"
3. Wait for files to be uploaded
4. Record baseline performance metrics
5. Present implementation plan
6. Wait for "proceed" confirmation
7. Provide complete code implementations
8. Provide testing instructions
9. Record new performance metrics
```

---

## DETAILED SESSION BREAKDOWN

### ⏳ PHASE 1: QUICK WINS & CLEANUP - CURRENT PHASE

**Phase Goal:** Immediate performance gains with minimal code changes (~8 hours)

**Expected Improvement:**
- FPS: 25 → 35-40
- Draw Calls: 17,141 → ~8,000

---

#### **SESSION 1: Task 1.1 - Reduce Vegetation Density** 🎯 NEXT

**Prompt Template:**
```
Let's start Task 1.1 - Reduce Vegetation Density

This is a quick configuration change to immediately reduce object count.

CHANGES NEEDED:
- ground_cover_samples_per_chunk: 75 → 25
- grass_density: 0.75 → 0.35  
- spawn_radius: 3 → 2
- large_vegetation_samples_per_chunk: 18 → 10

Please upload:
- res://vegetation_spawner.gd

I'll modify the @export variables and we should see immediate improvement.
```

**Files:**
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Load game and check FPS in forest biome
- [ ] Verify vegetation still looks acceptable
- [ ] Record new metrics

**Estimated Time:** 2 hours

---

#### **SESSION 2: Task 1.2 - Vegetation Despawn System**

**Prompt Template:**
```
Let's start Task 1.2 - Vegetation Despawn System

Currently vegetation spawns but never despawns when chunks unload, causing memory/node accumulation.

CHANGES NEEDED:
1. Add chunk_unloading signal to ChunkManager
2. Connect VegetationSpawner to signal
3. Track vegetation nodes per chunk
4. Clean up nodes when chunk unloads

Please upload:
- res://chunk_manager.gd
- res://vegetation_spawner.gd

Reference IMPLEMENTATION_GUIDE section 2 for code patterns.
```

**Files:**
- Modify: `chunk_manager.gd`, `vegetation_spawner.gd`

**Testing:**
- [ ] Walk around for 5 minutes
- [ ] Check node count stays stable
- [ ] No memory growth over time

**Estimated Time:** 3 hours

---

#### **SESSION 3: Task 1.3 - Material Caching System**

**Prompt Template:**
```
Let's start Task 1.3 - Material Caching System

Currently get_biome_terrain_material() creates new material every call, wasting VRAM.

CHANGES NEEDED:
1. Create MaterialCache singleton class
2. Cache biome materials (7 types)
3. Cache vegetation materials (bark, leaves, grass)
4. Update chunk.gd to use cache
5. Update vegetation_spawner.gd to use cache

Please upload:
- res://chunk.gd
- res://pixel_texture_generator.gd

I'll create the new material_cache.gd file.
Reference IMPLEMENTATION_GUIDE section 2 for implementation details.
```

**Files:**
- Create: `material_cache.gd`
- Modify: `chunk.gd`, `pixel_texture_generator.gd`

**Testing:**
- [ ] Verify materials render correctly
- [ ] Check VRAM usage reduced
- [ ] No visual differences

**Estimated Time:** 3 hours

---

### ⏳ PHASE 2: MULTIMESH IMPLEMENTATION - UPCOMING

**Phase Goal:** Dramatic draw call reduction via instancing (~14 hours)

**Expected Improvement:**
- Draw Calls: ~8,000 → ~1,000-2,000
- FPS: 35-40 → 50-55

---

#### **SESSION 4: Task 2.1 - MultiMesh Grass System**

**Prompt Template:**
```
Let's start Task 2.1 - MultiMesh Grass System

This is the biggest optimization - converting individual grass objects to MultiMesh.

CHANGES NEEDED:
1. Create GrassMultiMesh class
2. Single MultiMeshInstance3D per chunk for ALL grass
3. Procedural placement using noise
4. Integrate with VegetationSpawner

Please upload:
- res://vegetation_spawner.gd

I'll create the new grass_multimesh.gd file.
Reference IMPLEMENTATION_GUIDE section 3 for MultiMesh patterns.
```

**Files:**
- Create: `grass_multimesh.gd`
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Grass renders correctly
- [ ] Draw calls dramatically reduced
- [ ] Performance improved in grass-heavy areas

**Estimated Time:** 6 hours

---

#### **SESSION 5: Task 2.2 - MultiMesh Small Rocks**

**Prompt Template:**
```
Let's start Task 2.2 - MultiMesh Small Rocks

Same pattern as grass - convert decorative rocks to MultiMesh.

CHANGES NEEDED:
1. Create RockMultiMesh class (similar to GrassMultiMesh)
2. Only for non-harvestable decorative rocks
3. Integrate with VegetationSpawner

Please upload:
- res://vegetation_spawner.gd
- res://grass_multimesh.gd (reference for pattern)

I'll create the new rock_multimesh.gd file.
```

**Files:**
- Create: `rock_multimesh.gd`
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Decorative rocks render correctly
- [ ] Harvestable rocks still work normally
- [ ] Further draw call reduction

**Estimated Time:** 4 hours

---

#### **SESSION 6: Task 2.3 - Combine Berry Meshes**

**Prompt Template:**
```
Let's start Task 2.3 - Combine Berry Meshes

Currently each strawberry bush creates 12-26 separate berry MeshInstance3D nodes.

CHANGES NEEDED:
1. Refactor create_harvestable_strawberry()
2. Use SurfaceTool to combine all berries into single mesh
3. Single MeshInstance3D per bush instead of many

Please upload:
- res://vegetation_spawner.gd

Focus on the create_harvestable_strawberry() function around line 1283.
```

**Files:**
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Strawberry bushes look the same
- [ ] Harvesting still works
- [ ] Node count reduced per bush

**Estimated Time:** 4 hours

---

### ⏳ PHASE 3: LOD SYSTEMS - UPCOMING

**Phase Goal:** Distance-based optimization (~12 hours)

**Expected Improvement:**
- FPS: 50-55 → 60+ (TARGET MET)
- Draw Calls: <500 (TARGET MET)

---

#### **SESSION 7: Task 3.1 - Tree LOD System**

**Prompt Template:**
```
Let's start Task 3.1 - Tree LOD System

Implement 4-level LOD for trees based on distance.

LOD LEVELS:
- LOD0 (0-30m): Full CSG tree
- LOD1 (30-60m): Simplified (trunk + blob)
- LOD2 (60-100m): Billboard sprite
- LOD3 (100m+): Hidden

Please upload:
- res://vegetation_spawner.gd

I'll create the new tree_lod.gd file.
Reference IMPLEMENTATION_GUIDE section 4 for LOD patterns.
```

**Files:**
- Create: `tree_lod.gd`
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Trees transition smoothly between LODs
- [ ] No visible popping
- [ ] Performance improved at distance

**Estimated Time:** 6 hours

---

#### **SESSION 8: Task 3.2 - Vegetation Culling**

**Prompt Template:**
```
Let's start Task 3.2 - Vegetation Culling

Hide vegetation outside camera frustum (behind player).

CHANGES NEEDED:
1. Add frustum culling to VegetationSpawner
2. Periodic culling updates (not every frame)
3. ~100° view cone check

Please upload:
- res://vegetation_spawner.gd
```

**Files:**
- Modify: `vegetation_spawner.gd`

**Testing:**
- [ ] Vegetation behind player is hidden
- [ ] No visual issues when turning
- [ ] Performance improved

**Estimated Time:** 3 hours

---

#### **SESSION 9: Task 3.3 - Chunk LOD (Terrain)**

**Prompt Template:**
```
Let's start Task 3.3 - Chunk LOD for Terrain

Reduce terrain mesh detail at distance.

LOD LEVELS:
- LOD0 (0-2 chunks): Full resolution
- LOD1 (2-4 chunks): Half resolution  
- LOD2 (4+ chunks): Quarter resolution

Please upload:
- res://chunk.gd
- res://chunk_manager.gd
```

**Files:**
- Modify: `chunk.gd`, `chunk_manager.gd`

**Testing:**
- [ ] Terrain still looks good up close
- [ ] No seams between LOD levels
- [ ] Reduced primitive count

**Estimated Time:** 3 hours

---

### ⏳ PHASE 4: POLISH & SETTINGS - UPCOMING

**Phase Goal:** User controls and monitoring tools (~7 hours)

---

#### **SESSION 10: Task 4.1 - Performance Monitor HUD**

**Prompt Template:**
```
Let's start Task 4.1 - Performance Monitor HUD

Create debug overlay showing real-time metrics (toggle with F3).

DISPLAY:
- FPS (current and average)
- Draw Calls
- Objects Drawn
- Memory Usage
- Color-coded status (green/yellow/red)

I'll create:
- res://performance_hud.gd
- res://performance_hud.tscn
```

**Files:**
- Create: `performance_hud.gd`, `performance_hud.tscn`

**Testing:**
- [ ] F3 toggles display
- [ ] Metrics update in real-time
- [ ] Color coding works

**Estimated Time:** 2 hours

---

#### **SESSION 11: Task 4.2 - Quality Presets System**

**Prompt Template:**
```
Let's start Task 4.2 - Quality Presets System

Create QualitySettings singleton with presets.

PRESETS:
- Low: Minimal effects, short view distance
- Medium: Balanced
- High: Good quality (default)
- Ultra: Maximum quality

Please upload:
- res://chunk_manager.gd (need to hook view distance)
- res://vegetation_spawner.gd (need to hook density)

I'll create res://quality_settings.gd as an autoload.
```

**Files:**
- Create: `quality_settings.gd`
- Modify: (hooks only)

**Testing:**
- [ ] Each preset applies correctly
- [ ] Settings persist across sessions
- [ ] Performance scales with preset

**Estimated Time:** 3 hours

---

#### **SESSION 12: Task 4.3 - Settings Menu Integration**

**Prompt Template:**
```
Let's start Task 4.3 - Settings Menu Integration

Add Graphics tab to settings menu with quality controls.

UI ELEMENTS:
- Quality preset dropdown
- Individual setting sliders
- Apply/Revert buttons

Please upload:
- res://settings_menu.gd
- res://settings_menu.tscn
```

**Files:**
- Modify: `settings_menu.gd`, `settings_menu.tscn`

**Testing:**
- [ ] Graphics tab appears
- [ ] Dropdown changes presets
- [ ] Settings save correctly

**Estimated Time:** 2 hours

---

## GIT WORKFLOW INTEGRATION

### Branch Strategy

```bash
# Create feature branch at sprint start
git checkout -b v0.7.0-performance

# After each task, commit with descriptive message
git add .
git commit -m "Task X.Y: [Description]"

# Push regularly
git push origin v0.7.0-performance

# At sprint end, merge to main
git checkout main
git merge v0.7.0-performance
git tag -a v0.7.0 -m "Performance - Optimization sprint"
git push origin main --tags
```

### Commit Message Format

When user says "generate commit", output in this format:
```
Task X.Y: Brief description

- Change 1
- Change 2
- Performance impact: [metrics]
```

---

## PERFORMANCE TESTING PROTOCOL

### Before Each Phase

```
=== PHASE [N] BASELINE ===
Date: [Date]
Location: [Biome/Position]

FPS: ___
Draw Calls: ___
Objects Drawn: ___
Primitives: ___
Nodes: ___
Memory: ___ MB
```

### After Each Task

```
=== TASK [X.Y] COMPLETE ===
FPS: ___ (change: +/-___)
Draw Calls: ___ (change: +/-___)
Objects: ___ (change: +/-___)

Visual regression: [ ] None / [ ] Minor / [ ] Major
Bugs introduced: [ ] None / [ ] List: ___
```

### Phase Completion Check

```
=== PHASE [N] COMPLETE ===

Target FPS (60): [ ] Met / [ ] Not met (actual: ___)
Target Draw Calls (<500): [ ] Met / [ ] Not met (actual: ___)
Target Objects (<2000): [ ] Met / [ ] Not met (actual: ___)

Ready for next phase: [ ] Yes / [ ] No (blockers: ___)
```

---

## TROUBLESHOOTING

### Common Issues

**Issue: MultiMesh not rendering**
- Check instance_count > 0
- Verify mesh is assigned
- Check material is set

**Issue: LOD popping visible**
- Increase LOD transition distances
- Add hysteresis (different distances for switching up vs down)
- Use fade transitions

**Issue: Memory still growing**
- Verify cleanup signal connected
- Check is_instance_valid() before queue_free()
- Look for circular references

**Issue: Materials not caching**
- Ensure using static cache functions
- Check _ensure_initialized() is called
- Verify not creating new instances elsewhere

---

## SPRINT COMPLETION PROTOCOL

### Final Checklist

```
=== v0.7.0 "Performance" COMPLETE ===

PERFORMANCE TARGETS:
[ ] FPS: 60+ sustained
[ ] Draw Calls: <500
[ ] Objects: <2,000
[ ] Memory: Stable over 30 min

FEATURES:
[ ] Vegetation despawn working
[ ] Material caching active
[ ] MultiMesh grass implemented
[ ] MultiMesh rocks implemented
[ ] Berry meshes combined
[ ] Tree LOD functional
[ ] Vegetation culling working
[ ] Chunk LOD working
[ ] Performance HUD (F3)
[ ] Quality presets (Low/Med/High/Ultra)
[ ] Settings menu integration

TESTING:
[ ] All biomes tested
[ ] 30+ minute stability test
[ ] Visual regression check
[ ] No gameplay bugs

DOCUMENTATION:
[ ] ROADMAP updated
[ ] Commit messages complete
[ ] Release notes ready
```

### Release Commands

```bash
git checkout main
git pull origin main
git merge v0.7.0-performance
git tag -a v0.7.0 -m "Performance - Optimization sprint complete

- 60+ FPS achieved (from 25)
- <500 draw calls (from 17,141)
- MultiMesh grass and rocks
- Tree LOD system
- Quality presets
- Performance HUD"

git push origin main
git push origin v0.7.0
```

---

## CONCLUSION

This workflow provides:
- **Structure:** Phase-based development with clear sessions
- **Consistency:** Template prompts for each task
- **Quality:** Built-in testing and performance tracking
- **Efficiency:** Optimized for Claude's capabilities
- **Measurability:** Before/after metrics for every change

**Current Status:**
- ⏳ Phase 1: Quick Wins (Tasks 1.1-1.3) - PENDING
- ⏳ Phase 2: MultiMesh (Tasks 2.1-2.3) - UPCOMING
- ⏳ Phase 3: LOD Systems (Tasks 3.1-3.3) - UPCOMING
- ⏳ Phase 4: Polish (Tasks 4.1-4.3) - UPCOMING

**Remember:**
- One task per session = manageable chunks
- Test performance AFTER each change
- Record metrics before AND after
- Request file uploads FIRST = work with actual code
- Complete code only = production-ready output
- Ask to proceed = maintain control
- Visual quality must be maintained at High/Ultra

**Time Estimate:**
- 12 sessions × 2-4 hours each = ~41 hours
- Realistic timeline: 2-3 weeks solo development

**Performance Sprint Benefits:**
- Dramatically improved FPS (25 → 60+)
- Scalable quality settings for different hardware
- Foundation for future content additions
- Better player experience

Good luck with Crimson Veil v0.7.0! 🎮⚡
