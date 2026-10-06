import Foundation
import GymBuddyCore

/// Backups nobody has to remember. After each change settles, a new snapshot
/// goes into the app's own container; with iCloud on, today's file in the
/// user's iCloud Drive is replaced too. Which files to keep is Core's
/// `BackupRotation`; this only moves bytes.
@MainActor
final class AutoBackup {
    enum Outcome: Sendable {
        case local(Date)
        case cloud(Date)
        case cloudUnavailable
    }

    private let store: SQLiteStore
    private var pending: Task<Void, Never>?
    /// Changes arriving closer together than this become one backup — a
    /// burst of stepper taps in the workout editor isn't twenty versions.
    private let settle: Duration = .seconds(3)

    init(store: SQLiteStore) {
        self.store = store
    }

    nonisolated static var localDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Backups", directoryHint: .isDirectory)
    }

    func changed(iCloud: Bool, report: @escaping @MainActor (Outcome) -> Void) {
        pending?.cancel()
        let store = store
        let settle = settle
        pending = Task {
            try? await Task.sleep(for: settle)
            guard !Task.isCancelled else { return }
            let outcomes = await Task.detached(priority: .utility) {
                Self.write(store: store, iCloud: iCloud, now: .now)
            }.value
            outcomes.forEach(report)
        }
    }

    nonisolated static func write(store: SQLiteStore, iCloud: Bool, now: Date) -> [Outcome] {
        var outcomes: [Outcome] = []
        let fm = FileManager.default
        let local = localDirectory
        try? fm.createDirectory(at: local, withIntermediateDirectories: true)
        let file = local.appending(path: BackupRotation.localName(at: now))
        if (try? store.backup(to: file)) != nil {
            outcomes.append(.local(now))
            let names = (try? fm.contentsOfDirectory(atPath: local.path)) ?? []
            for name in BackupRotation.localExpired(names, now: now) {
                try? fm.removeItem(at: local.appending(path: name))
            }
        }
        guard iCloud else { return outcomes }
        guard let cloud = cloudDirectory() else { return outcomes + [.cloudUnavailable] }
        if (try? copyCoordinated(file, to: cloud.appending(path: BackupRotation.cloudName(at: now)))) != nil {
            outcomes.append(.cloud(now))
            let names = (try? fm.contentsOfDirectory(atPath: cloud.path)) ?? []
            for name in BackupRotation.cloudExpired(names, now: now) {
                try? removeCoordinated(cloud.appending(path: name))
            }
        }
        return outcomes
    }

    /// `iCloud Drive → Gym Buddies` in Files. Nil when the user isn't signed
    /// in to iCloud or has turned iCloud Drive off for the app. Blocks, so
    /// never call it on the main thread.
    nonisolated static func cloudDirectory() -> URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documents = container.appending(path: "Documents", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        return documents
    }

    nonisolated static var isICloudSignedIn: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private nonisolated static func copyCoordinated(_ source: URL, to destination: URL) throws {
        var coordinationError: NSError?
        var copyError: Error?
        NSFileCoordinator().coordinate(writingItemAt: destination, options: .forReplacing, error: &coordinationError) { url in
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                try FileManager.default.copyItem(at: source, to: url)
            } catch {
                copyError = error
            }
        }
        if let error = coordinationError ?? copyError { throw error }
    }

    private nonisolated static func removeCoordinated(_ url: URL) throws {
        var coordinationError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { url in
            try? FileManager.default.removeItem(at: url)
        }
        if let coordinationError { throw coordinationError }
    }

    /// Local snapshots, newest first, for the restore list.
    nonisolated static func localBackups() -> [(url: URL, date: Date, bytes: Int)] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: localDirectory.path)) ?? []
        return BackupRotation.sortedLocal(names).map { item in
            let url = localDirectory.appending(path: item.name)
            let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            return (url, item.date, bytes)
        }
    }
}
