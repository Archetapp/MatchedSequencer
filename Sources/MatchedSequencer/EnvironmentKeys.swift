import SwiftUI

// Environment key to hold the set of IDs that should remain visible
// even when they are not the active step, because their step had keepAlive = true.
private struct KeptAliveStepIdsKey: EnvironmentKey {
    static let defaultValue: Set<AnyHashable> = []
}

extension EnvironmentValues {
    var keptAliveStepIds: Set<AnyHashable> {
        get { self[KeptAliveStepIdsKey.self] }
        set { self[KeptAliveStepIdsKey.self] = newValue }
    }
}

// Environment key for the map indicating the active Role (.source/.destination)
// for each matched geometry ID.
private struct ActiveMatchedRoleMapKey: EnvironmentKey {
    static let defaultValue: [AnyHashable: Role] = [:]
}

extension EnvironmentValues {
    var activeMatchedRoleMap: [AnyHashable: Role] {
        get { self[ActiveMatchedRoleMapKey.self] }
        set { self[ActiveMatchedRoleMapKey.self] = newValue }
    }
}

// Environment key for the Namespace used by the sequencer container.
private struct SequenceNamespaceKey: EnvironmentKey {
    // Providing a default is tricky. A fatalError might be appropriate 
    // if the modifier is used outside a container, but for safety,
    // let's use a dummy static one. Modifiers should ideally check for nil?
    // Or, we make the Environment value Optional.
    static let defaultValue: Namespace.ID? = nil // Make it optional
}

extension EnvironmentValues {
    var sequenceNamespace: Namespace.ID? { // Make it optional
        get { self[SequenceNamespaceKey.self] }
        set { self[SequenceNamespaceKey.self] = newValue }
    }
} 