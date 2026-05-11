import Foundation
import CryptoKit

struct ParsedBinding {
    let behavior: String
    let params: [String]
}

struct ParsedLayer {
    let index: Int
    let name: String
    let bindings: [ParsedBinding]
}

enum ZMKParseError: LocalizedError {
    case fileNotFound
    case noKeymapNode
    case noLayers
    case bindingCount(layer: String, expected: Int, got: Int)

    var errorDescription: String? {
        switch self {
        case .fileNotFound: "Keymap file not found"
        case .noKeymapNode: "No keymap node found (expected compatible = \"zmk,keymap\")"
        case .noLayers: "No layers found in keymap"
        case .bindingCount(let layer, let expected, let got):
            "Layer \"\(layer)\" has \(got) bindings (expected \(expected))"
        }
    }
}

enum ZMKKeymapParser {
    static let corneKeyCount = 42

    static func parse(contentsOf url: URL) throws -> [ParsedLayer] {
        guard let data = FileManager.default.contents(atPath: url.path),
              let contents = String(data: data, encoding: .utf8) else {
            throw ZMKParseError.fileNotFound
        }
        return try parse(contents)
    }

    static func parse(_ source: String) throws -> [ParsedLayer] {
        let defines = collectDefines(source)
        let cleaned = stripComments(source)
        let keymapBody = try extractKeymapBody(cleaned)
        let rawLayers = extractLayerNodes(keymapBody)

        guard !rawLayers.isEmpty else { throw ZMKParseError.noLayers }

        var layers: [ParsedLayer] = []
        for (index, raw) in rawLayers.enumerated() {
            let name = extractLabel(raw.body) ?? humanize(raw.nodeName)
            let bindingsStr = extractBindings(raw.body)
            let bindings = tokenizeBindings(bindingsStr, defines: defines)
            layers.append(ParsedLayer(index: index, name: name, bindings: bindings))
        }

        return layers
    }

    static func fileHash(_ url: URL) -> String? {
        guard let data = FileManager.default.contents(atPath: url.path) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Preprocessing

    private static func collectDefines(_ source: String) -> [String: String] {
        var defines: [String: String] = [:]
        for line in source.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("#define") else { continue }
            let tokens = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            guard tokens.count >= 3 else { continue }
            defines[String(tokens[1])] = String(tokens[2])
        }
        return defines
    }

    private static func stripComments(_ source: String) -> String {
        var result = ""
        var i = source.startIndex
        while i < source.endIndex {
            let remaining = source[i...]
            if remaining.hasPrefix("//") {
                if let newline = remaining.firstIndex(of: "\n") {
                    i = source.index(after: newline)
                } else {
                    break
                }
            } else if remaining.hasPrefix("/*") {
                if let end = remaining.range(of: "*/") {
                    i = end.upperBound
                } else {
                    break
                }
            } else {
                result.append(source[i])
                i = source.index(after: i)
            }
        }
        return result
    }

    // MARK: - Keymap extraction

    private static func extractKeymapBody(_ source: String) throws -> String {
        guard let keymapRange = findNodeBody(in: source, containing: "compatible = \"zmk,keymap\"") else {
            throw ZMKParseError.noKeymapNode
        }
        return String(source[keymapRange])
    }

    private static func findNodeBody(in source: String, containing marker: String) -> Range<String.Index>? {
        guard let markerRange = source.range(of: marker) else { return nil }

        var searchIdx = markerRange.lowerBound
        while searchIdx > source.startIndex {
            searchIdx = source.index(before: searchIdx)
            if source[searchIdx] == "{" {
                break
            }
        }

        var depth = 1
        var i = source.index(after: searchIdx)
        while i < source.endIndex && depth > 0 {
            if source[i] == "{" { depth += 1 }
            else if source[i] == "}" { depth -= 1 }
            if depth > 0 { i = source.index(after: i) }
        }

        guard depth == 0 else { return nil }
        return source.index(after: searchIdx)..<i
    }

    // MARK: - Layer node extraction

    private struct RawLayer {
        let nodeName: String
        let body: String
    }

    private static func extractLayerNodes(_ keymapBody: String) -> [RawLayer] {
        var layers: [RawLayer] = []
        var i = keymapBody.startIndex

        while i < keymapBody.endIndex {
            guard let braceIdx = keymapBody[i...].firstIndex(of: "{") else { break }

            let prefix = keymapBody[i..<braceIdx]
            let nodeName = String(prefix.split(separator: "\n").last?
                .trimmingCharacters(in: .whitespaces) ?? "")
                .trimmingCharacters(in: .whitespaces)

            guard !nodeName.isEmpty, !nodeName.contains("compatible") else {
                i = keymapBody.index(after: braceIdx)
                continue
            }

            var depth = 1
            var j = keymapBody.index(after: braceIdx)
            while j < keymapBody.endIndex && depth > 0 {
                if keymapBody[j] == "{" { depth += 1 }
                else if keymapBody[j] == "}" { depth -= 1 }
                if depth > 0 { j = keymapBody.index(after: j) }
            }

            guard depth == 0 else { break }

            let body = String(keymapBody[keymapBody.index(after: braceIdx)..<j])
            layers.append(RawLayer(nodeName: nodeName, body: body))
            i = keymapBody.index(after: j)
        }

        return layers
    }

    // MARK: - Property extraction

    private static func extractLabel(_ body: String) -> String? {
        let patterns = ["label = \"", "display-name = \""]
        for pattern in patterns {
            guard let start = body.range(of: pattern) else { continue }
            let after = body[start.upperBound...]
            guard let end = after.firstIndex(of: "\"") else { continue }
            return String(after[..<end])
        }
        return nil
    }

    private static func extractBindings(_ body: String) -> String {
        guard let start = body.range(of: "bindings = <") else { return "" }
        let after = body[start.upperBound...]
        guard let end = after.firstIndex(of: ">") else { return "" }
        return String(after[..<end])
    }

    // MARK: - Binding tokenization

    private static func tokenizeBindings(_ raw: String, defines: [String: String]) -> [ParsedBinding] {
        let normalized = raw.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")

        let parts = normalized.components(separatedBy: "&")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return parts.map { part in
            let tokens = part.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            let behavior = tokens[0]
            let params = tokens.dropFirst().map { substitute($0, defines: defines) }
            return ParsedBinding(behavior: behavior, params: params)
        }
    }

    private static func substitute(_ token: String, defines: [String: String]) -> String {
        defines[token] ?? token
    }

    // MARK: - Utilities

    private static func humanize(_ nodeName: String) -> String {
        nodeName
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
            .replacingOccurrences(of: " layer", with: "")
            .replacingOccurrences(of: " Layer", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
