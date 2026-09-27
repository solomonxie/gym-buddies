# Session

A workout being performed. Full-screen cover — the tab bar is gone, because
nothing else is happening for the next hour.

This is the screen the app exists for. Everything on it is sized by how often
it gets touched: **log a set** fifty times a workout, **± reps/weight** a few
times, everything else almost never. So the top half is for reading, the bottom
half is for thumbs.

```
 (×)          Fraiser Heights          (≡)
                  00:14:22
 ━━━━━━ ▓▓▓▓▓▓ ░░░░░░ ░░░░░░ ░░░░░░ ░░░░░░    ← one segment per exercise:
                                                 done · current (accent) · to go
  Seated Machine Rows          ( ▶| Skip )
  Back · Machine

  ● ○ ○  Set 2 of 3 ⌄             LAST TIME
                                 10 × 50 lb

            [ muscle map, faded ]              ← decoration, never tapped
 ╭────────────────────────────────────────╮
 │ ( − )             10             ( + ) │
 │                  REPS                  │
 ╰────────────────────────────────────────╯
 ╭────────────────────────────────────────╮
 │ ( − )            50.0            ( + ) │  ← 60pt round targets at the
 │              LB  ± 10 lb               │     thumb's edges; machine =
 ╰────────────────────────────────────────╯     10 lb a tap, not a flat 1
 ╭────────────────────────────────────────╮
 │               ✓  Log set               │  ← 72pt, the one accent fill
 ╰────────────────────────────────────────╯
  Next  Lat Pull Downs  3 × 10 · 60 lb  ⌃    ← opens the jump sheet
```

Reached from: `Start` / `▶` on Train ([`workouts.md`](workouts.md)) · `Resume`
on an unfinished session

## States

```
resting — the bar appears ABOVE the button and never replaces it
 ╭▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒─────────────────────────╮
 │ ◷ Rest  00:00:28          ( +30s ) (×) │  ← tinted fill grows left→right:
 ╰▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒─────────────────────────╯     the ring, unrolled
 ╭────────────────────────────────────────╮
 │               ✓  Log set               │  ← still live: starting early
 ╰────────────────────────────────────────╯     is a legitimate choice

rest elapsed, on screen
 ╭▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╮
 │ ◷ Rest over                        (×) │  ← bell, green; stays until ×
 ╰▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╯     or the next set

rest elapsed, phone in a pocket
 ⌐ Rest over · Seated Machine Rows 3 of 3 ¬   ← local notification, not a
                                                foreground timer

first ever time
  ○ ○ ○  Set 1 of 3               LAST TIME
                                          —

last set of the last exercise
 │          ✓  Log set & finish           │  ← opens the summary directly

exercise with no load (bodyweight, band)
 │ ( − )             12             ( + ) │
 │                  REPS                  │  ← weight tile gone entirely,
                                              not a disabled "0.0"

treadmill — minutes, and incline instead of weight
 │ ( − )             20             ( + ) │
 │                MINUTES                 │  ← ± 1 min
 │ ( − )            8.5             ( + ) │
 │           INCLINE %  ± 0.5%            │  ← steps and clamps 0–30%,
                                              never a weight
 LAST TIME  20 min · 8% incline

progression offer, set 1 only, once per exercise per session
 ╭────────────────────────────────────────╮
 │ ↗ Hit all 3 × 10 last time. Try 60 lb? │
 │ ( Not today )  ( Use 60 lb )           │
 ╰────────────────────────────────────────╯

change sets — tap "Set 3 of 4 ⌄", unfolds in place
  ● ● ○ ○  Set 3 of 4 ⌃
  (1)· (2)  (3) [4] (5)  (6)                  ← 1 dimmed, not hidden
  2 already logged, so fewer isn't offered.

every exercise done or skipped
                    ✓
     Every exercise is done or skipped.
            ( Go back to one )
 ╭────────────────────────────────────────╮
 │             Finish workout             │
 ╰────────────────────────────────────────╯
```

## Overlays

```
 ≡ jump sheet — the rack you wanted is busy
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
                 Jump to              Done
  ✓ Walking                  1 × 5 · 3 lb    ← done rows are disabled
  ● Seated Machine Rows      1 of 3 done     ← ● = where you are
    Lat Pull Downs          3 × 10 · 60 lb
    Seated Leg Curls             skipped

 keypad — tap a number; 50 → 135 isn't a job for ±
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
               Weight (lb)
                  50
  ( Cancel )                  [[ Set ]]

 long-press Log set, 2+ sets left
 ┌──────────────────────────────────────┐
 │ Log several identical sets           │
 │ For warm-ups: each at the reps and   │
 │ weight shown.                        │
 │ ( Log 2 sets )  ( Log 3 sets )       │
 │ ( Cancel )                           │
 └──────────────────────────────────────┘

 × with sets logged
 ┌──────────────────────────────────────┐
 │ Finish this workout?                 │
 │ 7 sets logged, 14 minutes.           │
 │ ( Save & exit )                      │
 │ ( Discard )!                         │
 │ ( Keep going )                       │
 └──────────────────────────────────────┘

 × with nothing logged
 ┌──────────────────────────────────────┐
 │ Leave?                               │
 │ Nothing was logged, so nothing will  │
 │ be saved.                            │
 │ ( Leave )!          ( Keep going )   │
 └──────────────────────────────────────┘

 Summary, after the last set
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
  WORKOUT COMPLETE                           ← "FINISHING EARLY" +
  Fraiser Heights                               ( Keep going ) otherwise
  ╭──────────╮ ╭──────────╮ ╭────────────╮
  │ 42:18    │ │ 11       │ │ 3,240 lb   │
  │ TIME     │ │ SETS     │ │ MOVED      │
  ╰──────────╯ ╰──────────╯ ╰────────────╯
  ╭──────────────────────────────────────╮
  │ PERSONAL RECORDS                     │
  │ ★ Lat Pull Downs         60 lb × 10  │
  ╰──────────────────────────────────────╯
  ╭──────────────────────────────────────╮
  │ SKIPPED                              │
  │ Seated Leg Curls                     │
  ╰──────────────────────────────────────╯
  ╭──────────────────────────────────────╮
  │ Weights differed from the plan on 1  │
  │ line. Update the workout?            │
  │ [ Leave the plan | Update it ]       │
  │ Lat Pull Downs        50 lb → 60 lb  │
  ╰──────────────────────────────────────╯
  ╭──────────────────────────────────────╮
  │ NOTES                                │
  │ How it went, anything to remember    │
  ╰──────────────────────────────────────╯
  ( Discard )!         [[ Save ]]           ← Discard asks once more
```

## Interactions

| Target | Action | Result |
|---|---|---|
| `[[ ✓ Log set ]]` | tap | writes the log, starts rest, advances the counter |
| `[[ ✓ Log set ]]` | long-press | log several identical sets, for warm-ups |
| `( + ) / ( − )` weight | tap | one real increment of *that* equipment |
| `( + ) / ( − )` | press-hold | repeats, accelerating every five steps |
| reps / weight number | tap | keypad sheet |
| `Set 2 of 3 ⌄` | tap | change-sets row; can't drop below what's logged |
| `( ▶\| Skip )` | tap | skip to the next exercise; anything logged stays logged |
| `(≡)` / `Next …` | tap | jump sheet |
| jump-sheet row | tap | jumps straight to it |
| `+30s` | tap | extends rest, keeping the time already rested |
| `(×)` on rest | tap | dismiss, no penalty, no confirm |
| `(×)` top-left | tap | exit dialog above |

## Copy

| Key | String |
|---|---|
| `session.logSet` | Log set |
| `session.logSet.final` | Log set & finish |
| `session.set` | Set {n} of {total} |
| `session.lastTime` | LAST TIME / {reps} × {weight} |
| `session.lastTime.none` | — |
| `session.skip` | Skip |
| `session.next` | Next {exercise} {sets} × {reps} · {weight} |
| `session.resting` | Rest |
| `session.restOver` | Rest over |
| `session.restOver.notification` | Rest over · {exercise} {n} of {total} |
| `session.extend` | +30s |
| `session.jump` | Jump to |
| `session.skipped` | skipped |
| `session.progression` | Hit all {sets} × {reps} last time. Try {weight}? |
| `session.deload` | Short of {sets} × {reps} twice running. Try {weight}? |
| `session.progression.no` | Not today |
| `session.progression.yes` | Use {weight} |
| `session.setsFloor` | {n} already logged, so fewer isn't offered. |
| `session.multi` | For warm-ups: each at the reps and weight shown. |
| `session.allDone` | Every exercise is done or skipped. |
| `session.exit.some` | {n} sets logged, {m} minutes. |
| `session.exit.none` | Nothing was logged, so nothing will be saved. |
| `session.summary.stats` | TIME · SETS · MOVED |
| `session.summary.drift` | Weights differed from the plan on {n} lines. Update the workout? |
| `session.summary.discard` | {n} logged sets won't be saved. |

## Notes

**`LAST TIME` is the whole reason to open an app instead of using paper.** It's
the one number you actually want at the top of a set and it costs one query.

The `✗` that got rejected, so it doesn't come back:

```
 ✗   Set     Reps    Weight
     1/3     10      50.0
    CHANGE   [−][+]  [−][+]
     …and no way to say "done"

     Three readouts of equal weight, and the
     action performed fifty times a workout
     has no control at all. Logging the set
     is not a side effect of adjusting reps.
```

The progression offer appears **once per exercise per session** and is a
question, never an automatic change. An app that silently moves the pin for you
is an app you stop trusting the first time it's wrong.
