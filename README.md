# MatchedSequencer

A SwiftUI library for orchestrating complex sequences of animations involving both `matchedGeometryEffect` and standard view transitions.

## Features

*   **Declarative Sequences:** Define animation sequences as an array of `SequenceStep` structs.
*   **Matched Geometry:** Seamlessly integrate `matchedGeometryEffect` transitions between `.source` and `.destination` views using `.matched` steps.
*   **Standard Transitions:** Use standard SwiftUI `.transition()` modifiers triggered by `.transition` steps.
*   **Keep Alive:** Optionally keep views visible even after their step is no longer active using `keepAlive: true`.
*   **Concurrency Control:** Run multiple animation steps concurrently using `waitForCompletion: false` and `delay: 0`.
*   **Configurable:** Control sequence direction (`.sequenceReversed`), animation presence (`.sequenceAnimates`), and observe running state (`.isRunning`).

## Core Components

*   **`MatchedSequencerContainer`**: The main container view that manages the sequence and provides the `Namespace`.
*   **`SequenceStep`**: A struct defining a single step in the sequence.
    *   `id`: A unique `Hashable` identifier for the view targeted by this step.
    *   `animation`: The `Animation?` to use for this step's state changes.
    *   `type`: `.matched` or `.transition`.
    *   `delay`: `TimeInterval` before this step starts (relative to the previous step completing its wait or the start of a concurrent batch).
    *   `keepAlive`: `Bool` (default `true`). If `true`, the view associated with `id` remains visible after this step (if it's a `.transition` step) until explicitly removed or replaced by a non-keepAlive step targeting the same ID.
    *   `waitForCompletion`: `Bool` (default `true`). If `false`, the coordinator won't wait for an internal animation duration after this step, allowing the next step's `delay` (or a concurrent batch) to start sooner.
*   **`.sequencer(id:keepAlive:)`**: View modifier for views animated by `.transition` steps. Apply standard `.transition()` before this modifier.
*   **`.matchedSequencer(id:role:properties:anchor:)`**: View modifier for views animated by `.matched` steps. Automatically uses the container's `Namespace`.

## Usage

1.  **Define IDs:** Create a `Hashable` enum for your sequence element IDs.
    ```swift
    enum MySequenceId: Hashable {
        case elementA, elementB, elementC
    }
    ```
2.  **Define Sequence:** Create an array of `SequenceStep`.
    ```swift
    let sequence: [SequenceStep] = [
        .init(MySequenceId.elementA, .smooth, type: .transition),
        .init(MySequenceId.elementB, .interpolatingSpring(), type: .matched, delay: 0.2),
        .init(MySequenceId.elementC, .smooth, type: .transition, delay: 0.5, keepAlive: true)
        // ... more steps
    ]
    ```
3.  **Create Container:** Use `MatchedSequencerContainer` in your view.
    ```swift
    @State private var trigger = false
    @State private var isRunning = false

    // ... inside body ...
    MatchedSequencerContainer(steps: sequence) { // Implicit namespace
        VStack {
            MyViewA()
                .sequencer(MySequenceId.elementA)
                .transition(.opacity)
                
            MySourceView()
                .matchedSequencer(MySequenceId.elementB, .source)
                .frame(width: 50)
                
            MyDestinationView()
                .matchedSequencer(MySequenceId.elementB, .destination)
                .frame(width: 100)
                
            MyViewC()
                .sequencer(MySequenceId.elementC)
        }
    }
    .startSequence(when: $trigger)
    .isRunning($isRunning)
    // .sequenceReversed(shouldReverse) // Optional
    // .sequenceAnimates(shouldAnimate) // Optional
    .onChange(of: isRunning) { newValue, _ in 
        if !newValue { trigger = false } 
    }
    ```

## Concepts

*   **Matched Geometry:** Define two views with the same ID but different `role` (`.source`, `.destination`). When a `.matched` step targets that ID, the container updates the expected role, causing the `.matchedSequencer` modifier to show the correct view and triggering the `matchedGeometryEffect` animation.
*   **Keep Alive:** Steps with `keepAlive: true` ensure their associated view remains in the hierarchy even when not the `activeStepId`. This is useful for layering or keeping context.
*   **Concurrency:** To run step B and C concurrently after step A finishes:
    *   Set `waitForCompletion: false` on step A.
    *   Set `delay: 0` on step B.
    *   Set `delay: 0` on step C.
    *   Set `waitForCompletion` on step B depending on whether C should wait for B.
    *   Set `waitForCompletion` on step C depending on whether the *next* step (D) should wait for the B+C batch.

## Installation

*(Placeholder)* Add MatchedSequencer as a Swift Package dependency to your project.

```
https://your-repo-url/MatchedSequencer.git
```

## Examples

See the files in `Sources/MatchedSequencer/Examples/` for detailed usage:

*   `MinimalSequenceExample.swift`: A bare-bones example.
*   `BasicSequenceExample.swift`: Demonstrates core features including concurrency and keep-alive.
*   `AdvancedSequenceExample.swift`: Shows multiple matched pairs and more complex transitions. 