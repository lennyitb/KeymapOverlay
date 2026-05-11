import Foundation

struct CornePhysicalKey {
    let position: Int
    let row: Int
    let col: Int
    let half: KeyHalf
    let widthMultiplier: CGFloat

    init(_ position: Int, row: Int, col: Int, half: KeyHalf, widthMultiplier: CGFloat = 1.0) {
        self.position = position
        self.row = row
        self.col = col
        self.half = half
        self.widthMultiplier = widthMultiplier
    }
}

enum CorneLayout {
    // ZMK binding positions 0-41 mapped to physical grid
    static let physicalKeys: [CornePhysicalKey] = [
        // Left row 0 (positions 0-5)
        CornePhysicalKey(0,  row: 0, col: 0, half: .left),
        CornePhysicalKey(1,  row: 0, col: 1, half: .left),
        CornePhysicalKey(2,  row: 0, col: 2, half: .left),
        CornePhysicalKey(3,  row: 0, col: 3, half: .left),
        CornePhysicalKey(4,  row: 0, col: 4, half: .left),
        CornePhysicalKey(5,  row: 0, col: 5, half: .left),
        // Right row 0 (positions 6-11)
        CornePhysicalKey(6,  row: 0, col: 0, half: .right),
        CornePhysicalKey(7,  row: 0, col: 1, half: .right),
        CornePhysicalKey(8,  row: 0, col: 2, half: .right),
        CornePhysicalKey(9,  row: 0, col: 3, half: .right),
        CornePhysicalKey(10, row: 0, col: 4, half: .right),
        CornePhysicalKey(11, row: 0, col: 5, half: .right),
        // Left row 1 (positions 12-17)
        CornePhysicalKey(12, row: 1, col: 0, half: .left),
        CornePhysicalKey(13, row: 1, col: 1, half: .left),
        CornePhysicalKey(14, row: 1, col: 2, half: .left),
        CornePhysicalKey(15, row: 1, col: 3, half: .left),
        CornePhysicalKey(16, row: 1, col: 4, half: .left),
        CornePhysicalKey(17, row: 1, col: 5, half: .left),
        // Right row 1 (positions 18-23)
        CornePhysicalKey(18, row: 1, col: 0, half: .right),
        CornePhysicalKey(19, row: 1, col: 1, half: .right),
        CornePhysicalKey(20, row: 1, col: 2, half: .right),
        CornePhysicalKey(21, row: 1, col: 3, half: .right),
        CornePhysicalKey(22, row: 1, col: 4, half: .right),
        CornePhysicalKey(23, row: 1, col: 5, half: .right),
        // Left row 2 (positions 24-29)
        CornePhysicalKey(24, row: 2, col: 0, half: .left),
        CornePhysicalKey(25, row: 2, col: 1, half: .left),
        CornePhysicalKey(26, row: 2, col: 2, half: .left),
        CornePhysicalKey(27, row: 2, col: 3, half: .left),
        CornePhysicalKey(28, row: 2, col: 4, half: .left),
        CornePhysicalKey(29, row: 2, col: 5, half: .left),
        // Right row 2 (positions 30-35)
        CornePhysicalKey(30, row: 2, col: 0, half: .right),
        CornePhysicalKey(31, row: 2, col: 1, half: .right),
        CornePhysicalKey(32, row: 2, col: 2, half: .right),
        CornePhysicalKey(33, row: 2, col: 3, half: .right),
        CornePhysicalKey(34, row: 2, col: 4, half: .right),
        CornePhysicalKey(35, row: 2, col: 5, half: .right),
        // Left thumb (positions 36-38)
        CornePhysicalKey(36, row: 3, col: 0, half: .left),
        CornePhysicalKey(37, row: 3, col: 1, half: .left),
        CornePhysicalKey(38, row: 3, col: 2, half: .left),
        // Right thumb (positions 39-41)
        CornePhysicalKey(39, row: 3, col: 0, half: .right),
        CornePhysicalKey(40, row: 3, col: 1, half: .right),
        CornePhysicalKey(41, row: 3, col: 2, half: .right),
    ]

    static func keyDefinitions(from bindings: [LayerBinding], heldBindings: [Int: LayerBinding] = [:]) -> [KeyDefinition] {
        let bindingsByPosition = Dictionary(uniqueKeysWithValues: bindings.map { ($0.position, $0) })
        return physicalKeys.map { phys in
            if let held = heldBindings[phys.position] {
                return KeyDefinition(
                    row: phys.row, col: phys.col, half: phys.half,
                    label: held.displayLabel,
                    sfSymbols: held.displaySymbols,
                    type: held.keyType,
                    widthMultiplier: phys.widthMultiplier,
                    isHeld: true
                )
            }
            if let binding = bindingsByPosition[phys.position] {
                return KeyDefinition(
                    row: phys.row, col: phys.col, half: phys.half,
                    label: binding.displayLabel,
                    sfSymbols: binding.displaySymbols,
                    type: binding.keyType,
                    widthMultiplier: phys.widthMultiplier,
                    isCombo: binding.isCombo
                )
            }
            return KeyDefinition(
                row: phys.row, col: phys.col, half: phys.half,
                label: "", type: .blank, widthMultiplier: phys.widthMultiplier
            )
        }
    }

    static func mainRows(for half: KeyHalf, keys: [KeyDefinition]) -> [[KeyDefinition]] {
        (0...2).map { row in
            keys.filter { $0.half == half && $0.row == row }
                .sorted { $0.col < $1.col }
        }
    }

    static func thumbKeys(for half: KeyHalf, keys: [KeyDefinition]) -> [KeyDefinition] {
        keys.filter { $0.half == half && $0.row == 3 }
            .sorted { $0.col < $1.col }
    }

    // MARK: - Default fallback (matches the original hardcoded layout)

    static let defaultKeys: [KeyDefinition] = [
        // Left row 0
        KeyDefinition(row: 0, col: 0, half: .left, label: "Tab", sfSymbol: "arrow.right.to.line", type: .modifier),
        KeyDefinition(row: 0, col: 1, half: .left, label: "Q"),
        KeyDefinition(row: 0, col: 2, half: .left, label: "W"),
        KeyDefinition(row: 0, col: 3, half: .left, label: "E"),
        KeyDefinition(row: 0, col: 4, half: .left, label: "R"),
        KeyDefinition(row: 0, col: 5, half: .left, label: "T"),
        // Left row 1
        KeyDefinition(row: 1, col: 0, half: .left, label: "Ctrl", sfSymbol: "control", type: .modifier),
        KeyDefinition(row: 1, col: 1, half: .left, label: "A"),
        KeyDefinition(row: 1, col: 2, half: .left, label: "S"),
        KeyDefinition(row: 1, col: 3, half: .left, label: "D"),
        KeyDefinition(row: 1, col: 4, half: .left, label: "F"),
        KeyDefinition(row: 1, col: 5, half: .left, label: "G"),
        // Left row 2
        KeyDefinition(row: 2, col: 0, half: .left, label: "Shift", sfSymbol: "shift", type: .modifier),
        KeyDefinition(row: 2, col: 1, half: .left, label: "Z"),
        KeyDefinition(row: 2, col: 2, half: .left, label: "X"),
        KeyDefinition(row: 2, col: 3, half: .left, label: "C"),
        KeyDefinition(row: 2, col: 4, half: .left, label: "V"),
        KeyDefinition(row: 2, col: 5, half: .left, label: "B"),
        // Left thumb
        KeyDefinition(row: 3, col: 0, half: .left, label: "Cmd", sfSymbol: "command", type: .modifier),
        KeyDefinition(row: 3, col: 1, half: .left, label: "Lwr", type: .layer),
        KeyDefinition(row: 3, col: 2, half: .left, label: "Spc", type: .letter),
        // Right row 0
        KeyDefinition(row: 0, col: 0, half: .right, label: "Y"),
        KeyDefinition(row: 0, col: 1, half: .right, label: "U"),
        KeyDefinition(row: 0, col: 2, half: .right, label: "I"),
        KeyDefinition(row: 0, col: 3, half: .right, label: "O"),
        KeyDefinition(row: 0, col: 4, half: .right, label: "P"),
        KeyDefinition(row: 0, col: 5, half: .right, label: "Bksp", sfSymbol: "delete.left", type: .modifier),
        // Right row 1
        KeyDefinition(row: 1, col: 0, half: .right, label: "H"),
        KeyDefinition(row: 1, col: 1, half: .right, label: "J"),
        KeyDefinition(row: 1, col: 2, half: .right, label: "K"),
        KeyDefinition(row: 1, col: 3, half: .right, label: "L"),
        KeyDefinition(row: 1, col: 4, half: .right, label: ";", type: .symbol),
        KeyDefinition(row: 1, col: 5, half: .right, label: "'", type: .symbol),
        // Right row 2
        KeyDefinition(row: 2, col: 0, half: .right, label: "N"),
        KeyDefinition(row: 2, col: 1, half: .right, label: "M"),
        KeyDefinition(row: 2, col: 2, half: .right, label: ",", type: .symbol),
        KeyDefinition(row: 2, col: 3, half: .right, label: ".", type: .symbol),
        KeyDefinition(row: 2, col: 4, half: .right, label: "/", type: .symbol),
        KeyDefinition(row: 2, col: 5, half: .right, label: "Shift", sfSymbol: "shift", type: .modifier),
        // Right thumb
        KeyDefinition(row: 3, col: 0, half: .right, label: "Ent", sfSymbol: "return", type: .modifier),
        KeyDefinition(row: 3, col: 1, half: .right, label: "Rse", type: .layer),
        KeyDefinition(row: 3, col: 2, half: .right, label: "Alt", sfSymbol: "option", type: .modifier),
    ]
}
