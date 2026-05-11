import SwiftUI

struct KeyboardHalfView: View {
    let half: KeyHalf
    let keys: [KeyDefinition]

    var body: some View {
        VStack(spacing: KeyboardMetrics.keySpacing) {
            ForEach(CorneLayout.mainRows(for: half, keys: keys), id: \.first?.id) { row in
                HStack(spacing: KeyboardMetrics.keySpacing) {
                    ForEach(row) { key in
                        KeyView(key: key)
                    }
                }
            }

            HStack(spacing: KeyboardMetrics.keySpacing) {
                if half == .left {
                    Spacer()
                }
                ForEach(CorneLayout.thumbKeys(for: half, keys: keys)) { key in
                    KeyView(key: key)
                }
                if half == .right {
                    Spacer()
                }
            }
        }
    }
}

#Preview("Left Half") {
    KeyboardHalfView(half: .left, keys: CorneLayout.defaultKeys)
        .padding()
}

#Preview("Right Half") {
    KeyboardHalfView(half: .right, keys: CorneLayout.defaultKeys)
        .padding()
}
