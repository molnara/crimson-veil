# AI Usage Analysis - Crimson Veil

**Analysis Date:** December 11, 2025  
**Analyzed By:** Claude Opus 4.5  
**Project Version:** v0.4.0

---

## Executive Summary

This document captures the baseline AI usage patterns and development velocity for the Crimson Veil project. Use this data to plan future sprints and optimize AI-assisted development workflows.

**Key Finding:** 81 commits in 4 days using 43% of weekly Sonnet capacity = highly efficient development pace that can be sustained long-term.

---

## Baseline Metrics (December 7-11, 2025)

### Project Output

| Metric | Value |
|--------|-------|
| Development Period | 4 days (Dec 7-11, 2025) |
| Total Commits | 81 |
| Releases | 2 (v0.2.0, v0.3.0) |
| Major Features | ~18-20 |
| Sessions per Feature | 1-3 (avg ~2) |
| Code Quality Grade | A (Opus review) |

### Usage at Analysis Time

| Resource | Used | Remaining | Resets |
|----------|------|-----------|--------|
| All Models | 27% | 73% | Mon 5:00 PM |
| Sonnet Only | 43% | 57% | Mon 5:00 PM |
| Current Session | 0% | 100% | - |

### Timeline Context

- **Project started:** Sunday, Dec 7, 2025 at 9:16 PM EST
- **Weekly reset:** Monday, Dec 8, 2025 at 5:00 PM
- **Week 1 work (before reset):** ~8-10 commits (initial setup, world gen, day/night)
- **Week 2 work (after reset):** ~70+ commits (most features)

---

## Capacity Calculations

### Sonnet Capacity

```
Weekly Sonnet Budget: 100%
Current Usage: 43%
Sessions This Week: ~20-25 estimated

Per-Session Cost: 43% ÷ 22.5 avg = ~1.9% per session
Weekly Session Capacity: 100% ÷ 1.9% = ~52 sessions/week
```

**Sonnet Weekly Capacity: 45-55 sessions**

### Opus Capacity

```
"All Models" Usage: 27%
Opus Sessions This Week: 1 (code review)
Remaining: 73%

Estimated Opus Capacity: ~3-4 sessions/week
(Opus sessions consume significantly more quota)
```

**Opus Weekly Capacity: 3-4 sessions**

### Feature Cost by Size

| Size | Sessions | Sonnet % | Weekly Max |
|------|----------|----------|------------|
| Small | 1 | ~2% | 25-30 |
| Medium | 2 | ~4% | 12-15 |
| Large | 3 | ~6% | 8-10 |

---

## Feature-to-Session Mapping

### Estimated Sessions Per Feature (This Week)

| Feature | Complexity | Est. Sessions | Actual Outcome |
|---------|------------|---------------|----------------|
| Initial project setup | Large | 2-3 | ✅ Working |
| World generation | Large | 2-3 | ✅ Working |
| Day/night cycle | Medium | 1-2 | ✅ Working |
| Biome system | Medium | 1-2 | ✅ Working |
| Vegetation spawning | Large | 2-3 | ✅ Working |
| Harvesting system | Medium | 2 | ✅ Working |
| Tree physics | Medium | 1-2 | ✅ Working |
| Log breaking | Medium | 1-2 | ✅ Working |
| Critter spawning | Medium | 1-2 | ✅ Working |
| Inventory UI | Medium | 2 | ✅ Working |
| Crafting system | Medium | 1-2 | ✅ Working |
| Tool system | Small | 1 | ✅ Working |
| Health/hunger | Medium | 2 | ✅ Working |
| Controller support | Medium | 1-2 | ✅ Working |
| DEVELOPMENT_GUIDE | Medium | 2-3 | ✅ Working |
| Sprint planning | Small | 1 | ✅ Working |
| Item stacking | Medium | 1-2 | ✅ Working |
| Container placement | Large | 2-3 | ✅ Working |
| Container UI | Large | 2-3 | ✅ Working |
| Code review (Opus) | Medium | 1 | ✅ Complete |
| Doc modernization | Small | 1 | ✅ Working |

**Total Estimated: 35-50 sessions**
**Actual Usage: 43% Sonnet ≈ 22-25 sessions**

This suggests either:
1. Sessions were more efficient than estimated
2. Some features were combined in single sessions
3. Workflow improved significantly over the 4 days

---

## Efficiency Observations

### What Improved Over Time

1. **File upload workflow** - Started requesting specific files before coding
2. **DEVELOPMENT_GUIDE usage** - Created comprehensive context document
3. **Commit batching** - Grouped related changes into single commits
4. **Feature scoping** - Better at defining "done" criteria upfront

### Workflow Refinements Discovered

1. **Always upload DEVELOPMENT_GUIDE.md first** - Provides full project context
2. **One feature per session** - Cleaner commits, focused work
3. **Request files before suggesting code** - Prevents integration issues
4. **Use commit checklist** - Ensures nothing is missed

### Model Selection Patterns

| Task Type | Best Model | Reason |
|-----------|------------|--------|
| Bug fixes | Sonnet | Quick, focused changes |
| New features | Sonnet | Implementation work |
| UI/UX work | Sonnet | Iterative refinement |
| Code review | Opus | Deep analysis needed |
| Architecture decisions | Opus | Complex reasoning |
| Documentation | Sonnet | Straightforward writing |
| Sprint planning | Either | Depends on complexity |

---

## Recommendations

### For Maximum Output

1. **Start each week with a plan** - Know which features to tackle
2. **Use Sonnet for 90% of work** - Save Opus for strategic decisions
3. **Batch small fixes** - Combine related tweaks in one session
4. **Front-load complex features** - Do large features early in week when fresh

### For Sustainable Pace

1. **Target 50% weekly usage** - Leave buffer for unexpected needs
2. **3-4 medium features per day** - Sustainable without burnout
3. **One Opus session per week** - For code review or architecture
4. **Document as you go** - Reduces context-loading in future sessions

### Warning Signs

- Using >70% capacity by Wednesday = slow down
- Multiple failed implementations = step back, use Opus for architecture review
- Sessions getting longer = features may need better scoping

---

## Future Tracking Template

Use this table to track weekly usage patterns:

### Week of [DATE]

| Day | Sessions | Features Completed | Notes |
|-----|----------|-------------------|-------|
| Mon | | | |
| Tue | | | |
| Wed | | | |
| Thu | | | |
| Fri | | | |
| Sat | | | |
| Sun | | | |

**End of Week:**
- Sonnet Usage: ___%
- Opus Usage: ___%
- Total Features: ___
- Commits: ___

---

## Historical Comparisons

### Week 1: December 7-11, 2025 (Baseline)

| Metric | Value |
|--------|-------|
| Sonnet Usage | 43% |
| Opus Usage | ~25% (1 session) |
| Features | ~20 |
| Commits | 81 |
| Efficiency | Excellent |

*Add future weeks below for comparison*

---

## Appendix: Raw Data Sources

### GitHub Insights (Dec 11, 2025)
- Repository: molnara/crimson-veil
- Period: November 11 - December 11, 2025 (1 month view)
- Commits to main: 81
- Authors: 1 (molnara)
- Releases: 2 (v0.2.0, v0.3.0)

### Claude Usage Dashboard
- Plan: Max subscription
- All Models: 27% used
- Sonnet Only: 43% used
- Reset: Monday 5:00 PM

### Commit History Highlights
- First commit: Dec 7, 2025 9:16 PM EST (Initial commit)
- Most active day: Dec 11, 2025 (container system, UI, stacking)
- Largest feature: Container UI (Phase 2) - ~7 related commits

---

*This analysis should be updated periodically to track changes in development velocity and AI usage patterns.*
