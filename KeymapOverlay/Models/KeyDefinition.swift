import Foundation

enum KeyHalf {
    case left, right
}

enum KeyType: String, Codable {
    case letter
    case modifier
    case symbol
    case layer
    case blank
    case mouse
}

struct KeyDefinition: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    let half: KeyHalf
    let label: String
    let sfSymbols: [String]
    let type: KeyType
    let widthMultiplier: CGFloat
    let isCombo: Bool
    let isHeld: Bool

    init(row: Int, col: Int, half: KeyHalf, label: String, sfSymbol: String? = nil, sfSymbols: [String]? = nil,
         type: KeyType = .letter, widthMultiplier: CGFloat = 1.0, isCombo: Bool = false, isHeld: Bool = false) {
        self.row = row
        self.col = col
        self.half = half
        self.label = label
        if let symbols = sfSymbols {
            self.sfSymbols = symbols
        } else if let symbol = sfSymbol {
            self.sfSymbols = [symbol]
        } else {
            self.sfSymbols = []
        }
        self.type = type
        self.widthMultiplier = widthMultiplier
        self.isCombo = isCombo
        self.isHeld = isHeld
    }
}
