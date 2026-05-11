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
            if key.isCombo {
                comboContent
            } else if !key.sfSymbols.isEmpty {
                symbolWithCaption
            } else {
                plainLabel
            }
        case .layer:
            Text(key.label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        case .blank:
            Text(key.label)
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
        default:
            if !key.sfSymbols.isEmpty {
                symbolWithCaption
            } else {
                plainLabel
            }
        }
    }

    private var comboContent: some View {
        VStack {
            Spacer()
            HStack(spacing: 1) {
                ForEach(key.sfSymbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 11))
                }
                if key.sfSymbols.isEmpty || !key.label.isEmpty && key.sfSymbols.allSatisfy({ isModifierSymbol($0) }) {
                    Text(key.label)
                        .font(.system(size: 11, weight: .medium))
                }
                Spacer()
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
        }
        .foregroundStyle(.primary.opacity(0.8))
    }

    private func isModifierSymbol(_ symbol: String) -> Bool {
        ["command", "option", "control", "shift"].contains(symbol)
    }

    private var symbolWithCaption: some View {
        VStack(alignment: .leading, spacing: 1) {
            Spacer()
            HStack(spacing: 1) {
                ForEach(key.sfSymbols, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .font(.system(size: 11))
                }
            }
            Text(key.label)
                .font(.system(size: 8))
            Spacer().frame(height: 4)
        }
        .padding(.leading, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(.primary.opacity(0.8))
    }

    private var plainLabel: some View {
        Text(key.label)
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(.primary)
    }
}

#Preview("Keys") {
    VStack(spacing: KeyboardMetrics.keySpacing) {
        HStack(spacing: KeyboardMetrics.keySpacing) {
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "A"))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "Cmd", sfSymbol: "command", type: .modifier))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: ";", type: .symbol))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "Lwr", type: .layer))
        }
        HStack(spacing: KeyboardMetrics.keySpacing) {
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "←",
                sfSymbols: ["option", "arrow.left"], type: .modifier, isCombo: true))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "→",
                sfSymbols: ["command", "shift", "arrow.right"], type: .modifier, isCombo: true))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "Bksp", sfSymbol: "delete.left", type: .modifier))
            KeyView(key: KeyDefinition(row: 0, col: 0, half: .left, label: "▽", type: .blank))
        }
    }
    .padding()
}
