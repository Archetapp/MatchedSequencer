import SwiftUI

// Modifiers for MatchedSequencerContainer Configuration
public extension MatchedSequencerContainer {

    /// Triggers the sequence when the provided binding becomes true.
    /// The binding is NOT automatically reset by the container; the caller should reset it based on the `isRunning` state.
    /// - Parameter trigger: A `Binding<Bool>` to control the sequence start.
    func startSequence(when trigger: Binding<Bool>) -> MatchedSequencerContainer {
        .init(
            steps: self.steps,
            startTrigger: trigger,
            isRunningExternally: self.$isRunningExternally,
            reversed: self.reversed,
            animates: self.animates,
            onSequenceEndAction: self.onSequenceEndAction,
            onSequenceStepChangeAction: self.onSequenceStepChangeAction,
            content: self.content
        )
    }
    
    /// Resets the animation sequence state completely, ensuring a clean start for the next animation.
    /// Use this when having issues with animation flickering or inconsistent states.
    /// - Parameter reset: A binding that triggers the reset when set to true. Will be set back to false after reset.
    func sequenceReset(when reset: Binding<Bool>) -> some View {
        self.onChange(of: reset.wrappedValue) { oldValue, newValue in
            if newValue {
                // If the reset flag is true, perform the reset
                withAnimation(nil) {
                    self.coordinator.resetSequence()
                }
                
                // After resetting, set the flag back to false
                DispatchQueue.main.async {
                    reset.wrappedValue = false
                }
            }
        }
    }
    
    /// Runs the sequence in reverse order if set to true.
    /// - Parameter reversed: A boolean indicating whether to reverse the sequence. Defaults to true.
    func sequenceReversed(_ reversed: Bool = true) -> MatchedSequencerContainer {
        .init(
            steps: self.steps,
            startTrigger: self.$startTrigger,
            isRunningExternally: self.$isRunningExternally,
            reversed: reversed,
            animates: self.animates,
            onSequenceEndAction: self.onSequenceEndAction,
            onSequenceStepChangeAction: self.onSequenceStepChangeAction,
            content: self.content
        )
    }
    
    /// Determines whether the sequence steps use animations and delays.
    /// If false, the sequence jumps instantly between states.
    /// - Parameter animates: A boolean indicating whether to animate. Defaults to true.
    func sequenceAnimates(_ animates: Bool = true) -> MatchedSequencerContainer {
        .init(
            steps: self.steps,
            startTrigger: self.$startTrigger,
            isRunningExternally: self.$isRunningExternally,
            reversed: self.reversed,
            animates: animates,
            onSequenceEndAction: self.onSequenceEndAction,
            onSequenceStepChangeAction: self.onSequenceStepChangeAction,
            content: self.content
        )
    }
    
    /// Provides a binding to observe the running state of the sequence.
    /// The binding becomes `true` when the sequence starts and `false` when it completes or is cancelled.
    /// - Parameter isRunning: A `Binding<Bool>` that reflects the sequence's active state.
    func isRunning(_ isRunning: Binding<Bool>) -> MatchedSequencerContainer {
        .init(
            steps: self.steps,
            startTrigger: self.$startTrigger,
            isRunningExternally: isRunning,
            reversed: self.reversed,
            animates: self.animates,
            onSequenceEndAction: self.onSequenceEndAction,
            onSequenceStepChangeAction: self.onSequenceStepChangeAction,
            content: self.content
        )
    }
    
    /// Executes the provided action when the sequence completes normally.
    /// This action is *not* called if the sequence is cancelled or interrupted.
    /// - Parameter action: The closure to execute upon sequence completion.
    func onSequenceEnd(_ action: @escaping () -> Void) -> MatchedSequencerContainer {
        .init(
            steps: self.steps,
            startTrigger: self.$startTrigger,
            isRunningExternally: self.$isRunningExternally,
            reversed: self.reversed,
            animates: self.animates,
            onSequenceEndAction: action,
            onSequenceStepChangeAction: self.onSequenceStepChangeAction,
            content: self.content
        )
    }
    
    /// Executes the provided action whenever the active sequence step changes.
    /// The action receives the current step (or nil when sequence ends) and its index.
    /// - Parameter action: The closure to execute on each step change, receiving (step, index).
    func onSequenceStepChange(_ action: @escaping (SequenceStep<ID>?, Int?) -> Void) -> MatchedSequencerContainer {
        return .init(
            steps: self.steps,
            startTrigger: self.$startTrigger,
            isRunningExternally: self.$isRunningExternally,
            reversed: self.reversed,
            animates: self.animates,
            onSequenceEndAction: self.onSequenceEndAction,
            onSequenceStepChangeAction: action,
            content: self.content
        )
    }
} 
