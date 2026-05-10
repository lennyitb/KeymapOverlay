import SwiftUI

enum KeyboardMetrics {
    static let keySize: CGFloat = 44
    static let keySpacing: CGFloat = 4
    static let cornerRadius: CGFloat = 7
    static let halfGap: CGFloat = 40
    static let borderWidth: CGFloat = 0.5
    static let overlayPadding: CGFloat = 24
    static let overlayCornerRadius: CGFloat = 16
}

struct KeyView: View {
    let key: KeyDefinition

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: KeyboardMetrics.cornerRadius)
                .fill(Color(white: 0.92))
            RoundedRectangle(cornerRadius: KeyboardMetrics.cornerRadius)
                .strokeBorder(Color(white: 0.72), lineWidth: KeyboardMetrics.borderWidth)

            keyContent
        }
        .frame(
            width: KeyboardMetrics.keySize * key.widthMultiplier + KeyboardMetrics.keySpacing * (key.widthMultiplier - 1),
            height: KeyboardMetrics.keySize
        )
    }

    @ViewBuilder
    private var keyContent: some View {
        switch key.type {
        case .modifier:
            modifierContent
        case .layer:
            Text(key.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        default:
            Text(key.label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.primary)
        }
    }

    private var modifierContent: some View {
        VStack(spacing: 2) {
            Spacer()
            HStack(spacing: 3) {
                if let symbol = key.sfSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10))
                }
                Text(key.label)
                    .font(.system(size: 9))
                Spacer()
            }
            .padding(.leading, 5)
            .padding(.bottom, 4)
        }
        .foregroundStyle(.primary.opacity(0.8))
    }
}

#Preview("Keys") {
    HStack(spacing: KeyboardMetrics.keySpacing) {
        KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "A"))
        KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "Cmd", sfSymbol: "command", type: .modifier))
        KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: ";", type: .symbol))
        KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "Lwr", type: .layer))
    }
    .padding()
}
