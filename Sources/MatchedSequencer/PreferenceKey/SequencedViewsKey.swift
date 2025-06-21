import SwiftUI

struct SequencedViewsKey: PreferenceKey {
    typealias Value = [SequencedViewInfo]

    static var defaultValue: Value = []

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue().filter { !value.contains($0) })
    }
} 
