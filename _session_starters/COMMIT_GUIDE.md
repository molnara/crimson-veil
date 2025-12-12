# Commit Process Guide

**How "Generate a commit" works**

---

## 🎯 When You Say "Generate a commit"

I will create and share:

1. **COMMIT_MESSAGE.txt** - Ready-to-use commit message
2. **SESSION_START.md** - Updated with sprint progress
3. **ROADMAP.txt** - Tasks marked complete
4. **CHANGELOG.txt** (optional) - New entry if significant milestone

---

## 📝 Commit Message Format

```
<type>(<scope>): <short summary>

Changed files:
- path/to/file1.gd (what changed)
- path/to/file2.gd (what changed)

<Optional longer description>

Implements Task X.X from v0.X.0 sprint
```

**Example:**
```
feat(audio): Add UI sounds system

Changed files:
- scripts/audio/audio_manager.gd (added ui_sounds category)
- scripts/ui/inventory_ui.gd (play inventory_toggle sound)
- scripts/ui/crafting_ui.gd (play craft_complete sound)

Implements Task 3.1 - UI Sounds from v0.5.0 sprint
```

---

## 🔄 Your Workflow

After I generate the commit files:

```bash
# 1. Commit your code changes
git add .
git commit -F COMMIT_MESSAGE.txt

# 2. (Optional) Copy updated docs to repo
cp SESSION_START.md /path/to/repo/
cp ROADMAP.txt /path/to/repo/

# 3. Push
git push
```

---

## 📋 What Gets Updated

### COMMIT_MESSAGE.txt
- Conventional commit format
- List of changed files
- Task reference

### SESSION_START.md
- Sprint progress percentage
- Recent changes (last 5)
- Task completion status
- Known issues

### ROADMAP.txt
- Task checkmarks [x]
- Sprint progress count
- Completion timestamps

### CHANGELOG.txt (if exists)
- New entry with timestamp
- Changes summary
- Task reference

---

## 🎯 File Output Rules

**Documentation files** (SESSION_START.md, ROADMAP.txt, etc):
- ✅ Complete file with all sections
- ✅ Exact filename (no suffixes)
- ✅ UTF-8 encoding (→ ✅ 🎯)

**Code files** (.gd, .tscn):
- ❌ Not included in commit output
- ✅ You handle via Git
- ✅ I only output if explicitly requested

---

## 💡 Tips

**Fast commits:**
- Upload just SESSION_START.md or QUICK_START.md
- Say "Generate a commit"
- Use the commit message I create

**Detailed commits:**
- Upload SESSION_START.md + ROADMAP.txt
- Say "Generate a commit"
- I'll update both with full context

**Custom commits:**
- Tell me what changed
- I'll create appropriate commit message
- You handle the rest

---

## 🔧 Customization

Want different commit message format? Just ask:
- "Use imperative mood"
- "Include issue numbers"
- "Add co-author tags"
- Etc.

---

**That's it! Simple, fast, Git-native.**
