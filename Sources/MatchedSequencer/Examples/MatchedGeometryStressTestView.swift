import SwiftUI
import MatchedSequencer

struct MatchedGeometryStressTestView: View {
    // Use state for triggering and observing the sequence
    @State private var triggerSequence = false
    @State private var sequenceIsActive = false

    // Define a single ID for the geometry effect that will be shared
    struct GeometryIDs {
        static let sharedCircle = "sharedCircleEffect"
    }

    // Define the sequence steps: Alternate the role of 'sharedCircle'
    private let sequenceSteps: [SequenceStep] = [
        // Start with source visible (small, blue, left)
        SequenceStep(GeometryIDs.sharedCircle, type: .matched, delay: 0.5, keepAlive: true),
        // Transition to destination (large, red, right)
        SequenceStep(GeometryIDs.sharedCircle, .easeInOut(duration: 0.6), type: .matched, delay: 0.5, waitForCompletion: true),
        // Transition back to source - MATCH DURATION TO FIRST TRANSITION
        SequenceStep(GeometryIDs.sharedCircle, .easeInOut(duration: 0.6), type: .matched, delay: 0.5, waitForCompletion: true),
//         --- Temporarily removed subsequent steps for debugging ---
         // Transition back to destination quickly
         SequenceStep(GeometryIDs.sharedCircle, .easeOut, type: .matched, delay: 0.1, waitForCompletion: true), // Maybe wait to see it?
         // Transition back to source very quickly
         SequenceStep(GeometryIDs.sharedCircle, .easeIn(duration: 0.2), type: .matched, delay: 0.0, waitForCompletion: true),
    ]

    var body: some View {
        VStack {
            Text("Matched Geometry Stress Test")
                .font(.title)
                .padding(.bottom)

            // Use MatchedSequencerContainer
            MatchedSequencerContainer(steps: sequenceSteps) { namespace in
                ZStack {
                    // --- Small Circle (Left) - SOURCE ---
                    Circle()
                        .fill(Color.blue)
                        // Apply matched geometry first
                        .matchedSequencer( 
                            GeometryIDs.sharedCircle, 
                            .source, 
                            properties: .frame, 
                            anchor: .center
                        )
                        // Then define the frame for this instance
                        .frame(width: 50, height: 50)
                        // Then position it
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.leading, 50)

                    // --- Large Circle (Right) - DESTINATION ---
                    Circle()
                        .fill(Color.red)
                         // Apply matched geometry first
                        .matchedSequencer( 
                            GeometryIDs.sharedCircle, 
                            .destination, 
                            properties: .frame, 
                            anchor: .center
                        )
                         // Then define the frame for this instance
                        .frame(width: 150, height: 150)
                        // Then position it
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .padding(.trailing, 50)

                    // Removed Medium Circle (Top Center) as it doesn't fit the source/destination model per ID easily
                }
                .frame(height: 400) // Give the ZStack some space
                .border(Color.gray.opacity(0.5)) // Visual guide
            }
            // Add container modifiers for control and observation
            .sequenceAnimates(true) // Default, but explicit
            .startSequence(when: $triggerSequence)
            .isRunning($sequenceIsActive)
            .onChange(of: sequenceIsActive) { _, newValue in
                 // Reset trigger when sequence finishes
                 if !newValue {
                     triggerSequence = false
                 }
             }


            Button(sequenceIsActive ? "Running..." : "Start Sequence") {
                triggerSequence = true // Set trigger to start
            }
            .padding(.top)
            .disabled(sequenceIsActive) // Disable button while running

            Spacer()
        }
        .padding()
    }
}

struct MatchedGeometryStressTestView_Previews: PreviewProvider {
    static var previews: some View {
        MatchedGeometryStressTestView()
    }
} 
