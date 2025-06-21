import SwiftUI

public struct SequenceStep<ID: Hashable>: Equatable {
    public let id: ID
    public let animation: Animation?
    public let type: StepType
    public let delay: TimeInterval
    public let keepAlive: Bool
    public let waitForCompletion: Bool

    public enum StepType {
        case matched
        case transition
    }

    public init(_ id: ID, _ animation: Animation? = .default, type: StepType, delay: TimeInterval = 0, keepAlive: Bool = true, waitForCompletion: Bool = true) {
        self.id = id
        self.animation = animation
        self.type = type
        self.delay = delay
        self.keepAlive = keepAlive
        self.waitForCompletion = waitForCompletion
    }
    
    /// Convenience method to get the ID as a specific type
    public func idAs<T>(_ type: T.Type) -> T? {
        return id as? T
    }

    public static func == (lhs: SequenceStep<ID>, rhs: SequenceStep<ID>) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.delay == rhs.delay &&
               lhs.keepAlive == rhs.keepAlive &&
               lhs.waitForCompletion == rhs.waitForCompletion
    }
}

// Type alias for backward compatibility with AnyHashable
public typealias AnySequenceStep = SequenceStep<AnyHashable> 
