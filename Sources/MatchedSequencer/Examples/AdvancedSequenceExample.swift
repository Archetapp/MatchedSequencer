import SwiftUI

// Define IDs for the advanced sequence
enum AdvancedSequenceId: Hashable {
    case title
    case cardPair // Matched
    case detailText
    case iconPair // Matched
    case statusIndicator
    case finalMessage
    // // Add an optional ID for an 'empty' state if needed to explicitly hide things
    // case none 
}

// Example Usage: Advanced Sequence
struct AdvancedSequenceExample: View {

    // Define the sequence steps
    let sequence: [SequenceStep] = [
        .init(AdvancedSequenceId.title, .smooth(duration: 0.4), type: .transition),
        .init(AdvancedSequenceId.cardPair, .interpolatingSpring(stiffness: 150, damping: 12), type: .matched, delay: 0.2), // Show source card
        .init(AdvancedSequenceId.detailText, .smooth(duration: 0.5), type: .transition, delay: 0.1, keepAlive: true), // Show details, keep alive
        .init(AdvancedSequenceId.cardPair, .interpolatingSpring(stiffness: 170, damping: 15), type: .matched, delay: 0.3), // Switch card to destination
        .init(AdvancedSequenceId.iconPair, .interpolatingSpring(stiffness: 120, damping: 10), type: .matched, delay: 0.1), // Show source icon
        .init(AdvancedSequenceId.iconPair, .interpolatingSpring(stiffness: 140, damping: 12), type: .matched, delay: 0.4), // Switch icon to destination
        .init(AdvancedSequenceId.statusIndicator, .smooth(duration: 0.4), type: .transition, delay: 0.1, keepAlive: true), // Show status, keep alive
        .init(AdvancedSequenceId.finalMessage, .smooth(duration: 0.6), type: .transition, delay: 0.5) // Show final message (implicitly hides details/status due to keepAlive=false)
    ]

    // Trigger for the sequence
    @State private var triggerSequence = false
    // State reflecting the container's actual running status
    @State private var sequenceIsActive = false

    // Configuration states
    @State private var shouldReverse = false
    @State private var shouldAnimate = true

    var body: some View {
        VStack {
            // Control Buttons (Similar to Basic Example)
            HStack {
                Button("Run Forward") {
                    shouldReverse = false
                    shouldAnimate = true
                    triggerSequence = true
                }
                .buttonStyle(.borderedProminent).tint(.blue)
                .disabled(sequenceIsActive)

                Button("Run Reversed") {
                    shouldReverse = true
                    shouldAnimate = true
                    triggerSequence = true
                }
                .buttonStyle(.bordered).tint(.orange)
                .disabled(sequenceIsActive)

                Button("Jump to End") {
                    shouldReverse = false
                    shouldAnimate = false
                    triggerSequence = true
                }
                .buttonStyle(.bordered).tint(.green)
                .disabled(sequenceIsActive)
            }
            .padding(.top)

            Text(sequenceIsActive ? "Sequence Running..." : "Sequence Idle")
                .font(.caption)
                .foregroundColor(sequenceIsActive ? .orange : .secondary)
                .padding(.bottom, 5)

            // MatchedSequencer Container
            MatchedSequencerContainer(steps: sequence) { namespace in
                // Main content Vstack
                VStack(spacing: 30) {
                    // 1. Title
                    Text("Complex Process")
                        .font(.largeTitle.bold())
                        .sequencer(AdvancedSequenceId.title)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // 2. Card Pair (Matched)
                    ZStack {
                        // Source Card
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.blue)
                            .overlay(Text("Initial State").font(.title2).bold().foregroundColor(.white))
                            .matchedSequencer(AdvancedSequenceId.cardPair, .source)
                            .frame(height: 150)
                        
                        // Destination Card
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.green)
                            .overlay(
                                VStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                    Text("Processing Complete")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            )
                            .matchedSequencer(AdvancedSequenceId.cardPair, .destination)
                            .frame(height: 100)
                    }
                    
                    // 3. Detail Text (Transition, KeepAlive)
                    Text("Details about the process will appear here and remain visible for a while even as other elements change.")
                        .font(.callout)
                        .padding()
                        .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .sequencer(AdvancedSequenceId.detailText)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        
                    // 4. Icon Pair (Matched)
                    HStack(spacing: 20) {
                        Spacer()
                        // Source Icon
                        Image(systemName: "gearshape")
                            .foregroundColor(.orange)
                            .matchedSequencer(AdvancedSequenceId.iconPair, .source)
                            .frame(width: 50, height: 50)
                            .background(.orange.opacity(0.1), in: Circle())
                        
                        // Destination Icon
                        Image(systemName: "bell.badge.fill")
                            .symbolRenderingMode(.multicolor)
                            .matchedSequencer(AdvancedSequenceId.iconPair, .destination)
                            .frame(width: 60, height: 60)
                            .background(.purple.opacity(0.15), in: Circle())
                        Spacer()
                    }
                    
                    // 5. Status Indicator (Transition, KeepAlive)
                    Capsule()
                        .fill(.cyan)
                        .overlay(Text("Status: Active").font(.caption).bold().foregroundColor(.black))
                        .frame(height: 30)
                        .sequencer(AdvancedSequenceId.statusIndicator)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        
                    // 6. Final Message (Transition)
                    Text("All steps observed.")
                        .font(.title3.italic())
                        .foregroundColor(.gray)
                        .sequencer(AdvancedSequenceId.finalMessage)
                        .transition(.blurReplace())
                    
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .bottom)

            }
            // Apply modifiers correctly based on configuration state
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
        .navigationTitle("Advanced Sequence") // Add a title if used in NavigationView
    }
}

struct AdvancedSequenceExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // Wrap in NavigationView for title
            AdvancedSequenceExample()
                .preferredColorScheme(.dark)
        }
    }
} 
