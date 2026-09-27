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
| Train · Workout detail · Add exercises | tab, pushed pages | [`uiux/workouts.md`](uiux/workouts.md) |
| Exercises (♥ filter) · Exercise detail · Editor | tab, pushed page, sheet | [`uiux/exercises.md`](uiux/exercises.md) |
| Progress · Session log · Trend | tab, pushed pages | [`uiux/logs.md`](uiux/logs.md) |
| Settings · About | tab, pushed page | [`uiux/settings.md`](uiux/settings.md) |
| Components | reused parts | [`uiux/components.md`](uiux/components.md) |

Four tabs, Train first: the tab you open is the one that starts a workout.
Favourites is a `♥` chip at the head of the Exercises filter row, not a tab —
it's the library with a filter, so it lives in the same list and drawing.

Look: neutral system surfaces, cards with 20pt corners, one accent (ember
orange). Colour means "you can act on this"; everything else is grey.

## Screen map

```
      Launch
        │
        ▼
 ┌─────────┬───────────┬──────────┬──────────┐
 │  Train  │ Exercises │ Progress │ Settings │
 └─────────┴───────────┴──────────┴──────────┘
      │          │           │          │
      │          │           │          ├─▶ Units · Rest (in place)
      │          │           │          ├─▶ Export ─▶ [share] · Import ─▶ [picker]
      │          │           │          └─▶ About
      │          │           │
      │          │           ├─▶ Session log ─▶ Trend ─▶ Exercise detail
      │          │           └─▶ [share] CSV
      │          │
      │          ├─▶ ♥ filter (in place)
      │          ├─▶ Exercise detail ─▶ Trend · Session log · Workout detail
      │          └─▶ New exercise (sheet)
      │
      ├─▶ Workout detail ─┬─▶ Add exercises ─▶ New exercise (sheet)
      │                   └─▶ Edit line (in place)
      │
      └─▶ ▶ Start / Resume ═════▶ ┏━━━━━━━━━━━━━┓
                                  ┃   SESSION   ┃
                                  ┗━━━━━━━━━━━━━┛
                                        │
                       ┌────────────────┼───────────────┐
                       ▼                ▼               ▼
                   ≡ Jump to     Keypad (sheet)   Finish ─▶ Summary

 [brackets] = OS-owned surface    ═══ = full-screen cover, tabs hidden
```

## The flow that the app is for

Log a set. It happens fifty times a workout and it is one tap:

```
   set in progress            tap [[ ✓ Log set ]]        resting
 ┌──────────────────┐       ┌──────────────────┐     ┌──────────────────┐
 │ ●○○ Set 2 of 3   │       │   written to the │     │ ●●○ Set 3 of 3   │
 │ (−)   10    (+)  │  ──▶  │   log as-is, the │ ──▶ │ (−)   10    (+)  │
 │ (−)  50.0   (+)  │       │   plan untouched │     │ (−)  50.0   (+)  │
 │                  │       └──────────────────┘     │ ◷ Rest 00:00:58  │
 │ [[ ✓ Log set ]]  │                                │ [[ ✓ Log set ]]  │
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
  last set of last one ──▶ Summary sheet ──▶ ( Discard )! [[ Save ]]
                                                  │
                                         "Discard this workout?"
                                          asked once more
```

## Cross-screen states

Drawn per screen; these are the rules behind them.

```
empty      no workouts     → "Build a workout" invitation, not a blank list
           no logs yet     → Progress says what will appear, → Train
           no favourites   → "Show all exercises", doesn't scold
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
- Rest and elapsed share one format (`00:00:28`) so they read as a pair;
  finished durations drop to `42:18`.

Full strings live per screen, under each drawing's `Copy` table.

## Deviations from the `uiux` skill

- **60pt minimum tap target** for anything touched mid-set, against the usual
  44pt. The skill's figure assumes a dry finger and a steady hand; this app is
  used with neither. Everywhere outside the Session screen, 44pt stands.
- **Four tabs, not the reference app's five.** The earlier plan kept five
  (Exercises · Favourites · Workouts · Logs & Graphs · Settings) for muscle
  memory. Favourites was the library with a filter, so it became a `♥` chip in
  Exercises; Train moved first because starting a workout is why you open the
  app. Fewer tabs, and each one a distinct job.
- Otherwise none. Two of its mobile rules are load-bearing and cited where used:
  the **in-place unfolding picker** for the workout line editor
  ([`uiux/workouts.md`](uiux/workouts.md)) and **explanations behind an ⓘ** in
  Settings ([`uiux/settings.md`](uiux/settings.md)).
