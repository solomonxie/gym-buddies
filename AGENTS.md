# Rules live in Core, never in a view

`Core/` is a pure Foundation SwiftPM package — no SwiftUI, no SQLite import in
the logic types, no UIKit. It decides every number the app shows. A screen that
wants to know which set is next, how much rest is left, or what to suggest next
week asks `Core`; it does not work it out locally from `@State`.

The rule that keeps it honest: if you can be wrong about it without being able
to see it on screen, it belongs in `Core` with a test. `cd Core && swift test`
runs in about a second and needs no simulator, so there is no excuse.

Invariants worth breaking a build over:

- **The log is the truth, the plan is a suggestion.** Nudging reps or weight
  mid-set changes what gets written down and nothing else. Updating the saved
  workout is a separate, explicit act.
- **Set counters are per plan line, not per exercise.** The same movement can
  appear twice in one workout; a shared counter strands sets.
- **Weight is stored in kilograms and compared to a tenth of a gram.** Never
  compare two `Weight`s by raw `Double` equality, and never store pounds.
- **`+` uses `Equipment.increment`, never a constant.** A hardcoded step is a
  bug even when it happens to be right for the exercise in front of you.
- **Rest starts from completing a set**, never from a view calling the timer
  directly, so it cannot drift out of step with the session.
- **`RestTimer` takes the current time as a parameter.** It holds no clock, so
  a `TimelineView`, a background wake-up, and a test agree.

# Draw it before you build it

Every screen is already drawn in `docs/uiux/`. Build the drawing; if the
drawing is wrong, fix the drawing in the same commit. A UI change with no
mockup update leaves two sources of truth, and the stale one wins arguments it
shouldn't.

Tasks and their order live in `docs/IMPLEMENT_PLAN.md` — check a box only when
the code is merged and tests pass.

# The gym is a hostile place to read a screen

Arm's length, sweaty fingers, thirty seconds, one hand on the bar. So:

- **60pt minimum** for anything tapped mid-set — Apple's 44pt assumes a dry
  finger and a steady hand. 44pt is fine everywhere outside the Session screen.
- **Mid-set controls live in the bottom third.**
- **Numbers that change while you watch them are tabular**, so nothing jitters.
- **Never congratulate.** No streak fires, no confetti, no "Great job!". State
  what happened and stop.

# Native Swift, iPhone only, no dependencies

- **No third-party packages.** Foundation, SwiftUI, Swift Charts, UserNotifications,
  system `SQLite3`. If hand-rolling something is genuinely hard — a
  security-sensitive primitive, or weeks of correctness-critical work — say so
  in `docs/DESIGN.md`'s Risks section before adding it, not after.
- **`xcodegen` is a dev-time tool, not a dependency.** Regenerate with
  `xcodegen generate` after editing `project.yml`; never hand-edit
  `project.pbxproj`.
- **No cloud builds.** Local `xcodebuild`/`devicectl` only.
- **Physical device for QA.** If the paired iPhone isn't reachable, say so —
  don't quietly switch to a simulator for anything beyond a compile check.
- **No signing secrets in tracked files** — `DEVELOPMENT_TEAM` stays blank in
  `project.yml`, per the `security` skill.

# Nothing leaves the phone, and nothing is borrowed

No server, no analytics, no telemetry, no ad SDK, no crash reporter that phones
home. The only data egress is a file the user explicitly exports, or the
user's own iCloud Drive when they turn on iCloud backup. Adding a
network call is a design decision, not an implementation detail — it goes in
`docs/DESIGN.md` first.

Exercise illustrations are a licensing question, not a drawing one. The
reference app's artwork is commercially licensed and cannot be copied — see
`docs/IMPLEMENT_PLAN.md` T2.5.
