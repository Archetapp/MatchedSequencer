import SwiftUI
import Combine

// ObservableObject to manage the sequence state and logic
@MainActor // Ensure state updates happen on the main thread
final class SequenceCoordinator: ObservableObject {
    
    // Published properties for views to observe
    @Published var activeStepId: AnyHashable? = nil
    @Published var isRunning: Bool = false
    @Published var keptAliveStepIds: Set<AnyHashable> = []
    @Published public var activeMatchedRoleMap: [AnyHashable: Role] = [:]
    
    // Internal state
    private var isRunningInternally: Bool = false // Prevents overlapping Task runs
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration (set externally, e.g., by modifiers)
    var steps: [SequenceStep] = []
    var reversed: Bool = false
    var animates: Bool = true
    // We still need a way to trigger externally
    // Let's use a PassthroughSubject for this
    let startTriggerSubject = PassthroughSubject<Void, Never>()

    init() {
        // print("SequenceCoordinator init") // REMOVED
        
        // Observe the start trigger subject
        startTriggerSubject
            .sink { [weak self] in
                self?.runSequence()
            }
            .store(in: &cancellables)
    }
    
    // Function to configure the coordinator (called by container/modifiers)
    func configure(steps: [SequenceStep], reversed: Bool, animates: Bool) {
         // Only update if changed to avoid unnecessary churn
         if self.steps.map({ $0.id }) != steps.map({ $0.id }) { // Basic check
            self.steps = steps
            // print("Coordinator configured: steps count = \(steps.count)") // REMOVED
         } 
         if self.reversed != reversed {
             self.reversed = reversed
             // print("Coordinator configured: reversed = \(reversed)") // REMOVED
         }
         if self.animates != animates {
             self.animates = animates
              // print("Coordinator configured: animates = \(animates)") // REMOVED
         }
    }
    
    private func runSequence() {
        // print("Coordinator: runSequence called. isRunningInternally=\(isRunningInternally)") // REMOVED
        guard !isRunningInternally else { 
            // print("Coordinator: runSequence aborted: already running internally.") // REMOVED
            return
        }

        isRunningInternally = true
        self.isRunning = true // Publish external state
        
        // --- START Initial State Setup ---
        var initialRoleMap: [AnyHashable: Role] = [:]
        for step in self.steps where step.type == .matched {
            initialRoleMap[step.id] = .source // Default all matched to source
        }
        self.activeMatchedRoleMap = initialRoleMap
        self.keptAliveStepIds = [] // Reset keep-alive
        // --- END Initial State Setup ---

        // Local copy for updates within the Task
        var currentKeptAliveIds: Set<AnyHashable> = [] 
        var currentRoleMap = initialRoleMap
        
        let effectiveSteps = reversed ? steps.reversed() : steps
        // print("Coordinator: runSequence starting Task. reversed=\(reversed), animates=\(animates)") // REMOVED

        Task {
            var initialResetTransaction = Transaction()
            if !animates { initialResetTransaction.disablesAnimations = true }
             // Use objectWillChange.send() before state change for manual publishing if needed,
             // but @Published should handle activeStepId and isRunning
            withTransaction(initialResetTransaction) { self.activeStepId = nil }
            
            if animates {
                 try? await Task.sleep(nanoseconds: 50_000_000)
            }

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
                var batchActiveStepId: AnyHashable? = self.activeStepId
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
                            
                            // print("DEBUG: SequenceCoordinator - Activating Batch Step: \(currentBatchStep.id)") // REMOVED
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
                    // print("DEBUG: SequenceCoordinator - Batch End State: Active=\(String(describing: self.activeStepId)), Roles=\(self.activeMatchedRoleMap), KeptAlive=\(self.keptAliveStepIds)") // REMOVED
                    
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
                   // print("DEBUG: SequenceCoordinator - Keeping final step alive: \(finalId)") // REMOVED
            }
            // --- Final Keep Alive Check --- END

            // Sequence finished Transaction
            var finalResetTransaction = Transaction()
            if animates {
                finalResetTransaction.animation = .default
            } else {
                finalResetTransaction.disablesAnimations = true
            }
            withTransaction(finalResetTransaction) {
                self.activeStepId = nil
            }
            
            isRunning = false 
            isRunningInternally = false
            // print("Coordinator Task finished.") // REMOVED
        }
    }
} 
