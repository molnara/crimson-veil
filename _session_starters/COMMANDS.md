# Quick Commands Reference

**Terminal commands for common tasks**

---

## 🎮 Running the Game

```bash
# Launch main game
godot --path . world.tscn

# Test audio systems
godot --path . audio_manager_test.tscn

# Run in debug mode
godot --path . --verbose world.tscn
```

---

## 📦 Git Workflow

### Standard Commit Process
```bash
# Stage all changes
git add .

# Commit using generated message
git commit -F COMMIT_MESSAGE.txt

# Push to remote
git push
```

### Quick Commit (manual message)
```bash
git add .
git commit -m "feat(audio): Add UI sounds"
git push
```

---

## 🔍 Viewing History

### Recent Changes
```bash
# Last 10 commits (one line each)
git log --oneline -10

# Last 20 commits with details
git log -20

# Commits from last 7 days
git log --since="7 days ago"
```

### Sprint-Specific History
```bash
# All v0.5.0 commits
git log --oneline --grep="v0.5"

# All audio-related commits
git log --oneline --grep="audio"

# All commits by date range
git log --since="2025-12-11" --until="2025-12-12"
```

### Viewing Changes
```bash
# What changed in last commit
git diff HEAD~1

# What changed in specific commit
git show <commit-hash>

# Compare two commits
git diff <hash1> <hash2>

# See file changes only (no content)
git diff --stat HEAD~1
```

---

## 🔄 Branch Management

```bash
# Create new feature branch
git checkout -b feature/ui-sounds

# Switch to existing branch
git checkout main

# List all branches
git branch -a

# Delete local branch
git branch -d feature/ui-sounds
```

---

## 🛠️ Useful Godot Commands

### Project Management
```bash
# Export project (if export presets configured)
godot --path . --export "Linux/X11" build/game.x86_64

# Validate scene files
godot --path . --check-only world.tscn

# Run headless (no window)
godot --path . --no-window --quit
```

### Debugging
```bash
# Run with verbose output
godot --path . --verbose

# Run with debug collisions visible
godot --path . --debug-collisions

# Run with specific resolution
godot --path . --resolution 1920x1080
```

---

## 📁 File Operations

### Finding Files
```bash
# Find all .gd files
find . -name "*.gd"

# Find files containing text
grep -r "audio_manager" --include="*.gd"

# Count lines of code
find . -name "*.gd" -exec wc -l {} + | sort -n
```

### Copying Documentation
```bash
# Copy updated docs to repo root
cp SESSION_START.md /path/to/crimson-veil/
cp ROADMAP.txt /path/to/crimson-veil/
cp COMMIT_GUIDE.md /path/to/crimson-veil/
```

---

## 🧹 Cleanup Commands

```bash
# Remove untracked files (dry run first!)
git clean -n

# Actually remove untracked files
git clean -f

# Remove .import files and .godot folder
rm -rf .godot/ .import/

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard all local changes (dangerous!)
git reset --hard HEAD
```

---

## 📊 Project Stats

```bash
# Total lines of GDScript
find . -name "*.gd" -exec cat {} \; | wc -l

# Number of GDScript files
find . -name "*.gd" | wc -l

# Number of audio files
find audio/ -type f | wc -l

# Disk usage of audio folder
du -sh audio/

# Repository size
du -sh .git/
```

---

## 🎯 Quick Reference

**Most common commands:**
```bash
godot --path . world.tscn              # Run game
git log --oneline -10                  # View recent commits
git add . && git commit -F COMMIT_MESSAGE.txt && git push   # Full commit
git diff HEAD~1                        # See last changes
```

**Save these in your shell aliases:**
```bash
alias gdrun='godot --path . world.tscn'
alias gdtest='godot --path . audio_manager_test.tscn'
alias glog='git log --oneline -20'
alias gcommit='git add . && git commit -F COMMIT_MESSAGE.txt && git push'
```

---

**Need more? Check Git/Godot documentation or ask Claude!**
