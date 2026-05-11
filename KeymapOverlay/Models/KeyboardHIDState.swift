import Foundation

struct KeyboardHIDState: Equatable {
    var layerState: UInt16 = 0
    var modifiers: UInt8 = 0
    var modFlags: UInt8 = 0

    var isNonBaseLayerActive: Bool {
        (layerState & ~UInt16(1)) != 0
    }
}
