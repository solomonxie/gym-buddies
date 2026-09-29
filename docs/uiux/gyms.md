# Gyms

Where you train: what each place has, what it costs, when it's open, how far
it is. Answers "where can I go right now?" before you put your shoes on.

```
  Gyms                                    +
  OPEN WHEN YOU GET THERE
 ╭────────────────────────────────────────╮
 │ Home                           Home  › │
 │ Open all day · on the spot             │
 ├────────────────────────────────────────┤
 │ Anytime Fitness                      › │
 │ Open till 22:00 · 15 min · $45/month   │
 ├────────────────────────────────────────┤
 │ City Pool                            › │
 │ Shuts 40 min after you arrive · 20 min │  ← under an hour: warn
 ╰────────────────────────────────────────╯
  CLOSED NOW
 ╭────────────────────────────────────────╮
 │ Uni Gym                              › │
 │ Opens Wed 06:00 · 25 min · $8/visit    │
 ╰────────────────────────────────────────╯
  Counts travel time: open means open on arrival.
```

Reached from: the Gyms tile on Train (it shows how many are open now)

## Gym editor

Pushed from a row, or `+` for a new one. Saves as you go, like a workout line.

```
 ‹ Gyms        Anytime Fitness
  [ Name                              ]
  TRAVEL
  Travel time        [−] 15 min [+]        ← 5 min a tap
  PRICE
  [ 45.00 ]                  ( month ⌄ )    ← visit / month / year; blank = free
  EQUIPMENT
  Machines & equipment         12 of 43  ›  ← bodyweight always counts
  HOURS                   ( Same every day )
  Open 24 hours                       ( )
  Mon   06:00 – 22:00                 (●)   ← toggle off = closed that day
  Tue   06:00 – 22:00                 (●)
  ⋮
  Sun   Closed                        ( )
  NOTES
  [ Bring a lock                      ]
  WORKOUTS HERE
  Muscle Building · Upper              ›
  Delete gym!                              ← absent on Home
```

## Equipment

Pushed from the editor. The machines and equipment you'd look for on the
floor — about forty, not the few hundred exercises they serve. A gym has a
leg press or it doesn't; "machine" says too little.

```
 ‹ Anytime Fitness      Equipment
  ┌──────────────────────────────────────┐
  │ 🔍 Search                            │
  └──────────────────────────────────────┘
  WEIGHTS & CABLES  4/5             All    ← whole kind in one tap
 ╭────────────────────────────────────────╮
 │ Barbell                            (●) │
 │ 50 exercises                           │
 │ Cable station                      (●) │
 │ 31 exercises                           │
 │   ⋮                                    │  ← 5 rows until opened;
 ╰────────────────────────────────────────╯     then "Show fewer"
  MACHINES  12/30                   All
 ╭────────────────────────────────────────╮
 │ Ab crunch machine                  ( ) │
 │ 1 exercise                             │
 │   ⋮                                    │
 │ Show 25 more                           │
 ╰────────────────────────────────────────╯
  CARDIO  3/8                       All
```

An exercise needs one piece: its free weight or the cable station, or its
named machine (all five Smith machine moves need the Smith machine). A
custom machine exercise is its own machine. `All` / `None` act on the whole
kind, folded rows included, or on what the search shows. Gyms saved with the
older lists get the kit those exercises used.

Close before open (22:00 – 02:00) runs past midnight and belongs to the day it
opens.

## States

```
home
 │ Home                           Home  › │  ← badge; no Delete in editor
  Home starts open all day with no equipment ticked; tick what you own.

nothing open
  OPEN WHEN YOU GET THERE
  Nothing's open now.

deleting
 ┌──────────────────────────────────────┐
 │ Delete "Uni Gym"?                    │
 │ 2 workouts stop pointing at it.      │
 │  ( Cancel )        ( Delete )!       │
 └──────────────────────────────────────┘
```

## Copy

| Key | String |
|---|---|
| `gyms.open` | OPEN WHEN YOU GET THERE |
| `gyms.closed` | CLOSED NOW |
| `gyms.allDay` | Open all day |
| `gyms.until` | Open till {time} |
| `gyms.closingSoon` | Shuts {n} min after you arrive |
| `gyms.opens` | Opens {day} {time} |
| `gyms.never` | No hours set |
| `gyms.here` | on the spot |
| `gyms.away` | {n} min |
| `gyms.footer` | Counts travel time: open means open on arrival. |
| `gym.delete` | {n} workouts stop pointing at it. |

## Notes

Travel time is typed in, not measured: no location, no maps, nothing leaves
the phone.
