# Session

A workout being performed. Full-screen cover — the tab bar is gone, because
nothing else is happening for the next hour.

This is the screen the app exists for. Everything on it is sized by how often
it gets touched: **log a set** fifty times a workout, **± reps/weight** a few
times, everything else almost never.

```
  Exit      Fraiser Heights      00:14:22
 ──────────────────────────────────────────
  ≡   Seated Machine Rows            ▶|
      Back · Machine
 ──────────────────────────────────────────
  SET 2 of 3          last time: 10 × 50 lb
 ──────────────────────────────────────────


          10                50.0
         REPS                LB

      [  −  ] [  +  ]   [  −  ] [  +  ]      ← 60pt targets, machine = 10 lb
                                               a tap, not a flat 1

 ╭────────────────────────────────────────╮
 │           LOG SET  ·  2 of 3           │  ← full width, thumb zone
 ╰────────────────────────────────────────╯
 ──────────────────────────────────────────
  UP NEXT
  Lat Pull Downs        3 × 10 · 50 lb   ›
  Seated Leg Curls      3 × 10 · 50 lb   ›
  Seated Machine Press  3 × 10 · 40 lb   ›
```

Reached from: ▶ on a workout ([`workouts.md`](workouts.md)) · resuming an
unfinished session on launch

## States

```
resting — the bar appears ABOVE the button and never replaces it
 ╭────────────────────────────────────────╮
 │ RESTING  00:00:28 [███░░░░░░] +30s   × │
 ╰────────────────────────────────────────╯
 ╭────────────────────────────────────────╮
 │           LOG SET  ·  3 of 3           │  ← still live: starting early
 ╰────────────────────────────────────────╯     is a legitimate choice

rest elapsed, phone in a pocket
 ⌐ Rest over · Seated Machine Rows 3 of 3 ¬   ← local notification, not a
                                                foreground timer

first ever time
  SET 1 of 3                  last time: —

last set of the last exercise
 ╭────────────────────────────────────────╮
 │        LOG SET  ·  FINISH WORKOUT      │
 ╰────────────────────────────────────────╯

exercise with no load (bodyweight, band)
          12
         REPS                                 ← weight column gone entirely,
      [  −  ] [  +  ]                           not a disabled "0.0"

progression offer, shown once per exercise per session
  SET 1 of 3          last time: 10 × 50 lb
  ⌐ Hit all 3 × 10 last time. Try 60 lb? ¬
                        ( No )   ( Use 60 )

at risk of stranding sets
  CHANGE SETS                                 ← 2 already logged
  [ 1 ]·  [ 2 ]  [ 3 ]  [ 4 ]  [ 5 ]            1 is disabled, not hidden

skipped exercise, seen in the ≡ list
  ✓ Walking              1 × 5 · 3 lb
    Seated Machine Rows  2 of 3           ●    ← ● = where you are
    Lat Pull Downs       skipped
```

## Overlays

```
 ≡ exercise list — jump anywhere, the rack you wanted is busy
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
  Jump to                              Done
  ✓ Walking               1 × 5 · 3 lb
  ● Seated Machine Rows   2 of 3 done
    Lat Pull Downs        3 × 10 · 50 lb
    Seated Leg Curls      3 × 10 · 50 lb

 Exit, with sets logged
 ┌──────────────────────────────────────┐
 │ Finish this workout?                 │
 │ 7 sets logged, 14 minutes.           │
 │ ( Keep going )                       │
 │ ( Discard )!        [[ Save & exit ]]│
 └──────────────────────────────────────┘

 Exit, nothing logged
 ┌──────────────────────────────────────┐
 │ Leave? Nothing was logged, so        │
 │ nothing will be saved.               │
 │ ( Keep going )       [[ Leave ]]     │
 └──────────────────────────────────────┘

 Summary, after the last set
 ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
  Fraiser Heights            42:18
  11 sets · 3,240 lb moved
  ★ Lat Pull Downs 60 lb × 10 — best yet
  ─────────────────────────────────────
  Weights differed from the plan on 2
  lines. Update the workout?
  ( Leave the plan )     ( Update it )
  ─────────────────────────────────────
  ( Discard )!            [[ Save ]]
```

## Interactions

| Target | Action | Result |
|---|---|---|
| `[[ LOG SET ]]` | tap | writes the log, starts rest, advances the counter |
| `[[ LOG SET ]]` | long-press | log several sets at once, for warm-ups |
| `[ + ] / [ − ]` weight | tap | one real increment of *that* equipment |
| `[ + ] / [ − ]` weight | press-hold | repeats, accelerating |
| reps / weight number | tap | keypad, for when ± is the wrong tool |
| `SET 2 of 3` | tap | the change-sets row, can't drop below what's logged |
| `▶\|` | tap | skip to the next exercise; anything logged stays logged |
| `≡` | tap | jump sheet |
| `UP NEXT` row | tap | jumps straight to it |
| `+30s` | tap | extends rest, keeping the time already rested |
| `×` on rest | tap | dismiss, no penalty, no confirm |
| `Exit` | tap | confirm sheet above |

## Copy

| Key | String |
|---|---|
| `session.logSet` | LOG SET · {n} of {total} |
| `session.logSet.final` | LOG SET · FINISH WORKOUT |
| `session.set` | SET {n} of {total} |
| `session.lastTime` | last time: {reps} × {weight} |
| `session.lastTime.none` | last time: — |
| `session.resting` | RESTING |
| `session.restOver` | Rest over · {exercise} {n} of {total} |
| `session.extend` | +30s |
| `session.upNext` | UP NEXT |
| `session.jump` | Jump to |
| `session.skipped` | skipped |
| `session.progression` | Hit all {sets} × {reps} last time. Try {weight}? |
| `session.exit.some` | {n} sets logged, {m} minutes. |
| `session.exit.none` | Leave? Nothing was logged, so nothing will be saved. |
| `session.summary.volume` | {n} sets · {volume} moved |
| `session.summary.pr` | ★ {exercise} {weight} × {reps} — best yet |
| `session.summary.drift` | Weights differed from the plan on {n} lines. Update the workout? |

## Notes

**`last time:` is the whole reason to open an app instead of using paper.** It's
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
