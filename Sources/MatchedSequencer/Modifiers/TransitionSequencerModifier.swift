import SwiftUI

// This modifier handles the visibility of views marked for transition sequence.
struct TransitionSequencerModifier: ViewModifier {
    @Environment(\.activeSequencerId) private var activeSequencerId
    @Environment(\.keptAliveStepIds) private var keptAliveStepIds
    // TODO: We might need the animation from the step here later
    // @Environment(\.currentSequenceAnimation) private var currentAnimation 
    let id: AnyHashable
    let keepAlive: Bool
    
    func body(content: Content) -> some View {
        let isActive = activeSequencerId == id
        let isKeptAlive = keptAliveStepIds.contains(id)
        let shouldBeVisible = isActive || isKeptAlive
        
        // Use shouldBeVisible for the condition now
        Group {
            if shouldBeVisible {
                content
            } else {
                EmptyView()
            }
        }
        .id("TransitionWrapper_\(id)")
    }
} 
