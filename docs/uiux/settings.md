# Settings

Fifth tab. Short on purpose — there is no account, no sync, and no ad
preferences to bury anything under.

```
  Settings
 ──────────────────────────────────────────
  UNITS
  Weight                  [ KG | LB ]
 ──────────────────────────────────────────
  REST  ⓘ
  Between sets                    60s   ›
  Between exercises               90s   ›
  Alert when rest is over          ─●
  Vibrate                          ─●
 ──────────────────────────────────────────
  DURING A WORKOUT
  Keep the screen awake            ○─      ← off: the notification covers it
  Suggest heavier weights          ─●
  Count down the last 3 seconds    ─●
 ──────────────────────────────────────────
  YOUR DATA  ⓘ
  Exercises                        24   ›
  Workouts                          3   ›
  Sessions logged                  28   ›
  Last backup        Sep 21, 2026 · 84 KB
  ( Export… )          ( Import… )
 ──────────────────────────────────────────
  About                                 ›
  Gym Buddy 0.1.0 · no ads, no account,
  nothing leaves this phone
```

Reached from: tab bar

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

 YOUR DATA ⓘ
 ⌐ Everything is one SQLite file on this
   phone. There is no account and no server,
   so a backup is the only copy that
   survives losing the device — export it
   somewhere you'll still have. ¬
```

## Changing units

```
  Weight                  [ KG | LB ]
             tap KG ↓
 ┌──────────────────────────────────────┐
 │ Show weights in kilograms?           │
 │ Every logged set is converted for    │
 │ display. Nothing is rewritten — your │
 │ history is stored in kilograms       │
 │ already.                             │
 │  ( Cancel )        [[ Use kg ]]      │
 └──────────────────────────────────────┘
```

## States

```
never exported
  Last backup                       never
  ⌐ Nothing is backed up. ¬   ( Export… )

notifications denied
  REST  ⓘ
  ⚠ Alerts are off in iOS Settings, so
    rest will only show on screen.
                        ( Open Settings )
  Alert when rest is over      ─●·

import, would replace
 ┌──────────────────────────────────────┐
 │ Replace everything?                  │
 │ This backup has 31 sessions and 4    │
 │ workouts. Your current 28 and 3 are  │
 │ overwritten.                         │
 │  ( Cancel )       [[ Replace ]]!     │
 └──────────────────────────────────────┘

mid-session
  Weight                  [ KG | LB ]·
  ⌐ Finish the workout first. ¬            ← changing units mid-set is
                                              how a log gets misread
```

## Interactions

| Target | Action | Result |
|---|---|---|
| `[ KG \| LB ]` | tap | confirm sheet above; display only, storage unchanged |
| rest rows | tap | unfolds in place: 30 / 45 / 60 / 90 / 120 / custom |
| `ⓘ` | tap | popover, not a pushed page |
| `Export…` | tap | writes the SQLite file, then `[ share sheet ]` |
| `Import…` | tap | `[ document picker ]` → confirm → reload |
| `Exercises` / `Workouts` / `Sessions` | tap | the matching tab, unfiltered |
| `About` | tap | version, licences, the not-a-coach note |

## Copy

| Key | String |
|---|---|
| `settings.units` | UNITS |
| `settings.units.weight` | Weight |
| `settings.units.confirm` | Every logged set is converted for display. Nothing is rewritten. |
| `settings.rest.betweenSets` | Between sets |
| `settings.rest.betweenExercises` | Between exercises |
| `settings.rest.info` | Rest starts on its own when you log a set… |
| `settings.screenAwake` | Keep the screen awake |
| `settings.suggest` | Suggest heavier weights |
| `settings.countdown` | Count down the last 3 seconds |
| `settings.data.info` | Everything is one SQLite file on this phone… |
| `settings.backup.never` | Nothing is backed up. |
| `settings.notifDenied` | Alerts are off in iOS Settings, so rest will only show on screen. |
| `settings.unitsLocked` | Finish the workout first. |
| `settings.about.tagline` | no ads, no account, nothing leaves this phone |

## Notes

`Keep the screen awake` defaults **off**. It's the setting every gym app turns
on by default, and it costs a visible chunk of battery to solve a problem the
rest notification already solves.

Units can't be changed mid-session. A set logged under one unit and read back
under another during the same workout is the cheapest possible way to put the
wrong number on the bar.
