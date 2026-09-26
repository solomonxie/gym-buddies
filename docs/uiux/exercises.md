# Exercises & Favourites

The library. First tab, and the same list filtered is the second tab.

```
  Exercises                             +
 ──────────────────────────────────────────
  ┌──────────────────────────────────────┐
  │ 🔍 Search                            │
  └──────────────────────────────────────┘
  [ ALL | Arms | Back | Chest | Legs | … ]
 ──────────────────────────────────────────
  BACK                                  (4)
  Barbell Deadlifts        Barbell    ♥  ›
  Lat Pull Downs           Machine       ›
  Pull Ups                 Bodyweight ♥  ›
  Seated Machine Rows      Machine       ›
 ──────────────────────────────────────────
  CHEST                                 (3)
  Barbell Bench Press      Barbell    ♥  ›
  Dumbbell Flyes           Dumbbell      ›
  Push Ups                 Bodyweight    ›
  ⋮
```

Reached from: tab bar · `+` on a workout ([`workouts.md`](workouts.md))

Grouped by muscle group, because that is how people decide what to do next. The
chip row jumps and filters at once.

## Exercise detail

```
 ‹ Back     Lat Pull Downs       ♥    ⋯
 ──────────────────────────────────────────
  ┌──────────────────────────────────────┐
  │                                      │
  │        [ illustration ]              │  ← see ../DESIGN.md, Risks:
  │                                      │     artwork is a licensing
  └──────────────────────────────────────┘     question, not a drawing one
  Back · Machine · 10 lb a pin
 ──────────────────────────────────────────
  YOUR BEST                    60 lb × 10
  LAST DONE            3 days ago, 50 lb ›
 ──────────────────────────────────────────
  [ Top set | Volume | Reps ]
  70 ┤                            ●
  60 ┤                  ●    ●
  50 ┤   ●    ●    ●
     └──────────────────────────────────
      Jul       Aug       Sep
 ──────────────────────────────────────────
  HOW TO
  1. Set the thigh pad so you can't lift
     off the seat.
  2. Pull the bar to your collarbone, not
     behind your neck.
  3. Let it rise all the way up between
     reps.
 ──────────────────────────────────────────
  IN 2 WORKOUTS
  Fraiser Heights        3 × 10 · 50 lb ›
  Pull Day               4 × 8  · 55 lb ›
```

## Favourites

```
  Favourites
 ──────────────────────────────────────────
  BACK                                  (2)
  Barbell Deadlifts        Barbell    ♥  ›
  Pull Ups                 Bodyweight ♥  ›
 ──────────────────────────────────────────
  CHEST                                 (1)
  Barbell Bench Press      Barbell    ♥  ›
```

Same rows, same detail screen, same `♥` to remove. It is the library with a
filter, and building it as a second list would be two things to keep in step.

## States

```
no favourites
 ┌────────────────────────────────────────┐
 │         Nothing starred yet            │
 │  Tap ♥ on an exercise to keep it here. │
 │        ( Browse exercises )            │
 └────────────────────────────────────────┘

never performed
  YOUR BEST                            —
  LAST DONE                            —
  [ chart area ]
  Do it once and the graph starts.

one session only
  70 ┤
  60 ┤        ●                            ← one point, no line, no trend claim
  50 ┤
     └──────────────────────────────────

custom exercise
 ‹ Back     Beep Test         ♥    ⋯
  Cardio · Bodyweight · yours       ( Edit )

no artwork yet
  ┌──────────────────────────────────────┐
  │              🏋                       │  ← SF Symbol by equipment,
  └──────────────────────────────────────┘     never a broken-image box

search, no match
  No exercise called "beep test".
  ( Create it )
```

## Interactions

| Target | Action | Result |
|---|---|---|
| row | tap | → exercise detail |
| `♥` | tap | toggles favourite in place, no navigation |
| row | swipe ← | `[ ♥ ]` `[ Add to workout… ]` |
| chip | tap | filter; the section headers stay for scanning |
| metric segment | tap | redraws the chart, remembered per exercise |
| `LAST DONE` | tap | → that session log ([`logs.md`](logs.md)) |
| `IN 2 WORKOUTS` row | tap | → that workout |
| `⋯` | tap | `Edit` (custom only) `Add to workout…` `Reset history`! |
| `+` | tap | create a custom exercise |

## Copy

| Key | String |
|---|---|
| `exercises.searchPlaceholder` | Search |
| `exercise.subtitle` | {group} · {equipment} · {increment} a pin |
| `exercise.best` | YOUR BEST |
| `exercise.lastDone` | {n} days ago, {weight} |
| `exercise.neverDone` | Do it once and the graph starts. |
| `exercise.howTo` | HOW TO |
| `exercise.inWorkouts` | IN {n} WORKOUTS |
| `favourites.empty` | Tap ♥ on an exercise to keep it here. |

## Notes

`10 lb a pin` in the subtitle is the app telling you what its `+` button will
do before you press it. It's also the only place the equipment model is visible,
and it makes an otherwise invisible design decision checkable.

The how-to is three steps and the three steps are the ones people get wrong. A
paragraph of anatomy would be padding — and getting it wrong on a deadlift is
worse than saying nothing, which is why unreviewed movements ship with the
section absent rather than filled in.
