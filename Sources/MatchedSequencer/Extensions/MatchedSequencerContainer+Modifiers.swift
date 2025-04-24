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
            content: self.content
        )
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
            content: self.content
        )
    }
} 
