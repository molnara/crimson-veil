# WORKFLOW GENERATOR GUIDE
## How to Create Claude Projects Workflow Documents for Future Sprints

This guide teaches Claude how to generate comprehensive workflow documents for any Crimson Veil sprint, based on the v0.6.0 workflow template.

---

## WHEN TO USE THIS GUIDE

Use this guide when you need to create a new workflow document for an upcoming sprint (e.g., v0.7.0, v0.8.0, etc.).

**User will say something like:**
- "Generate workflow for v0.7.0"
- "Create a new sprint workflow"
- "I need a workflow document for the next sprint"

---

## INPUTS REQUIRED FROM USER

Before generating a workflow, request these files:

1. **ROADMAP_v[X]_[Y]_[Z].txt** - The roadmap for the new sprint
2. **IMPLEMENTATION_GUIDE_v[X]_[Y]_[Z].txt** - Technical implementation details (if available)
3. **Previous workflow** (optional) - To maintain consistency

---

## WORKFLOW DOCUMENT STRUCTURE

Generate a Markdown document with these sections (in order):

### 1. HEADER
```markdown
# CRIMSON VEIL - CLAUDE PROJECTS WORKFLOW
## Development Strategy for v[X].[Y].[Z] "[Sprint Name]"

---
```

### 2. PROJECT SETUP

#### A. Claude Project Configuration
```markdown
## PROJECT SETUP

### Claude Project Configuration

**Project Name:** Crimson Veil

**Project Knowledge Base (Upload These Files):**
1. `ROADMAP_v[X]_[Y]_[Z].txt` - Sprint overview and task breakdown
2. `IMPLEMENTATION_GUIDE_v[X]_[Y]_[Z].txt` - Technical implementation details
3. `project.godot` - Project settings and configurations
4. Key existing scripts:
   - `player.gd`
   - `health_hunger_system.gd`
   - [other core systems from previous sprints]
   - [NEW files created in previous sprint marked as "CREATED"]
\`\`\`

**Rules for file list:**
- Include all core systems
- Mark files created in the immediately previous sprint with "(CREATED - Phase X complete)"
- Remove files that are no longer relevant

#### B. Custom Instructions

**Template:**
```markdown
**Custom Instructions for Project:**
\`\`\`
You(Claude) are assisting the Game Director(Xzarian) with development of Crimson Veil, a first-person survival game built in Godot 4.5.1. The project uses:
- GDScript for all game logic
- CSG primitives for 3D geometry
- AI-generated assets (audio via SFX Engine, textures via Leonardo.ai)
- Dual input support (M+KB and Xbox controller)

** VERY IMPORTANT: Project file structure res://, res://music, res://sfx **

Current sprint: v0.6.0 "Hunter & Prey" - Combat system implementation
Total tasks: 12 (grouped into 4 phases over ~48 hours)

CRITICAL RULES (MUST FOLLOW):
1. NEVER recreate existing code files from scratch
2. ALWAYS request files to be uploaded from GitHub before modifying them
3. Start each session by identifying which files are needed and requesting upload
4. Ask to "proceed" before implementing any code or making changes
5. Do NOT generate instructions, documentation, diagrams, or supplementary materials unless explicitly requested
6. When user says "generate commit", output a brief git commit message summarizing the changes
7. ALWAYS generate automated test scripts/scenes

Always:
1. Focus on production code only
2. Check ROADMAP and IMPLEMENTATION_GUIDE before suggesting implementations
3. Follow established code patterns from existing scripts
4. Respect locked design decisions
5. Consider controller support in all input implementations
6. Maintain performance targets (60 FPS, <100 draw calls)
7. Generate complete, production-ready code (not pseudocode)
8. Include error handling and edge case management
9. [Any sprint-specific rules from ROADMAP]
\`\`\`
```

**How to fill this:**
- Extract sprint name and description from ROADMAP header
- List total tasks from ROADMAP task count
- Calculate remaining time (total time - completed time if mid-sprint)
- Extract design philosophy from ROADMAP "DESIGN DECISIONS (LOCKED)" section
- Add any sprint-specific rules from ROADMAP notes

### 3. FILE MANAGEMENT WORKFLOW

**Copy this section verbatim** - it's universal:

```markdown
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
\`\`\`
Before we begin, please upload these existing files from GitHub:

REQUIRED FOR MODIFICATION:
- res://player.gd
- res://health_hunger_system.gd
- res://audio_manager.gd

NEW FILES TO CREATE:
- res://combat_system.gd
- res://weapon.gd

Please upload the existing files so I can modify them properly.
\`\`\`

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

**User:** "Let's start Task [X].[Y] - [Task Name]"

**Claude:** 
\`\`\`
Starting Task [X].[Y] - [Task Name].

Before we begin, please upload these existing files from GitHub:
- res://[file1].gd (need to integrate [feature])
- res://[file2].gd (need to add [integration])

I'll be creating these new files:
- res://[new_file1].gd
- res://[new_file2].gd

Please upload the existing files.
\`\`\`

**User:** [uploads files]

**Claude:**
\`\`\`
Files received. I can see [file1].gd currently handles [features]. 
I'll add [new integration].

IMPLEMENTATION PLAN:
[presents plan]

Shall I proceed?
\`\`\`

**User:** "Yes, proceed"

**Claude:** [provides code]

---
```

### 4. SESSION WORKFLOW STRUCTURE

```markdown
## SESSION WORKFLOW STRUCTURE

### Phase-Based Development Approach

Each session should focus on **one complete task** from the roadmap to maintain momentum and allow for testing between sessions.

### Session Template

\`\`\`
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

TESTING CRITERIA:
[ ] [Test 1]
[ ] [Test 2]
[ ] [Test 3]

OUTPUT NEEDED:
- Complete implementation files
- Testing instructions
- Integration notes
- Known issues/limitations

WORKFLOW:
1. Identify which existing files need to be modified
2. Request file upload: "Please upload these files from GitHub: [list]"
3. Wait for files to be uploaded
4. Review requirements and ask clarifying questions if needed
5. Present implementation plan
6. Wait for "proceed" confirmation
7. Provide complete code implementations (modifications to uploaded files + new files)
8. Provide testing instructions
\`\`\`
```

### 5. DETAILED SESSION BREAKDOWN

**This is the core section - generate from ROADMAP tasks**

**Structure:**
```markdown
## DETAILED SESSION BREAKDOWN

### [✅/🎯/⏳] PHASE [N]: [PHASE NAME] [- COMPLETE / - CURRENT PHASE / - UPCOMING]
\`\`\`

**For completed phases:**
```markdown
**Tasks [X].[Y]-[X].[Z] completed. The following have been created:**
- `file1.gd` (~X lines, description)
- `file2.gd` (description)
- Modified `existing_file.gd` (what changed)

**Key Features Implemented:**
- Feature 1
- Feature 2
- Feature 3

**Removed Features (if applicable):**
- ❌ Feature that was cut
\`\`\`

**For current/upcoming phases:**

For each task in the ROADMAP, create a session:

```markdown
#### **SESSION [N]: Task [X].[Y] - [Task Name]** [🎯 NEXT if current task]

**Prompt Template:**
\`\`\`
[Opening statement about what's being implemented]

(Note: Claude will first request you upload [list files] before proceeding)

[Detailed requirements from ROADMAP and IMPLEMENTATION_GUIDE]

[Specific implementation details:]
1. [Requirement 1]
   - [Detail]
   - [Detail]

2. [Requirement 2]
   - [Detail]
   - [Detail]

[Files to create/modify list]

[Reference to IMPLEMENTATION_GUIDE sections if applicable]

Expected deliverables:
- [Deliverable 1]
- [Deliverable 2]
- [Deliverable 3]
\`\`\`

**Expected Output:**
- [What Claude should produce]
- [Documentation needs]
- [Testing requirements]
\`\`\`

**How to generate sessions:**

1. **Read ROADMAP tasks** - Extract task IDs, names, time estimates
2. **Group related tasks** - Combine small tasks (< 2h) into single sessions
3. **Extract requirements** - Pull details from ROADMAP and IMPLEMENTATION_GUIDE
4. **Identify files** - Note which files need to be created/modified
5. **Reference guide sections** - Point to relevant IMPLEMENTATION_GUIDE sections
6. **Add deliverables** - List concrete outputs expected

**Session numbering:**
- Start at 1 for the first task in the sprint
- Increment sequentially
- If mid-sprint, continue from where previous phase left off

### 6. GIT COMMIT GENERATION

**Copy this section verbatim** - it's universal:

```markdown
---

## GIT COMMIT GENERATION

### Quick Commit Command

When you're ready to commit your changes, simply say:
\`\`\`
generate commit
\`\`\`

Claude will output a properly formatted git commit message based on the work completed in the session.

### Commit Message Format:

\`\`\`
v[X].[Y].[Z]: Task [X.Y] - [Brief description]

- [Key change 1]
- [Key change 2]
- [Key change 3]

Tested: [Brief test result]
Ref: Session [X]
```

### Example Usage:

**You:** "generate commit"

**Claude:**
```
v[X].[Y].[Z]: Task [X.Y] - [Task name]

- [Change 1]
- [Change 2]
- [Change 3]

Tested: [Test result]
Ref: Session [X]
```

**Then you can copy-paste:**
```bash
git add [files]
git commit -m "v[X].[Y].[Z]: Task [X.Y] - [Task name]

- [Change 1]
- [Change 2]
- [Change 3]

Tested: [Test result]
Ref: Session [X]"
git push
```

---
```

### 7. GITHUB WORKFLOW INTEGRATION

**Customize this for the sprint:**

```markdown
## GITHUB WORKFLOW INTEGRATION

### Commit Strategy:

**After Each Session:**

**Option 1 - Use "generate commit" command:**
```bash
# In Claude, type: "generate commit"
# Copy the generated commit message

# Review changes
git status
git diff

# Stage files
git add [files changed in session]

# Commit with Claude's generated message
git commit -m "[paste generated message]"

# Push to feature branch
git push origin v[X].[Y].[Z]-[feature-name]
\`\`\`

**Branch Strategy:**
\`\`\`
main (stable releases)
  │
  └─ v[X].[Y].[Z]-[feature-name] (current sprint)
       │
       ├─ phase-1-[name] (Sessions [range])
       ├─ phase-2-[name] (Sessions [range])
       ├─ phase-3-[name] (Sessions [range])
       └─ phase-4-[name] (Sessions [range])
\`\`\`

**Merge Protocol:**
- Complete each phase
- Test thoroughly
- Merge phase branch to v[X].[Y].[Z]-[feature-name]
- Only merge to main when ALL tasks complete

---
\`\`\`

**How to customize:**
- Replace version numbers with actual sprint version
- Use feature name from sprint (e.g., "combat", "save-system", "bosses")
- Update phase names based on ROADMAP phase structure
- Update session ranges based on how many sessions per phase

### 8. TESTING & ITERATION WORKFLOW

**Copy this section verbatim** - it's universal:

```markdown
## TESTING & ITERATION WORKFLOW

### After Each Session:

1. **Immediate Testing:**
   - Apply code changes to local project
   - Test specific features implemented
   - Note any bugs or issues

2. **Session Summary:**
   - Post a summary of what was completed
   - List any deviations from plan
   - Note any blockers

3. **Next Session Prep:**
   - Update Claude with test results
   - Provide any error messages
   - Clarify requirements if needed

### Testing Template:
\`\`\`
SESSION [X] TEST RESULTS:
═════════════════════════

Completed Features:
✓ [Feature 1]
✓ [Feature 2]
✗ [Feature 3] - Issue: [description]

Bugs Found:
1. [Bug description]
   - Reproduction steps
   - Expected vs actual behavior
   - Error message (if any)

Performance Notes:
- FPS: [X] (target: 60)
- Draw calls: [X] (target: <100)
- Memory: [X] MB (target: <500)

Questions for Next Session:
1. [Question 1]
2. [Question 2]
```

---
```

### 9. PROMPT OPTIMIZATION TIPS

**Copy this section verbatim** - it's universal:

```markdown
## PROMPT OPTIMIZATION TIPS

### Best Practices:

1. **Always Request File Upload First:**
   - Start every session by identifying needed files
   - Explicitly request upload from GitHub
   - Never assume or recreate existing code
   - Wait for files before proceeding

2. **Always Ask to Proceed:**
   - Present implementation plan first
   - Wait for confirmation before writing code
   - Allows you to course-correct if needed

3. **Code Only (No Docs Unless Requested):**
   - Skip UML diagrams, architecture docs, flowcharts
   - Focus on production-ready GDScript files
   - Only provide implementation code and testing instructions
   - Exception: Inline code comments are always good

4. **Reference Documentation:**
   - Always mention which section of IMPLEMENTATION_GUIDE to follow
   - Point to specific code snippets when available
   - Reference balance tables for numerical values

5. **Complete Specifications:**
   - Include all required properties/functions
   - Specify exact file paths
   - List all integration points

6. **Edge Cases:**
   - Explicitly ask for edge case handling
   - Mention state conflicts (e.g., dodge while charging)
   - Request error handling

7. **Testing Requirements:**
   - Include "how to test" instructions
   - Request test scenarios
   - Ask for performance considerations

8. **Incremental Complexity:**
   - Start with core functionality
   - Add polish in later prompts
   - Don't try to do everything at once

### Sample Good Prompt Structure:
\`\`\`
TASK: [Clear objective]

CONTEXT:
- Current state: [what exists]
- Dependencies: [what's needed]
- References: [docs sections]

REQUIREMENTS:
1. [Specific requirement]
2. [Specific requirement]
3. [Specific requirement]

DELIVERABLES:
- [Expected file 1]
- [Expected file 2]
- [Expected documentation]

CONSTRAINTS:
- [Performance target]
- [Compatibility requirement]
- [Code style guideline]

TESTING:
How to verify: [specific test steps]
```

### Expected Response Pattern:

**Claude's Initial Response:**
```
I'll implement Task [X.Y] - [Task Name].

First, please upload these existing files from GitHub:
- res://file1.gd
- res://file2.gd

I'll be creating these new files:
- res://new_file1.gd
- res://new_file2.gd

Please upload the existing files so I can review them and integrate properly.
```

**Your Response:**
```
[Upload files via Claude interface]
```

**Claude's Next Response:**
```
Files received. I've reviewed the current implementation.

PLAN:
1. Create/modify [details]
2. Add [details]
3. Integrate [details]

This will involve:
- [Key implementation detail 1]
- [Key implementation detail 2]
- [Key implementation detail 3]

Shall I proceed with this implementation?
```

**Your Response:**
```
Yes, proceed.
```

**Then Claude provides complete code.**

---
```

### 10. TROUBLESHOOTING GUIDE

**Copy this section verbatim** - it's universal:

```markdown
## TROUBLESHOOTING GUIDE

### If Claude Produces Incomplete Code:

**Prompt:**
\`\`\`
The code snippet you provided is incomplete. Please provide the FULL implementation of [file.gd] including:
- All necessary imports
- Complete function bodies
- All edge case handling
- Inline comments explaining logic
- Integration instructions

Do not use placeholders or "..." in the code.
```

### If Implementation Doesn't Match Spec:

**Prompt:**
```
The implementation doesn't match the ROADMAP requirements. Specifically:

Expected: [requirement from ROADMAP]
Received: [what Claude provided]

Please revise to exactly match the specification in IMPLEMENTATION_GUIDE section [X].
Reference balance table for numerical values.
```

### If Code Has Errors:

**Prompt:**
```
The code produces this error:
[paste error message]

File: [file.gd]
Line: [X]
Context: [what you were doing]

Please provide:
1. Root cause analysis
2. Fixed code
3. Explanation of the fix
4. How to prevent similar errors
```

---
```

### 11. QUALITY ASSURANCE CHECKLIST

**Copy this section verbatim** - it's universal:

```markdown
## QUALITY ASSURANCE CHECKLIST

### Before Moving to Next Session:

**Code Quality:**
- [ ] All functions have docstrings
- [ ] Variables have meaningful names
- [ ] No magic numbers (use constants)
- [ ] Error handling present
- [ ] Edge cases covered

**Integration:**
- [ ] New code follows existing patterns
- [ ] No duplicate code
- [ ] Proper signal connections
- [ ] Resource paths correct
- [ ] Input actions defined

**Performance:**
- [ ] No unnecessary _process loops
- [ ] Efficient collision detection
- [ ] Proper node pooling
- [ ] Texture sizes optimized
- [ ] Audio streams configured correctly

**Testing:**
- [ ] Manual testing completed
- [ ] No console errors
- [ ] Expected behavior verified
- [ ] Controller tested (if applicable)
- [ ] Performance acceptable

---
```

### 12. SPRINT COMPLETION PROTOCOL

**Customize this for the sprint:**

```markdown
## SPRINT COMPLETION PROTOCOL

### When All [N] Tasks Complete:

1. **Final Testing:**
   - Run complete testing checklist (from Session [X])
   - Test all [major features from sprint]
   - Verify all sounds play (if applicable)
   - Check controller support
   - Performance profiling

2. **Documentation:**
   - Update ROADMAP progress ([N]/[N] tasks - 100%)
   - Create CHANGELOG_v[X]_[Y]_[Z].md
   - Document known issues
   - List post-release improvements (v[X].[Y+1].[Z] ideas)

3. **Release Preparation:**
\`\`\`
   Please create a v[X].[Y].[Z] release summary:
   
   1. Feature overview ([sprint focus] highlights)
   2. Complete changelog (all [N] tasks)
   3. [Any design changes/simplifications made and why]
   4. Known issues and limitations
   5. Post-release roadmap (v[X].[Y+1].[Z] improvements)
   6. Testing instructions for users
   7. Credits (AI tools used: SFX Engine, Leonardo.ai)
   
   Format as Markdown for GitHub release notes.
\`\`\`

4. **Git Release:**
   ```bash
   # Final commit
   git add .
   git commit -m "v[X].[Y].[Z]: [Sprint name] complete - All [N] tasks ✓"
   
   # Merge to main
   git checkout main
   git merge v[X].[Y].[Z]-[feature-name]
   
   # Tag release
   git tag -a v[X].[Y].[Z] -m "Release v[X].[Y].[Z] - [Sprint Name]"
   git push origin main --tags
\`\`\`

5. **Next Sprint Planning:**
\`\`\`
   v[X].[Y].[Z] is complete. Help me plan v[X].[Y+1].[Z]:
   
   Review ROADMAP "NEXT SPRINT IDEAS" section.
   Based on v[X].[Y].[Z] learnings [and any specific notes], propose:
   
   1. v[X].[Y+1].[Z] scope (which features from backlog)
   2. [Any questions about restoring removed features if applicable]
   3. Task breakdown (similar to v[X].[Y].[Z] structure)
   4. Estimated timeline
   5. Key technical challenges
   6. Dependencies/prerequisites
   ```

---
```

**How to customize:**
- Replace [N] with total task count
- Replace [X] with final session number
- List major features from the sprint
- Add any sprint-specific release notes
- Include questions about design decisions if applicable

### 13. CONCLUSION

**Customize this for the sprint:**

```markdown
## CONCLUSION

This workflow provides:
- **Structure:** Phase-based development with clear sessions
- **Consistency:** Template prompts for each task
- **Quality:** Built-in testing and documentation
- **Efficiency:** Optimized for Claude's capabilities
- **Maintainability:** Version control integration
- **Flexibility:** [Any sprint-specific adaptations noted]

**Current Status:**
- [Status of each phase with emoji: ✅ COMPLETE / 🎯 NEXT / ⏳ UPCOMING]

**Remember:**
- One task per session = manageable chunks
- Test between sessions = catch issues early
- Reference docs always = avoid ambiguity
- Request file uploads FIRST = work with actual code
- Complete code only = production-ready output
- Ask to proceed = maintain control
- Document everything = future-proof development

**Time Estimate:**
- [X] sessions remaining × 2-4 hours each = ~[Y]-[Z] hours
- Total sprint: ~[Total] hours ([Completed] hours already completed in Phase [N])
- Realistic timeline: [X]-[Y] weeks solo development

**[Sprint-Specific Benefits/Notes]:**
- [Benefit or note 1]
- [Benefit or note 2]
- [Benefit or note 3]

Good luck with Crimson Veil v[X].[Y].[Z]! 🎮⚔️
\`\`\`

**How to customize:**
- Calculate remaining sessions and time
- List phase statuses accurately
- Add sprint-specific benefits or notes (e.g., simplifications, new tech)
- Update version number throughout

---

## GENERATION PROCESS

When user requests a workflow document, follow these steps:

### STEP 1: Request Inputs
\`\`\`
I'll generate a comprehensive workflow document for v[X].[Y].[Z].

Please upload these files:
1. ROADMAP_v[X]_[Y]_[Z].txt (required)
2. IMPLEMENTATION_GUIDE_v[X]_[Y]_[Z].txt (optional but recommended)
3. Previous workflow document (optional, for consistency)

Once uploaded, I'll create the workflow document.
```

### STEP 2: Analyze Inputs

1. **Read ROADMAP:**
   - Extract version number
   - Extract sprint name
   - Count total tasks
   - Identify phases
   - Note design decisions
   - Extract task details (ID, name, time, description)
   - Note any completed tasks (if mid-sprint)

2. **Read IMPLEMENTATION_GUIDE (if provided):**
   - Extract code snippets
   - Note file structure
   - Identify balance tables
   - Find testing protocols
   - Extract audio/texture generation prompts

3. **Determine Sprint Status:**
   - Fresh start? All tasks pending
   - Mid-sprint? Some phases complete
   - Which phase is current/next?

### STEP 3: Generate Document

Follow the structure outlined above, section by section:

1. Generate header with version and sprint name
2. Create project setup with accurate file lists
3. Copy universal sections (file management, testing, troubleshooting, QA)
4. **Generate session breakdown (most important):**
   - Create one session per task (or combined for small tasks)
   - Number sessions sequentially
   - Mark completed phases as ✅ COMPLETE
   - Mark current task as 🎯 NEXT
   - Mark upcoming phases as ⏳ UPCOMING
   - Extract requirements from ROADMAP for each session
   - Add prompt templates with detailed instructions
   - List files to create/modify
   - Reference IMPLEMENTATION_GUIDE sections
5. Customize Git workflow with correct version/branch names
6. Customize sprint completion protocol
7. Generate conclusion with accurate status and time estimates

### STEP 4: Present to User

```
I've generated the workflow document for v[X].[Y].[Z] "[Sprint Name]".

Summary:
- Total tasks: [N] ([M] completed, [N-M] remaining)
- Total sessions: [X]
- Current phase: Phase [Y] - [Phase Name]
- Next task: Task [X].[Y] - [Task Name]
- Estimated time remaining: ~[X]-[Y] hours

The document includes:
✓ Project setup with current file list
✓ [N] detailed session prompts
✓ Git workflow integration
✓ Testing protocols
✓ Sprint completion checklist

[Present the generated workflow document]
```

---

## QUALITY CHECKS

Before presenting the workflow, verify:

- [ ] All version numbers are correct and consistent
- [ ] Session numbers are sequential
- [ ] Task IDs match ROADMAP exactly
- [ ] Phase statuses are accurate (✅/🎯/⏳)
- [ ] File lists include all relevant scripts
- [ ] Prompt templates reference correct IMPLEMENTATION_GUIDE sections
- [ ] Time estimates are calculated correctly
- [ ] Git branch names use correct version
- [ ] Sprint-specific design decisions are noted
- [ ] All placeholders ([X], [Y], etc.) are replaced with actual values

---

## EXAMPLES

### Example Request:

**User:** "Generate workflow for v0.7.0"

### Example Response:

```
I'll generate a comprehensive workflow document for v0.7.0.

Please upload these files:
1. ROADMAP_v0_7_0.txt (required)
2. IMPLEMENTATION_GUIDE_v0_7_0.txt (optional but recommended)

Once uploaded, I'll create the workflow document.
```

**[User uploads files]**

```
I've generated the workflow document for v0.7.0 "Save & Persist".

Summary:
- Total tasks: 8 (0 completed, 8 remaining)
- Total sessions: 6
- Current phase: Phase 1 - Save System Foundation
- Next task: Task 1.1 - Save Manager Architecture
- Estimated time: ~24-32 hours

The document includes:
✓ Project setup with files from v0.6.0
✓ 6 detailed session prompts
✓ Git workflow integration  
✓ Testing protocols
✓ Sprint completion checklist

[Presents full workflow document]
```

---

## SPECIAL CASES

### Case 1: Mid-Sprint Workflow Update

If generating workflow mid-sprint (some tasks complete):

1. Request current state: "Which tasks have been completed?"
2. Mark completed phases with ✅ COMPLETE
3. Update "Current Status" section accurately
4. Recalculate remaining time
5. Start session numbering from next uncompleted task

### Case 2: No IMPLEMENTATION_GUIDE

If IMPLEMENTATION_GUIDE not provided:

1. Generate sessions with more general prompts
2. Focus on ROADMAP requirements only
3. Note in session prompts: "Reference ROADMAP for detailed requirements"
4. Suggest creating IMPLEMENTATION_GUIDE for better results

### Case 3: Very Large Sprint (15+ tasks)

If sprint has many tasks:

1. Consider grouping related small tasks (<2h) into single sessions
2. Suggest to user: "This sprint has [N] tasks. Consider breaking into multiple sub-sprints?"
3. If proceeding, clearly organize into phases
4. Add section navigation (table of contents) for easier reference

### Case 4: Sprint Without Clear Phases

If ROADMAP doesn't define phases:

1. Analyze tasks and group logically:
   - Foundation/Core (setup, base systems)
   - Implementation (main features)
   - Polish (audio, visual, effects)
   - Integration (testing, final touches)
2. Create phase structure: "Phase 1: [Name]", "Phase 2: [Name]", etc.
3. Note in document: "Phases derived from task analysis"

---

## VERSION CONTROL

When generating workflows, maintain version in filename and throughout:

**Filename:** `crimson_veil_claude_projects_workflow_v[X]_[Y]_[Z].md`

**Example:** `crimson_veil_claude_projects_workflow_v0_7_0.md`

This allows users to:
- Keep multiple sprint workflows
- Reference old workflows
- Track workflow evolution

---

## FINAL DELIVERABLE

Always present the workflow as a complete, ready-to-use Markdown file that can be:
1. Uploaded to Claude Projects knowledge base
2. Stored in the GitHub repo (docs/ directory)
3. Referenced throughout the sprint

The workflow should be **self-contained** - a developer should be able to follow it without needing to constantly reference the ROADMAP or IMPLEMENTATION_GUIDE (though those should still be uploaded to Claude Projects).

---

## COMPLETION

After generating the workflow:

```
Workflow document complete! 

Next steps:
1. Review the workflow document
2. Upload to Claude Projects knowledge base
3. Upload ROADMAP and IMPLEMENTATION_GUIDE to knowledge base
4. Start Session 1 when ready

Would you like me to:
- Adjust any session prompts?
- Add more detail to specific sections?
- Create a testing protocol checklist?
```

Good luck generating workflows! 🚀
