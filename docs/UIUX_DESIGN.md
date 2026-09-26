# Interface: one screen matters, the rest is setup

Every screen is drawn in [`uiux/`](uiux/) — this file is the map, the flows, and
the rules that cross screens. Product reasoning is in [`DESIGN.md`](DESIGN.md).

Drawn against the `uiux` skill: `references/notation.md` for glyphs,
`references/text-figma.md` for the per-screen files, `references/mobile.md` for
gestures, in-place pickers, and the ⓘ rule.

## Screens & surfaces

| Surface | Kind | Drawing |
|---|---|---|
| **Session** (active workout) | full-screen cover | [`uiux/session.md`](uiux/session.md) |
| Exercises · Favourites · Exercise detail | tabs, pushed page | [`uiux/exercises.md`](uiux/exercises.md) |
| Workouts · Workout detail · Add exercise | tab, pushed pages | [`uiux/workouts.md`](uiux/workouts.md) |
| Logs & Graphs · Session log · Trend | tab, pushed pages | [`uiux/logs.md`](uiux/logs.md) |
| Settings and children | tab | [`uiux/settings.md`](uiux/settings.md) |
| Components | reused parts | [`uiux/components.md`](uiux/components.md) |

Five tabs, matching what the reference app established — this is a category
where people arrive with muscle memory from somewhere else, and moving Workouts
off the middle tab buys nothing.

Favourites is the library with a filter applied, not a second list, so it lives
in the same drawing file.

## Screen map

```
      Launch
        │
        ▼
 ┌──────────┬────────────┬──────────┬───────────────┬──────────┐
 │ Exercises│ Favourites │ Workouts │ Logs & Graphs │ Settings │
 └──────────┴────────────┴──────────┴───────────────┴──────────┘
      │           │            │             │            │
      └──▶ Exercise detail ◀───┤             │            ├─▶ Units
                               │             │            ├─▶ Rest defaults
                               │             │            └─▶ Backup ─▶ [share]
                               │             │
                               │             └─▶ Session log ─▶ Trend
                               │
                               ├─▶ Workout detail ─┬─▶ Add exercise
                               │                   └─▶ Edit line
                               │
                               └─▶ ▶ Start ═══════▶ ┏━━━━━━━━━━━━━┓
                                                    ┃   SESSION   ┃
                                                    ┗━━━━━━━━━━━━━┛
                                                          │
                                        ┌─────────────────┼──────────────┐
                                        ▼                 ▼              ▼
                                   Exercise list       Notes        Finish ─▶ Summary

 [brackets] = OS-owned surface    ═══ = full-screen cover, tabs hidden
```

## The flow that the app is for

Log a set. It happens fifty times a workout and it is one tap:

```
   set in progress            tap [[ LOG SET ]]          resting
 ┌──────────────────┐       ┌──────────────────┐     ┌──────────────────┐
 │   10      50.0   │       │   written to the │     │   10      50.0   │
 │  REPS      LB    │  ──▶  │   log as-is, the │ ──▶ │  REPS      LB    │
 │ [−][+]  [−][+]   │       │   plan untouched │     │ [−][+]  [−][+]   │
 │                  │       └──────────────────┘     │ RESTING 00:00:58 │
 │ [[ LOG SET 2/3 ]]│                                │ [[ LOG SET 3/3 ]]│
 └──────────────────┘                                └──────────────────┘
                                                      ↑ still tappable
```

**Resting never blocks logging.** The rest bar appears above the button, it
never replaces it — dropping straight into the next set is a legitimate choice
and the app has no business making you dismiss a timer first.

Finishing an exercise, and finishing the workout:

```
  last set of exercise ──▶ rest starts ──▶ next exercise loaded
                                            with ITS targets
  last set of last one ──▶ Summary sheet ──▶ ( Discard ) [[ Save ]]
                                                  │
                                            ⌐ Nothing saved ¬
```

## Cross-screen states

Drawn per screen; these are the rules behind them.

```
empty      no workouts     → "Build one" invitation, not a blank list
           no logs yet     → Logs shows what a graph will look like, greyed
           no favourites   → points at the library, doesn't scold
loading    none            → everything is a local SQLite read; a spinner
                             would be a lie
error      db unreadable   → one screen, "restore from a backup", never a
                             silent empty list
partial    exercise with   → weight controls hide entirely rather than
           no load            showing a disabled "0.0"
offline    always          → the word never appears; there is no network
```

## Copy rules

- **Numbers over words.** `3 × 10 · 50 lb` beats "3 sets of 10 reps at 50
  pounds" on a card read at arm's length.
- **Never congratulate.** No "Great job!", no confetti. The summary states what
  happened: sets, volume, duration, any personal record.
- Weights carry their unit every time they appear. A bare `50` in a log read six
  months later is worthless.
- A skipped exercise says **`skipped`**, never "failed" or "missed".
- Rest and elapsed share one format (`00:00:28`) so they read as a pair.

Full strings live per screen, under each drawing's `Copy` table.

## Deviations from the `uiux` skill

- **60pt minimum tap target** for anything touched mid-set, against the usual
  44pt. The skill's figure assumes a dry finger and a steady hand; this app is
  used with neither. Everywhere outside the Session screen, 44pt stands.
- Otherwise none. Two of its mobile rules are load-bearing and cited where used:
  the **in-place unfolding picker** for the workout line editor
  ([`uiux/workouts.md`](uiux/workouts.md)) and **explanations behind an ⓘ** in
  Settings ([`uiux/settings.md`](uiux/settings.md)).
