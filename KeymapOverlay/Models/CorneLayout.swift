import Foundation

enum CorneLayout {
    static let keys: [KeyDefinition] = leftKeys + rightKeys

    // Left half:
    //   Tab  Q  W  E  R  T
    //   Ctrl A  S  D  F  G
    //   Shft Z  X  C  V  B
    //            Cmd Lwr Spc
    private static let leftKeys: [KeyDefinition] = [
        // Row 0
        KeyDefinition(row: 0, col: 0, half: .left, label: "Tab", sfSymbol: "arrow.right.to.line", type: .modifier),
        KeyDefinition(row: 0, col: 1, half: .left, label: "Q"),
        KeyDefinition(row: 0, col: 2, half: .left, label: "W"),
        KeyDefinition(row: 0, col: 3, half: .left, label: "E"),
        KeyDefinition(row: 0, col: 4, half: .left, label: "R"),
        KeyDefinition(row: 0, col: 5, half: .left, label: "T"),
        // Row 1
        KeyDefinition(row: 1, col: 0, half: .left, label: "Ctrl", sfSymbol: "control", type: .modifier),
        KeyDefinition(row: 1, col: 1, half: .left, label: "A"),
        KeyDefinition(row: 1, col: 2, half: .left, label: "S"),
        KeyDefinition(row: 1, col: 3, half: .left, label: "D"),
        KeyDefinition(row: 1, col: 4, half: .left, label: "F"),
        KeyDefinition(row: 1, col: 5, half: .left, label: "G"),
        // Row 2
        KeyDefinition(row: 2, col: 0, half: .left, label: "Shift", sfSymbol: "shift", type: .modifier),
        KeyDefinition(row: 2, col: 1, half: .left, label: "Z"),
        KeyDefinition(row: 2, col: 2, half: .left, label: "X"),
        KeyDefinition(row: 2, col: 3, half: .left, label: "C"),
        KeyDefinition(row: 2, col: 4, half: .left, label: "V"),
        KeyDefinition(row: 2, col: 5, half: .left, label: "B"),
        // Thumb cluster (row 3)
        KeyDefinition(row: 3, col: 0, half: .left, label: "Cmd", sfSymbol: "command", type: .modifier),
        KeyDefinition(row: 3, col: 1, half: .left, label: "Lwr", type: .layer),
        KeyDefinition(row: 3, col: 2, half: .left, label: "Spc", type: .letter),
    ]

    // Right half:
    //   Y  U  I  O  P  Bksp
    //   H  J  K  L  ;  '
    //   N  M  ,  .  /  Shft
    //   Ent Rse Alt
    private static let rightKeys: [KeyDefinition] = [
        // Row 0
        KeyDefinition(row: 0, col: 0, half: .right, label: "Y"),
        KeyDefinition(row: 0, col: 1, half: .right, label: "U"),
        KeyDefinition(row: 0, col: 2, half: .right, label: "I"),
        KeyDefinition(row: 0, col: 3, half: .right, label: "O"),
        KeyDefinition(row: 0, col: 4, half: .right, label: "P"),
        KeyDefinition(row: 0, col: 5, half: .right, label: "Bksp", sfSymbol: "delete.left", type: .modifier),
        // Row 1
        KeyDefinition(row: 1, col: 0, half: .right, label: "H"),
        KeyDefinition(row: 1, col: 1, half: .right, label: "J"),
        KeyDefinition(row: 1, col: 2, half: .right, label: "K"),
        KeyDefinition(row: 1, col: 3, half: .right, label: "L"),
        KeyDefinition(row: 1, col: 4, half: .right, label: ";", type: .symbol),
        KeyDefinition(row: 1, col: 5, half: .right, label: "'", type: .symbol),
        // Row 2
        KeyDefinition(row: 2, col: 0, half: .right, label: "N"),
        KeyDefinition(row: 2, col: 1, half: .right, label: "M"),
        KeyDefinition(row: 2, col: 2, half: .right, label: ",", type: .symbol),
        KeyDefinition(row: 2, col: 3, half: .right, label: ".", type: .symbol),
        KeyDefinition(row: 2, col: 4, half: .right, label: "/", type: .symbol),
        KeyDefinition(row: 2, col: 5, half: .right, label: "Shift", sfSymbol: "shift", type: .modifier),
        // Thumb cluster (row 3)
        KeyDefinition(row: 3, col: 0, half: .right, label: "Ent", sfSymbol: "return", type: .modifier),
        KeyDefinition(row: 3, col: 1, half: .right, label: "Rse", type: .layer),
        KeyDefinition(row: 3, col: 2, half: .right, label: "Alt", sfSymbol: "option", type: .modifier),
    ]

    static func mainRows(for half: KeyHalf) -> [[KeyDefinition]] {
        (0...2).map { row in
            keys.filter { $0.half == half && $0.row == row }
                .sorted { $0.col < $1.col }
        }
    }

    static func thumbKeys(for half: KeyHalf) -> [KeyDefinition] {
        keys.filter { $0.half == half && $0.row == 3 }
            .sorted { $0.col < $1.col }
    }
}
