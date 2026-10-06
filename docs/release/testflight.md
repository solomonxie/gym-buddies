# TestFlight external testing

App Store Connect → TestFlight → External Testing → **+** group → add the build. First build of a version goes through Beta App Review (~1 day).

## Test Information

Beta App Description (≤4000):

```
Gym Buddies is a workout log built around the active set: one tap to end a set with reps and weight pre-filled from your plan, a + that steps the weight by what the equipment allows, and an automatic rest timer whose notification reaches a locked phone.

No account, no server. To see it with data: Settings → Demo mode (sample workouts, gyms and ten weeks of history, kept apart from your own).

What's in this beta:
• Live workout screen with rest timer and notifications
• Templates: gym basics, strength, swim, pregnancy and more
• 300+ exercises with muscle maps and how-tos
• Gyms list with equipment and opening hours
• Progress charts and personal records, kg/lb
• CSV export, local and iCloud backups
```

Feedback Email: `you@example.com`

## Contact Information

| Field | Value |
|---|---|
| First Name | TODO |
| Last Name | TODO |
| Phone number | TODO — yours, with country code (`+1 …`) |
| Email | `you@example.com` |

## Sign-In Information

Sign-in required: **off** (no account in the app). Leave User Name / Password blank.

Review Notes: paste the App Review Notes block from [listing.md](listing.md) if present.

## Per build: What to Test

```
Start a workout from a template, end a few sets, lock the phone during rest and confirm the notification arrives. Change a weight with +, look up an exercise's muscle map. Turn on Settings → Demo mode and check Progress and records. Export a CSV. Report anything slow, wrong or confusing with a screenshot via TestFlight.
```
