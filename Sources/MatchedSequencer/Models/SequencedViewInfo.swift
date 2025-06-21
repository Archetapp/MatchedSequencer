import SwiftUI

struct SequencedViewInfo: Hashable, Equatable {
    let id: AnyHashable
    let role: Role
    let namespace: Namespace.ID

    static func == (lhs: SequencedViewInfo, rhs: SequencedViewInfo) -> Bool {
        lhs.id == rhs.id && lhs.role == rhs.role && lhs.namespace == rhs.namespace
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(role)
        hasher.combine(namespace)
    }
} 
