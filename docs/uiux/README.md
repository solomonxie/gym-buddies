# Screens

Drawings for every surface. Overview, flows, and cross-screen rules are one
level up in [`../UIUX_DESIGN.md`](../UIUX_DESIGN.md).

```
   TRAIN  (the only root, no tab bar)
      │
      ├─ [Exercises] ▶ Exercises
      ├─ [Gyms] ─────▶ Gyms
      ├─ [Progress] ─▶ Progress
      ├─ [Settings] ─▶ Settings   (last row on the page)
      ▶ Start ═════▶  SESSION  (full screen)
```

| File | Surface |
|---|---|
| [`session.md`](session.md) | the active workout — the screen the app is for |
| [`workouts.md`](workouts.md) | Train: up next, workouts, templates, workout detail, add exercises |
| [`exercises.md`](exercises.md) | library, favourites section, exercise detail, editor |
| [`gyms.md`](gyms.md) | Gyms: open now, gym editor |
| [`logs.md`](logs.md) | Progress: stats, history, session log, per-exercise trend |
| [`settings.md`](settings.md) | settings and its children |
| [`components.md`](components.md) | reused parts, all variants |

## Glyphs used here

Full alphabet in the `uiux` skill's `references/notation.md`. This app leans on:

```
[[ End set ]]  the one filled accent button      ›  pushes a screen
( Skip )       soft / secondary button           ✓  done
(×) (≡) (▶)    round icon button                 ≡  jump to any exercise
╭─╮ ╰─╯        a card, 20pt corners              ⓘ  popover with the long text
▒▒▒ on a border  clock fill, the ring unrolled    [▣] equipment glyph tile
(♡) / [♥]      chip off / on                     ▶|  skip this exercise
!  destructive                                   ⌐ … ¬  toast
3 × 10 · 50 lb   sets × reps · load — the app's one compact number format
```

Width: 43 columns inside every frame, so stacked mocks compare column by column.
