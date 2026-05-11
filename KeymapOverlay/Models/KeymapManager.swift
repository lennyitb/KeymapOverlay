import Foundation
import SwiftData

@Observable
@MainActor
class KeymapManager {
    var currentKeys: [KeyDefinition] = CorneLayout.defaultKeys
    var activeLayerIndex: Int = 0
    var layerNames: [String] = []
    var parseError: String?

    private var modelContainer: ModelContainer
    private var storedLayers: [[LayerBinding]] = []
    private var fileWatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Persistence

    func loadFromPersistence() {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Keymap>(sortBy: [SortDescriptor(\.lastParsedDate, order: .reverse)])
        guard let keymap = try? context.fetch(descriptor).first else { return }

        let sortedLayers = keymap.layers.sorted { $0.index < $1.index }
        layerNames = sortedLayers.map(\.name)
        storedLayers = sortedLayers.map { layer in
            layer.bindings.sorted { $0.position < $1.position }
        }
        recomputeCurrentKeys()
    }

    @discardableResult
    func parseAndStore(filePath: String) -> Bool {
        let url = URL(fileURLWithPath: filePath)

        guard let hash = ZMKKeymapParser.fileHash(url) else {
            parseError = "Cannot read file"
            return false
        }

        let context = modelContainer.mainContext
        let existing = try? context.fetch(FetchDescriptor<Keymap>())

        do {
            let parsed = try ZMKKeymapParser.parse(contentsOf: url)
            let layerNameMap = Dictionary(uniqueKeysWithValues: parsed.map { ($0.index, $0.name) })

            if let old = existing {
                for keymap in old { context.delete(keymap) }
            }

            let keymap = Keymap(sourceFilePath: filePath, sourceFileHash: hash)
            context.insert(keymap)

            for parsedLayer in parsed {
                let layer = Layer(index: parsedLayer.index, name: parsedLayer.name)
                layer.keymap = keymap
                keymap.layers.append(layer)

                for (position, parsedBinding) in parsedLayer.bindings.enumerated() {
                    let display = ZMKKeyCodeMap.resolveBinding(
                        behavior: parsedBinding.behavior,
                        params: parsedBinding.params,
                        layerNames: layerNameMap
                    )
                    let finalLabel = parsedBinding.annotation?.label ?? display.label
                    let finalSymbols = parsedBinding.annotation?.icons ?? display.sfSymbols
                    let binding = LayerBinding(
                        position: position,
                        behaviorName: parsedBinding.behavior,
                        primaryParam: parsedBinding.params.first ?? "",
                        secondaryParam: parsedBinding.params.count > 1 ? parsedBinding.params[1] : nil,
                        displayLabel: finalLabel,
                        displaySymbols: finalSymbols,
                        isCombo: display.isCombo,
                        keyType: display.type
                    )
                    binding.layer = layer
                    layer.bindings.append(binding)
                }
            }

            try context.save()
            parseError = nil
            loadFromPersistence()
            return true
        } catch {
            parseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Active layer

    func setActiveLayer(from state: KeyboardHIDState) {
        let newIndex = highestActiveLayer(state.layerState)
        guard newIndex != activeLayerIndex else { return }
        activeLayerIndex = newIndex
        recomputeCurrentKeys()
    }

    private func highestActiveLayer(_ layerState: UInt16) -> Int {
        guard layerState != 0 else { return 0 }
        var highest = 0
        for bit in 0..<16 where layerState & (1 << bit) != 0 {
            highest = bit
        }
        return min(highest, storedLayers.count - 1)
    }

    private func recomputeCurrentKeys() {
        guard !storedLayers.isEmpty else {
            currentKeys = CorneLayout.defaultKeys
            return
        }

        let targetIndex = min(activeLayerIndex, storedLayers.count - 1)
        var heldBindings: [Int: LayerBinding] = [:]
        if targetIndex > 0 {
            for layerIdx in 0..<targetIndex {
                for binding in storedLayers[layerIdx] {
                    let isLayerSwitch = (binding.behaviorName == "mo" || binding.behaviorName == "lt")
                        && binding.primaryParam == String(targetIndex)
                    if isLayerSwitch {
                        heldBindings[binding.position] = binding
                    }
                }
            }
        }
        currentKeys = CorneLayout.keyDefinitions(from: storedLayers[targetIndex], heldBindings: heldBindings)
    }

    // MARK: - File watching

    func startWatchingFile(_ path: String) {
        stopWatchingFile()
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = source.data
            if flags.contains(.delete) || flags.contains(.rename) {
                self.restartWatcher(path: path)
            } else {
                self.parseAndStore(filePath: path)
            }
        }

        source.setCancelHandler { [fd = fileDescriptor] in
            close(fd)
        }

        source.resume()
        fileWatchSource = source
    }

    func stopWatchingFile() {
        fileWatchSource?.cancel()
        fileWatchSource = nil
        fileDescriptor = -1
    }

    private func restartWatcher(path: String) {
        stopWatchingFile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, FileManager.default.fileExists(atPath: path) else { return }
            self.parseAndStore(filePath: path)
            self.startWatchingFile(path)
        }
    }
}
