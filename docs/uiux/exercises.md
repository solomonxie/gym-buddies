# Exercises

The library, pushed from its tile on Train. Favourites head the same list.

```
  Exercises                               +
  ┌──────────────────────────────────────┐
  │ 🔍 Search 180 exercises              │  ← always shown, not pulled
  └──────────────────────────────────────┘     down
  FAVOURITES                              5  ← only once something is ♥'d
 ╭────────────────────────────────────────╮
 │ [▣] Barbell Deadlifts            ♥   › │
 │     Barbell                            │
 │ [▣] Pull Ups                     ♥   › │
 │     Bodyweight                         │
 │ [▣] Barbell Bench Press          ♥   › │
 │     Barbell                            │
 │ Show 2 more                            │  ← 3 rows until opened
 ╰────────────────────────────────────────╯
  BACK                                   14
 ╭────────────────────────────────────────╮
 │ [▣] Barbell Deadlifts            ♥   › │
 │     Barbell                            │
 │ [▣] Lat Pull Downs               ♡   › │  ← ♡ faint until tapped
 │     Machine                            │
 │ [▣] Pull Ups                     ♥   › │
 │     Bodyweight                         │
 │ Show 11 more                           │  ← opened: every row, then
 ╰────────────────────────────────────────╯     "Show fewer"
   ⋮
```

Reached from: the Exercises tile on Train, or Settings → Your data. Detail also opens from a trend's `ⓘ`.

Grouped by muscle group, because that is how people decide what to do next.
Each group shows 3 rows so every group fits a scroll or two; no chip row —
the headers are the index. Search matches name or equipment and opens every
group. Favourites are the same rows, repeated in a section on top.

## Exercise detail

```
 ‹ Exercises     Lat Pull Downs       ♥  ⋯
 ──────────────────────────────────────────
        ┌───────┐   ┌───────┐
        │ front │   │ back  │                ← muscle map, primary muscle
        │  ░▓░  │   │  ▓▓▓  │                   strong, secondary faint;
        └───────┘   └───────┘ (▣)             (▣) equipment badge
  Back · Machine · 10 lb a step
 ──────────────────────────────────────────
  Your best                     60 lb × 10
  Last done          3 days ago, 50 lb   ›
 ──────────────────────────────────────────
  [ Top set | Volume | Reps ]
  60 lb  Thu 18 Sep                          ← readout follows the finger
  70 ┤                            ●
  60 ┤                  ●────●
  50 ┤   ●────●────●
     └──────────────────────────────────
      Jul       Aug       Sep
  Every session                          ›
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
  Fraiser Heights        3 × 10 · 50 lb  ›
  Pull Day                4 × 8 · 55 lb  ›
```

## New / edit exercise — sheet

```
 ( Cancel )     New exercise        ( Save )  ← Save off until named
 ──────────────────────────────────────────
  Name              Beep Test
  Muscle group      Cardio               ⌄
  Equipment         Bodyweight           ⌄
  Held for time                         ○─
  + adds 2.5 lb a tap.                       ← "No weight is tracked for
 ──────────────────────────────────────────     this equipment." for bands
  MUSCLES WORKED
  Quads                     primary      ✓   ← first picked is primary
  Glutes                    secondary    ✓
  Hamstrings
  ⋮
 ──────────────────────────────────────────
  HOW TO
  One step per line
  Optional. Three lines covering what
  people get wrong is plenty.
```

## States

```
no favourites
  No FAVOURITES section at all — nothing to scold.

never performed
  Your best                              —
  Last done                              —
  ┌──────────────────────────────────────┐
  │   Do it once and the graph starts.   │
  └──────────────────────────────────────┘

one session only
  60 ┤        ●                            ← one point, no line, no trend claim
     └──────────────────────────────────

custom exercise
  Cardio · Bodyweight · yours
  ⋯ → Edit · Add to workout…
      Reset history! · Delete exercise!

no muscles listed
            ┌─────┐
            │ [▣] │                        ← the equipment glyph, large;
            └─────┘                           never a broken-image box

search, no match
  No exercise called "beep test".
  ( Create it )                            ← opens the sheet, name filled in

group empty
  Nothing in this group yet.
  ( Create it )
```

## Interactions

| Target | Action | Result |
|---|---|---|
| row | tap | → exercise detail |
| `♥` | tap | toggles favourite in place, no navigation |
| row | swipe ← | `[ ♥ Favourite ]` `[ Add to workout… ]` |
| `Show N more` / `Show fewer` | tap | opens / folds that section in place |
| metric segment | tap | redraws the chart; remembered, shared with Trend |
| chart | drag | value and date readout follows the finger |
| `Last done` | tap | → that session log ([`logs.md`](logs.md)) |
| `Every session` | tap | → trend |
| `IN n WORKOUTS` row | tap | → that workout |
| `⋯` | tap | `Edit`* `Add to workout…` `Reset history`! `Delete exercise`!* (*custom only) |
| `+` | tap | new-exercise sheet |

## Copy

| Key | String |
|---|---|
| `exercises.searchPlaceholder` | Search {n} exercises |
| `exercise.row.custom` | {equipment} · yours |
| `exercise.subtitle` | {group} · {equipment} · {increment} a step |
| `exercise.best` | Your best |
| `exercise.lastDone` | {n} days ago, {weight} |
| `exercise.neverDone` | Do it once and the graph starts. |
| `exercise.every` | Every session |
| `exercise.howTo` | HOW TO |
| `exercise.inWorkouts` | IN {n} WORKOUTS |
| `exercise.addTo` | Add {exercise} to… |
| `exercise.addTo.none` | Build a workout first, on Train. |
| `exercise.reset` | {n} logged sets are removed. The sessions they were in are kept. |
| `exercise.delete` | It's removed from your workouts. Sets already logged stay in your history. |
| `editor.increment` | + adds {increment} a tap. |
| `editor.noLoad` | No weight is tracked for this equipment. |
| `editor.howTo.hint` | Optional. Three lines covering what people get wrong is plenty. |
| `library.more` | Show {n} more |
| `library.fewer` | Show fewer |

## Notes

`10 lb a step` in the subtitle is the app telling you what its `+` button will
do before you press it. It's also the only place the equipment model is visible,
and it makes an otherwise invisible design decision checkable.

The how-to is three steps and the three steps are the ones people get wrong. A
paragraph of anatomy would be padding — and getting it wrong on a deadlift is
worse than saying nothing, which is why unreviewed movements ship with the
section absent rather than filled in.

Muscle maps and equipment glyphs are drawn in code and SF Symbols — no licensed
artwork (see [`../DESIGN.md`](../DESIGN.md), Risks).
