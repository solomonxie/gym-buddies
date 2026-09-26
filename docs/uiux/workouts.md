# Workouts

The workouts you've built, what's in each one, and how exercises get added.
Middle tab — the one you open to start training.

```
  Workouts                              +
 ──────────────────────────────────────────
 ╭────────────────────────────────────────╮
 │ Fraiser Heights                     ▶  │
 │ 6 exercises · ~45 min                  │
 │ last done 3 days ago                  ›│
 ├────────────────────────────────────────┤
 │ Push Day                            ▶  │
 │ 5 exercises · ~40 min                  │
 │ last done 6 days ago                  ›│
 ├────────────────────────────────────────┤
 │ Legs                                ▶  │
 │ 4 exercises · ~35 min                  │
 │ never done                            ›│
 ╰────────────────────────────────────────╯
```

Reached from: tab bar

## Workout detail

```
 ‹ Back    Fraiser Heights    ⋯    🗑    +
 ──────────────────────────────────────────
 ╭────────────────────────────────────────╮
 │            ▶  START WORKOUT            │  ← the reason you're here,
 ╰────────────────────────────────────────╯     not a small icon in a bar
 ──────────────────────────────────────────
  6 exercises · ~45 min · 18 sets
 ──────────────────────────────────────────
  ☰ Walking                             ›
    Cardio · 1 × 5 · 3 lb
 ──────────────────────────────────────────
  ☰ Seated Machine Rows                 ›
    Back · 3 × 10 · 50 lb
 ──────────────────────────────────────────
  ☰ Lat Pull Downs                      ›
    Back · 3 × 10 · 50 lb · rest 90s
 ──────────────────────────────────────────
  ☰ Seated Leg Curls                    ›
    Legs · 3 × 10 · 50 lb
 ──────────────────────────────────────────
  ☰ Seated Machine Presses              ›
    Shoulders · 3 × 10 · 40 lb
 ──────────────────────────────────────────
  ☰ Planking                            ›
    Core · 3 × 60s
 ──────────────────────────────────────────
  ( + Add an exercise )
```

`☰` is the drag handle; order is the order you'll do them in, and it's meant to
be dragged, so it gets a visible grip rather than a hidden long-press.

## Editing a line — unfolds in place

Per the `uiux` skill (`references/mobile.md`): the row stays put, everything
below moves down. Nothing gets covered, so there's nothing to dismiss.

```
      tap the row                 unfolded in place
 ┌────────────────────────┐   ┌────────────────────────┐
 │ ☰ Lat Pull Downs     › │   │ ☰ Lat Pull Downs     ⌄ │
 │   Back · 3 × 10 · 50 │   │┌──────────────────────┐│
 ├────────────────────────┤ → ││ Sets    [−]  3  [+]  ││
 │ ☰ Seated Leg Curls   › │   ││ Reps    [−] 10  [+]  ││
 │   Legs · 3 × 10 · 50 │   ││ Weight  [−] 50  [+]  ││  ← machine: 10 lb
 └────────────────────────┘   ││ Rest    [ 60 | 90 |  ││     a tap
                              ││          120 | ⌨ ]   ││
                              ││ ( Remove )!          ││
                              │└──────────────────────┘│
                              │ ☰ Seated Leg Curls   › │
                              └────────────────────────┘
```

## Add exercise

```
 ‹ Back    Add to Fraiser Heights     ✓
 ──────────────────────────────────────────
  ┌──────────────────────────────────────┐
  │ 🔍 Search                            │
  └──────────────────────────────────────┘
  [ ALL | Arms | Back | Chest | Legs | … ]  ← scrolls horizontally
 ──────────────────────────────────────────
  ✓ Barbell Curls            Arms · Bar
    Cable Tricep Extensions  Arms · Cable
  ✓ Dumbbell Hammer Curls    Arms · DB
    Bench Spider Curls       Arms · Bar
    Cable Preacher Curls     Arms · Cable
    ⋮
 ──────────────────────────────────────────
  2 selected               [[ Add 2 ]]
```

Multi-select, because nobody adds exactly one exercise. Added lines take the
app's default sets/reps and the weight from the last time you did that movement
— a brand-new exercise starts at an empty bar, not at zero.

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
  0 exercises
 ┌────────────────────────────────────────┐
 │   ( + Add an exercise )                │
 └────────────────────────────────────────┘
  ▶ START WORKOUT·        ← disabled, nothing to do

session already running
 ╭────────────────────────────────────────╮
 │  ▶  RESUME — Fraiser Heights  00:14:22 │
 ╰────────────────────────────────────────╯

search finds nothing
  No exercise called "beep test".
  ( Create it )                           ← custom exercises are the escape hatch

deleting
 ┌──────────────────────────────────────┐
 │ Delete "Fraiser Heights"?            │
 │ The 8 sessions you logged from it    │
 │ are kept.                            │
 │  ( Cancel )        [[ Delete ]]!     │
 └──────────────────────────────────────┘

long name
  ☰ Seated Cable Row with Wide…        ›
```

## Interactions

| Target | Action | Result |
|---|---|---|
| card `▶` | tap | straight into [`session.md`](session.md), no detail stop |
| card body | tap | → workout detail |
| `☰` | drag | reorder; saved on drop, no Done button |
| row | tap | unfolds the editor in place |
| row | swipe ← | `[ Remove ]`! |
| `⋯` | tap | `Duplicate` `Rename` `Export…` |
| `+` | tap | → add exercise, multi-select |
| chip row | tap | filters the list, `ALL` clears |

## Copy

| Key | String |
|---|---|
| `workouts.summary` | {n} exercises · ~{minutes} min |
| `workouts.lastDone` | last done {n} days ago |
| `workouts.neverDone` | never done |
| `workouts.empty` | A workout is a list of exercises in the order you'll do them. |
| `workout.start` | ▶ START WORKOUT |
| `workout.resume` | ▶ RESUME — {name} {elapsed} |
| `workout.line` | {group} · {sets} × {reps} · {weight} |
| `workout.lineWithRest` | {group} · {sets} × {reps} · {weight} · rest {n}s |
| `workout.delete` | The {n} sessions you logged from it are kept. |
| `add.selected` | {n} selected |
| `add.noResults` | No exercise called "{query}". |

## Notes

`▶` on the card, not just inside the detail screen: the common case is "do the
thing I did last Tuesday", and that shouldn't cost a screen transition.

Deleting a workout keeps its logged sessions. History is a record of what you
did, and it doesn't stop being true because you reorganised your plan.

`~45 min` is estimated from the logged sessions of this workout, not from sets
× rest. Once there's one real session, the estimate uses it.
