import SwiftUI

public struct MatchedSequencerContainer<Content: View>: View {
    @Namespace internal var sequenceNamespace
    @StateObject internal var coordinator = SequenceCoordinator()
    
    // Make configuration properties internal for access by extension/modifiers
    internal var steps: [SequenceStep]
    internal var reversed: Bool = false
    internal var animates: Bool = true
    
    // Make bindings internal for access by extension/modifiers
    @Binding internal var startTrigger: Bool
    @Binding internal var isRunningExternally: Bool
    
    // Closure to execute on sequence end
    internal var onSequenceEndAction: (() -> Void)? = nil
    
    let content: (Namespace.ID) -> Content

    // Public initializer only needs steps and content now
    public init(
        steps: [SequenceStep],
        @ViewBuilder content: @escaping (Namespace.ID) -> Content
    ) {
        self.steps = steps
        self._startTrigger = .constant(false)
        self._isRunningExternally = .constant(false)
        self.content = content
    }
    
    // Internal initializer used by modifiers to set bindings/config
    // Access levels of parameters don't need changing here
    init(
        steps: [SequenceStep],
        startTrigger: Binding<Bool>,
        isRunningExternally: Binding<Bool>,
        reversed: Bool,
        animates: Bool,
        onSequenceEndAction: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Namespace.ID) -> Content
    ) {
        self.steps = steps
        self._startTrigger = startTrigger
        self._isRunningExternally = isRunningExternally
        self.reversed = reversed
        self.animates = animates
        self.onSequenceEndAction = onSequenceEndAction
        self.content = content
    }

    public var body: some View {
        content(sequenceNamespace)
            .environment(\.activeSequencerId, coordinator.activeStepId)
            .environment(\.keptAliveStepIds, coordinator.keptAliveStepIds)
            .environment(\.activeMatchedRoleMap, coordinator.activeMatchedRoleMap)
            .environment(\.sequenceNamespace, sequenceNamespace)
            .preference(key: SequenceCoordinatorPreferenceKey.self, value: coordinator)
            .onAppear { 
                coordinator.configure(steps: steps, reversed: reversed, animates: animates)
            }
            .onChange(of: steps.map { $0.id }) { _, _ in 
                coordinator.configure(steps: steps, reversed: reversed, animates: animates)
            }
            .onChange(of: reversed) { _, newReversed in
                 coordinator.configure(steps: steps, reversed: newReversed, animates: animates)
            }
            .onChange(of: animates) { _, newAnimates in
                 coordinator.configure(steps: steps, reversed: reversed, animates: newAnimates)
            }
            .onChange(of: startTrigger) { _, newValue in
                print("Container onChange(startTrigger): \(newValue)")
                if newValue == true {
                    coordinator.startTriggerSubject.send()
                }
            }
             .onChange(of: coordinator.isRunning) { _, newValue in
                 print("Container onChange(coordinator.isRunning): \(newValue)")
                 if isRunningExternally != newValue {
                     isRunningExternally = newValue
                 }
             }
            // Listen for the coordinator's end signal
            .onReceive(coordinator.sequenceDidEndSubject) { _ in
                onSequenceEndAction?() // Execute the stored action if it exists
            }
    }
}

struct SequenceCoordinatorPreferenceKey: PreferenceKey {
    static var defaultValue: SequenceCoordinator? = nil
    static func reduce(value: inout SequenceCoordinator?, nextValue: () -> SequenceCoordinator?) {
        value = value ?? nextValue()
    }
}

// Removed conflicting extension from previous attempts here

// Extension to provide the `.sequenceRunning` modifier convenience
public extension MatchedSequencerContainer {
    func sequenceRunning(_ isRunning: Binding<Bool>) -> MatchedSequencerContainer {
        var view = self
        view._startTrigger = isRunning
        return view
    }
}

// Need to adjust the View modifiers to react to `activeStepId`.
// The current SequencerModifier applies matchedGeometryEffect unconditionally.
// It needs to be conditional based on the container's state.
// This likely means the container needs to inject the activeStepId into the environment
// or pass it down somehow so the modifiers/views can react.

// Let's refine this next. 
