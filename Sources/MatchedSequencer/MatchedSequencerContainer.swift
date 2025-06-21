import SwiftUI

public struct MatchedSequencerContainer<ID: Hashable, Content: View>: View {
    @Namespace internal var sequenceNamespace
    @StateObject internal var coordinator = SequenceCoordinator<ID>()
    
    // Make configuration properties internal for access by extension/modifiers
    internal var steps: [SequenceStep<ID>]
    internal var reversed: Bool = false
    internal var animates: Bool = true
    
    // Make bindings internal for access by extension/modifiers
    @Binding internal var startTrigger: Bool
    @Binding internal var isRunningExternally: Bool
    
    // Closure to execute on sequence end
    internal var onSequenceEndAction: (() -> Void)? = nil
    
    // Closure to execute on sequence step change
    internal var onSequenceStepChangeAction: ((SequenceStep<ID>?, Int?) -> Void)? = nil
    
    let content: (Namespace.ID) -> Content
    
    // Public initializer only needs steps and content now
    public init(
        steps: [SequenceStep<ID>],
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
        steps: [SequenceStep<ID>],
        startTrigger: Binding<Bool>,
        isRunningExternally: Binding<Bool>,
        reversed: Bool,
        animates: Bool,
        onSequenceEndAction: (() -> Void)? = nil,
        onSequenceStepChangeAction: ((SequenceStep<ID>?, Int?) -> Void)? = nil,
        @ViewBuilder content: @escaping (Namespace.ID) -> Content
    ) {
        self.steps = steps
        self._startTrigger = startTrigger
        self._isRunningExternally = isRunningExternally
        self.reversed = reversed
        self.animates = animates
        self.onSequenceEndAction = onSequenceEndAction
        self.onSequenceStepChangeAction = onSequenceStepChangeAction
        self.content = content
    }
    
    public var body: some View {
        content(sequenceNamespace)
            .environment(\.activeSequencerId, coordinator.activeStepId as AnyHashable?)
            .environment(\.keptAliveStepIds, Set(coordinator.keptAliveStepIds.map { $0 as AnyHashable }))
            .environment(\.activeMatchedRoleMap, Dictionary(uniqueKeysWithValues: coordinator.activeMatchedRoleMap.map { (key, value) in (key as AnyHashable, value) }))
            .environment(\.sequenceNamespace, sequenceNamespace)
            .onAppear {
                coordinator.configure(steps: steps, reversed: reversed, animates: animates, onSequenceStepChange: onSequenceStepChangeAction)
            }
            .onChange(of: steps) { oldSteps, newSteps in
                if oldSteps != newSteps {
                    coordinator.configure(steps: steps, reversed: reversed, animates: animates, onSequenceStepChange: onSequenceStepChangeAction)
                }
            }
            .onChange(of: reversed) { _, newReversed in
                coordinator.configure(steps: steps, reversed: newReversed, animates: animates, onSequenceStepChange: onSequenceStepChangeAction)
            }
            .onChange(of: animates) { _, newAnimates in
                coordinator.configure(steps: steps, reversed: reversed, animates: newAnimates, onSequenceStepChange: onSequenceStepChangeAction)
            }
            .onChange(of: startTrigger) { _, newValue in
                if newValue == true {
                    coordinator.startTriggerSubject.send()
                }
            }
            .onChange(of: coordinator.isRunning) { _, newValue in
                if isRunningExternally != newValue {
                    isRunningExternally = newValue
                }
            }
        // Listen for the coordinator's end signal
            .onReceive(coordinator.sequenceDidEndSubject) { _ in
                onSequenceEndAction?() // Execute the stored action if it exists
            }
            // Listen for the coordinator's step change signal
            .onReceive(coordinator.sequenceStepDidChangeSubject) { stepInfo in
                onSequenceStepChangeAction?(stepInfo.step, stepInfo.index)
            }
    }
}

// Remove the generic PreferenceKey since it's complex, we'll use AnyHashable for environment
extension MatchedSequencerContainer {
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
