import SwiftUI

// Define an enum for type-safe sequence IDs
enum SequenceElementId: Hashable {
    case circlePair
    case animatedText
    case otherContent
    case finishedState
}

// Example Usage:
struct BasicSequenceExample: View {
    
    // Define the sequence steps
    let sequence: [SequenceStep] = [
        .init(
            SequenceElementId.circlePair,
            .spring(),
            type: .matched
        ),
        .init(
            SequenceElementId.animatedText,
            .spring(),
            type: .transition,
            waitForCompletion: false
        ),
        .init(
            SequenceElementId.otherContent,
            .bouncy(),
            type: .transition,
            delay: 0.0,
            waitForCompletion: true
        ),
        .init(
            SequenceElementId.circlePair,
            .spring(),
            type: .matched,
            delay: 0.1
        ),
        .init(
            SequenceElementId.finishedState,
            .spring(),
            type: .transition,
            delay: 0.2
        )
    ]
    
    @State private var triggerSequence = false
    @State private var sequenceIsActive = false
    @State private var shouldReverse = false
    @State private var shouldAnimate = true
    
    var body: some View {
        VStack {
            // Control Buttons
            HStack {
                Button("Run Forward") { 
                    shouldReverse = false
                    shouldAnimate = true
                    triggerSequence = true // Trigger the sequence
                }
                .buttonStyle(.borderedProminent).tint(.blue)
                .disabled(sequenceIsActive) // Disable based on actual running state
                
                Button("Run Reversed") { 
                    shouldReverse = true
                    shouldAnimate = true
                    triggerSequence = true // Trigger the sequence
                }
                .buttonStyle(.bordered).tint(.orange)
                 .disabled(sequenceIsActive) // Disable based on actual running state
                
                 Button("Jump to End") { 
                     shouldReverse = false // Jump forward to the *defined* end state
                     shouldAnimate = false
                     triggerSequence = true // Trigger the sequence
                 }
                 .buttonStyle(.bordered).tint(.green)
                 .disabled(sequenceIsActive) // Disable based on actual running state
            }
            .padding(.top)
            
            Text(sequenceIsActive ? "Sequence Running..." : "Sequence Idle") // Use actual running state
                .font(.caption)
                .foregroundColor(sequenceIsActive ? .orange : .secondary)
                .padding(.bottom, 5)
                
            MatchedSequencerContainer(steps: sequence) { namespace in
                VStack(spacing: 50) {

                   SubView()
                    
                    Circle().foregroundStyle(.indigo)
                        .matchedSequencer(SequenceElementId.circlePair, .destination, properties: [.size, .frame])
                        .frame(width: 150, height: 150)
                    
                    Text("Animated Text")
                        .font(.title).fontWeight(.bold).padding()
                        .background(.yellow.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.black)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                        .sequencer(SequenceElementId.animatedText)
                    
                     Text("Other Content")
                         .font(.body).padding()
                         .background(.mint.opacity(0.8), in: Capsule())
                         .foregroundStyle(.black)
                         .transition(.move(edge: .trailing).combined(with: .opacity))
                         .sequencer(SequenceElementId.otherContent)
                         
                    // Add the Finished State View
                    Text("Finished!")
                        .font(.largeTitle).bold()
                        .foregroundStyle(.green)
                        .transition(.blurReplace())
                        .sequencer(SequenceElementId.finishedState)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(white: 0.1))
                .ignoresSafeArea(edges: .bottom)
            }
            .startSequence(when: $triggerSequence)
            .sequenceReversed(shouldReverse)
            .sequenceAnimates(shouldAnimate)
            .isRunning($sequenceIsActive)
            .onChange(of: sequenceIsActive) { newValue, _ in
                if newValue == false {
                    triggerSequence = false
                }
            }
        }
    }
}


struct SubView: View {
    var body: some View {
        SubView2()
    }
}

struct SubView2: View {
    var body: some View {
        SubView3()
    }
}

struct SubView3: View {
    var body: some View {
        Circle().foregroundStyle(.cyan)
            .matchedSequencer(SequenceElementId.circlePair, .source)
            .frame(width: 100, height: 100)
    }
}

struct BasicSequenceExample_Previews: PreviewProvider {
    static var previews: some View {
        BasicSequenceExample()
            .preferredColorScheme(.dark) // Preview in dark mode
    }
}

// Next step: Modify MatchedSequencerContainer to provide `activeStepId` to children
// and modify the children/modifiers to react to it. 
