import Foundation

/// The built-in catalogue. Instructions are three cues for the mistakes people
/// most often make, and are left out where a movement is too variable to
/// describe without guessing.
public enum SeedLibrary {
    public static let exercises: [Exercise] =
        arms + back + chest + shoulders + legs + core + cardio + fullBody + swim + mobility

    public static var byID: [String: Exercise] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    /// Lowercase, alphanumerics kept, every other run collapsed to one hyphen.
    static func slug(_ name: String) -> String {
        var out = ""
        for ch in name.lowercased() {
            if ch.isASCII, ch.isLetter || ch.isNumber {
                out.append(ch)
            } else if !out.isEmpty, out.last != "-" {
                out.append("-")
            }
        }
        while out.last == "-" { out.removeLast() }
        return out
    }

    private static func e(
        _ name: String,
        id: String? = nil,
        _ group: MuscleGroup,
        _ equipment: Equipment,
        _ muscles: [Muscle],
        timed: Bool = false,
        minutes: Bool = false,
        laps: Bool = false,
        how: [String] = []
    ) -> Exercise {
        Exercise(
            id: id ?? slug(name),
            name: name,
            muscleGroup: group,
            equipment: equipment,
            muscles: muscles,
            instructions: how.isEmpty ? nil : how.joined(separator: "\n"),
            measure: laps ? .laps : minutes ? .minutes : timed ? .seconds : .reps
        )
    }

    // MARK: - Arms

    private static let arms: [Exercise] = [
        e("Barbell Curls", .arms, .barbell, [.biceps, .forearms], how: [
            "Pin your elbows at your sides; don't let them drift forward",
            "No hip swing; if you have to lean back, the weight is too heavy",
            "Lower all the way to straight arms under control",
        ]),
        e("Cable Tricep Extensions", .arms, .cable, [.triceps], how: [
            "Keep your elbows fixed; only the forearms move",
            "Lock out fully on every rep",
            "Don't lean over the handle to push with bodyweight",
        ]),
        e("Dumbbell Hammer Curls", .arms, .dumbbell, [.biceps, .forearms], how: [
            "Palms face each other the whole rep; don't rotate",
            "Keep elbows by your sides instead of swinging them forward",
            "Lower slowly to full extension",
        ]),
        e("Dumbbell Curls", .arms, .dumbbell, [.biceps, .forearms], how: [
            "Turn palms up as you lift; finish with the pinky higher",
            "Keep elbows still; don't swing the shoulders into it",
            "Lower to straight arms before the next rep",
        ]),
        e("EZ Bar Curls", .arms, .barbell, [.biceps, .forearms], how: [
            "Grip the angled part so wrists sit comfortably",
            "Keep elbows at your sides; don't lean back to finish",
            "Lower all the way down under control",
        ]),
        e("Incline Dumbbell Curls", .arms, .dumbbell, [.biceps], how: [
            "Keep your back and head on the bench throughout",
            "Let arms hang straight down; don't bring elbows forward",
            "Use lighter weight than standing curls",
        ]),
        e("Concentration Curls", .arms, .dumbbell, [.biceps], how: [
            "Brace the upper arm against the inner thigh",
            "Curl toward the shoulder without lifting the elbow off",
            "Lower fully; don't cut the bottom short",
        ]),
        e("Barbell Preacher Curls", .arms, .barbell, [.biceps], how: [
            "Keep the back of your arms flat on the pad",
            "Stop just short of lockout at the bottom to protect elbows",
            "Don't lift your hips off the seat to finish reps",
        ]),
        e("Dumbbell Preacher Curls", .arms, .dumbbell, [.biceps], how: [
            "Keep the back of your arm flat on the pad",
            "Stop just short of lockout to protect the elbow",
            "Don't lift your shoulder to finish the rep",
        ]),
        e("Machine Preacher Curls", .arms, .machine, [.biceps], how: [
            "Set the seat so armpits sit at the top of the pad",
            "Keep elbows on the pad through the whole rep",
            "Lower slowly to nearly straight arms",
        ]),
        e("Cable Curls", .arms, .cable, [.biceps, .forearms], how: [
            "Stand close enough that the cable pulls straight down",
            "Keep elbows pinned; don't lean back",
            "Lower until arms are straight",
        ]),
        e("Cable Hammer Curls", .arms, .cable, [.biceps, .forearms], how: [
            "Use a rope with thumbs pointing up",
            "Keep elbows pinned at your sides",
            "Lower until arms are straight",
        ]),
        e("Spider Curls", .arms, .dumbbell, [.biceps], how: [
            "Lie chest down on an incline bench, arms hanging",
            "Keep upper arms vertical; don't swing them forward",
            "Squeeze at the top, lower fully",
        ]),
        e("Zottman Curls", .arms, .dumbbell, [.biceps, .forearms], how: [
            "Curl up with palms facing up",
            "Turn palms down at the top and lower slowly",
            "Keep elbows still at your sides",
        ]),
        e("Reverse Barbell Curls", .arms, .barbell, [.forearms, .biceps], how: [
            "Grip overhand, hands shoulder width",
            "Keep wrists straight; don't let them bend back",
            "Use much less weight than a regular curl",
        ]),
        e("Drag Curls", .arms, .barbell, [.biceps]),
        e("Cross Body Hammer Curls", .arms, .dumbbell, [.biceps, .forearms], how: [
            "Curl toward the opposite shoulder, thumb up",
            "Keep the elbow by your side",
            "Lower fully before switching arms",
        ]),
        e("Band Curls", .arms, .band, [.biceps], how: [
            "Stand on the band with feet hip width",
            "Keep elbows at your sides",
            "Lower slowly against the band's pull",
        ]),
        e("Kettlebell Curls", .arms, .kettlebell, [.biceps, .forearms], how: [
            "Hold the handle with the bell hanging below",
            "Keep elbows pinned; don't swing",
            "Lower to straight arms",
        ]),
        e("Close Grip Bench Press", .arms, .barbell, [.triceps, .chest, .frontDelts], how: [
            "Hands about shoulder width; narrower strains the wrists",
            "Keep elbows tucked close to your sides",
            "Touch the lower chest, then press straight up",
        ]),
        e("Skull Crushers", .arms, .barbell, [.triceps], how: [
            "Lower the bar behind the top of your head, not to your face",
            "Keep upper arms still; don't turn it into a press",
            "Keep elbows from flaring out wide",
        ]),
        e("Dumbbell Skull Crushers", .arms, .dumbbell, [.triceps], how: [
            "Lower the dumbbells beside your head, not onto it",
            "Keep upper arms still and pointing up",
            "Keep elbows from flaring out",
        ]),
        e("Overhead Dumbbell Tricep Extensions", .arms, .dumbbell, [.triceps], how: [
            "Keep elbows pointing up, not flared out",
            "Lower behind your head until forearms pass parallel",
            "Brace your core so your lower back doesn't arch",
        ]),
        e("Overhead Cable Tricep Extensions", .arms, .cable, [.triceps], how: [
            "Keep elbows close to your head and pointing forward",
            "Stretch fully behind the head before extending",
            "Brace; don't let the ribs flare to move the weight",
        ]),
        e("Rope Pushdowns", .arms, .cable, [.triceps], how: [
            "Keep elbows pinned at your sides",
            "Spread the rope apart at the bottom and lock out",
            "Don't let the stack yank your hands above chest height",
        ]),
        e("Straight Bar Pushdowns", .arms, .cable, [.triceps], how: [
            "Keep elbows at your sides; only forearms move",
            "Lock out fully at the bottom",
            "Stand tall rather than hunching over the bar",
        ]),
        e("Single Arm Cable Pushdowns", .arms, .cable, [.triceps], how: [
            "Keep the working elbow pinned to your side",
            "Lock out fully at the bottom",
            "Don't twist the torso to push",
        ]),
        e("Tricep Dips", .arms, .bodyweight, [.triceps, .chest], how: [
            "Keep your torso upright to bias the triceps",
            "Lower until upper arms are about parallel, not deeper",
            "Don't let your shoulders roll forward at the bottom",
        ]),
        e("Bench Dips", .arms, .bodyweight, [.triceps], how: [
            "Keep hips close to the bench",
            "Lower only until upper arms are parallel to the floor",
            "Keep shoulders down, away from your ears",
        ]),
        e("Dumbbell Kickbacks", .arms, .dumbbell, [.triceps], how: [
            "Keep your upper arm parallel to the floor and still",
            "Extend fully and pause at lockout",
            "Don't swing the weight; go lighter",
        ]),
        e("Cable Kickbacks", .arms, .cable, [.triceps], how: [
            "Hinge forward with the upper arm parallel to the floor",
            "Only the forearm moves; lock out behind you",
            "Use light weight; don't swing",
        ]),
        e("Diamond Push Ups", .arms, .bodyweight, [.triceps, .chest], how: [
            "Keep your body in one straight line",
            "Elbows travel back along your sides, not out",
            "Touch your chest to your hands each rep",
        ]),
        e("Band Pushdowns", .arms, .band, [.triceps], how: [
            "Anchor the band high",
            "Keep elbows at your sides",
            "Lock out fully at the bottom",
        ]),
        e("Machine Tricep Extensions", .arms, .machine, [.triceps], how: [
            "Line up your elbows with the machine's pivot",
            "Extend fully and squeeze",
            "Control the return; don't let the stack drop",
        ]),
        e("JM Press", .arms, .barbell, [.triceps]),
        e("Barbell Wrist Curls", .arms, .barbell, [.forearms], how: [
            "Rest forearms on your thighs or a bench, wrists over the edge",
            "Let the bar roll to your fingertips, then curl it back up",
            "Move only at the wrist; keep forearms down",
        ]),
        e("Reverse Wrist Curls", .arms, .barbell, [.forearms], how: [
            "Rest forearms on a bench, palms facing down",
            "Lift the back of the hand; only the wrist moves",
            "Use much lighter weight than wrist curls",
        ]),
        e("Dumbbell Wrist Curls", .arms, .dumbbell, [.forearms], how: [
            "Rest the forearm on a bench, wrist over the edge",
            "Let the dumbbell roll toward the fingers, then curl",
            "Keep the forearm still",
        ]),
        e("Wrist Roller", .arms, .none, [.forearms]),
        e("Plate Pinch", .arms, .none, [.forearms], timed: true),
    ]

    // MARK: - Back

    private static let back: [Exercise] = [
        e("Seated Machine Rows", .back, .machine, [.lats, .traps, .biceps], how: [
            "Sit tall; don't rock the torso back to move the weight",
            "Pull elbows back and squeeze shoulder blades together",
            "Let the shoulder blades travel forward on the return",
        ]),
        e("Lat Pull Downs", .back, .machine, [.lats, .biceps], how: [
            "Pull to the upper chest, not behind the neck",
            "Lead with the elbows; don't lean far back",
            "Let arms straighten fully at the top",
        ]),
        e("Barbell Deadlifts", .back, .barbell, [.lowerBack, .glutes, .hamstrings], how: [
            "Bar over midfoot and touching your shins before you pull",
            "Keep your back flat; hips and shoulders rise together",
            "Stand tall at the top; don't lean back",
        ]),
        e("Pull Ups", .back, .bodyweight, [.lats, .biceps], how: [
            "Start from a full hang, arms straight",
            "Pull until your chin clears the bar without craning the neck",
            "Don't kick or swing to finish reps",
        ]),
        e("Chin Ups", .back, .bodyweight, [.lats, .biceps], how: [
            "Palms facing you, hands about shoulder width",
            "Start each rep from straight arms",
            "Get your chin over the bar without reaching with the neck",
        ]),
        e("Neutral Grip Pull Ups", .back, .bodyweight, [.lats, .biceps], how: [
            "Palms face each other on parallel handles",
            "Start each rep from straight arms",
            "Pull until your chin clears the handles",
        ]),
        e("Assisted Pull Ups", .back, .machine, [.lats, .biceps], how: [
            "More counterweight means easier, not harder",
            "Go to straight arms at the bottom of every rep",
            "Keep the same form you'd use unassisted",
        ]),
        e("Band Assisted Pull Ups", .back, .band, [.lats, .biceps], how: [
            "Loop the band over the bar and under a foot or knee",
            "Thicker band means more help",
            "Start every rep from straight arms",
        ]),
        e("Scapular Pull Ups", .back, .bodyweight, [.lats, .traps], how: [
            "Hang with arms straight throughout",
            "Pull shoulders down away from your ears",
            "Keep elbows locked; this isn't a pull up",
        ]),
        e("Inverted Rows", .back, .bodyweight, [.lats, .traps, .biceps], how: [
            "Keep your body rigid from heels to head",
            "Pull your chest to the bar, not your chin",
            "Lower until arms are fully straight",
        ]),
        e("Bent Over Barbell Rows", .back, .barbell, [.lats, .traps, .rearDelts], how: [
            "Hinge at the hips with a flat back",
            "Pull the bar to your lower ribs, not your chest",
            "Keep the torso still; don't stand up to finish reps",
        ]),
        e("Pendlay Rows", .back, .barbell, [.lats, .traps], how: [
            "Start each rep with the bar resting on the floor",
            "Back roughly parallel to the floor and flat",
            "Pull explosively to the lower chest",
        ]),
        e("One Arm Dumbbell Rows", .back, .dumbbell, [.lats, .traps, .biceps], how: [
            "Keep your back flat and hips square to the bench",
            "Pull the dumbbell toward your hip, not your shoulder",
            "Don't twist your torso to lift the weight",
        ]),
        e("Chest Supported Dumbbell Rows", .back, .dumbbell, [.lats, .traps, .rearDelts], how: [
            "Lie chest down on an incline bench",
            "Keep your chest on the pad as you row",
            "Pull elbows back toward your hips",
        ]),
        e("Seated Cable Rows", .back, .cable, [.lats, .traps, .biceps], how: [
            "Keep your torso upright; don't rock back and forth",
            "Pull the handle to your stomach and squeeze your back",
            "Let arms extend fully on the return",
        ]),
        e("Single Arm Cable Rows", .back, .cable, [.lats, .traps], how: [
            "Sit or stand tall facing the cable",
            "Pull the elbow back past your side",
            "Don't twist the torso to move the weight",
        ]),
        e("T Bar Rows", .back, .barbell, [.lats, .traps], how: [
            "Hinge forward with a flat back",
            "Drive elbows back, keeping them close to your body",
            "Don't jerk the weight up with your legs",
        ]),
        e("Seal Rows", .back, .barbell, [.lats, .traps, .rearDelts]),
        e("Meadows Rows", .back, .barbell, [.lats, .traps]),
        e("Kettlebell Rows", .back, .kettlebell, [.lats, .traps], how: [
            "Hinge with a flat back or brace on a bench",
            "Pull the bell toward your hip",
            "Don't rotate the torso to lift",
        ]),
        e("Band Rows", .back, .band, [.lats, .traps], how: [
            "Anchor the band at chest height",
            "Pull elbows back and squeeze your shoulder blades",
            "Return slowly against the band",
        ]),
        e("Machine High Rows", .back, .machine, [.lats, .traps]),
        e("Close Grip Lat Pull Downs", .back, .cable, [.lats, .biceps], how: [
            "Use a close neutral handle",
            "Pull to the upper chest, leaning back only slightly",
            "Let arms straighten fully at the top",
        ]),
        e("Single Arm Lat Pull Downs", .back, .cable, [.lats], how: [
            "Pull the elbow down toward your hip",
            "Keep the torso from twisting",
            "Let the arm straighten fully at the top",
        ]),
        e("Band Lat Pull Downs", .back, .band, [.lats], how: [
            "Anchor the band high overhead",
            "Pull elbows down to your sides",
            "Let arms straighten slowly",
        ]),
        e("Straight Arm Pulldowns", .back, .cable, [.lats], how: [
            "Keep arms nearly straight; this is not a pushdown",
            "Pull the bar in an arc down to your thighs",
            "Hinge slightly and keep the torso still",
        ]),
        e("Rack Pulls", .back, .barbell, [.lowerBack, .traps, .glutes], how: [
            "Set the bar just below or above the knee",
            "Keep a flat back and the bar against your legs",
            "Lock out by squeezing glutes, not leaning back",
        ]),
        e("Snatch Grip Deadlifts", .back, .barbell, [.lowerBack, .traps, .hamstrings]),
        e("Deficit Deadlifts", .back, .barbell, [.lowerBack, .glutes, .hamstrings]),
        e("Barbell Shrugs", .back, .barbell, [.traps], how: [
            "Lift the shoulders straight up toward your ears",
            "Don't roll the shoulders",
            "Pause at the top instead of bouncing",
        ]),
        e("Dumbbell Shrugs", .back, .dumbbell, [.traps], how: [
            "Shrug straight up; no rolling",
            "Keep arms straight; don't bend the elbows to help",
            "Hold the top for a second",
        ]),
        e("Machine Shrugs", .back, .machine, [.traps], how: [
            "Shrug straight up toward your ears",
            "Keep arms straight",
            "Pause at the top",
        ]),
        e("Back Extensions", .back, .bodyweight, [.lowerBack, .glutes, .hamstrings], how: [
            "Set the pad just below the hip bones",
            "Rise to a straight line, not past it",
            "Move slowly; don't fling the torso up",
        ]),
        e("Reverse Hyperextensions", .back, .machine, [.glutes, .lowerBack], how: [
            "Lie with hips at the edge of the pad",
            "Swing legs up with glutes to torso height, no higher",
            "Lower under control; don't let momentum take over",
        ]),
        e("Superman Hold", .back, .bodyweight, [.lowerBack, .glutes], timed: true, how: [
            "Lie face down, arms overhead",
            "Lift arms, chest, and legs slightly off the floor",
            "Look at the floor; don't crane your neck",
        ]),
        e("Dead Hang", .back, .bodyweight, [.forearms, .lats], timed: true, how: [
            "Grip the bar with arms fully straight",
            "Keep shoulders active, not shrugged up to the ears",
            "Hold without swinging",
        ]),
        e("Dumbbell Pullovers", .back, .dumbbell, [.lats, .chest], how: [
            "Hold one dumbbell over your chest, elbows slightly bent",
            "Lower behind your head only to a comfortable stretch",
            "Keep elbow bend fixed on the way up",
        ]),
        e("Cable Pullovers", .back, .cable, [.lats], how: [
            "Face a high cable with a rope or bar",
            "Keep arms nearly straight as you pull down",
            "Pull to your thighs, then return slowly",
        ]),
    ]

    // MARK: - Chest

    private static let chest: [Exercise] = [
        e("Barbell Bench Press", .chest, .barbell, [.chest, .triceps, .frontDelts], how: [
            "Pin shoulder blades back and down before you unrack",
            "Lower to mid chest with elbows angled, not flared at 90°",
            "Keep your feet planted and butt on the bench",
        ]),
        e("Dumbbell Flyes", .chest, .dumbbell, [.chest], how: [
            "Keep a slight, fixed bend in the elbows",
            "Lower only until you feel a stretch, not below the bench",
            "Bring the weights together in an arc; don't press them",
        ]),
        e("Push Ups", .chest, .bodyweight, [.chest, .triceps, .frontDelts], how: [
            "Hold a straight line; don't let hips sag or pike",
            "Elbows at about 45°, not flared straight out",
            "Chest to the floor, then lock out",
        ]),
        e("Incline Barbell Bench Press", .chest, .barbell, [.chest, .frontDelts, .triceps], how: [
            "Set the bench to about 30°; steeper is a shoulder press",
            "Lower the bar to the upper chest",
            "Keep shoulder blades pinned to the bench",
        ]),
        e("Decline Barbell Bench Press", .chest, .barbell, [.chest, .triceps]),
        e("Paused Bench Press", .chest, .barbell, [.chest, .triceps, .frontDelts], how: [
            "Lower as you would a normal bench press",
            "Pause motionless on the chest for a full second",
            "Press without bouncing or losing tightness",
        ]),
        e("Dumbbell Bench Press", .chest, .dumbbell, [.chest, .triceps, .frontDelts], how: [
            "Lower until the dumbbells are level with your chest",
            "Keep elbows at about 45° to your torso",
            "Press up and slightly in; don't clang the weights",
        ]),
        e("Incline Dumbbell Press", .chest, .dumbbell, [.chest, .frontDelts, .triceps], how: [
            "Keep the bench at about 30°",
            "Lower to the upper chest with elbows slightly tucked",
            "Keep shoulder blades back against the bench",
        ]),
        e("Decline Dumbbell Press", .chest, .dumbbell, [.chest, .triceps], how: [
            "Hook your feet before lying back",
            "Lower to the lower chest, elbows at about 45°",
            "Press up without clashing the dumbbells",
        ]),
        e("Incline Dumbbell Flyes", .chest, .dumbbell, [.chest, .frontDelts], how: [
            "Set the bench at about 30°",
            "Keep a slight, fixed bend in the elbows",
            "Stop at a comfortable stretch",
        ]),
        e("Dumbbell Squeeze Press", .chest, .dumbbell, [.chest, .triceps], how: [
            "Press the dumbbells firmly together the whole set",
            "Lower them to your chest while squeezing",
            "Keep elbows tucked",
        ]),
        e("Dumbbell Floor Press", .chest, .dumbbell, [.chest, .triceps], how: [
            "Lie on the floor, knees bent",
            "Lower until upper arms touch the floor, then pause",
            "Don't bounce elbows off the floor",
        ]),
        e("Barbell Floor Press", .chest, .barbell, [.chest, .triceps], how: [
            "Lie on the floor under the bar, knees bent",
            "Pause when your upper arms touch the floor",
            "Press without bouncing the elbows",
        ]),
        e("Kettlebell Floor Press", .chest, .kettlebell, [.chest, .triceps]),
        e("Smith Machine Bench Press", .chest, .machine, [.chest, .triceps, .frontDelts], how: [
            "Line the bar up with your mid chest",
            "Set the safety stops before you start",
            "Keep shoulder blades pinned back",
        ]),
        e("Smith Machine Incline Press", .chest, .machine, [.chest, .frontDelts], how: [
            "Set the bench at about 30°",
            "Line the bar up with your upper chest",
            "Set the safety stops before you start",
        ]),
        e("Machine Chest Press", .chest, .machine, [.chest, .triceps, .frontDelts], how: [
            "Set the seat so the handles line up with mid chest",
            "Keep your back against the pad",
            "Don't let the stack touch down between reps",
        ]),
        e("Incline Machine Chest Press", .chest, .machine, [.chest, .frontDelts], how: [
            "Set the seat so the handles line up with upper chest",
            "Keep your back against the pad",
            "Don't lock out hard at the top",
        ]),
        e("Pec Deck Flyes", .chest, .machine, [.chest], how: [
            "Set the seat so handles are at chest height",
            "Keep a slight bend in the elbows throughout",
            "Control the return; don't let the arms fly back",
        ]),
        e("Cable Crossovers", .chest, .cable, [.chest], how: [
            "Stagger your stance and lean slightly forward",
            "Keep elbows slightly bent and fixed",
            "Bring hands together in front of you; don't press",
        ]),
        e("Low To High Cable Flyes", .chest, .cable, [.chest, .frontDelts], how: [
            "Set the pulleys low",
            "Sweep hands up and together to chest height",
            "Keep a slight fixed bend in the elbows",
        ]),
        e("High To Low Cable Flyes", .chest, .cable, [.chest], how: [
            "Set the pulleys high",
            "Sweep hands down and together in front of your hips",
            "Keep a slight fixed bend in the elbows",
        ]),
        e("Single Arm Cable Chest Press", .chest, .cable, [.chest]),
        e("Chest Dips", .chest, .bodyweight, [.chest, .triceps], how: [
            "Lean your torso forward to bias the chest",
            "Lower until upper arms are about parallel",
            "Don't let shoulders roll forward at the bottom",
        ]),
        e("Incline Push Ups", .chest, .bodyweight, [.chest, .triceps], how: [
            "Hands on a bench or box, body in one straight line",
            "Lower your chest to the edge",
            "Lower the box as you get stronger",
        ]),
        e("Decline Push Ups", .chest, .bodyweight, [.chest, .frontDelts], how: [
            "Feet on a bench, hands on the floor",
            "Keep your body in one straight line",
            "Lower until your head nearly touches",
        ]),
        e("Knee Push Ups", .chest, .bodyweight, [.chest, .triceps], how: [
            "Keep a straight line from knees to head",
            "Don't let hips pike up",
            "Chest to the floor each rep",
        ]),
        e("Wide Push Ups", .chest, .bodyweight, [.chest], how: [
            "Hands wider than shoulder width",
            "Keep hips in line; don't sag",
            "Lower until your chest nearly touches",
        ]),
        e("Archer Push Ups", .chest, .bodyweight, [.chest, .triceps]),
        e("Clap Push Ups", .chest, .bodyweight, [.chest, .triceps]),
        e("Band Chest Press", .chest, .band, [.chest, .triceps], how: [
            "Anchor the band behind you at chest height",
            "Press forward until arms are straight",
            "Return slowly; don't let the band snap back",
        ]),
        e("Band Flyes", .chest, .band, [.chest]),
        e("Band Push Ups", .chest, .band, [.chest, .triceps]),
        e("Svend Press", .chest, .none, [.chest]),
    ]

    // MARK: - Shoulders

    private static let shoulders: [Exercise] = [
        e("Seated Machine Shoulder Press", id: "seated-machine-presses", .shoulders, .machine, [.frontDelts, .triceps], how: [
            "Set the seat so handles start at shoulder height",
            "Keep your back flat against the pad",
            "Press without locking out hard or shrugging",
        ]),
        e("Dumbbell Lateral Raises", .shoulders, .dumbbell, [.sideDelts], how: [
            "Raise out to the side, stopping at shoulder height",
            "Lead with the elbows, slightly bent",
            "No swinging; use a weight you can lower slowly",
        ]),
        e("Barbell Overhead Press", .shoulders, .barbell, [.frontDelts, .triceps, .sideDelts], how: [
            "Squeeze glutes and brace; don't lean back",
            "Move your head back, then through once the bar passes",
            "Finish with the bar over your midfoot, arms locked",
        ]),
        e("Seated Dumbbell Shoulder Press", .shoulders, .dumbbell, [.frontDelts, .triceps], how: [
            "Keep your back against an upright bench",
            "Lower until the dumbbells reach ear level",
            "Keep forearms vertical; wrists over elbows",
        ]),
        e("Standing Dumbbell Shoulder Press", .shoulders, .dumbbell, [.frontDelts, .triceps], how: [
            "Brace your core and squeeze your glutes",
            "Press straight up; don't lean back",
            "Lower to ear level each rep",
        ]),
        e("Arnold Press", .shoulders, .dumbbell, [.frontDelts, .sideDelts, .triceps], how: [
            "Start with palms facing you at chin height",
            "Rotate palms forward as you press up",
            "Reverse the rotation on the way down",
        ]),
        e("Push Press", .shoulders, .barbell, [.frontDelts, .triceps, .quads], how: [
            "Dip a few inches by bending the knees, torso upright",
            "Drive hard with the legs, then press to lockout",
            "Don't turn the dip into a squat",
        ]),
        e("Z Press", .shoulders, .barbell, [.frontDelts, .triceps]),
        e("Landmine Press", .shoulders, .barbell, [.frontDelts, .chest, .triceps], how: [
            "Hold the end of the bar at shoulder height",
            "Press up and forward along the bar's arc",
            "Brace; don't twist or lean back",
        ]),
        e("Smith Machine Overhead Press", .shoulders, .machine, [.frontDelts, .triceps]),
        e("Single Arm Kettlebell Press", .shoulders, .kettlebell, [.frontDelts, .triceps], how: [
            "Start with the bell racked against the forearm",
            "Brace and avoid leaning away from the working arm",
            "Lock out with the bicep by your ear",
        ]),
        e("Kettlebell Bottoms Up Press", .shoulders, .kettlebell, [.frontDelts, .forearms]),
        e("Kettlebell Halos", .shoulders, .kettlebell, [.frontDelts, .traps]),
        e("Band Overhead Press", .shoulders, .band, [.frontDelts, .triceps]),
        e("Pike Push Ups", .shoulders, .bodyweight, [.frontDelts, .triceps], how: [
            "Hips high so your body forms an upside down V",
            "Lower the top of your head toward the floor ahead of hands",
            "Keep elbows from flaring straight out",
        ]),
        e("Handstand Push Ups", .shoulders, .bodyweight, [.frontDelts, .triceps]),
        e("Wall Handstand Hold", .shoulders, .bodyweight, [.frontDelts, .triceps], timed: true),
        e("Cable Lateral Raises", .shoulders, .cable, [.sideDelts], how: [
            "Stand side-on with the cable crossing in front of you",
            "Raise to shoulder height, no higher",
            "Keep the torso still; don't lean away to help",
        ]),
        e("Single Arm Cable Lateral Raises", .shoulders, .cable, [.sideDelts], how: [
            "Stand side-on, cable running in front of you",
            "Raise to shoulder height",
            "Keep the torso still",
        ]),
        e("Machine Lateral Raises", .shoulders, .machine, [.sideDelts], how: [
            "Line up your shoulders with the machine's pivot",
            "Lead with the elbows",
            "Stop at shoulder height",
        ]),
        e("Band Lateral Raises", .shoulders, .band, [.sideDelts], how: [
            "Stand on the band, handles at your sides",
            "Raise out to shoulder height",
            "Lower slowly against the band",
        ]),
        e("Dumbbell Front Raises", .shoulders, .dumbbell, [.frontDelts], how: [
            "Raise to eye level, not above",
            "Keep a soft bend in the elbows",
            "Don't lean back or swing the weight",
        ]),
        e("Plate Front Raises", .shoulders, .none, [.frontDelts], how: [
            "Hold the plate at the sides",
            "Raise to eye level, arms slightly bent",
            "Don't lean back",
        ]),
        e("Cable Front Raises", .shoulders, .cable, [.frontDelts], how: [
            "Stand facing away from a low cable",
            "Raise to eye level",
            "Don't swing with the hips",
        ]),
        e("Bent Over Reverse Flyes", .shoulders, .dumbbell, [.rearDelts, .traps], how: [
            "Hinge until your torso is nearly parallel to the floor",
            "Lift out to the sides, not back toward the hips",
            "Use light weight; don't swing with the torso",
        ]),
        e("Reverse Pec Deck", .shoulders, .machine, [.rearDelts, .traps], how: [
            "Face the pad with handles at shoulder height",
            "Keep arms nearly straight and push out wide",
            "Don't shrug the shoulders up",
        ]),
        e("Cable Rear Delt Flyes", .shoulders, .cable, [.rearDelts], how: [
            "Set the cables at shoulder height and cross them",
            "Pull out wide with nearly straight arms",
            "Don't shrug or lean back",
        ]),
        e("Face Pulls", .shoulders, .cable, [.rearDelts, .traps], how: [
            "Set the rope at head height or higher",
            "Pull toward your face, hands ending beside the ears",
            "Keep elbows high; don't turn it into a row",
        ]),
        e("Band Face Pulls", .shoulders, .band, [.rearDelts, .traps], how: [
            "Anchor the band at head height",
            "Pull toward your face, elbows high",
            "Finish with hands beside your ears",
        ]),
        e("Band Pull Aparts", .shoulders, .band, [.rearDelts, .traps], how: [
            "Hold the band at shoulder height, arms straight",
            "Pull it apart until it touches your chest",
            "Keep shoulders down; don't shrug",
        ]),
        e("Barbell Upright Rows", .shoulders, .barbell, [.sideDelts, .traps], how: [
            "Use a grip at least shoulder width",
            "Lift elbows only to shoulder height",
            "Stop if you feel pinching in the shoulder",
        ]),
        e("Dumbbell Upright Rows", .shoulders, .dumbbell, [.sideDelts, .traps], how: [
            "Raise elbows only to shoulder height",
            "Keep the dumbbells close to your body",
            "Stop if you feel pinching in the shoulder",
        ]),
        e("Cable Upright Rows", .shoulders, .cable, [.sideDelts, .traps], how: [
            "Use a grip at least shoulder width",
            "Raise elbows only to shoulder height",
            "Stop if you feel pinching in the shoulder",
        ]),
        e("Y Raises", .shoulders, .dumbbell, [.sideDelts, .traps]),
        e("Cable External Rotations", .shoulders, .cable, [.rearDelts], how: [
            "Keep the elbow at your side, bent 90°",
            "Rotate the forearm outward only",
            "Use light weight and move slowly",
        ]),
        e("Band External Rotations", .shoulders, .band, [.rearDelts], how: [
            "Keep the elbow tucked at your side",
            "Rotate the forearm outward",
            "Return slowly against the band",
        ]),
    ]

    // MARK: - Legs

    private static let legs: [Exercise] = [
        e("Barbell Squats", .legs, .barbell, [.quads, .glutes, .adductors], how: [
            "Brace your core before you descend, not halfway down",
            "Knees track in line with your toes; don't let them cave",
            "Hips at least to knee height; keep heels on the floor",
        ]),
        e("Seated Leg Curls", .legs, .machine, [.hamstrings], how: [
            "Line your knees up with the machine's pivot",
            "Keep your hips down on the seat",
            "Control the return; don't let the pad snap back",
        ]),
        e("Leg Press", .legs, .machine, [.quads, .glutes], how: [
            "Keep your lower back flat on the pad at the bottom",
            "Don't lock your knees out at the top",
            "Knees track over the toes; don't let them cave in",
        ]),
        e("Walking Lunges", .legs, .dumbbell, [.quads, .glutes], how: [
            "Take a long enough step that the front heel stays down",
            "Lower the back knee toward the floor, torso upright",
            "Push through the front heel into the next step",
        ]),
        e("Front Squats", .legs, .barbell, [.quads, .glutes], how: [
            "Rest the bar on your shoulders, elbows up high",
            "Keep your torso upright; don't let elbows drop",
            "Sit straight down between your heels",
        ]),
        e("Box Squats", .legs, .barbell, [.glutes, .quads, .hamstrings], how: [
            "Sit back onto the box; don't drop onto it",
            "Pause briefly without relaxing",
            "Drive up with knees pushed out",
        ]),
        e("Pause Squats", .legs, .barbell, [.quads, .glutes], how: [
            "Squat to your normal depth",
            "Hold still for a full second at the bottom",
            "Stay braced; don't relax during the pause",
        ]),
        e("Overhead Squats", .legs, .barbell, [.quads, .glutes, .frontDelts]),
        e("Zercher Squats", .legs, .barbell, [.quads, .glutes]),
        e("Landmine Squats", .legs, .barbell, [.quads, .glutes]),
        e("Goblet Squats", .legs, .dumbbell, [.quads, .glutes], how: [
            "Hold the weight against your chest, elbows down",
            "Sit between your knees with your chest up",
            "Keep your heels planted throughout",
        ]),
        e("Kettlebell Goblet Squats", .legs, .kettlebell, [.quads, .glutes], how: [
            "Hold the bell by the horns against your chest",
            "Sit between your knees, chest up",
            "Keep heels planted",
        ]),
        e("Smith Machine Squats", .legs, .machine, [.quads, .glutes], how: [
            "Set feet slightly forward of the bar",
            "Set the safety stops before you start",
            "Keep knees in line with toes",
        ]),
        e("Hack Squats", .legs, .machine, [.quads, .glutes], how: [
            "Keep your back and hips flat against the pad",
            "Go as deep as you can without your hips peeling off",
            "Don't lock your knees hard at the top",
        ]),
        e("Pendulum Squats", .legs, .machine, [.quads, .glutes]),
        e("Belt Squats", .legs, .machine, [.quads, .glutes]),
        e("Bodyweight Squats", .legs, .bodyweight, [.quads, .glutes], how: [
            "Push hips back and down, chest up",
            "Keep your whole foot on the floor",
            "Knees follow the toes; don't let them cave in",
        ]),
        e("Jump Squats", .legs, .bodyweight, [.quads, .glutes, .calves], how: [
            "Squat to a comfortable depth, then jump",
            "Land softly with knees bent",
            "Reset before the next rep",
        ]),
        e("Pistol Squats", .legs, .bodyweight, [.quads, .glutes]),
        e("Sissy Squats", .legs, .bodyweight, [.quads]),
        e("Cossack Squats", .legs, .bodyweight, [.adductors, .quads, .glutes]),
        e("Wall Sit", .legs, .bodyweight, [.quads], timed: true, how: [
            "Slide down until thighs are parallel to the floor",
            "Keep your back flat against the wall",
            "Knees over ankles, not past the toes",
        ]),
        e("Bulgarian Split Squats", .legs, .dumbbell, [.quads, .glutes], how: [
            "Stand far enough forward that the front heel stays down",
            "Drop the back knee straight down",
            "Keep most of your weight on the front leg",
        ]),
        e("Dumbbell Split Squats", .legs, .dumbbell, [.quads, .glutes], how: [
            "Stand in a long stagger, both feet forward-facing",
            "Drop the back knee straight down",
            "Keep your torso upright",
        ]),
        e("Dumbbell Step Ups", .legs, .dumbbell, [.quads, .glutes], how: [
            "Place your whole foot on the box",
            "Drive up with the top leg; don't push off the bottom one",
            "Step down under control",
        ]),
        e("Dumbbell Reverse Lunges", .legs, .dumbbell, [.quads, .glutes], how: [
            "Step back far enough to drop the knee straight down",
            "Keep your torso upright",
            "Drive through the front heel to return",
        ]),
        e("Barbell Reverse Lunges", .legs, .barbell, [.quads, .glutes], how: [
            "Step back, not out to the side",
            "Drop the back knee straight down",
            "Keep the bar level; don't lean forward",
        ]),
        e("Bodyweight Lunges", .legs, .bodyweight, [.quads, .glutes], how: [
            "Step long enough that the front heel stays down",
            "Lower the back knee toward the floor",
            "Push back through the front heel",
        ]),
        e("Lateral Lunges", .legs, .bodyweight, [.adductors, .quads, .glutes], how: [
            "Step wide and sit back into one hip",
            "Keep the other leg straight",
            "Keep both feet flat",
        ]),
        e("Curtsy Lunges", .legs, .bodyweight, [.glutes, .quads]),
        e("Romanian Deadlifts", .legs, .barbell, [.hamstrings, .glutes, .lowerBack], how: [
            "Push your hips back; knees only slightly bent",
            "Keep the bar dragging along your thighs",
            "Stop when your back starts to round, not at the floor",
        ]),
        e("Dumbbell Romanian Deadlifts", .legs, .dumbbell, [.hamstrings, .glutes], how: [
            "Hinge at the hips with a soft knee",
            "Keep the dumbbells close to your legs",
            "Keep your back flat; stop where the stretch ends",
        ]),
        e("Single Leg Romanian Deadlifts", .legs, .dumbbell, [.hamstrings, .glutes], how: [
            "Hinge on one leg with a soft knee",
            "Keep hips square to the floor",
            "Let the back leg rise in line with your torso",
        ]),
        e("Stiff Leg Deadlifts", .legs, .barbell, [.hamstrings, .lowerBack], how: [
            "Knees nearly straight, not locked",
            "Keep the back flat as you lower",
            "Stop when your back starts to round",
        ]),
        e("Sumo Deadlifts", .legs, .barbell, [.glutes, .adductors, .quads], how: [
            "Wide stance, toes out, hands inside the knees",
            "Push knees out over your toes as you pull",
            "Keep your chest up and the bar close",
        ]),
        e("Trap Bar Deadlifts", .legs, .barbell, [.quads, .glutes, .hamstrings], how: [
            "Stand centered inside the bar",
            "Keep your back flat as you grip the handles",
            "Drive through the floor; hips and chest rise together",
        ]),
        e("Kettlebell Sumo Deadlifts", .legs, .kettlebell, [.glutes, .adductors]),
        e("Kettlebell Deadlifts", .legs, .kettlebell, [.glutes, .hamstrings], how: [
            "Bell between your feet, under your hips",
            "Hinge with a flat back to grip it",
            "Stand by driving hips forward",
        ]),
        e("Good Mornings", .legs, .barbell, [.hamstrings, .lowerBack, .glutes], how: [
            "Keep a soft bend in the knees",
            "Push the hips back with a flat back",
            "Use light weight; stop before your back rounds",
        ]),
        e("Lying Leg Curls", .legs, .machine, [.hamstrings], how: [
            "Line up your knees with the machine's pivot",
            "Keep hips pressed into the pad",
            "Lower slowly to straight legs",
        ]),
        e("Standing Leg Curls", .legs, .machine, [.hamstrings], how: [
            "Line your knee up with the pivot",
            "Keep your hips against the pad",
            "Lower slowly",
        ]),
        e("Nordic Curls", .legs, .bodyweight, [.hamstrings]),
        e("Glute Ham Raises", .legs, .machine, [.hamstrings, .glutes]),
        e("Leg Extensions", .legs, .machine, [.quads], how: [
            "Line up your knees with the machine's pivot",
            "Squeeze to full extension at the top",
            "Lower slowly; don't let the stack drop",
        ]),
        e("Single Leg Press", .legs, .machine, [.quads, .glutes], how: [
            "Put the foot in the middle of the platform",
            "Keep your lower back flat on the pad",
            "Don't lock the knee at the top",
        ]),
        e("Barbell Hip Thrusts", .legs, .barbell, [.glutes, .hamstrings], how: [
            "Upper back on the bench just below the shoulder blades",
            "Shins vertical at the top; tuck your chin",
            "Finish with glutes, not by arching the lower back",
        ]),
        e("Machine Hip Thrusts", .legs, .machine, [.glutes], how: [
            "Set the pad across your hips",
            "Drive through your heels to full hip extension",
            "Tuck your chin; don't arch your back",
        ]),
        e("Glute Bridges", .legs, .bodyweight, [.glutes, .hamstrings], how: [
            "Feet flat and close enough to touch with fingertips",
            "Drive through the heels and squeeze at the top",
            "Don't arch your lower back to get higher",
        ]),
        e("Single Leg Glute Bridges", .legs, .bodyweight, [.glutes, .hamstrings], how: [
            "Keep hips level as you lift",
            "Drive through the planted heel",
            "Don't arch your lower back",
        ]),
        e("Band Glute Bridges", .legs, .band, [.glutes]),
        e("Cable Pull Throughs", .legs, .cable, [.glutes, .hamstrings], how: [
            "Face away from a low cable, rope between legs",
            "Hinge at the hips, not the knees",
            "Stand by squeezing glutes, not leaning back",
        ]),
        e("Cable Glute Kickbacks", .legs, .cable, [.glutes], how: [
            "Hinge slightly and brace on the machine",
            "Kick back with the heel, not the toe",
            "Don't arch your lower back to go higher",
        ]),
        e("Machine Glute Kickbacks", .legs, .machine, [.glutes]),
        e("Hip Abductions", .legs, .machine, [.glutes], how: [
            "Sit tall with your back on the pad",
            "Push out with the knees, not by rocking the torso",
            "Control the pads back together",
        ]),
        e("Hip Adductions", .legs, .machine, [.adductors], how: [
            "Start at a stretch you can control",
            "Squeeze the pads together without rocking",
            "Let them open slowly",
        ]),
        e("Cable Hip Abductions", .legs, .cable, [.glutes]),
        e("Band Lateral Walks", .legs, .band, [.glutes], how: [
            "Band above the knees or at the ankles",
            "Stay in a half squat",
            "Keep tension; don't let feet come together",
        ]),
        e("Band Clamshells", .legs, .band, [.glutes]),
        e("Copenhagen Plank", .legs, .bodyweight, [.adductors, .obliques], timed: true),
        e("Standing Calf Raises", .legs, .machine, [.calves], how: [
            "Lower until you feel a full stretch in the calf",
            "Rise all the way onto the balls of your feet",
            "Pause at the bottom; don't bounce",
        ]),
        e("Seated Calf Raises", .legs, .machine, [.calves], how: [
            "Pad sits on the lower thigh, just above the knee",
            "Lower to a full stretch, then rise fully",
            "Pause at the bottom; don't bounce",
        ]),
        e("Smith Machine Calf Raises", .legs, .machine, [.calves], how: [
            "Stand on a plate or step under the bar",
            "Lower to a full stretch",
            "Rise fully; don't bounce",
        ]),
        e("Leg Press Calf Raises", .legs, .machine, [.calves], how: [
            "Place balls of your feet on the platform edge",
            "Keep knees straight but not locked",
            "Lower to a full stretch; don't bounce",
        ]),
        e("Donkey Calf Raises", .legs, .machine, [.calves]),
        e("Dumbbell Calf Raises", .legs, .dumbbell, [.calves], how: [
            "Stand on a step with the heel hanging off",
            "Lower to a full stretch",
            "Rise fully and pause",
        ]),
        e("Single Leg Calf Raises", .legs, .bodyweight, [.calves], how: [
            "Stand on a step on one foot",
            "Hold something for balance",
            "Lower fully and rise fully",
        ]),
        e("Box Jumps", .legs, .none, [.quads, .glutes, .calves], how: [
            "Land softly with knees bent, hips back",
            "Step down; don't jump back off the box",
            "Pick a box you can land on, not one you barely clear",
        ]),
        e("Broad Jumps", .legs, .bodyweight, [.quads, .glutes, .hamstrings]),
    ]

    // MARK: - Core

    private static let core: [Exercise] = [
        e("Planking", .core, .bodyweight, [.abs, .obliques], timed: true, how: [
            "Elbows under shoulders, body in one straight line",
            "Don't let your hips sag or pike up",
            "Squeeze glutes and brace like you're about to be poked",
        ]),
        e("Hanging Leg Raises", .core, .bodyweight, [.abs], how: [
            "Start from a dead hang without swinging",
            "Curl your pelvis up, not just lift the legs",
            "Lower slowly; don't let momentum carry the next rep",
        ]),
        e("Cable Woodchoppers", .core, .cable, [.obliques, .abs], how: [
            "Rotate through the torso, not just the arms",
            "Pivot the back foot as you turn",
            "Control the return; don't let the cable pull you",
        ]),
        e("Side Plank", .core, .bodyweight, [.obliques, .abs], timed: true, how: [
            "Elbow directly under the shoulder",
            "Keep hips lifted in line with shoulders and feet",
            "Don't roll your chest toward the floor",
        ]),
        e("Crunches", .core, .bodyweight, [.abs], how: [
            "Curl your ribs toward your hips; don't pull on your neck",
            "Lift only your shoulder blades off the floor",
            "Lower slowly between reps",
        ]),
        e("Bicycle Crunches", .core, .bodyweight, [.abs, .obliques], how: [
            "Rotate the shoulder toward the knee, not just the elbow",
            "Fully extend the other leg",
            "Move slowly; speed makes it easier",
        ]),
        e("Reverse Crunches", .core, .bodyweight, [.abs], how: [
            "Lift your hips off the floor, not just your knees",
            "Keep the movement slow",
            "Don't use momentum to swing",
        ]),
        e("Sit Ups", .core, .bodyweight, [.abs], how: [
            "Anchor your feet if you need to",
            "Roll up one vertebra at a time",
            "Don't yank your head with your hands",
        ]),
        e("Decline Sit Ups", .core, .bodyweight, [.abs], how: [
            "Hook your feet securely",
            "Roll up rather than jerking your torso",
            "Lower under control",
        ]),
        e("V Ups", .core, .bodyweight, [.abs], how: [
            "Lift arms and legs at the same time",
            "Reach toward your toes at the top",
            "Lower slowly without crashing down",
        ]),
        e("Lying Leg Raises", .core, .bodyweight, [.abs], how: [
            "Press your lower back into the floor the whole time",
            "Lower your legs only as far as you can keep it pressed",
            "Move slowly; don't swing",
        ]),
        e("Hanging Knee Raises", .core, .bodyweight, [.abs], how: [
            "Hang still before each rep",
            "Bring knees above hip height, tilting the pelvis up",
            "Lower under control",
        ]),
        e("Toes To Bar", .core, .bodyweight, [.abs, .lats], how: [
            "Start from a still hang",
            "Tilt your pelvis and bring toes to the bar",
            "Control the descent",
        ]),
        e("Captains Chair Knee Raises", .core, .machine, [.abs]),
        e("Cable Crunches", .core, .cable, [.abs], how: [
            "Kneel and hold the rope beside your head",
            "Curl your spine down; don't just hinge at the hips",
            "Keep your hips still",
        ]),
        e("Machine Crunches", .core, .machine, [.abs]),
        e("Ab Wheel Rollouts", .core, .none, [.abs, .lats], how: [
            "Keep your hips from sagging as you roll out",
            "Roll only as far as you can keep your back flat",
            "Pull back with your abs, not your hips",
        ]),
        e("Flutter Kicks", .core, .bodyweight, [.abs], timed: true, how: [
            "Keep your lower back pressed to the floor",
            "Keep legs straight and low",
            "Raise your legs if your back lifts",
        ]),
        e("Russian Twists", .core, .bodyweight, [.obliques, .abs], how: [
            "Lean back with a straight spine",
            "Turn your chest, not just your arms",
            "Keep the pace controlled",
        ]),
        e("Dead Bugs", .core, .bodyweight, [.abs], how: [
            "Keep your lower back pressed to the floor",
            "Extend the opposite arm and leg slowly",
            "Exhale as you extend",
        ]),
        e("Bird Dogs", .core, .bodyweight, [.lowerBack, .abs, .glutes], how: [
            "Keep hips level as you extend",
            "Reach long with the arm and leg; don't lift high",
            "Pause at the end of each rep",
        ]),
        e("Hollow Body Hold", .core, .bodyweight, [.abs], timed: true, how: [
            "Press your lower back into the floor",
            "Lift shoulders and legs just off the ground",
            "Raise your legs if your back starts to lift",
        ]),
        e("L Sit", .core, .bodyweight, [.abs, .triceps], timed: true),
        e("Mountain Climbers", .core, .bodyweight, [.abs, .frontDelts], how: [
            "Hold a high plank with shoulders over hands",
            "Drive knees toward your chest without lifting hips",
            "Keep your weight on your hands",
        ]),
        e("Plank Shoulder Taps", .core, .bodyweight, [.abs, .obliques], how: [
            "Hold a high plank, feet wide",
            "Tap one shoulder without rocking the hips",
            "Move slowly",
        ]),
        e("Dragon Flags", .core, .bodyweight, [.abs]),
        e("Pallof Press", .core, .cable, [.obliques, .abs], how: [
            "Stand side-on to the cable",
            "Press straight out without letting the torso rotate",
            "Brace and keep your hips square",
        ]),
        e("Band Pallof Press", .core, .band, [.obliques, .abs], how: [
            "Stand side-on to the anchor",
            "Press straight out without rotating",
            "Keep hips square",
        ]),
        e("Band Woodchoppers", .core, .band, [.obliques]),
        e("Dumbbell Side Bends", .core, .dumbbell, [.obliques], how: [
            "Hold one dumbbell; free hand on your hip",
            "Bend directly sideways, not forward",
            "Move slowly",
        ]),
        e("Suitcase Carries", .core, .kettlebell, [.obliques, .forearms, .traps], how: [
            "Carry a weight in one hand only",
            "Stay upright; don't lean toward or away from it",
            "Walk slowly with short steps",
        ]),
        e("Kettlebell Windmills", .core, .kettlebell, [.obliques, .sideDelts]),
        e("Landmine Rotations", .core, .barbell, [.obliques, .abs]),
        e("Weighted Plank", .core, .none, [.abs], timed: true),
    ]

    // MARK: - Cardio

    private static let cardio: [Exercise] = [
        e("Walking", .cardio, .none, [.quads, .calves], minutes: true),
        e("Rowing Machine", .cardio, .machine, [.lats, .quads, .hamstrings], minutes: true, how: [
            "Drive with the legs first, then lean back, then pull",
            "Return in reverse: arms, body, then knees",
            "Pull the handle to your lower ribs, not your chin",
        ]),
        e("Treadmill Running", .cardio, .treadmill, [.quads, .calves, .hamstrings], minutes: true, how: [
            "Keep a steady cadence and short strides",
            "Land under your hips, not out in front",
            "Don't hold the handrails",
        ]),
        e("Incline Treadmill Walking", .cardio, .treadmill, [.glutes, .calves], minutes: true, how: [
            "Let go of the handrails",
            "Stand upright; don't lean into the incline",
            "Shorten your stride instead of slowing to a crawl",
        ]),
        e("Treadmill Walking", .cardio, .treadmill, [.quads, .calves], minutes: true),
        e("Running", .cardio, .none, [.quads, .calves, .hamstrings], minutes: true, how: [
            "Land under your hips, not out in front",
            "Keep a relaxed upper body",
            "Build pace gradually",
        ]),
        e("Sprints", .cardio, .none, [.quads, .hamstrings, .glutes]),
        e("Stationary Bike", .cardio, .machine, [.quads, .glutes], minutes: true, how: [
            "Set the seat so your knee is slightly bent at the bottom",
            "Keep your hips still on the seat",
            "Add resistance rather than spinning with none",
        ]),
        e("Air Bike", .cardio, .machine, [.quads, .glutes, .frontDelts], minutes: true),
        e("Cycling", .cardio, .none, [.quads, .glutes], minutes: true),
        e("Elliptical", .cardio, .machine, [.quads, .glutes], minutes: true),
        e("Stair Climber", .cardio, .machine, [.glutes, .quads, .calves], minutes: true, how: [
            "Stand upright and use the rails only for balance",
            "Put your whole foot on each step",
            "Slow the machine before you lean on it",
        ]),
        e("Ski Ergometer", .cardio, .machine, [.lats, .triceps, .abs], minutes: true),
        e("Jump Rope", .cardio, .none, [.calves], timed: true, how: [
            "Turn the rope with the wrists, not the arms",
            "Jump just high enough to clear the rope",
            "Land softly on the balls of your feet",
        ]),
        e("Jumping Jacks", .cardio, .bodyweight, [.calves, .sideDelts], how: [
            "Land softly on the balls of your feet",
            "Bring arms fully overhead",
            "Keep a steady rhythm",
        ]),
        e("High Knees", .cardio, .bodyweight, [.quads, .abs], timed: true),
        e("Butt Kicks", .cardio, .bodyweight, [.hamstrings], timed: true),
        e("Skater Jumps", .cardio, .bodyweight, [.glutes, .quads]),
        e("Tuck Jumps", .cardio, .bodyweight, [.quads, .abs]),
        e("Shadow Boxing", .cardio, .none, [.frontDelts, .obliques], timed: true),
        e("Battle Ropes", .cardio, .none, [.frontDelts, .forearms, .abs], timed: true),
        e("Swimming", .cardio, .pool, [.lats, .frontDelts], minutes: true),
        e("Hiking", .cardio, .none, [.quads, .glutes, .calves], minutes: true),
        e("Rucking", .cardio, .none, [.quads, .traps], minutes: true),
    ]

    // MARK: - Full body

    private static let fullBody: [Exercise] = [
        e("Kettlebell Swings", .fullBody, .kettlebell, [.glutes, .hamstrings, .lowerBack], how: [
            "Hinge at the hips; this is not a squat",
            "Snap the hips forward; the arms don't lift the bell",
            "Let the bell float to chest height, no higher",
        ]),
        e("Burpees", .fullBody, .bodyweight, [.quads, .chest, .abs], how: [
            "Keep your plank straight; don't let hips sag",
            "Land the jump back with feet flat and under you",
            "Keep a steady pace rather than sprinting and stalling",
        ]),
        e("Single Arm Kettlebell Swings", .fullBody, .kettlebell, [.glutes, .hamstrings, .obliques], how: [
            "Hinge at the hips; this is not a squat",
            "Don't let your shoulders rotate with the bell",
            "Snap the hips; the arm doesn't lift",
        ]),
        e("Kettlebell Cleans", .fullBody, .kettlebell, [.glutes, .hamstrings, .forearms]),
        e("Kettlebell Clean And Press", .fullBody, .kettlebell, [.frontDelts, .glutes, .triceps]),
        e("Kettlebell Snatches", .fullBody, .kettlebell, [.glutes, .frontDelts, .hamstrings]),
        e("Turkish Get Ups", .fullBody, .kettlebell, [.frontDelts, .abs, .glutes]),
        e("Power Cleans", .fullBody, .barbell, [.glutes, .hamstrings, .traps], how: [
            "Keep the bar close; it should brush your thighs",
            "Extend hips fully before pulling with the arms",
            "Catch with elbows high and forward",
        ]),
        e("Hang Cleans", .fullBody, .barbell, [.glutes, .hamstrings, .traps], how: [
            "Start standing with the bar at the thighs",
            "Extend hips fully before pulling with the arms",
            "Catch with elbows high and forward",
        ]),
        e("Clean And Jerk", .fullBody, .barbell, [.quads, .glutes, .frontDelts]),
        e("Power Snatches", .fullBody, .barbell, [.glutes, .hamstrings, .traps]),
        e("Barbell Thrusters", .fullBody, .barbell, [.quads, .glutes, .frontDelts], how: [
            "Front squat to full depth with elbows up",
            "Drive out of the bottom and press in one motion",
            "Keep the bar over your midfoot overhead",
        ]),
        e("Dumbbell Thrusters", .fullBody, .dumbbell, [.quads, .glutes, .frontDelts]),
        e("Dumbbell Snatches", .fullBody, .dumbbell, [.glutes, .frontDelts, .hamstrings]),
        e("Dumbbell Clean And Press", .fullBody, .dumbbell, [.frontDelts, .glutes, .quads]),
        e("Man Makers", .fullBody, .dumbbell, [.chest, .frontDelts, .quads]),
        e("Devil Press", .fullBody, .dumbbell, [.glutes, .frontDelts, .chest]),
        e("Renegade Rows", .fullBody, .dumbbell, [.lats, .abs, .obliques], how: [
            "Hold a high plank with feet wide",
            "Row without rotating the hips",
            "Keep the body rigid throughout",
        ]),
        e("Farmer Carries", .fullBody, .dumbbell, [.forearms, .traps, .abs], how: [
            "Stand tall with shoulders back, not shrugged",
            "Take short, steady steps",
            "Keep the weights still at your sides; no swinging",
        ]),
        e("Overhead Carries", .fullBody, .kettlebell, [.frontDelts, .abs, .traps], how: [
            "Lock the arm overhead, bicep by the ear",
            "Keep ribs down; don't arch your back",
            "Walk slowly",
        ]),
        e("Wall Balls", .fullBody, .none, [.quads, .glutes, .frontDelts], how: [
            "Squat full depth with the ball at your chest",
            "Drive up and throw in one motion",
            "Catch and go straight into the next squat",
        ]),
        e("Medicine Ball Slams", .fullBody, .none, [.lats, .abs, .frontDelts], how: [
            "Lift the ball fully overhead",
            "Slam it with your whole body",
            "Hinge to pick it up; don't round your back",
        ]),
        e("Sled Pushes", .fullBody, .none, [.quads, .glutes, .calves], how: [
            "Lean forward with arms extended",
            "Drive with short, powerful steps",
            "Keep your back flat",
        ]),
        e("Sled Pulls", .fullBody, .none, [.hamstrings, .glutes, .lats]),
        e("Tire Flips", .fullBody, .none, [.glutes, .hamstrings, .lowerBack]),
        e("Bear Crawls", .fullBody, .bodyweight, [.frontDelts, .quads, .abs], timed: true, how: [
            "Hover knees an inch off the ground",
            "Keep your back flat",
            "Move opposite hand and foot together",
        ]),
        e("Inchworms", .fullBody, .bodyweight, [.hamstrings, .abs, .frontDelts], how: [
            "Bend knees as much as needed to reach the floor",
            "Walk hands out to a plank",
            "Walk feet back toward hands",
        ]),
        e("Muscle Ups", .fullBody, .bodyweight, [.lats, .triceps, .chest]),
    ]

    // MARK: - Swim

    /// One per stroke, counted in lengths so the pool turns them into distance.
    private static let swim: [Exercise] = [
        e("Freestyle Swim", .cardio, .pool, [.lats, .frontDelts, .triceps], laps: true, how: [
            "Breathe by rolling your body to the side, not by lifting your head",
            "Reach long, then pull under your body all the way to your hip",
            "Kick from the hips with loose ankles, not from the knees",
        ]),
        e("Backstroke Swim", .cardio, .pool, [.lats, .frontDelts, .abs], laps: true, how: [
            "Keep your head still with your ears in the water",
            "Enter little finger first, straight above your shoulder",
            "Count strokes from the flags to the wall so you never hit it",
        ]),
        e("Breaststroke Swim", .cardio, .pool, [.quads, .adductors, .chest], laps: true, how: [
            "Pull, breathe, kick, glide, in that order",
            "Keep your hands in front of your shoulders on the pull",
            "Glide with arms straight before starting the next stroke",
        ]),
        e("Butterfly Swim", .cardio, .pool, [.chest, .lats, .abs], laps: true, how: [
            "Drive the wave from your chest, not your knees",
            "Two kicks a stroke: one as the hands enter, one as they push out",
            "Breathe low and forward, chin skimming the water",
        ]),
        e("Individual Medley", .cardio, .pool, [.lats, .chest, .quads], laps: true, how: [
            "Butterfly, backstroke, breaststroke, freestyle, in that order",
            "Each stroke covers a quarter of the distance",
            "Hold back on the butterfly; it costs the most",
        ]),
        e("Kickboard Kicks", .cardio, .pool, [.quads, .glutes, .hamstrings], laps: true, how: [
            "Hold the far end of the board with straight arms",
            "Kick from the hips with pointed toes",
            "Keep kicks small and quick, just under the surface",
        ]),
        e("Pull Buoy Swim", .cardio, .pool, [.lats, .triceps, .frontDelts], laps: true, how: [
            "Squeeze the buoy between your thighs and don't kick",
            "Keep your core tight so your hips stay high",
            "Make every pull long, all the way to the hip",
        ]),
        e("Water Walking", .cardio, .pool, [.quads, .glutes], minutes: true, how: [
            "Walk in chest-deep water, heel then toe",
            "Swing your arms as you would on land",
            "Stand tall rather than leaning into the water",
        ]),
    ]

    // MARK: - Mobility and warm-ups

    private static let mobility: [Exercise] = [
        e("Cat Cow", .back, .bodyweight, [.lowerBack, .abs], how: [
            "On hands and knees, hands under shoulders, knees under hips",
            "Round your back up as you breathe out, then let it sag gently as you breathe in",
            "Move slowly through the whole spine",
        ]),
        e("Childs Pose", .back, .bodyweight, [.lats, .lowerBack], timed: true, how: [
            "Kneel with knees apart and sit back onto your heels",
            "Walk your hands forward and rest your forehead down",
            "Breathe slowly into your back",
        ]),
        e("Thoracic Open Books", .back, .bodyweight, [.obliques, .chest], how: [
            "Lie on your side, knees bent to a right angle, arms straight in front",
            "Sweep the top arm over to the other side, following it with your eyes",
            "Keep your knees together and on the floor",
        ]),
        e("Chin Tucks", .back, .bodyweight, [.traps], how: [
            "Sit or stand tall with your eyes level",
            "Slide your chin straight back into a double chin",
            "Hold two seconds; don't tip your head down",
        ]),
        e("Doorway Chest Stretch", .chest, .bodyweight, [.chest, .frontDelts], timed: true, how: [
            "Forearms on the door frame, elbows at shoulder height",
            "Step one foot through until the chest opens",
            "Keep your ribs down rather than arching your lower back",
        ]),
        e("Arm Circles", .shoulders, .bodyweight, [.sideDelts, .frontDelts], timed: true, how: [
            "Arms straight out to the sides",
            "Start with small circles and let them grow",
            "Switch direction halfway",
        ]),
        e("Worlds Greatest Stretch", .legs, .bodyweight, [.glutes, .hamstrings, .obliques], how: [
            "Step into a deep lunge with both hands inside the front foot",
            "Drop the inside elbow toward the front ankle",
            "Rotate that arm up to the ceiling, eyes following it",
        ]),
        e("Hip Flexor Stretch", .legs, .bodyweight, [.quads], timed: true, how: [
            "Kneel on one knee with the other foot flat in front",
            "Squeeze the back glute and tuck your pelvis under",
            "Shift forward only until the front of the back hip stretches",
        ]),
        e("Leg Swings", .legs, .bodyweight, [.hamstrings, .adductors], how: [
            "Hold a wall or rail for balance",
            "Swing one leg forward and back, then side to side",
            "Let the range grow gradually rather than kicking",
        ]),
        e("Side Lying Leg Raises", .legs, .bodyweight, [.glutes], how: [
            "Lie on your side with the bottom knee bent for balance",
            "Lift the top leg with toes pointing forward, not up",
            "Lower slowly without rolling your hips back",
        ]),
        e("Lateral Bounds", .legs, .bodyweight, [.glutes, .quads, .adductors], how: [
            "Push off one leg sideways as far as you can",
            "Land softly on the other leg and hold for a second",
            "Keep the landing knee in line with the toes",
        ]),
        e("Pelvic Floor Contractions", .core, .bodyweight, [.abs], how: [
            "Squeeze and lift as if stopping the flow of urine",
            "Hold 3 to 5 seconds while breathing normally, glutes relaxed",
            "Relax fully for as long as you held",
        ]),
        e("Medicine Ball Rotational Throws", .core, .none, [.obliques, .abs, .glutes], how: [
            "Stand side-on to a wall with the ball at your back hip",
            "Turn from the back foot and hips first, arms last",
            "Throw hard into the wall and catch the rebound",
        ]),
    ]
}
