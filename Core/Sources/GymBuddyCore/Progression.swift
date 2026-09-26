import Foundation

/// What to put on the bar this time, from what happened last time.
///
/// Double progression, the boring one that works: hit every target rep on
/// every set and the load goes up by one real increment of that equipment;
/// miss twice running and it comes down. Anything cleverer needs RPE or bar
/// speed, which this app does not ask for and should not pretend to know.
public enum Progression {
    public enum Suggestion: Equatable, Sendable {
        case hold(Weight)
        case increase(to: Weight, from: Weight)
        case deload(to: Weight, from: Weight)

        public var weight: Weight {
            switch self {
            case .hold(let w): w
            case .increase(let w, _): w
            case .deload(let w, _): w
            }
        }
    }

    public static func suggest(
        for plan: WorkoutExercise,
        equipment: Equipment,
        history: [WorkoutLog],
        unit: WeightUnit,
        deloadAfterMisses: Int = 2
    ) -> Suggestion {
        guard equipment.isLoadable else { return .hold(plan.targetWeight) }

        let sessions = sessionSets(for: plan.exerciseID, in: history)
        guard let last = sessions.last else { return .hold(plan.targetWeight) }

        let lastWeight = last.map(\.weight).max() ?? plan.targetWeight

        if metTarget(last, plan: plan) {
            let next = equipment.stepped(lastWeight, by: 1, in: unit)
            return .increase(to: next, from: lastWeight)
        }

        let misses = sessions.reversed().prefix { !metTarget($0, plan: plan) }.count
        if misses >= deloadAfterMisses {
            return .deload(to: equipment.stepped(lastWeight, by: -1, in: unit), from: lastWeight)
        }
        return .hold(lastWeight)
    }

    private static func metTarget(_ sets: [SetLog], plan: WorkoutExercise) -> Bool {
        sets.count >= plan.targetSets && sets.allSatisfy { $0.reps >= plan.targetReps }
    }

    /// Sets for one exercise, grouped by session, oldest session first.
    private static func sessionSets(
        for exerciseID: String,
        in history: [WorkoutLog]
    ) -> [[SetLog]] {
        history
            .sorted { $0.startedAt < $1.startedAt }
            .map { $0.sets.filter { $0.exerciseID == exerciseID } }
            .filter { !$0.isEmpty }
    }
}
