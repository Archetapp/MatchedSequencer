import SwiftUI

enum MinimalId: Hashable {
    case shape
    case message
}

struct MinimalSequenceExample: View {

    let sequence: [SequenceStep] = [
        .init(MinimalId.shape, .smooth, type: .matched),
        .init(MinimalId.message, .smooth, type: .transition, delay: 0.3),
        .init(MinimalId.shape, .interpolatingSpring(stiffness: 150, damping: 12), type: .matched, delay: 0.5)
    ]

    @State private var triggerSequence = false
    @State private var sequenceIsActive = false

    var body: some View {
        VStack {
            Button("Run Sequence") {
                triggerSequence = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(sequenceIsActive)
            .padding(.top)

            MatchedSequencerContainer(steps: sequence) { namespace in
                VStack(spacing: 40) {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 40)
                        .foregroundStyle(.teal)
                        .matchedSequencer(
                            MinimalId.shape,
                            .source
                        )
                        .frame(width: 80, height: 80)

                    RoundedRectangle(cornerRadius: 15)
                        .foregroundStyle(.indigo)
                        .matchedSequencer(
                            MinimalId.shape,
                            .destination
                        )
                        .frame(width: 120, height: 60)
                    
                    Text("Hello, Sequencer!")
                        .font(.title2)
                        .padding()
                        .background(.yellow.opacity(0.2), in: Capsule())
                        .sequencer(MinimalId.message)
                        .transition(.scale.combined(with: .opacity))
                        
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
            .startSequence(when: $triggerSequence)
            .isRunning($sequenceIsActive)
            .onChange(of: sequenceIsActive) { newValue, _ in
                if !newValue { triggerSequence = false }
            }
        }
        .navigationTitle("Minimal Example")
    }
}

struct MinimalSequenceExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MinimalSequenceExample()
        }
    }
} 
