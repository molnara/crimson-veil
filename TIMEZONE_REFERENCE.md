# Timezone & Timestamp Guidelines for Crimson Veil

## Project Timezone Standard

**Primary Timezone:** EST/EDT (Eastern Time - User's timezone)  
**User Location:** Hamilton, Ontario, CA (EST/EDT)  
**System Timezone:** UTC (Claude's system runs in UTC)

---

## Timestamp Format

**Standard Format:** `[YYYY-MM-DD HH:MM]`

**Examples:**
- `[2025-12-11 16:30]` - 4:30 PM EST on December 11, 2025
- `[2025-12-11 09:00]` - 9:00 AM EST on December 11, 2025
- `[2025-12-12 14:15]` - 2:15 PM EST on December 12, 2025

---

## When to Use Timestamps

### CHANGELOG.txt
- Every entry requires timestamp
- Use user's local time (EST/EDT)
- Round to nearest 15 minutes for planning sessions
- Use actual time for code commits

### ROADMAP.txt
- Sprint start dates in headers
- Task completion dates if tracking
- Not required for all entries

### DEVELOPMENT_GUIDE.md
- Version release dates
- Code review dates
- Major milestone dates

---

## Time Conversion Reference

| UTC Time | EST Time | EDT Time |
|----------|----------|----------|
| 00:00 | 19:00 (prev day) | 20:00 (prev day) |
| 12:00 | 07:00 | 08:00 |
| 18:00 | 13:00 | 14:00 |
| 21:30 | 16:30 | 17:30 |

**EST:** UTC - 5 hours (Winter: November - March)  
**EDT:** UTC - 4 hours (Summer: March - November)

---

## How to Determine Correct Date/Time

### For Claude:
1. Check system time: `date '+%Y-%m-%d %H:%M %Z'`
2. System returns UTC time
3. Convert to EST: Subtract 5 hours (winter) or 4 hours (summer)
4. Use converted time for timestamps

### Current Time Check (December 11, 2025):
- System (UTC): 21:31
- User (EST): 16:31 (4:31 PM)
- Correct date: 2025-12-11

### Why This Matters:
- Prevents future-dating entries (using tomorrow's date today)
- Keeps change history accurate
- Maintains consistency across sessions
- Git commit timestamps match CHANGELOG timestamps

---

## Sprint Planning Sessions

**Time Rounding for Planning:**
- Round to nearest 15 or 30 minutes
- Reflects approximate session start time
- Not critical to be exact (planning is conceptual)

**Example:**
- Actual time: 4:31 PM EST
- Rounded: 4:30 PM EST or 16:30
- Timestamp: `[2025-12-11 16:30]`

---

## Checklist for Timestamps

Before adding timestamps to any document:
- [ ] Check current system date/time
- [ ] Convert UTC to EST (subtract 5 hours in winter)
- [ ] Verify correct date (especially near midnight UTC)
- [ ] Round to appropriate interval (15min for planning)
- [ ] Use format: `[YYYY-MM-DD HH:MM]`
- [ ] Double-check: Date is not in the future

---

## Common Mistakes

❌ **Using UTC time directly**: `[2025-12-11 21:30]` when user is in EST
✅ **Convert to user's timezone**: `[2025-12-11 16:30]`

❌ **Using tomorrow's date**: `[2025-12-12 XX:XX]` when it's still Dec 11
✅ **Use current date**: `[2025-12-11 XX:XX]`

❌ **Forgetting timezone conversion**: UTC midnight = EST evening (previous day)
✅ **Always convert**: Subtract 5 hours from UTC (winter)

---

## Quick Reference Commands

**Check current time:**
```bash
date '+%Y-%m-%d %H:%M %Z'  # System time (UTC)
```

**Convert UTC to EST (winter):**
```
UTC_HOUR - 5 = EST_HOUR
If EST_HOUR < 0, subtract 1 from date and add 24 to hour
```

**Example:**
- UTC: 2025-12-11 02:00
- EST: 2025-12-10 21:00 (previous day!)

---

This guide ensures all timestamps are accurate and consistent with the user's timezone.
