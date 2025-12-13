# Commit Guide

## "Generate a commit" → I Output:
1. **COMMIT_MESSAGE.txt** - Ready for `git commit -F`
2. **SESSION_START.md** - Updated progress
3. **ROADMAP.txt** - Marked complete (if exists)

## Message Format
```
{type}({scope}): {summary}

Changed files:
- {file} ({what})

Implements Task {X.X} from v{X.X.X}
```

**Types:** feat, fix, docs, refactor, perf, test

## Your Git Commands
```bash
git add .
git commit -F COMMIT_MESSAGE.txt
git push
```

## Session End
```bash
# Optional: Copy docs to repo
cp SESSION_START.md /path/to/repo/docs/
cp ROADMAP.txt /path/to/repo/docs/

# Then push
git push
```

That's it. Solo dev = simple.
