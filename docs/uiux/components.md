# Components

Anything drawn twice. Variants in one block so they can be compared.

## Look

```
 accent     ember orange  #F0541C  (dark #FF6B2E)   ← the only colour, and
 surfaces   system grouped greys, light + dark        it means "you can act
 card       20pt continuous corners on the grouped    on this"
            background; inner tiles 14pt
 record     gold ★        done  green ✓
 numbers    SF Rounded, tabular digits
 labels     small caps eyebrow: LAST TIME, SETS, HISTORY
```

Everything that isn't tappable is greyscale, so the one thing that matters
stands out. Gold and green mark facts (a record, a finished rest), not actions.

## Primary action

The one filled button on a screen. Full width, accent, 20pt corners; 64pt
tall, 72pt on Session. Grey when disabled.

```
 end       ╭──────────────────────────────╮
           │         ✓  End set 2         │   72pt
           ╰──────────────────────────────╯
 final     │      ✓  End set & finish     │   72pt
 finish    │        Finish workout        │   72pt, all done or skipped
 hero      │           ▶  Start           │
 detail    │       ▶  Start workout       │
 resume    │          ↻  Resume           │
 disabled  │       ▶  Start workout      ·│  ← grey; reason in a footnote
```

## Soft button

Quiet secondary: tinted text on a soft capsule, 44pt.

```
 accent    ( +30s )  ( Use 60 lb )  ( Create it )  ( Show 50 more )
 grey      ( ▶| Skip )  ( Not today )
 red       ( Discard )!
```

## Value tile

Session's reps and weight. The only control most people touch mid-set.
Side by side in one row above the set button.

```
         ╭───────────────────╮ ╭──────────────────╮
         │ (−)   10    (+)   │ │ (−)  50.0   (+)  │   60pt tall
         │       REPS        │ │       LB         │
         ╰───────────────────╯ ╰──────────────────╯
 timed   │ (−)   60    (+)   │
         │     SECONDS       │
 unloaded  weight tile removed, reps takes the row

 (−) (+)  36pt circles in a 60pt tap target; hold repeats,
          faster every five steps; light haptic on press
 number   24pt tabular, rolls on change; tap → keypad sheet
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

## Line stepper

The compact version, outside Session: workout line editor, log set editor.
44pt, because nobody edits a plan mid-set.

```
 Weight                   [ − ]   50   [ + ]
 lb, 10 lb a tap
```

## Set button

Session's primary action carries the clock. Resting: always Start set. Set
begun: End set. A rep set begins on its own when rest runs out; a timed one
waits for Start.

```
 resting   ╭▒▒▒▒▒▒▒▒▒────────────────╮ ╭──────╮
           │      ▶  Start set 3     │ │ +30s │
           │▒▒▒▒▒▒▒▒▒ Rest 00:00:28  │ │      │
           ╰▒▒▒▒▒▒▒▒▒────────────────╯ ╰──────╯
 timed     │       ✓  End set 1      │ │  ×   │
 time's up │ green, Time's up +00:12 │ │  ×   │
 idle      │        ✓  End set 2           │   no side button
```

Fill: a darker band over the accent, the time still to go — it drains
right→left as the countdown runs out. Side button 72pt, only while there's a clock to change.

## Progress marks

```
 set dots        ● ● ○  Set 3 of 3 ⌄     accent = done
 exercise strip  ━━━━ ━━━━ ▓▓▓▓ ░░░░ ░░░░   done · current · to go
 week dots       (✓) ( ) (✓) (✓) ( ) (✓) ( )
                  M   T   W   T   F   S   S
```

## Stat tile

```
 ╭───────────╮
 │ 42:18     │   24pt tabular value,
 │ TIME      │   eyebrow label under it
 ╰───────────╯
```

Always in threes: summary (Time · Sets · Moved), Progress (Sessions · lb moved
· Time).

## Chip bar

```
 (♡) [ All ] ( Arms ) ( Back ) ( Chest ) …    scrolls horizontally
 [♥] ( All ) [ Back ] ( Chest ) …             selected = inverted fill
```

The `♥` chip exists only where favourites matter (the library). Tapping a
selected group clears it.

## Exercise row

Used in the library, favourites, and add-exercises.

```
 library    [▣] Lat Pull Downs                ♡  ›
                Machine
 favourite  [▣] Barbell Deadlifts             ♥  ›
                Barbell
 custom     [▣] Beep Test                     ♡  ›
                Bodyweight · yours
 selectable  ◉  Dumbbell Hammer Curls  Arms · Dumbbell
 truncated  [▣] Seated Cable Row with W…      ♡  ›
```

`[▣]` = equipment glyph on an accent-tinted rounded square.

## Set line

One logged set, in a session log.

```
 normal      1  10 reps                  50 lb
 under       3   8 reps                  50 lb      ▼
 record      1  10 reps                  60 lb   ★ PR
 unloaded    1  12 reps                      —
 timed       1  60s                          —
```

## Compact load format

The app's one number format, used on every card:

```
 3 × 10 · 50 lb        sets × reps · load
 1 × 5 · 3 lb
 3 × 60s               held for seconds, no load
 1 × 20 min · 8% incline   minutes; a treadmill's load is its incline
 3 × 10 · 50 lb · rest 90s     only when the line overrides the default
```

Never "3 sets of 10 reps at 50 pounds" — read at arm's length, words are noise.

## Chart

```
 populated  60 lb  Thu 18 Sep           ← readout: last point, or the
            70 ┤                   ●       one under the finger
            60 ┤         ●────●
            50 ┤  ●────●
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

 ✗   A second colour for "Legs", another
     for "PR", a gradient on the hero card

     Colour stops meaning "tap here". One
     accent, everything else grey.
```
