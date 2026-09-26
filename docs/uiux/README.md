# Screens

Drawings for every surface. Overview, flows, and cross-screen rules are one
level up in [`../UIUX_DESIGN.md`](../UIUX_DESIGN.md).

```
 ┌──────────┬────────────┬──────────┬───────────────┬──────────┐
 │ Exercises│ Favourites │ Workouts │ Logs & Graphs │ Settings │
 └──────────┴────────────┴──────────┴───────────────┴──────────┘
      └───────────┴────────────┼─────────────┴────────────┘
                               │
                     ▶ Start ══╧══▶  SESSION  (full screen, tabs hidden)
```

| File | Surface |
|---|---|
| [`session.md`](session.md) | the active workout — the screen the app is for |
| [`workouts.md`](workouts.md) | workouts list, workout detail, add exercise |
| [`exercises.md`](exercises.md) | library, favourites, exercise detail |
| [`logs.md`](logs.md) | history, session log, per-exercise trend |
| [`settings.md`](settings.md) | settings and its children |
| [`components.md`](components.md) | reused parts, all variants |

## Glyphs used here

Full alphabet in the `uiux` skill's `references/notation.md`. This app leans on:

```
[[ LOG SET ]]  the primary, thumb-zone action    ›  pushes a screen
[████░░░░░░]   rest ring, drawn as a bar here    ✓  done
▶|  skip this exercise                           ≡  jump to any exercise
×  dismiss                                       ⓘ  popover with the long text
!  destructive                                   ⌐ … ¬  toast
3 × 10 · 50 lb   sets × reps · load — the app's one compact number format
```

Width: 43 columns inside every frame, so stacked mocks compare column by column.
