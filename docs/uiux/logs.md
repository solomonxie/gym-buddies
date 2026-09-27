# Progress

What you've actually done. Third tab.

```
  Progress                                ⇪  ← CSV of every session
  [    30d    |    90d    |    All    ]
 ╭───────────╮ ╭───────────╮ ╭────────────╮
 │ 12        │ │ 38k       │ │ 8h 40m     │
 │ SESSIONS  │ │ LB MOVED  │ │ TIME       │
 ╰───────────╯ ╰───────────╯ ╰────────────╯  ← all three follow the range
 ╭────────────────────────────────────────╮
 │ THIS WEEK                              │
 │  (✓)  ( )  (✓)  (✓)  ( )  (✓)  ( )     │  ← filled accent + ✓ = trained;
 │   M    T    W    T    F    S    S      │     no streak fire, no guilt
 ╰────────────────────────────────────────╯     for the gaps
 ╭────────────────────────────────────────╮
 │ VOLUME BY MUSCLE GROUP                 │
 │ Back      [██████████░░░░]    4,800 lb │
 │ Legs      [███████░░░░░░░]    3,600 lb │
 │ Chest     [█████░░░░░░░░░]    2,400 lb │
 │ Shoulders [███░░░░░░░░░░░]    1,600 lb │
 │ Arms      [░░░░░░░░░░░░░░]        0 lb │  ← the useful row is the
 ╰────────────────────────────────────────╯     empty one
  HISTORY                                12
 ╭────────────────────────────────────────╮
 │  23  Fraiser Heights                 › │
 │ SEP  42:18 · 11 sets · 3,240 lb        │
 ╰────────────────────────────────────────╯
 ╭────────────────────────────────────────╮
 │  21  Push Day ★                      › │
 │ SEP  38:02 · 15 sets · 4,100 lb        │
 ╰────────────────────────────────────────╯
   ⋮
```

Reached from: tab bar · `Last done` on an exercise opens a session log

`★` marks a session that set a personal record. It's the only decoration on the
screen and it means something specific.

## Session log

```
 ‹ Progress     Fraiser Heights         ⋯
 ──────────────────────────────────────────
  Tue, 23 Sep 2026 · 3:44 PM – 4:26 PM
  42:18 · 11 sets · 3,240 lb moved
 ──────────────────────────────────────────
  Walking                     Cardio    ›   ← header → trend
   1   5 reps                     3 lb
 ──────────────────────────────────────────
  Seated Machine Rows         Back      ›
   1  10 reps                    50 lb
   2  10 reps                    50 lb
   3   8 reps                    50 lb    ▼  ← ▼ = under the target
 ──────────────────────────────────────────
  Lat Pull Downs              Back      ›
   1  10 reps                    60 lb  ★ PR
   2  10 reps                    60 lb
   3  10 reps                    60 lb
 ──────────────────────────────────────────
  Seated Leg Curls            Legs      ›
  skipped
 ──────────────────────────────────────────
  NOTES
  Left shoulder tight on the rows, went
  light on the third set.
```

## Trend

Pushed from `Every session` on an exercise, or an exercise header in a log.

```
 ‹ Back          Lat Pull Downs          ⓘ  ← ⓘ → exercise detail
 ──────────────────────────────────────────
  [ Top set | Volume | Reps ]
  [   30d   |   90d   |  All ]
  60 lb  Thu 18 Sep
  70 ┤                              ●
  60 ┤                    ●────●
  50 ┤    ●────●────●
     └────────────────────────────────────
      Jul        Aug        Sep
 ──────────────────────────────────────────
  BEST
  60 lb × 10                 Thu 18 Sep  ›
 ──────────────────────────────────────────
  EVERY SESSION
  Thu 18 Sep    3 × 10 · 60 lb       ★   ›
  Mon 15 Sep    3 × 10 · 55 lb           ›
  Thu 11 Sep    3 × 9 · 55 lb        ▼   ›
  ⋮
```

## States

```
nothing logged
 ┌────────────────────────────────────────┐
 │           No sessions yet              │
 │  Finish a workout and it shows up here │
 │  with the numbers filled in.           │
 │           [[ Go to Train ]]            │
 └────────────────────────────────────────┘

empty range
  HISTORY                                 0
 ╭────────────────────────────────────────╮
 │ Nothing in the last 30d.               │
 ╰────────────────────────────────────────╯

one session
 │ Back      [██████████████]    3,240 lb │  ← one bar is 100%; no
                                               comparison is claimed

tap ★ PR in a log
 ┌──────────────────────────────────────┐
 │ ★ Lat Pull Downs 60 lb × 10          │
 │ Beat 55 lb × 10 from Mon 15 Sep.     │
 │                             ( OK )   │
 └──────────────────────────────────────┘

editing sets (⋯ → Edit sets)
  Set 1 · reps          [−]   10   [+]
  weight / lb           [−]   50   [+]    ← swipe ← to delete a set
                                   Done

deleting a session
 ┌──────────────────────────────────────┐
 │ Delete this session?                 │
 │ 11 sets, and the Lat Pull Downs PR   │
 │ it set.                              │
 │  ( Cancel )        ( Delete )!       │
 └──────────────────────────────────────┘

hundreds of sessions
  HISTORY                               284
   ⋮
  ( Show 50 more )                         ← paged, 50 at a time
```

## Interactions

| Target | Action | Result |
|---|---|---|
| history card | tap | → session log |
| exercise header in a log | tap | → trend for that exercise |
| `★ PR` set line | tap | alert naming the record and the one it beat |
| chart | tap/drag | value and date readout follows the finger |
| range segment | tap | remembered, shared with Trend |
| `⇪` | tap | `[ share sheet ]` with every session as CSV |
| `⋯` on a session | tap | `Edit sets` `Export CSV…` `Delete`! |
| `ⓘ` on a trend | tap | → exercise detail |

## Copy

| Key | String |
|---|---|
| `progress.tiles` | SESSIONS · {unit} MOVED · TIME |
| `progress.thisWeek` | THIS WEEK |
| `progress.byGroup` | VOLUME BY MUSCLE GROUP |
| `progress.history` | HISTORY |
| `progress.sessionLine` | {duration} · {n} sets · {volume} |
| `progress.emptyRange` | Nothing in the last {range}. |
| `progress.more` | Show {n} more |
| `progress.empty` | Finish a workout and it shows up here with the numbers filled in. |
| `progress.empty.action` | Go to Train |
| `log.range` | {date} · {start} – {end} |
| `log.totals` | {duration} · {n} sets · {volume} moved |
| `log.skipped` | skipped |
| `log.underTarget` | ▼ |
| `log.pr` | ★ PR |
| `log.pr.beat` | Beat {weight} × {reps} from {day}. |
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
