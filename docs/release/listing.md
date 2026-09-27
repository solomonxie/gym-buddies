# Publishing Gym Buddy — step by step

Every field below is ready to paste. `TODO` = only you can supply it.
App Store Connect paths start at **Apps → Gym Buddy → Distribution →**.

| | |
|---|---|
| Bundle ID | `com.example.gymbuddy` |
| SKU | `gymbuddy-ios` |
| Version | `1.0` (`MARKETING_VERSION` in `project.yml`) |
| Build | timestamp, set by `make release` |
| Devices | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) — no iPad screenshots needed |
| Min iOS | 17.0 |
| Privacy Policy URL | `https://github.com/solomonxie/gym-buddy/blob/master/docs/release/privacy-policy.md` |
| Support URL | `https://github.com/solomonxie/gym-buddy/issues` |

---

## 1. Apple Developer account

- [ ] developer.apple.com → Account → membership **active** (paid, Individual is fine).
- [ ] App Store Connect → **Business** (Agreements, Tax, and Banking) → no pending agreement banner. Free app: no Paid Apps agreement or banking needed.

## 2. Xcode and signing

- [ ] Xcode → Settings → **Accounts** → signed in with the developer Apple ID; the team shows under it.
- [ ] `cp Local.xcconfig.example Local.xcconfig`, set your Team ID (developer.apple.com → Membership). Gitignored — never commit it; the repo is public.
- [ ] `brew install xcodegen` once. `make check` passes: Core tests plus a device build.

## 3. Bundle ID and iCloud container

Created by automatic signing on the first device build. Verify at developer.apple.com →
Certificates, Identifiers & Profiles:

- [ ] Identifiers → `com.example.gymbuddy` → **iCloud** checked (iCloud Documents), container `iCloud.com.example.gymbuddy` assigned.
- [ ] `ExportOptions.plist` sets `iCloudContainerEnvironment = Production` at export — the entitlements file pins no environment.

Local notifications need no capability.

## 4. Run on the iPhone

- [ ] `make device`. Smoke-test: build a workout, start it, log sets, lock the phone during rest and get the notification, finish, see it in Progress. Settings → Automatic backups → On this phone lists a snapshot; restore it. Turn on Back up to iCloud and find today's file in Files → iCloud Drive → Gym Buddy.

## 5. Create the app in App Store Connect

**Apps → + → New App**

| Field | Value |
|---|---|
| Platforms | iOS |
| Name | `Gym Buddy: Workout Log` |
| Primary Language | English (U.S.) |
| Bundle ID | `com.example.gymbuddy` (dropdown) |
| SKU | `gymbuddy-ios` |
| User Access | Full Access |

If the name is taken, in order of preference: `Gym Buddy — Set Tracker` (23),
`Gym Buddy: Lift Log` (19), `Gym Buddy Workout Tracker` (25). The on-device name stays
`Gym Buddy` (`CFBundleDisplayName`) whichever you pick.

## 6. Listing content

Fill the pages in [App Store Connect pages](#app-store-connect-pages). Screenshots: [Screenshots](#screenshots).

## 7. Archive and upload

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

## 8. TestFlight

- [ ] **TestFlight** → the build shows no "Missing Compliance" (see [Export compliance](#export-compliance)).
- [ ] Internal Testing → **+** group `Me` → add your Apple ID → install via the TestFlight app.
- [ ] Same smoke test as step 4, on the TestFlight build — the exact binary Apple reviews. Check the rest notification with the phone locked, and iCloud backup specifically — it's the Production container now.

## 9. Submit

- [ ] `iOS App → 1.0 Prepare for Submission` → **Build** → **+** → pick the build.
- [ ] Every page in [App Store Connect pages](#app-store-connect-pages) filled; App Privacy published.
- [ ] **Add for Review** → **Submit for Review**.

## 10. App Review

- Typical: 24–48 h. Waiting for Review → In Review → Pending Developer Release.
- Rejection → **Resolution Center**: reply there, or fix and `make release` again (fresh build number), attach it, resubmit. `MARKETING_VERSION` needn't change for a rejected version.
- Likely question: 4.2 Minimum Functionality for a "simple" tracker. The review notes point at what it does that a note-taking app doesn't.

## 11. Release

- [ ] **Pending Developer Release** → `1.0` page → **Release This Version**. Live within ~24 h.
- [ ] `git tag v1.0 && git push --tags`.

---

## Screenshots

Apple requires one set: **iPhone 6.9" Display**, `1320 × 2868` (or `1290 × 2796`). App Store
Connect scales it for every smaller phone. The 6.5" slot (`1284 × 2778`) is optional and
generated anyway.

1. Unlock the paired iPhone, dark mode on (the app's best look), leave it on the home screen.
2. `make capture` — installs the Debug build and shoots eight screens from built-in demo data
   (held in memory; your real history is never opened). Output: `/tmp/gymbuddy-shots/`.
3. Check the status bar in each shot: full battery and no notification banner look best —
   charge first, and turn on Do Not Disturb.
4. `make screenshots SHOTS=/tmp/gymbuddy-shots` → overwrites `docs/release/screenshots/{6.9,6.5}/`.
5. Drag the `6.9` files into the 6.9" slot, in name order:

| # | Screen | Why it's there |
|---|---|---|
| 01 | Session | the product: one-tap Log set, thumb-zone steppers |
| 02 | Resting | rest timer above the button, never blocking it |
| 03 | Train | up-next workout, one tap to start |
| 04 | Progress | week, volume by muscle group, history |
| 05 | Trend | per-exercise chart |
| 06 | Exercise | muscle map, best, how-to |
| 07 | Summary | records, and the plan-update question |
| 08 | Library | 300 exercises, ♥ filter |

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
| Support URL | `https://github.com/solomonxie/gym-buddy/issues` |
| Marketing URL | leave blank |
| Version | `1.0` |
| Copyright | `2026 solomonxie` |
| Routing App Coverage File | leave blank |
| Build | the uploaded build (step 9) |
| App Review → Sign-In Required | Off |
| App Review → Contact First / Last Name | TODO |
| App Review → Phone | TODO (with country code, e.g. `+1 …`) |
| App Review → Email | TODO |
| App Review → Notes | below |
| App Review → Attachment | none |
| Version Release | **Manually release this version** |

Promotional Text (≤170):

```
Log a set in one tap. The + button moves the weight by what your equipment actually allows. Rest timer that reaches a locked phone. No ads, no account.
```

Description:

```
Gym Buddy is a workout log built for the thirty seconds between sets — phone at arm's length, one hand on the bar.

No ads. No account. No subscription. Your data stays on your phone — and in your own iCloud, if you turn backup on.

ONE TAP PER SET
• A full-width Log set button, right where your thumb already is
• Reps and weight arrive pre-filled from your plan; nudge them with big − and + buttons, or tap the number to type it
• "Last time" shows what you lifted on this set last session
• Hold Log set to record several warm-up sets at once

+ MOVES LIKE THE EQUIPMENT DOES
• A machine steps by a pin, a barbell by a pair of plates, dumbbells by the rack's step, kettlebells by bell size
• No more ten taps to move one pin, and no loads that no plate set can make

REST THAT REACHES YOUR POCKET
• Rest starts on its own when you log a set
• A notification fires with the screen locked; +30s keeps the time already rested
• The timer never blocks the next set

TRAIN YOUR WAY
• Build workouts: sets, reps, weight and rest per exercise, drag to reorder
• Cardio in minutes; a treadmill tracks its incline instead of a weight
• Skip an exercise or jump to another when the rack you wanted is busy
• Double-progression suggestions — hit every rep and it offers one step heavier. Always a question, never a change made for you
• Today's weights never rewrite your plan unless you say so at the end

300 EXERCISES
• Organised by muscle group, searchable, with favourites
• A muscle map for each movement and three-step how-tos where they've been reviewed
• Add your own

PROGRESS
• This week at a glance, volume by muscle group, full history
• Per-exercise charts: top set, volume or reps, over 30 days, 90 days or all time
• Personal records marked when you set them

YOUR DATA
• kg or lb, switchable any time — history is stored once and converted for display
• Automatic backups after every change, kept on the phone for 7 days; restore any of them
• Optional daily backup to your own iCloud Drive, so a new phone picks up where you left off
• Export sessions as CSV for your own spreadsheets

Free, with no ads, no analytics and no upsell.
```

Keywords (≤100 — "gym" and "buddy" omitted, the name indexes them):

```
workout,log,tracker,weightlifting,strength,sets,reps,rest timer,lifting,fitness,progress,no ads
```

App Review Notes:

```
No account or login is needed. To try it quickly: Train tab → + → name a workout → Add exercises → pick two or three → back → Start workout. Log a set with the orange button; the rest timer starts on its own, and with the phone locked a local notification fires when rest is over (allow notifications when asked).

The app makes no network requests of its own. All data is in a local SQLite database on the device, with automatic snapshots in the app container. Settings → Back up to iCloud (off by default) copies the database once a day into the user's own iCloud Drive container. Settings → Export… hands the file to the share sheet, and Import… restores one.

Exercise illustrations are muscle maps drawn in code plus SF Symbols; no third-party artwork is bundled.
```

What's New: not shown for a first version. From 1.1 on, write it here.

### `General → App Information`

| Field | Value |
|---|---|
| Name | `Gym Buddy: Workout Log` (22/30) |
| Subtitle | `Log sets in one tap. No ads.` (28/30) |
| Category — Primary | Health & Fitness |
| Category — Secondary | Utilities |
| Content Rights | **No**, it does not contain, show, or access third-party content |
| Age Rating | **Edit** → answers below → result **4+** |
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
| Medical or treatment information | None |
| Health & wellness topics | **No** — it records sets you log; it gives no health advice |
| Gambling, simulated gambling, contests, loot boxes | None / No |
| Made for Kids | No |

Regional (Korea, China Mainland, Vietnam) — leave unset.
**Digital Services Act** trader status: **Not a trader** (free, no monetization).

### `App Store → Trust & Safety → App Privacy`

| Field | Value |
|---|---|
| Privacy Policy URL | as above |
| Do you or your third-party partners collect data from this app? | **No, we do not collect data from this app** |

Then **Publish**. The label shows "Data Not Collected".

True only while there is no network code and no SDK — iCloud backup goes to the user's own
iCloud Drive, which Apple doesn't count as collection by the developer. Re-check before each submission:

```
grep -rnE "URLSession|URLRequest|NWConnection|analytics|firebase|sentry" Sources Core/Sources
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
| Availability | All countries or regions |
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
