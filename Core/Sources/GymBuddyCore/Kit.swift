import Foundation

/// One piece of gym equipment you'd look for on the floor: dumbbells, a cable
/// station, a leg press. A gym lists the kit it has; an exercise needs one.
public struct Kit: Identifiable, Hashable, Sendable {
    public enum Kind: String, CaseIterable, Sendable {
        case free, machine, cardio

        public var displayName: String {
            switch self {
            case .free: "Weights & cables"
            case .machine: "Machines"
            case .cardio: "Cardio"
            }
        }
    }

    public let id: String
    public let name: String
    public let kind: Kind

    /// What the exercise needs a gym to have; nil when it goes anywhere.
    public static func needed(by exercise: Exercise) -> Kit? {
        switch exercise.equipment {
        case .bodyweight, .none: nil
        case .machine:
            machineByExerciseID[exercise.id]
                ?? Kit(id: "exercise-\(exercise.id)", name: exercise.name, kind: .machine)
        default: byEquipment[exercise.equipment]
        }
    }

    /// Every kit the library's exercises use, plus a machine for each custom
    /// machine exercise, sorted within kind by name.
    public static func catalogue(for exercises: [Exercise]) -> [Kit] {
        var seen = Set<String>()
        let kits = (Array(byEquipment.values) + machines + exercises.compactMap(needed(by:)))
            .filter { seen.insert($0.id).inserted }
        return kits.sorted { ($0.kind.order, $0.name.lowercased()) < ($1.kind.order, $1.name.lowercased()) }
    }

    /// The catalogue grouped by kind and filtered by name.
    public static func pickable(_ exercises: [Exercise], matching query: String = "") -> [(kind: Kind, kits: [Kit])] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let shown = catalogue(for: exercises).filter { q.isEmpty || $0.name.localizedCaseInsensitiveContains(q) }
        return Kind.allCases.compactMap { kind in
            let kits = shown.filter { $0.kind == kind }
            return kits.isEmpty ? nil : (kind, kits)
        }
    }

    // MARK: - Catalogue

    static let byEquipment: [Equipment: Kit] = [
        .barbell: Kit(id: "barbell", name: "Barbell", kind: .free),
        .dumbbell: Kit(id: "dumbbell", name: "Dumbbells", kind: .free),
        .kettlebell: Kit(id: "kettlebell", name: "Kettlebells", kind: .free),
        .band: Kit(id: "band", name: "Resistance bands", kind: .free),
        .cable: Kit(id: "cable", name: "Cable station", kind: .free),
        .pool: Kit(id: "pool", name: "Pool", kind: .cardio),
        .treadmill: Kit(id: "treadmill", name: "Treadmill", kind: .cardio),
    ]

    /// Machine → the library's exercises done on it.
    private static let machineTable: [(name: String, kind: Kind, exercises: [String])] = [
        ("Ab crunch machine", .machine, ["Machine Crunches"]),
        ("Assisted pull-up machine", .machine, ["Assisted Pull Ups"]),
        ("Belt squat", .machine, ["Belt Squats"]),
        ("Captain's chair", .machine, ["Captains Chair Knee Raises"]),
        ("Chest press machine", .machine, ["Machine Chest Press", "Incline Machine Chest Press"]),
        ("Donkey calf raise", .machine, ["Donkey Calf Raises"]),
        ("Glute ham developer", .machine, ["Glute Ham Raises"]),
        ("Glute kickback machine", .machine, ["Machine Glute Kickbacks"]),
        ("Hack squat", .machine, ["Hack Squats"]),
        ("High row machine", .machine, ["Machine High Rows"]),
        ("Hip abductor / adductor", .machine, ["Hip Abductions", "Hip Adductions"]),
        ("Hip thrust machine", .machine, ["Machine Hip Thrusts"]),
        ("Lat pulldown", .machine, ["Lat Pull Downs"]),
        ("Lateral raise machine", .machine, ["Machine Lateral Raises"]),
        ("Leg extension", .machine, ["Leg Extensions"]),
        ("Leg press", .machine, ["Leg Press", "Single Leg Press", "Leg Press Calf Raises"]),
        ("Lying leg curl", .machine, ["Lying Leg Curls"]),
        ("Pec deck", .machine, ["Pec Deck Flyes", "Reverse Pec Deck"]),
        ("Pendulum squat", .machine, ["Pendulum Squats"]),
        ("Preacher curl machine", .machine, ["Machine Preacher Curls"]),
        ("Reverse hyper", .machine, ["Reverse Hyperextensions"]),
        ("Seated calf raise", .machine, ["Seated Calf Raises"]),
        ("Seated leg curl", .machine, ["Seated Leg Curls"]),
        ("Seated row machine", .machine, ["Seated Machine Rows"]),
        ("Shoulder press machine", .machine, ["Seated Machine Presses"]),
        ("Shrug machine", .machine, ["Machine Shrugs"]),
        ("Smith machine", .machine, ["Smith Machine Bench Press", "Smith Machine Incline Press",
                                     "Smith Machine Overhead Press", "Smith Machine Squats",
                                     "Smith Machine Calf Raises"]),
        ("Standing calf raise", .machine, ["Standing Calf Raises"]),
        ("Standing leg curl", .machine, ["Standing Leg Curls"]),
        ("Tricep extension machine", .machine, ["Machine Tricep Extensions"]),
        ("Air bike", .cardio, ["Air Bike"]),
        ("Elliptical", .cardio, ["Elliptical"]),
        ("Exercise bike", .cardio, ["Stationary Bike"]),
        ("Rowing machine", .cardio, ["Rowing Machine"]),
        ("Ski erg", .cardio, ["Ski Ergometer"]),
        ("Stair climber", .cardio, ["Stair Climber"]),
    ]

    static let machines: [Kit] = machineTable.map {
        Kit(id: "machine-\(SeedLibrary.slug($0.name))", name: $0.name, kind: $0.kind)
    }

    static let machineByExerciseID: [String: Kit] = Dictionary(uniqueKeysWithValues:
        zip(machineTable, machines).flatMap { row, kit in row.exercises.map { (SeedLibrary.slug($0), kit) } }
    )
}

private extension Kit.Kind {
    var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}
