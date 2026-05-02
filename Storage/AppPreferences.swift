import Foundation
import Observation

/// User-preference store backed by `UserDefaults`. Observable so SwiftUI views update.
/// We deliberately do NOT use `@AppStorage` (it doesn't trigger updates inside @Observable
/// classes, even with @ObservationIgnored) — manual UserDefaults reads and writes give
/// us a single source of truth that observation tracks correctly.
@MainActor
@Observable
final class AppPreferences {
    private let defaults: UserDefaults

    private enum Key {
        static let activeProfileID = "activeProfileID"
        static let lastActiveProjectID = "lastActiveProjectID"
        static let defaultModelByProfile = "defaultModelByProfile"
        static let showReasoning = "showReasoning"
        static let selectedMode = "selectedMode"
        static let selectedEffort = "selectedEffort"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self._activeProfileID = Self.readUUID(defaults, key: Key.activeProfileID)
        self._lastActiveProjectID = Self.readDictionary(defaults, key: Key.lastActiveProjectID)
        self._defaultModelByProfile = Self.readModelMap(defaults, key: Key.defaultModelByProfile)
        self._showReasoning = defaults.object(forKey: Key.showReasoning) as? Bool ?? true
        self._selectedMode = PromptMode(rawValue: defaults.string(forKey: Key.selectedMode) ?? "") ?? .code
        self._selectedEffort = PromptEffort(rawValue: defaults.string(forKey: Key.selectedEffort) ?? "") ?? .medium
    }

    // MARK: - Active profile

    private var _activeProfileID: UUID?
    var activeProfileID: UUID? {
        get { access(keyPath: \._activeProfileID); return _activeProfileID }
        set {
            withMutation(keyPath: \._activeProfileID) { _activeProfileID = newValue }
            defaults.set(newValue?.uuidString, forKey: Key.activeProfileID)
        }
    }

    // MARK: - Last active project per profile

    private var _lastActiveProjectID: [String: String]
    var lastActiveProjectID: [String: String] {
        get { access(keyPath: \._lastActiveProjectID); return _lastActiveProjectID }
        set {
            withMutation(keyPath: \._lastActiveProjectID) { _lastActiveProjectID = newValue }
            defaults.set(newValue, forKey: Key.lastActiveProjectID)
        }
    }

    func lastActiveProject(for profile: UUID) -> String? {
        lastActiveProjectID[profile.uuidString]
    }

    func setLastActiveProject(_ projectID: String?, for profile: UUID) {
        var map = lastActiveProjectID
        if let projectID {
            map[profile.uuidString] = projectID
        } else {
            map.removeValue(forKey: profile.uuidString)
        }
        lastActiveProjectID = map
    }

    // MARK: - Default model per profile

    private var _defaultModelByProfile: [String: ModelRef]
    var defaultModelByProfile: [String: ModelRef] {
        get { access(keyPath: \._defaultModelByProfile); return _defaultModelByProfile }
        set {
            withMutation(keyPath: \._defaultModelByProfile) { _defaultModelByProfile = newValue }
            persistModelMap(newValue)
        }
    }

    func defaultModel(for profile: UUID) -> ModelRef? {
        defaultModelByProfile[profile.uuidString]
    }

    func setDefaultModel(_ ref: ModelRef?, for profile: UUID) {
        var map = defaultModelByProfile
        if let ref {
            map[profile.uuidString] = ref
        } else {
            map.removeValue(forKey: profile.uuidString)
        }
        defaultModelByProfile = map
    }

    // MARK: - Selected mode

    private var _selectedMode: PromptMode
    var selectedMode: PromptMode {
        get { access(keyPath: \._selectedMode); return _selectedMode }
        set {
            withMutation(keyPath: \._selectedMode) { _selectedMode = newValue }
            defaults.set(newValue.rawValue, forKey: Key.selectedMode)
        }
    }

    // MARK: - Selected effort

    private var _selectedEffort: PromptEffort
    var selectedEffort: PromptEffort {
        get { access(keyPath: \._selectedEffort); return _selectedEffort }
        set {
            withMutation(keyPath: \._selectedEffort) { _selectedEffort = newValue }
            defaults.set(newValue.rawValue, forKey: Key.selectedEffort)
        }
    }

    // MARK: - Show reasoning

    private var _showReasoning: Bool
    var showReasoning: Bool {
        get { access(keyPath: \._showReasoning); return _showReasoning }
        set {
            withMutation(keyPath: \._showReasoning) { _showReasoning = newValue }
            defaults.set(newValue, forKey: Key.showReasoning)
        }
    }

    // MARK: - Persistence helpers

    private func persistModelMap(_ map: [String: ModelRef]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(map) {
            defaults.set(data, forKey: Key.defaultModelByProfile)
        }
    }

    private static func readUUID(_ defaults: UserDefaults, key: String) -> UUID? {
        guard let raw = defaults.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }

    private static func readDictionary(_ defaults: UserDefaults, key: String) -> [String: String] {
        defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    private static func readModelMap(_ defaults: UserDefaults, key: String) -> [String: ModelRef] {
        guard let data = defaults.data(forKey: key) else { return [:] }
        return (try? JSONDecoder().decode([String: ModelRef].self, from: data)) ?? [:]
    }
}
