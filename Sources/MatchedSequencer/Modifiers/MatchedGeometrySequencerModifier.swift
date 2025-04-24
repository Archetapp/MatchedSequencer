import SwiftUI

// This modifier purely applies the matchedGeometryEffect.
// Visibility/presence is handled by the view structure using the environment's activeStepId.
internal struct MatchedGeometrySequencerModifier: ViewModifier {
    @Environment(\.activeMatchedRoleMap) private var activeMatchedRoleMap
    @Environment(\.sequenceNamespace) private var sequenceNamespace
    
    let id: AnyHashable
    let role: Role
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool

    func body(content: Content) -> some View {
        let expectedActiveRole = activeMatchedRoleMap[id] ?? .source
        
        let shouldBeVisible = (self.role == expectedActiveRole)
        
        if shouldBeVisible {
            if let ns = sequenceNamespace {
                content
                    .matchedGeometryEffect(
                        id: id, 
                        in: ns,
                        properties: properties, 
                        anchor: anchor, 
                        isSource: true
                    )
            } else {
                content
            }
        } else {
            EmptyView()
        }
    }
} 
