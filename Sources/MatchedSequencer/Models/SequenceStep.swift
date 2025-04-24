import SwiftUI

public struct SequenceStep {
    let id: AnyHashable
    let animation: Animation?
    let type: StepType
    let delay: TimeInterval
    let keepAlive: Bool
    let waitForCompletion: Bool

    public enum StepType {
        case matched
        case transition
    }

    public init(_ id: AnyHashable, _ animation: Animation? = .default, type: StepType, delay: TimeInterval = 0, keepAlive: Bool = true, waitForCompletion: Bool = true) {
        self.id = id
        self.animation = animation
        self.type = type
        self.delay = delay
        self.keepAlive = keepAlive
        self.waitForCompletion = waitForCompletion
    }
} 