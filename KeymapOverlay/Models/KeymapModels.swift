import Foundation
import SwiftData

@Model
final class Keymap {
    var sourceFilePath: String
    var lastParsedDate: Date
    var sourceFileHash: String

    @Relationship(deleteRule: .cascade, inverse: \Layer.keymap)
    var layers: [Layer]

    init(sourceFilePath: String, sourceFileHash: String) {
        self.sourceFilePath = sourceFilePath
        self.lastParsedDate = Date()
        self.sourceFileHash = sourceFileHash
        self.layers = []
    }
}

@Model
final class Layer {
    var index: Int
    var name: String
    var keymap: Keymap?

    @Relationship(deleteRule: .cascade, inverse: \LayerBinding.layer)
    var bindings: [LayerBinding]

    init(index: Int, name: String) {
        self.index = index
        self.name = name
        self.bindings = []
    }
}

@Model
final class LayerBinding {
    var position: Int
    var behaviorName: String
    var primaryParam: String
    var secondaryParam: String?
    var displayLabel: String
    var displaySymbol: String?
    var keyType: KeyType
    var layer: Layer?

    init(position: Int, behaviorName: String, primaryParam: String, secondaryParam: String? = nil,
         displayLabel: String, displaySymbol: String? = nil, keyType: KeyType) {
        self.position = position
        self.behaviorName = behaviorName
        self.primaryParam = primaryParam
        self.secondaryParam = secondaryParam
        self.displayLabel = displayLabel
        self.displaySymbol = displaySymbol
        self.keyType = keyType
    }
}
