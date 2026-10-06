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
- **Swims count laps, the pool makes them distance.** Pool length is a short
  list (15/20/25 m, 25 yd, 33⅓/50 m), not a free number, and each set keeps
  the pool it was swum in so 20 laps in a 50 m pool never reads as 500 m.
- **Templates are copied, not referenced.** Adding one makes an ordinary
  workout; editing it can't change the template and vice versa.
- **Opening hours belong to the day they open.** 22:00–02:00 on Friday is still
  Friday at 1 a.m.; back-to-back all-day periods merge so "open till" is real.
  "Open" always means open on arrival, travel time included.

## Data & integrations

```
MuscleGroup       arms · back · chest · shoulders · legs · core · cardio · full body
Equipment         barbell · dumbbell · machine · cable · kettlebell · band · bodyweight
                  · treadmill · pool · other
Exercise          name, group, equipment, illustration, instructions, favourite
Workout           name, ordered [WorkoutExercise], gyms it's for
WorkoutExercise   exercise, target sets/reps/weight, optional rest override,
                  incline (treadmill), pool length (swim)
WorkoutTemplate   read-only content; copied into a Workout, never linked
Gym               name, equipment, price, weekly hours, travel minutes;
                  Home always exists
WorkoutSession    a Workout being performed now — cursor, working values, logs
SetLog            exercise, set number, reps, weight, completed at, pool length
WorkoutLog        one finished session: started, finished, [SetLog]
```

- **Storage**: one SQLite file on device. No cloud, no account. Demo mode (Settings) uses a second file, `GymBuddy-demo.sqlite`, seeded from `demo/seed.json`; never backed up or exported.
- **Backup, automatic**: after every change (debounced 3 s) a snapshot goes to
  the app container — never overwritten, newest 20 from today,
  then the newest one from each of the 6 days before.
  Restoring one snapshots the current data first, so a restore is undoable.
- **Backup, iCloud** (off by default): the same snapshot to the user's own
  iCloud Drive → Gym Buddies, one file per day replaced by each change, 30 days
  kept. The one network egress, chosen because a phone-only backup dies with
  the phone. It's the user's account and quota; we run nothing and see nothing,
  so App Privacy stays "Data Not Collected".
- **Backup, manual**: the database file out through the share sheet; same file
  back in.
- **Cost**: zero. No service, no API key, no ad SDK.
- **HealthKit**: optional, write-only workout records. Off by default, v2.

## Constraints

Rest alert, measured choice (T4.4): a scheduled `UNUserNotificationCenter`
notification, replaced on `+30s`, removed on dismiss. The alternative — a
silent keep-alive audio session — keeps the process running for a live
countdown on the lock screen but holds the audio hardware awake for the whole
workout, a steady battery cost, and App Review treats background audio that
plays nothing as abuse. The notification costs nothing between sets.

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

- **Exercise artwork — decided: drawn in code.** The reference app's
  illustrations are commercially licensed and can't be copied. Of the three
  options (licence a set, an openly-licensed one, draw our own), the app draws a
  front/back muscle map in SwiftUI plus an SF Symbol per equipment. Zero
  licensing risk, works in dark mode, and the map says more than a pose would.
- **Content volume.** ~300 movements ship; ~73% carry three-step how-tos.
  Movements where the cues weren't certain (Olympic variants, Turkish get-ups,
  dragon flags…) ship with the section absent — wrong text on a deadlift is
  worse than none.
- **Not a coach.** Progression suggestions are double progression and nothing
  cleverer — anything smarter needs RPE or bar speed, which this app doesn't
  ask for and shouldn't pretend to know.
- **Template numbers are starting points, not prescriptions.** Loads assume
  someone new to the movement, sets and rests follow ACSM strength and
  hypertrophy guidance, the pregnancy ones ACOG's (no supine work past the
  first trimester, talk test, stop signs listed). The app says "adjust to
  you" and lets double progression take it from there. Not medical advice.
- **Travel time is typed in.** Measuring it needs location and a maps
  service — a network call this app doesn't make.
- **No tabs.** Train is the one root; Progress, Exercises, Gyms and Settings
  are pushed from it — five tabs was too many (user feedback, Sep 2026).
- Open: does the workout builder need supersets in v1? Currently no — a
  superset is two lines with rest 0 on the first, which covers most of it
  without a new concept.
