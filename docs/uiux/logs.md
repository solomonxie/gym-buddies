# Logs & Graphs

What you've actually done. Fourth tab.

```
  Logs & Graphs            [ 30d | 90d | All ]
 ──────────────────────────────────────────
  THIS WEEK          4 sessions · 12,400 lb
  M  T  W  T  F  S  S
  ●  ·  ●  ●  ·  ●  ·                        ← ● = trained, no streak fire,
 ──────────────────────────────────────────     no guilt for the gaps
  VOLUME BY MUSCLE GROUP
  Back      [████████████░░░░]  4,800 lb
  Legs      [█████████░░░░░░░]  3,600 lb
  Chest     [██████░░░░░░░░░░]  2,400 lb
  Shoulders [████░░░░░░░░░░░░]  1,600 lb
  Arms      [░░░░░░░░░░░░░░░░]      0 lb    ← the useful row is the empty one
 ──────────────────────────────────────────
  HISTORY
  Fraiser Heights                        ›
  Tue 23 Sep · 42:18 · 11 sets · 3,240 lb
 ──────────────────────────────────────────
  Push Day                           ★   ›
  Sun 21 Sep · 38:02 · 15 sets · 4,100 lb
 ──────────────────────────────────────────
  Fraiser Heights                        ›
  Thu 18 Sep · 45:51 · 18 sets · 5,060 lb
  ⋮
```

Reached from: tab bar · `LAST DONE` on an exercise

`★` marks a session that set a personal record. It's the only decoration on the
screen and it means something specific.

## Session log

```
 ‹ Back    Fraiser Heights      ⋯
 ──────────────────────────────────────────
  Tue 23 Sep 2026 · 15:44 – 16:26
  42:18 · 11 sets · 3,240 lb moved
 ──────────────────────────────────────────
  Walking                    Cardio
   1   5 reps          3 lb
 ──────────────────────────────────────────
  Seated Machine Rows        Back
   1  10 reps         50 lb
   2  10 reps         50 lb
   3   8 reps         50 lb            ▼     ← ▼ = under the target
 ──────────────────────────────────────────
  Lat Pull Downs             Back
   1  10 reps         60 lb         ★ PR
   2  10 reps         60 lb
   3  10 reps         60 lb
 ──────────────────────────────────────────
  Seated Leg Curls           Legs
                             skipped
 ──────────────────────────────────────────
  NOTES
  Left shoulder tight on the rows, went
  light on the third set.
```

## Trend

Pushed from an exercise, or from tapping an exercise name in a session log.

```
 ‹ Back     Lat Pull Downs      ⋯
 ──────────────────────────────────────────
  [ Top set | Volume | Reps ]
  [ 30d | 90d | All ]
 ──────────────────────────────────────────
  70 ┤                              ●
  60 ┤                    ●    ●
  50 ┤    ●    ●    ●
  40 ┤
     └────────────────────────────────────
      Jul        Aug        Sep
 ──────────────────────────────────────────
  BEST                      60 lb × 10   ›
  Thu 18 Sep
 ──────────────────────────────────────────
  EVERY SESSION
  Thu 18 Sep    3 × 10 · 60 lb       ★  ›
  Mon 15 Sep    3 × 10 · 55 lb          ›
  Thu 11 Sep    3 ×  9 · 55 lb       ▼  ›
  ⋮
```

## States

```
nothing logged
 ┌────────────────────────────────────────┐
 │        No sessions yet                 │
 │  Finish a workout and it shows up here │
 │  with the numbers filled in.           │
 │        ( Go to workouts )              │
 └────────────────────────────────────────┘

one session
  VOLUME BY MUSCLE GROUP
  Back      [████████████████]  3,240 lb   ← one bar is 100%; no comparison
                                              is claimed

exporting
  ( Exporting… ⟳ )

deleting a session
 ┌──────────────────────────────────────┐
 │ Delete this session?                 │
 │ 11 sets, and the Lat Pull Downs PR   │
 │ it set.                              │
 │  ( Cancel )       [[ Delete ]]!      │
 └──────────────────────────────────────┘

all-time range, hundreds of sessions
  [ 30d | 90d | ALL ]
  HISTORY                          (284)     ← paged, 50 at a time
```

## Interactions

| Target | Action | Result |
|---|---|---|
| history row | tap | → session log |
| exercise name in a log | tap | → trend for that exercise |
| `★` | tap | popover naming the record and the one it beat |
| chart point | tap/drag | value and date readout follows the finger |
| range segment | tap | remembered across tabs |
| `⋯` on a session | tap | `Edit sets` `Export CSV…` `Delete`! |
| week dots | tap | → that day's sessions |

## Copy

| Key | String |
|---|---|
| `logs.thisWeek` | THIS WEEK |
| `logs.weekSummary` | {n} sessions · {volume} |
| `logs.byGroup` | VOLUME BY MUSCLE GROUP |
| `logs.history` | HISTORY |
| `logs.sessionLine` | {Day d Mon} · {duration} · {n} sets · {volume} |
| `logs.empty` | Finish a workout and it shows up here with the numbers filled in. |
| `log.range` | {start} – {end} |
| `log.skipped` | skipped |
| `log.underTarget` | ▼ |
| `log.pr` | ★ PR |
| `log.delete` | {n} sets, and the {exercise} PR it set. |
| `trend.best` | BEST |
| `trend.every` | EVERY SESSION |

## Notes

**Volume in lb moved is the only cross-exercise number that survives comparing
a 5 × 5 against a 3 × 10.** Everything on this screen that aggregates uses it,
and it always carries its unit.

The empty row in `VOLUME BY MUSCLE GROUP` — `Arms 0 lb` — is deliberately drawn
and deliberately not hidden. A muscle group you haven't touched in a month is
the most useful thing this screen can tell you, and sorting it to the bottom
with a zero bar says it without a word of nagging.

No streaks, no badges, no "you're on fire". The week dots show what happened; a
gap is information, not a failure state.
