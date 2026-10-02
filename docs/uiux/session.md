# Session

A workout being performed. Full-screen cover — Train is gone, because
nothing else is happening for the next hour.

This is the screen the app exists for. Everything on it is sized by how often
it gets touched: **end a set** fifty times a workout, **± reps/weight** a few
times, everything else almost never. So the top half is for reading, the bottom
half is for thumbs — the values sit in one row right above the button, ± at
each tile's edges.

```
 (×)          Fraiser Heights          (≡)
                  00:14:22
 ━━━━━━ ▓▓▓▓▓▓ ░░░░░░ ░░░░░░ ░░░░░░ ░░░░░░    ← one segment per exercise:
                                                 done · current (accent) · to go
  Seated Machine        (◀|) ( ▶| Skip )    ← (◀|) Back, icon only, when
  Rows                                          there's an unfinished one
  Back · Machine                                behind you

  ● ○ ○  Set 2 of 3 ⌄             LAST TIME
                                 10 × 50 lb

            [ muscle map, faded ]              ← decoration, never tapped
             front        back

 ╭───────────────────╮ ╭──────────────────╮
 │ (−)   10    (+)   │ │ (−)  50.0   (+)  │  ← one row, 60pt tall; ± drawn
 │       REPS        │ │       LB         │     small, tapped across 60pt;
 ╰───────────────────╯ ╰──────────────────╯     tap the number to type it
 ╭────────────────────────────────────────╮
 │             ✓  End set 2               │  ← 72pt, the one accent fill;
 ╰────────────────────────────────────────╯     reps outside rest: no Start
  Next  Lat Pull Downs  3 × 10 · 60 lb  ⌃    ← opens the jump sheet
```

Reached from: `Start` / `▶` on Train ([`workouts.md`](workouts.md)) · `Resume`
on an unfinished session

## States

```
one button, one action at a time — its fill is the clock, draining
right→left as rest or a timed set runs out; a 72pt side button appears
only while there's a clock to change

resting — always Start: the next set hasn't begun
 ╭▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒─────────────────╮ ╭──────╮
 │             ▶  Start set 3     │ │ +30s │  ← tap: rest ends, the set's
 │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ Rest 00:00:28   │ │      │     clock starts
 ╰▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒─────────────────╯ ╰──────╯

rep set running — Start tapped, or rest ran out on its own (counts from then)
 ╭────────────────────────────────╮ ╭──────╮
 │             ✓  End set 3       │ │  ×   │  ← × only after a tapped Start
 │            00:00:41            │ │      │
 ╰────────────────────────────────╯ ╰──────╯

rest elapsed, timed — nothing has started yet
 ╭────────────────────────────────────────╮
 │             ▶  Start set 3             │
 │               Rest over                │
 ╰────────────────────────────────────────╯

rest elapsed, phone in a pocket
 ⌐ Rest over · Seated Machine Rows 3 of 3 ¬   ← local notification, not a
                                                foreground timer

timed (plank seconds, treadmill minutes) — always needs a Start
 ╭────────────────────────────────────────╮
 │             ▶  Start set 1             │
 ╰────────────────────────────────────────╯

timed set running — counts down the SECONDS/MINUTES tile; ± moves the finish
 ╭▒▒▒▒▒▒▒▒▒▒▒▒────────────────────╮ ╭──────╮
 │             ✓  End set 1       │ │  ×   │  ← × cancels, nothing logged
 │▒▒▒▒▒▒▒▒▒▒▒▒    00:00:32        │ │      │
 ╰▒▒▒▒▒▒▒▒▒▒▒▒────────────────────╯ ╰──────╯

time's up
 ╭▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╮ ╭──────╮
 │             ✓  End set 1       │ │  ×   │  ← green, keeps counting over;
 │      Time's up +00:00:12       │ │      │     never ends by itself
 ╰▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╯ ╰──────╯
 ⌐ Time's up · Plank 1 of 3 ¬   ← locked phone

last set of an exercise
 │       ✓  End set & next exercise       │

last set of the last exercise
 │          ✓  End set & finish           │  ← opens the summary directly

first ever time
  ○ ○ ○  Set 1 of 3               LAST TIME
                                          —

exercise with no load (bodyweight, band)
 │ (−)                12               (+) │  ← weight tile gone; reps takes
 │                   REPS                    │     the row, not a disabled "0.0"

no muscles listed — no map, the space stays empty

treadmill — minutes, and incline instead of weight
 │ (−)   20    (+)   │ │ (−)   8.5   (+)  │  ← ± 1 min · incline steps
 │     MINUTES       │ │    INCLINE %     │     and clamps 0–30%
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

 type — tap a tile's number; 50 → 135 isn't a job for ±
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
            Weight (lb)  ± 10 lb
  ( − )            135|            ( + )     ← keypad up at once, Set

 long-press the big button, 2+ sets left
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
 │ ( Keep in background )               │  ← hides the screen, keeps
 │ ( Save & exit )                      │     the session and its clocks
 │ ( Discard )!                         │
 │ ( Keep going )                       │
 └──────────────────────────────────────┘

 × with nothing logged
 ┌──────────────────────────────────────┐
 │ Leave?                               │
 │ Nothing was logged, so nothing will  │
 │ be saved.                            │
 │ ( Keep in background )               │
 │ ( Leave )!          ( Keep going )   │
 └──────────────────────────────────────┘

 kept in background — at the bottom of every screen
 ╭────────────────────────────────────────╮
 │ Fraiser Heights            ⏱ 00:00:28 ⌃│  ← live clock: set, rest, or
 │ Seated Machine Rows · Set 2 of 3       │     elapsed; tap opens Session
 ╰────────────────────────────────────────╯
 [ Train ][ Exercises ][ Progress ][ Settings ]

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
| `[[ ▶ Start set ]]` | tap | ends rest, starts the set's clock (counts down if timed) |
| `[[ ✓ End set ]]` | tap | writes the log with its start, starts rest, advances the counter |
| big button | long-press | log several identical sets, for warm-ups |
| value number | tap | keypad sheet to type it |
| `( + ) / ( − )` weight | tap | one real increment of *that* equipment |
| `( + ) / ( − )` | press-hold | repeats, accelerating every five steps |
| `Set 2 of 3 ⌄` | tap | change-sets row; can't drop below what's logged |
| `( ▶\| Skip )` | tap | skip to the next exercise; anything logged stays logged |
| `(◀\|)` Back | tap | the last unfinished exercise left by skip, jump or finishing a line; un-skips it |
| `(≡)` / `Next …` | tap | jump sheet |
| jump-sheet row | tap | jumps straight to it |
| `(×)` beside a started set | tap | cancels the clock, nothing logged |
| `+30s` beside rest | tap | extends rest, keeping the time already rested |
| `(×)` top-left | tap | exit dialog above |
| `Keep in background` | tap | Session hides; mini bar at the bottom |
| mini bar | tap | back to Session |

## Copy

| Key | String |
|---|---|
| `session.endSet` | End set {n} |
| `session.endSet.next` | End set & next exercise |
| `session.endSet.final` | End set & finish |
| `session.resting` | Rest {time} |
| `session.set` | Set {n} of {total} |
| `session.lastTime` | LAST TIME / {reps} × {weight} |
| `session.lastTime.none` | — |
| `session.skip` | Skip |
| `session.back` | Back |
| `session.next` | Next {exercise} {sets} × {reps} · {weight} |
| `session.start` | Start set {n} |
| `session.timeUp` | Time's up |
| `session.timeUp.notification` | Time's up · {exercise} {n} of {total} |
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
| `session.background` | Keep in background |
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
