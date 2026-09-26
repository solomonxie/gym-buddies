# Components

Anything drawn twice. Variants in one block so they can be compared.

## Primary action

The `[[ LOG SET ]]` button and its relatives. Full width, 60pt tall, bottom
third of the screen.

```
 normal    ╭──────────────────────────────╮
           │       LOG SET  ·  2 of 3     │
           ╰──────────────────────────────╯
 final     │    LOG SET  ·  FINISH WORKOUT│
 start     │       ▶  START WORKOUT       │
 resume    │  ▶ RESUME — Fraiser 00:14:22 │
 disabled  │       ▶  START WORKOUT      ·│  ← annotate why on the right
 working   │            ⟳                 │
```

## Number stepper

The only control most people touch mid-set.

```
 loaded            10                50.0
                  REPS                LB
              [  −  ] [  +  ]   [  −  ] [  +  ]

 unloaded          12                          ← weight column removed,
                  REPS                            not disabled
              [  −  ] [  +  ]

 at zero       [  −  ]·[  +  ]                 ← can't go below 0

 props: value · unit · increment (from Equipment) · min
```

Increment comes from the equipment, never from a constant:

```
 Barbell     ± 2.5 kg   /  ± 5 lb      a pair of the smallest plates
 Cable       ± 2.5 kg   /  ± 5 lb
 Dumbbell    ± 2 kg     /  ± 5 lb      the rack's own step
 Machine     ± 5 kg     /  ± 10 lb     one pin
 Kettlebell  ± 4 kg     /  ± 10 lb     bells come in sizes
 Bodyweight  ± 1.25 kg  /  ± 2.5 lb    added weight only
 Band        —                          a band has a colour, not a weight
```

## Rest bar

```
 running   │ RESTING  00:00:28 [███░░░░░░] +30s × │
 nearly    │ RESTING  00:00:03 [█████████] +30s × │
 fired     │ REST OVER         [██████████]     × │
 absent    (nothing — no placeholder, no zero row)
```

Never replaces the primary action; it sits above it.

## Exercise row

Used in the library, favourites, add-exercise, and up-next.

```
 library    Lat Pull Downs           Machine    ›
 favourite  Barbell Deadlifts        Barbell ♥  ›
 selectable ✓ Dumbbell Hammer Curls  Arms · DB
 up next    Lat Pull Downs       3 × 10 · 50 lb ›
 in-session ● Seated Machine Rows    2 of 3 done
 done       ✓ Walking                1 × 5 · 3 lb
 skipped      Lat Pull Downs         skipped
 truncated  Seated Cable Row with W… Machine    ›
```

## Set line

One logged set, in a session log.

```
 normal      1  10 reps         50 lb
 under        3   8 reps         50 lb         ▼
 record       1  10 reps         60 lb      ★ PR
 unloaded     1  12 reps            —
 timed        1     60s              —
```

## Compact load format

The app's one number format, used on every card:

```
 3 × 10 · 50 lb        sets × reps · load
 1 × 5 · 3 lb
 3 × 60s               timed, no load
 3 × 10 · 50 lb · rest 90s     only when the line overrides the default
```

Never "3 sets of 10 reps at 50 pounds" — read at arm's length, words are noise.

## Chart

```
 populated  70 ┤                   ●
            60 ┤         ●    ●
            50 ┤  ●  ●
               └──────────────────────
                Jul     Aug     Sep

 one point  60 ┤        ●                ← no line: two points make a trend,
               └──────────────────────      one does not

 empty      Do it once and the graph starts.
```

## Bar row

```
 Back      [████████████░░░░]  4,800 lb
 Arms      [░░░░░░░░░░░░░░░░]      0 lb    ← kept, not hidden
 single    [████████████████]  3,240 lb    ← one bar claims no comparison
```

## Not this

```
 ✗   Set      Reps     Weight
     1/3      10       50.0
    CHANGE    [−][+]   [−][+]

     Three equal-weight readouts and no way
     to say "done". The action performed
     fifty times per workout needs to be
     the biggest thing on the screen.

 ✗   🔥 4-day streak!  Great job!

     Guilt as a feature. The week dots show
     what happened; a gap is information,
     not a failure state.

 ✗   Weight  [ − ]  50.0  [ + ]      step 1.0

     A universal ±1 means 10 taps to move a
     machine stack one pin, and puts loads
     on the bar that no plate set can make.
```
