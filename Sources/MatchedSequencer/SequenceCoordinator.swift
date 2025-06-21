import SwiftUI
import Combine

// ObservableObject to manage the sequence state and logic
@MainActor // Ensure state updates happen on the main thread
final class SequenceCoordinator<ID: Hashable>: ObservableObject {
    
    // Published properties for views to observe
    @Published var activeStepId: ID? = nil
    @Published var isRunning: Bool = false
    @Published var keptAliveStepIds: Set<ID> = []
    @Published var activeMatchedRoleMap: [ID: Role] = [:]
    
    // Subject to signal sequence completion
    let sequenceDidEndSubject = PassthroughSubject<Void, Never>()
    
    // Subject to signal step changes
    let sequenceStepDidChangeSubject = PassthroughSubject<(step: SequenceStep<ID>?, index: Int?), Never>()
    
    // Internal state
    private var isRunningInternally: Bool = false // Prevents overlapping Task runs
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration (set externally, e.g., by modifiers)
    var steps: [SequenceStep<ID>] = []
    var reversed: Bool = false
    var animates: Bool = true
    var onSequenceStepChangeAction: ((SequenceStep<ID>?, Int?) -> Void)? = nil
    // We still need a way to trigger externally
    // Let's use a PassthroughSubject for this
    let startTriggerSubject = PassthroughSubject<Void, Never>()

    init() {
        
        // Observe the start trigger subject
        startTriggerSubject
            .sink { [weak self] in
                self?.runSequence()
            }
            .store(in: &cancellables)
    }
    
    // Function to configure the coordinator (called by container/modifiers)
    func configure(steps: [SequenceStep<ID>], reversed: Bool, animates: Bool, onSequenceStepChange: ((SequenceStep<ID>?, Int?) -> Void)? = nil) {
         // Only update if changed to avoid unnecessary churn
         if self.steps.map({ $0.id }) != steps.map({ $0.id }) { // Basic check
            self.steps = steps
         } 
         if self.reversed != reversed {
             self.reversed = reversed
         }
         if self.animates != animates {
             self.animates = animates
         }
         
         // Store the callback
         self.onSequenceStepChangeAction = onSequenceStepChange
    }
    
    private func runSequence() {
        guard !isRunningInternally else {
            return
        }

        isRunningInternally = true
        self.isRunning = true // Publish external state

        // Local copies for updates within the Task will be initialized inside
        var currentKeptAliveIds: Set<ID> = [] // Initialize here, will be set in reset
        var currentRoleMap: [ID: Role] = [:] // Initialize here, will be set in reset

        let effectiveSteps = reversed ? steps.reversed() : steps

        Task {
            // --- START Initial State Reset ---
            // Ensure reset happens without animation, regardless of `self.animates`
            var initialResetTransaction = Transaction()
            initialResetTransaction.disablesAnimations = true

            withTransaction(initialResetTransaction) {
                self.activeStepId = nil // Reset active step
                self.keptAliveStepIds = [] // Reset keep-alive set

                // Calculate and set the initial role map
                var initialRoleMap: [ID: Role] = [:]
                for step in self.steps where step.type == .matched {
                    initialRoleMap[step.id] = .source // Default all matched to source
                }
                self.activeMatchedRoleMap = initialRoleMap

                // Update local copies for the Task after reset
                currentKeptAliveIds = self.keptAliveStepIds
                currentRoleMap = self.activeMatchedRoleMap
                
            }
            // --- END Initial State Reset ---

            // Optional brief pause *after* reset, *if* animating, to allow UI to settle?
            // This might not be necessary if the non-animated reset is effective.
            // if animates {
            //      try? await Task.sleep(nanoseconds: 16_000_000) // ~1 frame
            // }

            // --- Loop through Steps --- START
            var currentIndex = 0
            while currentIndex < effectiveSteps.count {
                let firstStepOfBatch = effectiveSteps[currentIndex]
                
                // --- Handle Delay (applied only for the *first* step of a potential batch) ---
                let delay = animates ? firstStepOfBatch.delay : 0
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                // --- Process Batch --- 
                var transaction = Transaction()
                // Use animation from the first step for the whole batch transaction?
                if animates, let anim = firstStepOfBatch.animation { transaction.animation = anim }
                else if !animates { transaction.disablesAnimations = true }
                
                var stepsProcessedInBatch = 0
                var batchEnded = false
                var lastStepInBatchRequiresWait = false
                
                // Use local vars to accumulate state changes for the batch
                var batchActiveStepId: ID? = self.activeStepId
                var batchRoleMap = currentRoleMap // Use local map from Task scope
                var batchKeepAliveIds = currentKeptAliveIds // Use local set from Task scope
                
                withTransaction(transaction) {
                    var batchIndex = currentIndex
                    while batchIndex < effectiveSteps.count && !batchEnded {
                        let currentBatchStep = effectiveSteps[batchIndex]
                        
                        // Determine if this step can run in the current batch
                        let isFirstStepInBatch = (batchIndex == currentIndex)
                        // Condition: Previous step must exist, not require waiting, and current step must have zero delay
                        let canRunConcurrently = !isFirstStepInBatch && 
                                                 currentBatchStep.delay == 0 && 
                                                 !effectiveSteps[batchIndex - 1].waitForCompletion
                        
                        if isFirstStepInBatch || canRunConcurrently {
                            // --- State Updates for this Step within Batch --- 
                            // 1. Keep Alive check for the ID being replaced
                            let previousIdForKeepAlive = batchActiveStepId 
                            if let prevId = previousIdForKeepAlive,
                               let previousStepConfig = self.steps.first(where: { $0.id == prevId }),
                               previousStepConfig.keepAlive {
                                batchKeepAliveIds.insert(prevId)
                            }
                            
                            // 2. Update Active ID for the batch
                            batchActiveStepId = currentBatchStep.id
                            
                            // 3. Update Role Map for the batch
                            if currentBatchStep.type == .matched {
                                // --- Toggle Role --- START
                                // Get the current role from the map (default to source if somehow missing)
                                let currentRole = batchRoleMap[currentBatchStep.id] ?? .source 
                                // Set the new role to the opposite
                                batchRoleMap[currentBatchStep.id] = (currentRole == .source ? .destination : .source)
                                // --- Toggle Role --- END
                            }
                            
                            // 4. Update Keep Alive Set for the batch (Remove current ID)
                            batchKeepAliveIds.remove(currentBatchStep.id)
                            
                            // --- End State Updates --- 
                            
                            stepsProcessedInBatch += 1
                            lastStepInBatchRequiresWait = currentBatchStep.waitForCompletion
                            
                            // If this step requires waiting, the batch must end after this step
                            if currentBatchStep.waitForCompletion {
                                batchEnded = true
                            }
                            
                            batchIndex += 1 // Move to next potential step
                            
                        } else {
                            // Cannot run concurrently, end the batch here
                            batchEnded = true
                        }
                    } // End inner batch loop
                    
                    // Publish the final accumulated state changes from the batch
                    self.activeStepId = batchActiveStepId
                    self.activeMatchedRoleMap = batchRoleMap
                    self.keptAliveStepIds = batchKeepAliveIds
                    
                    // Notify about step change
                    if let activeId = batchActiveStepId,
                       let activeStep = self.steps.first(where: { $0.id == activeId }) {
                        let stepIndex = effectiveSteps.firstIndex(where: { $0.id == activeId })
                        self.onSequenceStepChangeAction?(activeStep, stepIndex)
                        self.sequenceStepDidChangeSubject.send((activeStep, stepIndex))
                    }
                    
                    
                } // End withTransaction
                
                // Update the Task's local state tracking maps/sets for the next iteration
                currentRoleMap = self.activeMatchedRoleMap
                currentKeptAliveIds = self.keptAliveStepIds
                
                // --- Optional Wait AFTER Batch --- 
                if animates && lastStepInBatchRequiresWait {
                    // This sleep allows the animations triggered by the batch transaction 
                    // to visually progress before the next step's delay/processing starts.
                    try? await Task.sleep(nanoseconds: 600_000_000) 
                }
                
                // Advance main loop index past the processed batch
                currentIndex += stepsProcessedInBatch
                
            } // End main step loop
            // --- Loop through Steps --- END
            
            // --- Final Keep Alive Check --- START
            // Before resetting activeStepId, check if the final step should be kept alive.
            let finalStepId = self.activeStepId
            if let finalId = finalStepId,
               let finalStep = self.steps.first(where: { $0.id == finalId }),
               finalStep.keepAlive {
                   // Manually add the final step's ID to the published set
                   // if it's supposed to be kept alive.
                   // We do this before the final transaction resets the active ID.
                   self.keptAliveStepIds.insert(finalId)
            }
            // --- Final Keep Alive Check --- END

            // Sequence finished Transaction
            var finalCompletionTransaction = Transaction() // Renamed from finalResetTransaction
            // Animation for the final step to nil transition depends on 'animates' flag
            if !animates {
                 finalCompletionTransaction.disablesAnimations = true
            }
            // If we need a specific animation for the cleanup, set it here.
            // else { finalCompletionTransaction.animation = .default }

            // Reset activeStepId at the very end
            // KeepAlive state is handled before this
            withTransaction(finalCompletionTransaction) {
                self.activeStepId = nil
            }
            
            // Notify about sequence end (nil step)
            self.onSequenceStepChangeAction?(nil, nil)
            self.sequenceStepDidChangeSubject.send((nil, nil))

            isRunning = false
            isRunningInternally = false
            
            // Signal that the sequence ended naturally
            sequenceDidEndSubject.send()
        }
    }
    
    // Function to reset sequence state
    func resetSequence() {
        // Reset all published animation state
        self.activeStepId = nil
        self.keptAliveStepIds = []
        
        // Reset role map to initial state
        var initialRoleMap: [ID: Role] = [:]
        for step in self.steps where step.type == .matched {
            initialRoleMap[step.id] = .source // Default all matched to source
        }
        self.activeMatchedRoleMap = initialRoleMap
        
        // Reset running state
        isRunning = false
        isRunningInternally = false
    }
} 
