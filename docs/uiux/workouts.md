# Train

The workouts you've built, what's in each one, and how exercises get added.
First tab — the one you open to start training.

```
  Train                                   +
 ╭────────────────────────────────────────╮
 │ UP NEXT                                │  ← least recently done: a
 │ Fraiser Heights                        │     rotation without asking
 │ 6 exercises · ~45 min · last 6 days ago│     for one
 │                                        │
 │ Walking                   1 × 5 · 3 lb │
 │ Seated Machine Rows     3 × 10 · 50 lb │
 │ Lat Pull Downs          3 × 10 · 50 lb │
 │ Seated Leg Curls        3 × 10 · 50 lb │
 │ + 2 more                               │
 │ ╭────────────────────────────────────╮ │
 │ │              ▶  Start              │ │
 │ ╰────────────────────────────────────╯ │
 ╰────────────────────────────────────────╯
  WORKOUTS
 ╭────────────────────────────────────────╮
 │ Fraiser Heights                   (▶)  │
 │ 6 exercises · ~45 min                  │
 │ Last done 6 days ago                   │
 ╰────────────────────────────────────────╯
 ╭────────────────────────────────────────╮
 │ Push Day                          (▶)  │
 │ 5 exercises · ~40 min                  │
 │ Last done 3 days ago                   │
 ╰────────────────────────────────────────╯
 ╭────────────────────────────────────────╮
 │ Legs                              (▶)  │
 │ 1 exercise · ~4 min                    │
 │ Never done                             │
 ╰────────────────────────────────────────╯
```

Reached from: tab bar

## Workout detail

```
 ‹ Train      Fraiser Heights       ⋯   +
 ╭────────────────────────────────────────╮
 │           ▶  Start workout             │  ← the reason you're here,
 ╰────────────────────────────────────────╯     not a small icon in a bar
  GYMS
 ╭────────────────────────────────────────╮
 │ ✓ Home                                 │  ← tap to toggle; none ticked
 │   No barbell, machine                  │     means anywhere
 │ ✓ Anytime Fitness                      │
 │ ○ City Pool                            │
 ╰────────────────────────────────────────╯
  6 EXERCISES · ~45 MIN · 18 SETS
 ╭────────────────────────────────────────╮
 │ [▣] Walking                         ☰  │
 │     Cardio · 1 × 5 · 3 lb              │
 │ [▣] Seated Machine Rows             ☰  │
 │     Back · 3 × 10 · 50 lb              │
 │ [▣] Lat Pull Downs                  ☰  │
 │     Back · 3 × 10 · 50 lb · rest 90s   │
 │ [▣] Seated Leg Curls                ☰  │
 │     Legs · 3 × 10 · 50 lb              │
 │ [▣] Seated Machine Presses          ☰  │
 │     Shoulders · 3 × 10 · 40 lb         │
 │ [▣] Planking                        ☰  │
 │     Core · 3 × 60s                     │
 │ ⊕ Add exercises                        │
 ╰────────────────────────────────────────╯
  Tap to edit · hold and drag ☰ to reorder
```

`[▣]` is the equipment glyph on an accent-tinted tile — the row's only picture.
`☰` is a visible grip: order is the order you'll do them in, and it's meant to
be dragged.

## Editing a line — unfolds in place

Per the `uiux` skill (`references/mobile.md`): the row stays put, everything
below moves down. Nothing gets covered, so there's nothing to dismiss.

```
      tap the row                 unfolded in place
 ┌────────────────────────┐   ┌────────────────────────┐
 │ Lat Pull Downs       ☰ │   │ Lat Pull Downs       ☰ │
 │ Back · 3 × 10 · 50 lb  │   │┌──────────────────────┐│
 ├────────────────────────┤ → ││ Sets     [−]  3  [+] ││
 │ Seated Leg Curls     ☰ │   ││ Counted in    Reps ⌄ ││  ← this line only: Air Bike
 │ Legs · 3 × 10 · 50 lb  │   ││ Reps     [−] 10  [+] ││     in minutes here, reps
 └────────────────────────┘   ││ Weight   [−] 50  [+] ││     elsewhere; switching
                              ││  lb, 10 lb a tap     ││     resets the target
                              ││ Pool          25 m ⌄ ││  ← swim lines only: 15/20/
                              ││ Rest   Default (60s)⌄││     25 m, 25 yd, 33⅓/50 m
                              ││ Remove!              ││
                              │└──────────────────────┘│
                              │ Seated Leg Curls     ☰ │
                              └────────────────────────┘
```

Swim lines count in laps or minutes (never reps), and read
`8 × 2 laps · 25 m pool`.

## New workout — blank or from a template

`+` on Train, or Build a workout, opens this sheet.

```
  Cancel        New workout
  [ Name                    ] [[ Create ]]  ← blank, as before
  GYM BASICS
  Light Gym · 30 min                     ›
  STRENGTH
  Muscle Building · Upper                ›
  Muscle Building · Lower                ›
  Core Strength                          ›
  AROUND THE WORKDAY
  Pre-Work Wake-Up · 15 min              ›
  Lunch Break · 30 min                   ›
  After Work · Desk Reset                ›
  Leisure · Easy Movement                ›
  SPORT
  Baseball · Off-Season                  ›
  SWIM
  Swim · Freestyle Endurance             ›
  Swim · Four Strokes                    ›
  PREGNANCY
  Pregnancy · Gentle Strength            ›
  Pregnancy · Pool                       ›
```

Each row: name, then the one-line summary and `~{n} min` under it.

```
 ‹ New workout   Lunch Break · 30 min
  Dumbbell full body that fits a lunch
  hour, moderate enough to skip the long
  shower.
  · Moderate effort keeps the sweat down…   ← the template's reasons
  · One rack of dumbbells covers all of it
  6 EXERCISES · ~28 MIN
  Stationary Bike         1 × 5 min · rest 30s
  Goblet Squats     3 × 10 · 16 kg · rest 60s
  ⋮
  Pool                            25 m ⌄   ← swim templates only
  Starting loads — adjust to you.
 ╭────────────────────────────────────────╮
 │            [[ Add workout ]]           │
 ╰────────────────────────────────────────╯
```

Add creates an ordinary workout: every number editable, nothing linked back
to the template.

## Add exercises

```
 ‹ Back     Add to Fraiser Heights
  ┌──────────────────────────────────────┐
  │ 🔍 Search                            │
  └──────────────────────────────────────┘
  ( All ) ( Arms ) ( Back ) ( Chest ) …     ← scrolls horizontally
 ╭────────────────────────────────────────╮
 │ ◉ Barbell Curls   ♥   Arms · Barbell   │  ← favourites sort first
 │ ○ Cable Tricep Extensions Arms · Cable │
 │ ◉ Dumbbell Hammer Curls Arms · Dumbbell│
 │ ○ Bench Spider Curls  Arms · Barbell   │
 │   ⋮                                    │
 ╰────────────────────────────────────────╯
  2 selected               [[ Add 2 ]]       ← only while something's picked
```

Multi-select, because nobody adds exactly one exercise. Added lines take the
default 3 sets, and the reps and weight from the last time you did that
movement — a brand-new one starts at 10 reps and no load.

## States

```
no workouts
 ┌────────────────────────────────────────┐
 │           Nothing built yet            │
 │  A workout is a list of exercises in   │
 │  the order you'll do them.             │
 │        [[ Build a workout ]]           │
 └────────────────────────────────────────┘


empty workout
 │           ▶  Start workout·            │  ← disabled
  Add an exercise to start.

session running — Train swaps UP NEXT for this
 ╭────────────────────────────────────────╮
 │ IN PROGRESS                            │
 │ Fraiser Heights                        │
 │ 7 sets logged · 00:14:22               │
 │ ╭────────────────────────────────────╮ │
 │ │             ↻  Resume              │ │
 │ ╰────────────────────────────────────╯ │
 ╰────────────────────────────────────────╯
 │ Push Day                          (▶)· │  ← other ▶s grey: one session
                                              at a time

another workout's detail, mid-session
 │           ▶  Start workout·            │
  "Fraiser Heights" is still running.

search finds nothing
  No exercise called "beep test".
  ( Create it )                           ← custom exercises are the escape hatch

deleting
 ┌──────────────────────────────────────┐
 │ Delete "Fraiser Heights"?            │
 │ The 8 sessions you logged from it    │
 │ are kept.                            │
 │  ( Cancel )        ( Delete )!       │
 └──────────────────────────────────────┘
  never done → "It has never been done, so
  no history is affected."

long name
 │ [▣] Seated Cable Row with Wide…     ☰  │
```

## Interactions

| Target | Action | Result |
|---|---|---|
| `Start` / card `(▶)` | tap | straight into [`session.md`](session.md), no detail stop |
| card or hero body | tap | → workout detail |
| `+` on Train | tap | new-workout sheet: blank or a template |
| template row | tap | → preview; `Add workout` creates it and closes |
| gym row in detail | tap | ticks / unticks that gym |
| `☰` | hold & drag | reorder; saved on drop, no Done button |
| row | tap | unfolds the editor in place |
| row | swipe ← | `[ Delete ]`! |
| `⋯` | tap | `Rename` `Duplicate` `Export…` `Delete`! |
| `+` / `⊕ Add exercises` | tap | → add exercises, multi-select |
| chip row | tap | filters the list, `All` clears |

## Copy

| Key | String |
|---|---|
| `train.upNext` | UP NEXT |
| `train.inProgress` | IN PROGRESS |
| `train.heroSummary` | {n} exercises · ~{minutes} min · last {n} days ago |
| `train.more` | + {n} more |
| `train.progress` | {n} sets logged · {elapsed} |
| `workouts.header` | WORKOUTS |
| `workouts.summary` | {n} exercises · ~{minutes} min |
| `workouts.lastDone` | Last done {n} days ago |
| `workouts.neverDone` | Never done |
| `workouts.empty` | A workout is a list of exercises in the order you'll do them. |
| `workout.start` | Start |
| `workout.startFull` | Start workout |
| `workout.resume` | Resume |
| `workout.header` | {n} exercises · ~{minutes} min · {sets} sets |
| `workout.line` | {group} · {sets} × {reps} · {weight} |
| `workout.lineWithRest` | {group} · {sets} × {reps} · {weight} · rest {n}s |
| `workout.gyms` | GYMS |
| `workout.missing` | No {equipment list} |
| `template.caveat` | Starting loads — adjust to you. |
| `template.add` | Add workout |
| `workout.hint` | Tap to edit · hold and drag ☰ to reorder |
| `workout.cantStart.empty` | Add an exercise to start. |
| `workout.cantStart.busy` | "{name}" is still running. |
| `workout.delete` | The {n} sessions you logged from it are kept. |
| `add.selected` | {n} selected |
| `add.noResults` | No exercise called "{query}". |

## Notes

The hero card answers "what am I doing today?" before it's asked. It picks the
least recently done workout, so a three-way split rotates on its own.

`▶` on every card, not just inside the detail screen: the common case is "do
the thing I did last Tuesday", and that shouldn't cost a screen transition.

Deleting a workout keeps its logged sessions. History is a record of what you
did, and it doesn't stop being true because you reorganised your plan.

`~45 min` is the average of the last five logged sessions of this workout.
Before there is one, it's planned: sets × (40s work + rest).
