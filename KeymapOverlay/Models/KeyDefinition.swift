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
}

struct KeyDefinition: Identifiable {
    let id = UUID()
    let row: Int
    let col: Int
    let half: KeyHalf
    let label: String
    let sfSymbol: String?
    let type: KeyType
    let widthMultiplier: CGFloat

    init(row: Int, col: Int, half: KeyHalf, label: String, sfSymbol: String? = nil, type: KeyType = .letter, widthMultiplier: CGFloat = 1.0) {
        self.row = row
        self.col = col
        self.half = half
        self.label = label
        self.sfSymbol = sfSymbol
        self.type = type
        self.widthMultiplier = widthMultiplier
    }
}
