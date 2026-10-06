# Publishing Gym Buddies — step by step

Every field below is ready to paste. `TODO` = only you can supply it.
App Store Connect paths start at **Apps → Gym Buddies — Workout Tracker → Distribution →**.

| | |
|---|---|
| Bundle ID | `com.example.gymbuddy` |
| SKU | `gymbuddy-ios` |
| Version | `1.0` (`MARKETING_VERSION` in `project.yml`) |
| Build | timestamp, set by `make release` |
| Devices | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) — no iPad screenshots needed |
| Min iOS | 17.0 |
| Privacy Policy URL | `https://github.com/solomonxie/gym-buddies/blob/master/docs/release/privacy-policy.md` |
| Support URL | `https://github.com/solomonxie/gym-buddies/issues` |

---

## 1. Apple Developer account

- [ ] developer.apple.com → Account → membership **active** (paid, Individual is fine).
- [ ] App Store Connect → **Business** (Agreements, Tax, and Banking) → no pending agreement banner. Free app: no Paid Apps agreement or banking needed.

## 2. Xcode and signing

- [ ] Xcode → Settings → **Accounts** → signed in with the developer Apple ID; the team shows under it.
- [ ] `cp Local.xcconfig.example Local.xcconfig`, set your Team ID (developer.apple.com → Membership). Gitignored — never commit it; the repo is public.
- [ ] `brew install xcodegen` once. `make check` passes: Core tests plus a device build.

## 3–4. Bundle ID and iCloud container

Created by automatic signing on the first device build. Verify at developer.apple.com →
Certificates, Identifiers & Profiles:

- [ ] Identifiers → `com.example.gymbuddy` → **iCloud** checked (iCloud Documents), container `iCloud.com.example.gymbuddy` assigned.
- [ ] `ExportOptions.plist` sets `iCloudContainerEnvironment = Production` at export — the entitlements file pins no environment.

Local notifications need no capability.

## 5. Run on the iPhone

- [ ] `make device`. Smoke-test: Workouts **+** → add a template (and a blank one), start it, log sets with **End set**, lock the phone during rest and get the notification. × → Keep in background — the mini bar keeps it running. A timed or swim line counts down after **Start set**. Finish, see it under Progress. Gyms → add one with hours; "open now" updates. Settings (last row on the home screen) → Automatic backups → On this phone lists a snapshot; restore it. Turn on Back up to iCloud and find today's file in Files → iCloud Drive → Gym Buddies.

## 6. Create the app in App Store Connect

**Apps → + → New App**

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Gym Buddies — Workout Tracker` (29/30) — accepted in App Store Connect |
| Primary Language | English (U.S.) |
| Bundle ID | `com.example.gymbuddy` (dropdown) |
| SKU | `gymbuddy-ios` |
| User Access | Full Access |

The old name "Gym Buddy" is trademarked and "Gym Buddy: Workout Log" is taken, so the store name is
`Gym Buddies — Workout Tracker`. Keep the on-device name (`CFBundleDisplayName`) in step with
it: `Gym Buddies`. Never use "Gym Buddy" in the name, subtitle or keywords.

## 7. Listing content

Fill the pages in [App Store Connect pages](#app-store-connect-pages). Screenshots: [Screenshots](#screenshots).

## 8–9. Archive and upload

```
make release
```

Runs the Core tests and a build, then archives Release, signs for the App Store and uploads —
no Xcode Organizer. `make release BUILD=202609261830` pins the build number; left off it is a
timestamp.

Upload authenticates as the Apple ID signed into Xcode → Settings → Accounts. If it asks for
credentials in a terminal, add an App Store Connect API key instead: download the `.p8`, then
append `-authenticationKeyPath <abs path> -authenticationKeyID <id> -authenticationKeyIssuerID <issuer>`
to the `-exportArchive` call in `scripts/release-ios.sh`.
Processing: 15–60 min, then an email "build has completed processing".

Fallback, Xcode GUI: open `GymBuddy.xcodeproj` → destination **Any iOS Device (arm64)** →
Product → **Archive** → Organizer → **Distribute App** → App Store Connect → Upload.

## 10. TestFlight

- [ ] **TestFlight** → the build shows no "Missing Compliance" (see [Export compliance](#export-compliance)).
- [ ] Internal Testing → **+** group `Me` → add your Apple ID → install via the TestFlight app.
- [ ] Same smoke test as step 5, on the TestFlight build — the exact binary Apple reviews. Check the rest notification with the phone locked, and iCloud backup specifically — it's the Production container now.

## 11. Submit

- [ ] `iOS App → 1.0 Prepare for Submission` → **Build** → **+** → pick the build.
- [ ] Every page in [App Store Connect pages](#app-store-connect-pages) filled; App Privacy published.
- [ ] **Add for Review** → **Submit for Review**.

## 12. App Review

- Typical: 24–48 h. Waiting for Review → In Review → Pending Developer Release.
- Rejection → **Resolution Center**: reply there, or fix and `make release` again (fresh build number), attach it, resubmit. `MARKETING_VERSION` needn't change for a rejected version.
- Likely questions: 4.2 Minimum Functionality for a "simple" tracker — the notes point at what it does that a note-taking app doesn't. 1.4.1 for the two Pregnancy templates — each tells the user to get a midwife's or doctor's OK first and lists stop signs; About says it's not a coach.

### Guideline 2.1 "Information Needed" (new developer accounts)

Apple wants a screen recording plus answers 2–6. The answers are the App Review Notes further down — paste them into the reply **and** into App Review → Notes.

Record the build Apple will review. If it's a new build, upload it first (`make release`), pick it under **Build** on the `1.0` page, and install it from TestFlight.

Recording (the build Apple reviews, on the iPhone, current iOS):
1. iPhone Settings → Control Center → add **Screen Recording**. Turn on Do Not Disturb.
2. Start from a fresh install (delete the app first) so no personal history shows.
3. Start recording, then launch the app from the Home Screen.
4. ~2 minutes: **Build a workout** → Gym basics → Light Gym · 30 min → Add workout → Start → Skip the treadmill line → End set on Leg Press (rest runs on the button, **+30s**) → lock the phone until the rest notification arrives → unlock → × → Keep in background (mini bar on the home screen) → tap it to resume → × → Save & exit → summary → home: Progress → an exercise's trend → Exercises (search, open one: muscle map, how-to) → Gyms (add one, set hours) → Settings (units, rest, Automatic backups, Export…, About).
5. Stop. Photos → trim → share the video.

Reply: `App Review` in App Store Connect → the message → **Reply**, attach the video (or an unlisted link if it's too large), paste:

```
Hello, thank you for the review. Answers below, and the same text is now in the App Review Information notes.

1. Screen recording attached, captured on an iPhone 14 running the latest iOS, starting from launch. The app has no account registration or login (so no account deletion flow), no user-generated content shared with anyone, and no paid content.

[paste the App Review Notes block from PURPOSE AND AUDIENCE to the end]
```

## 13. Release

- [ ] **Pending Developer Release** → `1.0` page → **Release This Version**. Live within ~24 h.
- [ ] `git tag v1.0 && git push --tags`.

---

## Screenshots

Apple requires one set: **iPhone 6.9" Display**, `1320 × 2868` (or `1290 × 2796`). App Store
Connect scales it for every smaller phone.

**Ready** — `screenshots/`, ten JPEGs (no alpha), captured 2026-10-02 in Demo mode
on the iPhone 18 Pro simulator, light appearance, 9:41 status bar. Upload in filename order:

| # | File | Why it's there |
|---|---|---|
| 1 | `01-session` | the product: one big set button, reps and weight with − / + in the thumb zone |
| 2 | `02-resting` | rest counts down on the button, +30s beside it |
| 3 | `03-train` | home: up next, one tap to start, Exercises and Gyms tiles |
| 4 | `04-progress` | week, volume by muscle group, history |
| 5 | `05-trend` | per-exercise chart |
| 6 | `06-summary` | records, and the plan-update question |
| 7 | `07-exercise` | muscle map, best, trend |
| 8 | `08-gyms` | open on arrival, travel time, price |
| 9 | `09-treadmill` | timed cardio counting down, incline instead of weight |
| 10 | `10-library` | 300+ exercises, favourites |

Retake: Debug build on a simulator (or `make capture` on the iPhone), launch with
`-demo -screen <name>` (session, resting, train, logs, trend, summary, exercise, gyms, treadmill,
exercises), then `make screenshots SHOTS=<dir>`. The README shows the `6.9` set.

App Preview video: skip for 1.0.

---

## App Store Connect pages

### `iOS App → 1.0 Prepare for Submission`

| Field | Value |
|---|---|
| Previews and Screenshots | [Screenshots](#screenshots) |
| Promotional Text | below |
| Description | below |
| Keywords | below |
| Support URL | `https://github.com/solomonxie/gym-buddies/issues` |
| Marketing URL | leave blank |
| Version | `1.0` |
| Copyright | `2026 solomonxie` |
| Routing App Coverage File | leave blank |
| Build | the uploaded build (step 11) |
| App Review → Sign-In Required | Off |
| App Review → Contact First / Last Name | TODO |
| App Review → Phone | TODO (with country code, e.g. `+1 …`) |
| App Review → Email | TODO |
| App Review → Notes | below |
| App Review → Attachment | none |
| Version Release | **Manually release this version** |

Promotional Text (150/170):

```
Log a set in one tap. The + button moves the weight by what your equipment actually allows. Rest timer that reaches a locked phone. No account needed.
```

Description:

```
Gym Buddies is a workout log built for the thirty seconds between sets — phone at arm's length, one hand on the bar.

No ads. No account. No subscription. Your data stays on your phone — and in your own iCloud, if you turn backup on.

ONE TAP PER SET
• One full-width set button, right where your thumb already is: End set logs it, Start set times it
• Reps and weight sit just above it, pre-filled from your plan; nudge them with − and +, or tap the number to type it
• "Last time" shows what you lifted on this set last session
• Hold the button to record several warm-up sets at once
• Leave mid-workout and it keeps running behind a mini bar

+ MOVES LIKE THE EQUIPMENT DOES
• A machine steps by a pin, a barbell by a pair of plates, dumbbells by the rack's step, kettlebells by bell size
• No more ten taps to move one pin, and no loads that no plate set can make

REST THAT REACHES YOUR POCKET
• Rest starts on its own when you log a set and counts down on the button
• A notification fires with the screen locked; +30s keeps the time already rested
• Start the next set early whenever you're ready
• Timed sets count down, with a vibration for the last three seconds

TRAIN YOUR WAY
• Build workouts: sets, reps, weight and rest per exercise, drag to reorder
• Or start from a template: gym basics, strength, around the workday, sport, swim and pregnancy
• Cardio in minutes; a treadmill tracks its incline instead of a weight
• Swim in laps, with your pool's length (15 m to 50 m, or 25 yd) turning laps into distance
• Skip an exercise or jump to another when the rack you wanted is busy
• Double-progression suggestions — hit every rep and it offers one step heavier. Always a question, never a change made for you
• Today's weights never rewrite your plan unless you say so at the end

300+ EXERCISES
• Organised by muscle group, searchable, with favourites
• A muscle map for each movement and three-step how-tos where they've been reviewed
• Add your own

GYMS
• Tick the machines and equipment each gym has, its hours, price and travel time
• See which are open by the time you'd get there
• A workout tells you which exercises a gym can't do

PROGRESS
• This week at a glance, volume by muscle group, full history
• Per-exercise charts: top set, volume or reps, over 30 days, 90 days or all time
• Personal records marked when you set them

YOUR DATA
• kg or lb, switchable any time — history is stored once and converted for display
• Automatic backups after every change: today's and one for each of the last six days, kept on the phone; restore any of them
• Optional backup to your own iCloud Drive, one file a day for 30 days, so a new phone picks up where you left off
• Export sessions as CSV for your own spreadsheets

Gym Buddies is a log, not a coach: templates are starting points, not medical advice.

Free, with no ads, no analytics and no upsell.
```

Keywords (100/100 — the name indexes gym, buddies, workout, tracker; the subtitle indexes sets, rest, timer):

```
log,weightlifting,strength,reps,lifting,fitness,progress,swim,plan,exercise,routine,training,barbell
```

App Review Notes (also the Guideline 2.1 answers):

```
No account or login. The app opens on an empty home screen; a workout is added with one tap from the built-in templates.

PURPOSE AND AUDIENCE
Gym Buddies is a workout log for adults who train in a gym, at home or in a pool. It is built for the moment between sets: one large button logs the set, the next set's reps and weight are pre-filled, and rest is timed automatically with a local notification that reaches a locked phone. It replaces paper notebooks and generic notes apps, which don't time rest, track progress per exercise, or know how much a given machine or barbell can step by.

HOW TO USE THE MAIN FEATURES (no setup needed)
- Home: Build a workout (or Workouts + once one exists) → pick a template (e.g. Gym basics → Light Gym · 30 min) → Add workout → Start on the Up next card.
- Session: End set logs a set; rest then counts down on the same button (+30s beside it). Timed and cardio lines use Start set. Skip, go back, or jump with the list icon. Lock the phone during rest to see the notification (allow notifications when asked). × → Keep in background shows a mini bar on home; × → Save & exit shows the summary.
- Progress (home card): weekly view, volume by muscle group, history, per-exercise charts.
- Exercises (home tile): 300+ movements, search, favourites, muscle map, how-to steps.
- Gyms (home tile): equipment a gym has, opening hours, travel time; which are open now.
- Settings (last row on home): kg/lb, rest times, automatic backups, iCloud backup, export/import.

OPTIONAL FEATURES
- Back up to iCloud (off by default): copies the database to the user's own iCloud Drive (iCloud Drive → Gym Buddies).
- Rest and timer alerts (on by default, can be turned off): local notifications; permission is asked when the first workout starts.

EXTERNAL SERVICES
None of our own. The app makes no network requests. Only if the user turns it on, iOS syncs the backup file through the user's own iCloud Drive. Export uses the iOS share sheet. No analytics, advertising, crash reporting, authentication or payment services. We run no server.

REGIONAL DIFFERENCES
None. English only; the app works the same in every region. Weights in kg or lb, pools in metres or yards.

REGULATION
Gym Buddies is a personal record-keeping tool, not a medical device, and gives no medical advice. It does not read or write Apple Health. Workout templates are general exercise starting points; the two Pregnancy templates tell the user to get their midwife's or doctor's OK first and list when to stop. Exercise illustrations are muscle maps drawn in code plus SF Symbols; no third-party artwork, content or code is bundled.

All data is stored in a local SQLite database on the device. We receive no user data.
```

What's New: not shown for a first version. From 1.1 on, write it here.

### `General → App Information`

| Field | Value |
|---|---|
| Name | `Gym Buddies — Workout Tracker` (29/30) |
| Subtitle | `One-tap sets and rest timer` (27/30) |
| Category — Primary | Health & Fitness |
| Category — Secondary | Utilities |
| Content Rights | **No**, it does not contain, show, or access third-party content |
| Regulated Medical Device | **No**, a personal log that gives no diagnosis or treatment (required before Add for Review) |
| Age Rating | **Edit** → answers below → accept the result App Store Connect computes (expected 4+) |
| License Agreement | Apple standard EULA (default) |
| Privacy Policy URL | as above |

Age rating questionnaire — every answer:

| Section | Answer |
|---|---|
| Parental controls / age assurance | No |
| Unrestricted web access | No — there is no browser |
| User-generated content | No — notes are private to the device, never shared or published |
| Messaging and chat | No |
| Advertising | No |
| Violence, sexual content, profanity, horror, mature themes | None |
| Alcohol, tobacco, drugs | None |
| Medical or treatment information | None — no diagnosis or treatment; the Pregnancy templates only say to get a doctor's OK first |
| Health & wellness topics | **Yes** — general exercise templates, two of them for pregnancy |
| Gambling, simulated gambling, contests, loot boxes | None / No |
| Made for Kids | No |

Regional (Korea, China Mainland, Vietnam) — leave unset.
**Digital Services Act** trader status: **Not a trader** (free, no monetization).

### `App Store → Trust & Safety → App Privacy`

| Field | Value |
|---|---|
| Privacy Policy URL | as above |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |

Then **Publish**. The label shows "Data Not Collected". No location, Health, camera, photos or contacts access — gyms are whatever the user types.

True only while there is no network code and no SDK — iCloud backup goes to the user's own
iCloud Drive, which Apple doesn't count as collection by the developer. Re-check before each submission:

```
grep -rnE "URLSession|URLRequest|NWConnection|CLLocation|HealthKit|analytics|firebase|sentry" Sources Core/Sources
```

`Resources/PrivacyInfo.xcprivacy` is the matching privacy manifest: no tracking, no collected
data, required-reason APIs declared (file size lookup for the backup, `UserDefaults` for view
preferences).

### `App Store → Trust & Safety → App Accessibility`

Skip for 1.0 rather than over-claim. After a full VoiceOver and Larger Text pass, declare those two.

### `App Store → Monetization → Pricing and Availability`

| Field | Value |
|---|---|
| Base Country or Region | United States (USD) |
| Price | **Free** ($0.00) |
| Availability | All countries or regions. China mainland asks for an ICP filing number; without one, untick China mainland |
| Tax Category | App Store software (default) |
| iPhone and iPad Apps on Apple Silicon Macs | **Off** for 1.0 |
| Apple Vision Pro | Off |

### Not needed for 1.0

In-App Purchases, Subscriptions, In-App Events, Custom Product Pages, Product Page
Optimization, Promo Codes, Game Center, Featuring Nominations.

---

## Export compliance

Nothing to fill in. `ITSAppUsesNonExemptEncryption = false` (set in `project.yml`) answers
it at upload — the app uses no encryption beyond what iOS provides.
Verify: TestFlight → the build is **not** marked "Missing Compliance".
Only if it is: **Manage** → **None of the algorithms mentioned above**.
