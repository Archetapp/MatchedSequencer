import SwiftUI

public extension View {
    
    /// Applies matched geometry effect for use within a `MatchedSequencerContainer`.
    ///
    /// The visibility of the view should be controlled by the view hierarchy structure,
    /// typically using an `if` condition based on the `@Environment(\.activeSequencerId)`.
    ///
    /// - Parameters:
    ///   - id: The identifier for the matched geometry effect.
    ///   - role: `.source` or `.destination`.
    ///   - properties: The properties to match (default: `.frame`).
    ///   - anchor: The anchor point for the transition (default: `.center`).
    /// - Returns: A view modified with `matchedGeometryEffect`.
    public func matchedSequencer(
        _ id: AnyHashable,
        _ role: Role, 
        properties: MatchedGeometryProperties = .frame, 
        anchor: UnitPoint = .center
    ) -> some View {
        guard role == .source || role == .destination else {
             assertionFailure("Invalid role `\(role)` used with `matchedSequencer`. Use `.source` or `.destination`.")
             // Path 1: Return AnyView
             return AnyView(self) 
        }
        // Path 2: Also return AnyView to match Path 1's type
        return AnyView( 
            self.modifier(
                MatchedGeometrySequencerModifier(
                    id: id, 
                    role: role, 
                    properties: properties, 
                    anchor: anchor, 
                    isSource: role == .source
                )
            )
        )
    }

    /// Marks a view to be shown/hidden during a sequence based on its ID matching the active step ID.
    ///
    /// Apply a `.transition()` modifier to the view *before* this modifier to control its appearance/disappearance.
    ///
    /// - Parameter id: The identifier that triggers this view's visibility in the sequence.
    /// - Parameter keepAlive: If true (default), the view remains in the hierarchy but invisible when inactive.
    ///                        If false, the view is removed from the hierarchy (using `EmptyView`) when inactive.
    /// - Returns: A view that conditionally appears based on the active sequence step.
    public func sequencer(_ id: AnyHashable, keepAlive: Bool = true) -> some View {
        // This modifier handles its own visibility based on environment,
        // so no conditional return needed here. Can return ModifiedContent directly.
        self.modifier(TransitionSequencerModifier(id: id, keepAlive: keepAlive))
        // If we needed conditional logic here, we'd likely use AnyView too:
        // return AnyView(self.modifier(TransitionSequencerModifier(id: id)))
    }
} 
