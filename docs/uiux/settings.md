# Settings

Pushed from the Settings row at the bottom of Train. Short on purpose — there
is no account, no sync, and no ad preferences to bury anything under.

```
  Settings
 ──────────────────────────────────────────
  UNITS
  Weight                       [ KG | LB ]
 ──────────────────────────────────────────
  REST  ⓘ
  Between sets                        60s ›
  Between exercises                   90s ›
  Alert when rest or time is up         ─●
  Vibrate                               ─●
 ──────────────────────────────────────────
  DURING A WORKOUT
  Keep the screen awake                 ○─   ← off: the notification covers it
  Suggest heavier weights               ─●
  Count down the last 3 seconds         ─●   ← off with Vibrate: it's a haptic
 ──────────────────────────────────────────
  AUTOMATIC BACKUPS  ⓘ
  On this phone                  2 min ago ›
  Back up to iCloud                     ─●
  Last saved to iCloud 2 min ago.
 ──────────────────────────────────────────
  YOUR DATA  ⓘ
  Exercises                           301 ›
  Workouts                              3 ›
  Sessions logged                      28 ›
  Last export           21 Sep 2026 · 84 KB
  (     Export…     )  (     Import…     )
 ──────────────────────────────────────────
  About                                   ›
  Gym Buddy 1.0 (1) · no ads, no account,
  nothing leaves this phone unless you
  send it
```

Reached from: the Settings row at the bottom of Train

## The ⓘ popovers

The long text lives here, not under the heading — `uiux` skill,
`references/mobile.md`. One sentence at most stays outside, and only if you'd
read it every visit.

```
 REST ⓘ
 ⌐ Rest starts on its own when you log a
   set, and the alert is a notification, so
   it still reaches you with the phone in a
   pocket and the screen locked. A workout
   with per-exercise rest set on a line uses
   that instead of these. ¬

 AUTOMATIC BACKUPS ⓘ
 ⌐ After every change, a copy is saved on
   this phone — the newest 20 from today
   and the last one from each of the 6
   days before. With iCloud on, one file a
   day also goes to iCloud Drive → Gym
   Buddy, replaced by each change that day
   and kept for 30 days. ¬

 YOUR DATA ⓘ
 ⌐ Everything is one SQLite file on this
   phone. There is no account and no
   server, so an iCloud backup or an
   exported file is the only copy that
   survives losing the device. ¬
```

## Backups — pushed from "On this phone"

```
 ‹ Settings        Backups
 ──────────────────────────────────────────
  A copy is saved after every change: the
  newest 20 from today and the last one
  from each of the 6 days before.
  Restoring one saves what's here now
  first, so it can be undone.
 ──────────────────────────────────────────
  SATURDAY 26 SEPTEMBER
  21:05:33                          88 KB
  20:41:02                          88 KB
  ⋮
 ──────────────────────────────────────────
  FRIDAY 25 SEPTEMBER
  18:12:47                          84 KB
```

Row tap → `Restore this backup?` with its session and workout counts,
`( Cancel ) [[ Restore ]]!`. Disabled mid-workout.

States: no backups yet → "one is saved a few seconds after your next
change". iCloud on but unavailable → footer in orange: "Sign in to iCloud
with iCloud Drive on, in iOS Settings."

## Rest — unfolds in place

```
  Between sets                        60s ⌄
  [30] [45] [60] [90] [120] [180]            ← current one filled accent
  Custom: 60s                   [ − | + ]   ← 5s steps, 0–600
  Between exercises                   90s ›
```

## Changing units

```
  Weight                       [ KG | LB ]
             tap KG ↓
 ┌──────────────────────────────────────┐
 │ Show weights in kilograms?           │
 │ Every logged set is converted for    │
 │ display. Nothing is rewritten — your │
 │ history is stored in kilograms       │
 │ already.                             │
 │ ( Use kg )            ( Cancel )     │
 └──────────────────────────────────────┘
```

## About

```
 ‹ Settings          About
 ──────────────────────────────────────────
  Version                          1.0 (1)
  No ads, no account, no analytics.
  Nothing leaves this phone unless you
  export it.
 ──────────────────────────────────────────
  NOT A COACH      how suggestions work
  ILLUSTRATIONS    drawn in code, SF Symbols
  LICENCES         Apple frameworks only
```

## States

```
never exported, with sessions logged
  Last backup                        never
  Nothing is backed up.                      ← orange text, no nag banner
  (     Export…     )  (     Import…     )

notifications denied (and Alert on)
  REST  ⓘ
  ⚠ Alerts are off in iOS Settings, so
    rest will only show on screen.
  ( Open Settings )
  Alert when rest or time is up         ─●

import, would replace
 ┌──────────────────────────────────────┐
 │ Replace everything?                  │
 │ This backup has 31 sessions and 4    │
 │ workouts. Your current 28 and 3 are  │
 │ overwritten.                         │
 │  ( Cancel )        ( Replace )!      │
 └──────────────────────────────────────┘

import, wrong file
 ┌──────────────────────────────────────┐
 │ Couldn't do that                     │
 │ That file isn't a Gym Buddy backup.  │
 │                             ( OK )   │
 └──────────────────────────────────────┘

mid-session
  Weight                      [ KG | LB ]·
  Finish the workout first.                ← changing units mid-set is
  (     Export…     )  (     Import…    )·    how a log gets misread
```

## Interactions

| Target | Action | Result |
|---|---|---|
| `[ KG \| LB ]` | tap | confirm dialog above; display only, storage unchanged |
| rest rows | tap | unfolds in place: 30 / 45 / 60 / 90 / 120 / 180 / custom |
| `ⓘ` | tap | popover, not a pushed page |
| `Export…` | tap | writes the SQLite file, then `[ share sheet ]` |
| `Import…` | tap | `[ document picker ]` → confirm → reload |
| `Exercises` / `Sessions logged` | tap | pushes Exercises / Progress; `Workouts` is a count only — Train is one back-swipe away |
| `About` | tap | version, the not-a-coach note, illustrations, licences |

## Copy

| Key | String |
|---|---|
| `settings.units` | UNITS |
| `settings.units.weight` | Weight |
| `settings.units.confirm` | Every logged set is converted for display. Nothing is rewritten — your history is stored in kilograms already. |
| `settings.rest.betweenSets` | Between sets |
| `settings.rest.betweenExercises` | Between exercises |
| `settings.rest.custom` | Custom: {n}s |
| `settings.rest.info` | Rest starts on its own when you log a set… |
| `settings.screenAwake` | Keep the screen awake |
| `settings.suggest` | Suggest heavier weights |
| `settings.countdown` | Count down the last 3 seconds |
| `settings.data.info` | Everything is one SQLite file on this phone… |
| `settings.backup.never` | Only this phone has a copy. Turn on iCloud backup or export one. |
| `settings.auto.local` | On this phone |
| `settings.auto.icloud` | Back up to iCloud |
| `settings.auto.icloudLast` | Last saved to iCloud {relative}. |
| `settings.auto.icloudOff` | iCloud isn't available. Sign in to iCloud with iCloud Drive on, in iOS Settings. |
| `backups.restore` | From {date}: {n} sessions and {m} workouts. What's here now is saved as a backup first. |
| `settings.import.replace` | This backup has {n} sessions and {m} workouts. Your current {a} and {b} are overwritten. |
| `settings.import.bad` | That file isn't a Gym Buddy backup. |
| `settings.notifDenied` | Alerts are off in iOS Settings, so rest will only show on screen. |
| `settings.unitsLocked` | Finish the workout first. |
| `settings.about.tagline` | no ads, no account, nothing leaves this phone unless you send it |

## Notes

`Keep the screen awake` defaults **off**. It's the setting every gym app turns
on by default, and it costs a visible chunk of battery to solve a problem the
rest notification already solves.

Units and import are locked mid-session. A set logged under one unit and read
back under another during the same workout is the cheapest possible way to put
the wrong number on the bar.
