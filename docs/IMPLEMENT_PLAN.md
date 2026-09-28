# Implementation plan

Build order. Reasoning in [`DESIGN.md`](DESIGN.md), screens in
[`UIUX_DESIGN.md`](UIUX_DESIGN.md) and [`uiux/`](uiux/).

Every UI task cites the drawing it builds. A task with no drawing to point at
isn't specified yet.

## Phase 1: Rules before pixels

Everything that can be wrong in a way you can't see by looking at a screen —
set counters, rest arithmetic, unit conversion, records — lives in `Core`, a
pure Foundation package with no SwiftUI and no SQLite. It runs `swift test` on
macOS in about a second, so it gets finished and tested before the app target
exists, and every later phase depends on its types.

- [x] T1.1 Repo scaffold — xcodegen `project.yml`, generated `.xcodeproj` committed, `Core` local SwiftPM package wired as the app's only dependency — see `project.yml` — depends: none
- [x] T1.2 Design, UI/UX, and plan docs — see `docs` — depends: none
- [x] T1.3 `Weight` and `WeightUnit` — stored in kilograms, compared to a tenth of a gram so two loads a human calls equal don't sort as different — see `Core/Sources/GymBuddyCore/Weight.swift` — depends: none
- [x] T1.4 `Equipment` increments — one `+` tap moves a machine by a pin, a barbell by a plate pair, a band by nothing — see `Core/Sources/GymBuddyCore/Equipment.swift` — depends: T1.3
- [x] T1.5 Domain models — `Exercise`, `Workout`, `WorkoutExercise`, `SetLog`, `WorkoutLog`, `MuscleGroup` — see `Core/Sources/GymBuddyCore/Models.swift` — depends: T1.3
- [x] T1.6 `RestTimer` — clock-injected, so a `TimelineView`, a background wake-up, and a test all get the same answer — see `Core/Sources/GymBuddyCore/RestTimer.swift` — depends: none
- [x] T1.7 `WorkoutSession` state machine — cursor, working values, per-plan-line set counters, skip, jump, finish — see `Core/Sources/GymBuddyCore/WorkoutSession.swift` — depends: T1.4, T1.5
- [x] T1.8 `Stats` — volume, personal records, per-exercise series, volume by muscle group, streak — see `Core/Sources/GymBuddyCore/Stats.swift` — depends: T1.5
- [x] T1.9 `Progression` — double progression, and nothing cleverer — see `Core/Sources/GymBuddyCore/Progression.swift` — depends: T1.4, T1.5
- [x] T1.10 Core test suite — 73 tests (store, catalogue and session-flow suites added later) over units, increments, rest arithmetic, session advance/skip/jump, stranded sets, records, progression — see `Core/Tests/GymBuddyCoreTests` — depends: T1.3–T1.9

## Phase 2: Storage and content

Rules with nothing to operate on are academic. This phase gives them a
database and a library, and both are schema decisions that the screens then
read — doing them after the engine means the schema is shaped by what the
session actually consumes instead of guessed.

- [x] T2.1 `Store` protocol + `MemoryStore` — lets Phase 3 screens run before SQLite lands — see `Core/Sources/GymBuddyCore/Store.swift` — depends: T1.5
- [x] T2.2 Seed library, 24 movements across every muscle group — see `Core/Sources/GymBuddyCore/SeedLibrary.swift` — depends: T1.5
- [x] T2.3 SQLite store — system `SQLite3` module inside `Core` so persistence is testable on macOS too; schema, a migrations table, one repository per table — see `Core/Sources/GymBuddyCore` — depends: T2.1
- [x] T2.4 Full exercise catalogue — target ~300 movements with equipment, muscle group, and three-step how-to text. Movements without reviewed text ship with the section absent, never filled in with filler — see `Core/Sources/GymBuddyCore` — depends: T2.2
- [x] T2.5 Exercise artwork — pick one of licence a set / use an openly-licensed one / render SF Symbols plus a muscle-map highlight in code. **Decide before drawing anything**: this is a licensing question, and the reference app's illustrations cannot be copied. See `docs/DESIGN.md` Risks — see `Resources` — depends: none
- [x] T2.6 Backup — export the SQLite file through the share sheet, import it back with a replace confirm (drawing: `uiux/settings.md`) — see `Core/Sources/GymBuddyCore` — depends: T2.3
- [x] T2.7 Automatic backups — local snapshot per change (20/day, 7 days) and optional daily iCloud Drive file (30 days); rotation rules in `Core/Sources/GymBuddyCore/BackupRotation.swift`, restore list in Settings (drawing: `uiux/settings.md`) — depends: T2.6
- [x] T2.8 Measure and incline — reps / seconds / minutes per exercise; treadmill steps incline, never weight; SQLite migration 2 — see `Core/Sources/GymBuddyCore/Models.swift` — depends: T2.3
- [x] T2.9 Swim — `Equipment.pool`, `Measure.laps`, `PoolLength`, stroke-by-stroke catalogue entries; each set keeps its pool so laps stay a distance; SQLite migration 4 — see `Core/Sources/GymBuddyCore/PoolLength.swift` — depends: T2.8
- [x] T2.10 Workout templates — 13 ready-made workouts (gym, strength, workday, sport, swim, pregnancy) with sets, reps, starting kg and rest; loads on the equipment grid, time-boxed ones fit their slot — see `Core/Sources/GymBuddyCore/WorkoutTemplates.swift` — depends: T2.9
- [x] T2.11 Gyms — equipment, price in cents, weekly hours with past-midnight and 24 h, travel time, open-on-arrival status; Home always exists; workouts point at gyms — see `Core/Sources/GymBuddyCore/Gym.swift` — depends: T2.3

## Phase 3: Browse and build

The setup half of the app: find an exercise, put it in a workout, set the
targets. Ordinary screens, and being ordinary is fine. They're largely
parallel once the shared components exist — one task per screen file, disjoint
by construction.

- [x] T3.1 Tab shell (five tabs, later four — Favourites became a ♥ filter), `AppModel`, theme tokens, 60pt tap-target constant (drawing: `uiux/README.md`) — see `Sources/App` — depends: T2.1
- [x] T3.2 Shared components — primary action, number stepper, exercise row, set line, bar row, compact load format (drawing: `uiux/components.md`) — see `Sources/Screens/Shared` — depends: T1.4, T3.1
- [x] T3.3 Exercise library — muscle-group sections, chip filter, search (drawing: `uiux/exercises.md`) — see `Sources/Screens/Exercises` — depends: T3.2, T2.3
- [x] T3.4 Exercise detail — best, last done, how-to, which workouts use it (drawing: `uiux/exercises.md`) — see `Sources/Screens/Exercises` — depends: T3.2, T1.8
- [x] T3.5 Favourites — the library with a ♥ chip, not a second list (drawing: `uiux/exercises.md`) — see `Sources/Screens/Exercises` — depends: T3.3
- [x] T3.6 Workouts list and detail, drag to reorder, in-place line editor (drawing: `uiux/workouts.md`) — see `Sources/Screens/Workouts` — depends: T3.2, T2.3
- [x] T3.7 Add exercise — multi-select, chip filter, last-used weight prefill (drawing: `uiux/workouts.md`) — see `Sources/Screens/Workouts` — depends: T3.3
- [x] T3.8 Custom exercises — create and edit your own, the escape hatch when search finds nothing (drawing: `uiux/exercises.md`) — see `Sources/Screens/Exercises` — depends: T3.3
- [x] T3.9 Settings and its children, ⓘ popovers, unit switch guarded mid-session (drawing: `uiux/settings.md`) — see `Sources/Screens/Settings` — depends: T3.2
- [x] T3.10 New-workout sheet — blank or from a template, preview with reasons and pool picker (drawing: `uiux/workouts.md`) — see `Sources/Screens/Workouts/NewWorkoutSheet.swift` — depends: T2.10, T3.6
- [x] T3.11 Gyms screen and editor — open now / at a picked time, hours, price, equipment, travel; gyms ticked on workout detail with missing equipment named (drawing: `uiux/gyms.md`) — see `Sources/Screens/Gyms` — depends: T2.11, T3.6
- [ ] T3.12 No tabs — Train is the one root: Progress summary card, Exercises and Gyms tiles, `+` in the Workouts header, Settings behind `⚙` (drawing: `uiux/README.md`, `uiux/workouts.md`) — see `Sources/App/RootView.swift` — depends: T3.1, T3.11
- [ ] T3.13 Gym equipment per exercise — searchable picker with All/None per kind, old kinds migrated, workout detail names the exercises a gym can't do (drawing: `uiux/gyms.md`) — see `Sources/Screens/Gyms/GymKitView.swift` — depends: T3.11

## Phase 4: Run a workout

The reason the app exists, and the only screen worth being fussy about. It
comes after Phase 3 because it needs a real workout to run and a store to log
into — but its state already exists and is already tested, so these tasks are
drawing and wiring, not logic.

- [x] T4.1 Session shell — header, elapsed clock, current exercise, up-next list (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T1.7, T3.2
- [x] T4.2 Steppers and the primary action — one-tap logging, press-hold repeat, keypad on tapping a number, `last time:` readout (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T4.1
- [x] T4.3 Rest bar — ring, `+30s`, dismiss, and never covering the primary action (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T1.6, T4.1
- [x] T4.4 Rest alert with the screen locked — a scheduled `UNUserNotificationCenter` notification, rescheduled on extend and cancelled on dismiss. Compare against a keep-alive audio session and record the battery trade in `docs/DESIGN.md` — see `Sources/Screens/Session` — depends: T4.3
- [x] T4.5 Jump sheet, skip, change-sets row that can't strand a logged set (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T4.1
- [x] T4.6 Exit and summary — both confirm variants, volume, PR line, and the offer to push changed weights back into the plan (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T4.2, T1.8
- [x] T4.7 Progression offer — once per exercise per session, a question and never an automatic change (drawing: `uiux/session.md`) — see `Sources/Screens/Session` — depends: T1.9, T4.2
- [x] T4.8 Resume an interrupted session — the app gets killed mid-workout; the session is persisted on every logged set (drawing: `uiux/workouts.md` → resume) — see `Sources/Screens/Session` — depends: T2.3, T4.2
- [x] T4.9 Set clock — the big button is Start set → Log set → Log set & next exercise; the rest bar doubles as the set clock, counts up for reps and down for timed sets (treadmill minutes, plank seconds), time's-up alert with the screen locked, start time kept on the log (drawing: `uiux/session.md`) — see `Sources/Screens/Session/TimerBar.swift` — depends: T4.2, T4.4
- [x] T4.10 Keep in background — the exit dialog can hide the session instead of ending it; a mini bar at the bottom shows its live clock and opens it again (drawing: `uiux/session.md`) — see `Sources/Screens/Session/MiniSessionBar.swift` — depends: T4.6, T4.9
- [x] T4.11 Counted in, per workout line — reps, seconds or minutes, overriding the exercise; the set log keeps what it counted and `LAST TIME` only compares like with like (drawing: `uiux/workouts.md`) — see `Sources/Screens/Workouts/WorkoutDetailView.swift` — depends: T4.9
- [x] T4.12 Values beside the body — compact value cards next to the muscle map; tapping one opens a bottom adjust sheet with ± and typing. Back beside Skip returns to the last unfinished exercise left behind (drawing: `uiux/session.md`) — see `Sources/Screens/Session/ValuePanel.swift` — depends: T4.2, T4.5

## Phase 5: Logs and graphs

Reading back what Phase 4 wrote. Last of the feature phases because it is
worthless until there are real sessions to draw, and every number it shows
already comes from `Stats`.

- [x] T5.1 History — week dots, volume by muscle group, session list (drawing: `uiux/logs.md`) — see `Sources/Screens/Logs` — depends: T1.8, T3.2, T2.3
- [x] T5.2 Session log — per-exercise sets, under-target and PR marks, notes (drawing: `uiux/logs.md`) — see `Sources/Screens/Logs` — depends: T5.1
- [x] T5.3 Trend chart — Swift Charts, metric and range segments, scrub readout (drawing: `uiux/logs.md`) — see `Sources/Screens/Logs` — depends: T1.8, T3.4
- [x] T5.4 CSV export of sessions, for people who want their numbers in a spreadsheet — see `Sources/Screens/Logs` — depends: T5.1

## Phase 6: Ship it

Release chores. Grouped last because none of them is a capability.

- [x] T6.1 App icon and launch screen — see `Resources/Assets.xcassets` — depends: T2.5
- [x] T6.2 Signing without secrets — `DEVELOPMENT_TEAM` stays blank in `project.yml`; a gitignored `Local.xcconfig` or a build-time override carries the real value, per the `security` skill — see `project.yml` — depends: none
- [ ] T6.3 Accessibility (VoiceOver labels on glyph-only controls done; largest Dynamic Type pass still to do on device) — Dynamic Type at the largest setting on every screen, VoiceOver labels on every glyph-only control, and the Session screen usable without reading a single icon — see `Sources/Screens` — depends: Phase 4
- [ ] T6.4 Physical-device QA against every drawing in `uiux/`, including the smallest supported width — see `docs/uiux` — depends: Phase 4, Phase 5
- [ ] T6.5 TestFlight build, local `xcodebuild` only, no cloud builds — `make release`, steps in `docs/release/listing.md` — depends: T6.1, T6.2, T6.3

## Running this in parallel

The current parallel batch is whatever in the active phase has `depends: none`
or all-satisfied dependencies. Phase 3 is the widest fan-out — seven screen
tasks over mostly-disjoint files — but they all need T3.2 and T2.3 first, so
those two are the bottleneck worth doing well rather than fast.

T2.5 (artwork) has no dependencies and blocks T6.1, so it can start any time
and should, because it's a decision with a lead time rather than a task with an
effort estimate.

One agent owns this file and checks the boxes. Agents report done; they don't
edit the checklist.
