import SwiftUI

private struct ActiveSequencerIdKey: EnvironmentKey {
    static let defaultValue: AnyHashable? = nil
}

extension EnvironmentValues {
    public var activeSequencerId: AnyHashable? {
        get { self[ActiveSequencerIdKey.self] }
        set { self[ActiveSequencerIdKey.self] = newValue }
    }
} 
