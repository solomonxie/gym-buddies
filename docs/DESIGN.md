# Design: a workout tracker for the thirty seconds between sets

Product/business reasoning only. Interface lives in [`UIUX_DESIGN.md`](UIUX_DESIGN.md),
build order in [`IMPLEMENT_PLAN.md`](IMPLEMENT_PLAN.md).

## Problem

Gym tracking apps are used in a specific, hostile situation: standing at a
machine, one hand on the bar, sweaty fingers, thirty seconds before the next
set, phone held at arm's length. Almost every one of them is designed as
though you're sitting down.

The reference app this is modelled on (screenshots in the repo's issue thread)
gets the data model right and the moment wrong:

- **The most frequent action in the whole app has no obvious control.** You log
  a set dozens of times per workout. On the active-workout screen the biggest,
  most colourful things are the reps and weight readouts; "I finished that set"
  isn't visibly anywhere.
- **Weight steps by a fixed amount.** A machine stack moves in 10 lb pins, a
  barbell in plate pairs, a dumbbell rack in 5 lb steps. One `+` for all three
  means counting taps.
- **Two ad slots**, one of which sits between the content and the tab bar and
  covers the last card in the list.

## Core idea

The active-workout screen is the product; everything else is setup for it. So
it gets designed first, around one rule: **the thing you do most is the biggest
thing on the screen, and it sits where your thumb already is.**

Everything behind it — the library, the workout builder, the graphs — is
ordinary, and being ordinary is fine.

## Goals

- Exercise library by muscle group, searchable, with favourites
- Build and reorder workouts: exercise, target sets, reps, weight, rest
- Run a workout: log each set in one tap, rest timer that survives a locked
  screen, skip and reorder mid-session
- Weight steps by what the equipment physically allows
- Logs & graphs: history, volume, personal records, per-exercise trend
- kg or lb, offline, no account, no ads, no subscription

## Non-goals

- **No ads, ever.** It's the reason this exists.
- No account, no server, no social feed, no coach marketplace
- No nutrition or bodyweight tracking in v1
- No form coaching, no video — static illustrations and text only
- Android, iPad, and watchOS are all out of v1 (watchOS is the obvious v2)
- Not a programme generator — it won't write your training block

## Options considered

| Option | Deciding factor |
|---|---|
| React Native, like the sibling repos | Rejected — a JS runtime for an app whose hard part is a 60fps timer ring and one-tap latency |
| SwiftUI + SwiftData | Rejected — would drag the domain rules into a framework that can't be tested without a simulator |
| SwiftUI + Core Data | Same objection, plus a heavier migration story than this needs |
| **SwiftUI shell + a pure-Swift `Core` package + SQLite** | Chosen |

## Decision

Three layers, and the split is the point:

```
Core/         pure Foundation. Session state machine, rest timer, units,
              equipment increments, stats, progression. No SwiftUI, no SQLite.
              `swift test` on macOS, ~1 second, no simulator.
Sources/      SwiftUI. Draws Core's state and sends it events. Holds no rules.
Store         SQLite through the system SQLite3 module, inside Core so the
              persistence layer is testable off-device too.
```

Why bother: every bug that actually matters in this app is a rules bug — a set
counter that strands a completed set, a rest timer that restarts instead of
extending, a personal record that never matches because two equal weights
compare unequal. Those are cheap to test and impossible to see by looking at a
screen. Putting them behind a SwiftUI `@State` would make them testable only in
a simulator, which is where testing stops happening.

### Rules that fell out of building it

- **The log is the truth, the plan is a suggestion.** Nudging the weight down
  mid-set writes that number into the log and leaves the saved workout alone.
  Pushing it back into the template is a separate, deliberate act — "I went
  lighter because my shoulder hurt" must not silently rewrite the programme.
- **Weight is stored in kilograms and compared to a tenth of a gram.** 50 lb
  converted to kg and back is not bit-identical to 50 lb, so exact `Double`
  equality makes two loads a human calls equal sort as different. The
  personal-record tie-break depends on that comparison working.
- **Set counters are per plan line, not per exercise.** The same movement can
  legitimately appear twice in one workout; a shared counter strands sets.
- **Rest is derived from completing a set**, never started by a screen, so the
  timer can't drift out of step with the session.

## Data & integrations

```
MuscleGroup       arms · back · chest · shoulders · legs · core · cardio · full body
Equipment         barbell · dumbbell · machine · cable · kettlebell · band · bodyweight
Exercise          name, group, equipment, illustration, instructions, favourite
Workout           name, ordered [WorkoutExercise]
WorkoutExercise   exercise, target sets/reps/weight, optional rest override
WorkoutSession    a Workout being performed now — cursor, working values, logs
SetLog            exercise, set number, reps, weight, completed at
WorkoutLog        one finished session: started, finished, [SetLog]
```

- **Storage**: one SQLite file on device. No cloud, no account.
- **Backup**: the database file out through the share sheet; same file back in.
- **Cost**: zero. No service, no API key, no ad SDK.
- **HealthKit**: optional, write-only workout records. Off by default, v2.

## Constraints

- **The rest timer must fire with the screen locked and the phone in a pocket.**
  iOS does not keep a foreground timer running, so the alert is a scheduled
  local notification; the on-screen ring is only the visible half. A keep-alive
  audio session is the alternative and costs battery — see T4.4.
- **One-handed reach.** Anything tapped mid-set lives in the bottom third of
  the screen. Nothing tappable mid-set is under 60pt — Apple's 44pt minimum
  assumes a dry finger and a steady hand.
- **Glanceable at arm's length.** Numbers that change while you watch them are
  tabular so the layout can't jitter.

## Risks / open questions

- **Exercise artwork is the expensive part, and it's a licensing question, not
  a drawing one.** The reference app uses a commercially licensed illustration
  set; those images cannot be copied. Three real options: licence a set, use an
  openly-licensed one, or render SF Symbols plus a muscle-map highlight drawn
  in code. Until one is picked, the library ships text-only. This blocks
  nothing technical and everything visual.
- **Content volume.** ~300 exercises with correct instructions is weeks of
  writing, and wrong instructions on a deadlift are worse than none. The seed
  library is 24 movements; the rest is staged.
- **Not a coach.** Progression suggestions are double progression and nothing
  cleverer — anything smarter needs RPE or bar speed, which this app doesn't
  ask for and shouldn't pretend to know.
- Open: does the workout builder need supersets in v1? Currently no — a
  superset is two lines with rest 0 on the first, which covers most of it
  without a new concept.
