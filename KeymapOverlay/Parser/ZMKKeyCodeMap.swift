import Foundation

struct KeyDisplay {
    let label: String
    let sfSymbols: [String]
    let type: KeyType
    let isCombo: Bool

    init(label: String, sfSymbol: String?, type: KeyType) {
        self.label = label
        self.sfSymbols = sfSymbol.map { [$0] } ?? []
        self.type = type
        self.isCombo = false
    }

    init(label: String, sfSymbols: [String], type: KeyType, isCombo: Bool = false) {
        self.label = label
        self.sfSymbols = sfSymbols
        self.type = type
        self.isCombo = isCombo
    }
}

enum ZMKKeyCodeMap {
    static func resolve(_ keycode: String) -> KeyDisplay {
        if let combo = parseModifierCombo(keycode) {
            return combo
        }
        if let mapped = keycodes[keycode] {
            return mapped
        }
        if let mapped = keycodes[expandAlias(keycode)] {
            return mapped
        }
        return KeyDisplay(label: keycode, sfSymbol: nil, type: .symbol)
    }

    private static let modifierSymbols: [String: String] = [
        "LS": "shift", "RS": "shift",
        "LC": "control", "RC": "control",
        "LA": "option", "RA": "option",
        "LG": "command", "RG": "command",
    ]

    private static func parseModifierCombo(_ keycode: String) -> KeyDisplay? {
        var remaining = keycode
        var wrappers: [String] = []

        while let match = remaining.firstMatch(of: /^([LR][SCAG])\((.+)\)$/) {
            wrappers.append(String(match.1))
            remaining = String(match.2)
        }

        guard !wrappers.isEmpty else { return nil }

        // Shift + printable key = just show the shifted character
        if wrappers.allSatisfy({ $0 == "LS" || $0 == "RS" }),
           let shifted = shiftedCharacters[remaining] ?? shiftedCharacters[expandAlias(remaining)] {
            return KeyDisplay(label: shifted, sfSymbol: nil, type: .symbol)
        }

        let modSymbols = wrappers.compactMap { modifierSymbols[$0] }
        let inner = resolve(remaining)
        let allSymbols = modSymbols + inner.sfSymbols
        return KeyDisplay(label: inner.label, sfSymbols: allSymbols, type: .modifier, isCombo: true)
    }

    private static let shiftedCharacters: [String: String] = [
        // Numbers (short and long forms)
        "N1": "!", "N2": "@", "N3": "#", "N4": "$", "N5": "%",
        "N6": "^", "N7": "&", "N8": "*", "N9": "(", "N0": ")",
        "NUMBER_1": "!", "NUMBER_2": "@", "NUMBER_3": "#", "NUMBER_4": "$", "NUMBER_5": "%",
        "NUMBER_6": "^", "NUMBER_7": "&", "NUMBER_8": "*", "NUMBER_9": "(", "NUMBER_0": ")",
        // Symbols (short aliases)
        "MINUS": "_", "EQUAL": "+", "GRAVE": "~",
        "LBKT": "{", "RBKT": "}", "LBRC": "{", "RBRC": "}",
        "BSLH": "|", "FSLH": "?", "SEMI": ":", "SQT": "\"",
        "COMMA": "<", "DOT": ">",
        "APOS": "\"", "DQT": "\"",
        "UNDER": "_", "PLUS": "+", "TILDE": "~", "PIPE": "|",
        "EXCL": "!", "AT": "@", "POUND": "#", "HASH": "#",
        "DLLR": "$", "PRCNT": "%", "CARET": "^",
        "AMPS": "&", "ASTRK": "*", "STAR": "*",
        "LPAR": "(", "RPAR": ")", "QMARK": "?",
        "LT": "<", "GT": ">",
        // Symbols (expanded forms)
        "MINUS_ALIAS": "_", "EQUAL_ALIAS": "+", "GRAVE_ALIAS": "~",
        "LEFT_BRACKET": "{", "RIGHT_BRACKET": "}",
        "LEFT_BRACE": "{", "RIGHT_BRACE": "}",
        "BACKSLASH": "|", "SLASH": "?", "SEMICOLON": ":",
        "SINGLE_QUOTE": "\"", "DOUBLE_QUOTES": "\"",
        "COMMA_ALIAS": "<", "PERIOD": ">",
        "LEFT_PARENTHESIS": "(", "RIGHT_PARENTHESIS": ")",
        "UNDERSCORE": "_", "PLUS_ALIAS": "+", "TILDE_ALIAS": "~",
        "PIPE_ALIAS": "|", "CARET_ALIAS": "^",
        "EXCLAMATION": "!", "AT_SIGN": "@", "DOLLAR": "$",
        "PERCENT": "%", "AMPERSAND": "&", "ASTERISK": "*",
        "LESS_THAN": "<", "GREATER_THAN": ">", "QUESTION": "?",
        // Letters
        "A": "A", "B": "B", "C": "C", "D": "D", "E": "E", "F": "F",
        "G": "G", "H": "H", "I": "I", "J": "J", "K": "K", "L": "L",
        "M": "M", "N": "N", "O": "O", "P": "P", "Q": "Q", "R": "R",
        "S": "S", "T": "T", "U": "U", "V": "V", "W": "W", "X": "X",
        "Y": "Y", "Z": "Z",
    ]

    static func resolveBinding(behavior: String, params: [String], layerNames: [Int: String]) -> KeyDisplay {
        switch behavior {
        case "kp":
            guard let key = params.first else { return KeyDisplay(label: "?", sfSymbol: nil, type: .letter) }
            return resolve(key)
        case "mo":
            return layerDisplay(params: params, prefix: "", layerNames: layerNames)
        case "tog":
            return layerDisplay(params: params, prefix: "Tog", layerNames: layerNames)
        case "to":
            return layerDisplay(params: params, prefix: "To", layerNames: layerNames)
        case "sl":
            return layerDisplay(params: params, prefix: "SL", layerNames: layerNames)
        case "lt":
            guard params.count >= 2 else { return KeyDisplay(label: "?", sfSymbol: nil, type: .letter) }
            return resolve(params[1])
        case "mt":
            guard params.count >= 2 else { return KeyDisplay(label: "?", sfSymbol: nil, type: .letter) }
            return resolve(params[1])
        case "sk":
            guard let key = params.first else { return KeyDisplay(label: "?", sfSymbol: nil, type: .modifier) }
            let resolved = resolve(key)
            return KeyDisplay(label: resolved.label, sfSymbols: resolved.sfSymbols, type: .modifier)
        case "trans":
            return KeyDisplay(label: "▽", sfSymbol: nil, type: .blank)
        case "none":
            return KeyDisplay(label: "", sfSymbol: nil, type: .blank)
        case "bt":
            guard let param = params.first else { return KeyDisplay(label: "BT", sfSymbol: nil, type: .modifier) }
            return btDisplay(param)
        case "caps_word":
            return KeyDisplay(label: "CW", sfSymbol: "textformat.abc", type: .modifier)
        case "key_repeat":
            return KeyDisplay(label: "Rep", sfSymbol: "repeat", type: .modifier)
        case "mmv":
            guard let key = params.first else { return KeyDisplay(label: "Move", sfSymbol: "pointer.arrow", type: .mouse) }
            return resolve(key)
        case "msc", "mwh":
            guard let key = params.first else { return KeyDisplay(label: "Scroll", sfSymbol: "scroll", type: .mouse) }
            return resolve(key)
        case "mkp":
            guard let key = params.first else { return KeyDisplay(label: "Click", sfSymbol: "pointer.arrow", type: .mouse) }
            return resolve(key)
        default:
            if behavior.hasPrefix("sk") {
                guard let key = params.first else { return KeyDisplay(label: "?", sfSymbol: nil, type: .modifier) }
                let resolved = resolve(key)
                return KeyDisplay(label: resolved.label, sfSymbols: resolved.sfSymbols, type: .modifier)
            }
            let label = params.first.map { "\(behavior) \($0)" } ?? behavior
            return KeyDisplay(label: label, sfSymbol: nil, type: .modifier)
        }
    }

    private static func layerDisplay(params: [String], prefix: String, layerNames: [Int: String]) -> KeyDisplay {
        guard let param = params.first, let idx = Int(param) else {
            let label = prefix.isEmpty ? (params.first ?? "?") : "\(prefix) \(params.first ?? "?")"
            return KeyDisplay(label: label, sfSymbol: nil, type: .layer)
        }
        let name = layerNames[idx]
        let label: String
        if let name {
            label = prefix.isEmpty ? name : "\(prefix) \(name)"
        } else {
            label = prefix.isEmpty ? "L\(idx)" : "\(prefix) \(idx)"
        }
        return KeyDisplay(label: label, sfSymbol: nil, type: .layer)
    }

    private static func btDisplay(_ param: String) -> KeyDisplay {
        switch param {
        case "BT_CLR": return KeyDisplay(label: "BT Clr", sfSymbol: nil, type: .modifier)
        case "BT_SEL": return KeyDisplay(label: "BT Sel", sfSymbol: nil, type: .modifier)
        default:
            if param.hasPrefix("BT_SEL_"), let n = param.last {
                return KeyDisplay(label: "BT \(n)", sfSymbol: nil, type: .modifier)
            }
            return KeyDisplay(label: param, sfSymbol: nil, type: .modifier)
        }
    }

    private static func expandAlias(_ code: String) -> String {
        aliases[code] ?? code
    }

    // MARK: - Keycode Tables

    private static let aliases: [String: String] = [
        "RET": "RETURN", "ENTER": "RETURN", "ENT": "RETURN",
        "BSPC": "BACKSPACE", "BS": "BACKSPACE",
        "SPC": "SPACE",
        "ESC": "ESCAPE",
        "LSHFT": "LEFT_SHIFT", "LSFT": "LEFT_SHIFT", "LSHIFT": "LEFT_SHIFT",
        "RSHFT": "RIGHT_SHIFT", "RSFT": "RIGHT_SHIFT", "RSHIFT": "RIGHT_SHIFT",
        "LCTRL": "LEFT_CONTROL", "LCTL": "LEFT_CONTROL",
        "RCTRL": "RIGHT_CONTROL", "RCTL": "RIGHT_CONTROL",
        "LGUI": "LEFT_GUI", "LCMD": "LEFT_GUI", "LWIN": "LEFT_GUI", "LMETA": "LEFT_GUI",
        "RGUI": "RIGHT_GUI", "RCMD": "RIGHT_GUI", "RWIN": "RIGHT_GUI", "RMETA": "RIGHT_GUI",
        "LALT": "LEFT_ALT", "LOPT": "LEFT_ALT",
        "RALT": "RIGHT_ALT", "ROPT": "RIGHT_ALT",
        "DEL": "DELETE", "CAPS": "CAPSLOCK", "CLCK": "CAPSLOCK",
        "PSCRN": "PRINTSCREEN", "SLCK": "SCROLLLOCK",
        "PAUSE_BREAK": "PAUSE",
        "PG_UP": "PAGE_UP", "PG_DN": "PAGE_DOWN",
        "INS": "INSERT",
        "SEMI": "SEMICOLON",
        "SQT": "SINGLE_QUOTE", "APOS": "SINGLE_QUOTE",
        "DQT": "DOUBLE_QUOTES",
        "FSLH": "SLASH", "BSLH": "BACKSLASH",
        "COMMA": "COMMA_ALIAS", // handled below
        "DOT": "PERIOD",
        "EXCL": "EXCLAMATION", "AT": "AT_SIGN",
        "POUND": "HASH", "DLLR": "DOLLAR",
        "PRCNT": "PERCENT", "CARET": "CARET_ALIAS",
        "AMPS": "AMPERSAND", "ASTRK": "ASTERISK", "STAR": "ASTERISK",
        "LPAR": "LEFT_PARENTHESIS", "RPAR": "RIGHT_PARENTHESIS",
        "UNDER": "UNDERSCORE",
        "LBKT": "LEFT_BRACKET", "RBKT": "RIGHT_BRACKET",
        "LBRC": "LEFT_BRACE", "RBRC": "RIGHT_BRACE",
        "PIPE": "PIPE_ALIAS",
        "TILDE": "TILDE_ALIAS",
        "GRAVE": "GRAVE_ALIAS",
        "MINUS": "MINUS_ALIAS", "PLUS": "PLUS_ALIAS", "EQUAL": "EQUAL_ALIAS",
        "LT": "LESS_THAN", "GT": "GREATER_THAN",
        "QMARK": "QUESTION",
        "LEFT": "LEFT_ARROW", "RIGHT": "RIGHT_ARROW",
        "UP": "UP_ARROW", "DOWN": "DOWN_ARROW",
        "C_PP": "C_PLAY_PAUSE",
        "C_VOL_UP": "C_VOLUME_UP", "C_VOL_DN": "C_VOLUME_DOWN",
        "C_BRI_UP": "C_BRIGHTNESS_INC", "C_BRI_DN": "C_BRIGHTNESS_DEC",
        "C_NEXT": "C_NEXT_ALIAS", "C_PREV": "C_PREVIOUS",
        // Mouse
        "MOVE_U": "MOVE_UP", "MOVE_D": "MOVE_DOWN", "MOVE_L": "MOVE_LEFT", "MOVE_R": "MOVE_RIGHT",
        "SCROLL_UP": "SCRL_UP", "SCROLL_DOWN": "SCRL_DOWN", "SCROLL_LEFT": "SCRL_LEFT", "SCROLL_RIGHT": "SCRL_RIGHT",
        "MB1": "LCLK", "MB2": "RCLK", "MB3": "MCLK",
    ]

    private static let keycodes: [String: KeyDisplay] = {
        var map: [String: KeyDisplay] = [:]

        // Letters
        for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            map[String(c)] = KeyDisplay(label: String(c), sfSymbol: nil, type: .letter)
        }

        // Numbers
        for n in 0...9 {
            map["N\(n)"] = KeyDisplay(label: "\(n)", sfSymbol: nil, type: .symbol)
            map["NUMBER_\(n)"] = KeyDisplay(label: "\(n)", sfSymbol: nil, type: .symbol)
        }

        // Modifiers
        map["LEFT_SHIFT"] = KeyDisplay(label: "Shift", sfSymbol: "shift", type: .modifier)
        map["RIGHT_SHIFT"] = KeyDisplay(label: "Shift", sfSymbol: "shift", type: .modifier)
        map["LEFT_CONTROL"] = KeyDisplay(label: "Ctrl", sfSymbol: "control", type: .modifier)
        map["RIGHT_CONTROL"] = KeyDisplay(label: "Ctrl", sfSymbol: "control", type: .modifier)
        map["LEFT_GUI"] = KeyDisplay(label: "Cmd", sfSymbol: "command", type: .modifier)
        map["RIGHT_GUI"] = KeyDisplay(label: "Cmd", sfSymbol: "command", type: .modifier)
        map["LEFT_ALT"] = KeyDisplay(label: "Alt", sfSymbol: "option", type: .modifier)
        map["RIGHT_ALT"] = KeyDisplay(label: "Alt", sfSymbol: "option", type: .modifier)
        map["CAPSLOCK"] = KeyDisplay(label: "Caps", sfSymbol: "capslock", type: .modifier)

        // Whitespace / editing
        map["SPACE"] = KeyDisplay(label: "Spc", sfSymbol: nil, type: .letter)
        map["RETURN"] = KeyDisplay(label: "Ent", sfSymbol: "return", type: .modifier)
        map["TAB"] = KeyDisplay(label: "Tab", sfSymbol: "arrow.right.to.line", type: .modifier)
        map["BACKSPACE"] = KeyDisplay(label: "Bksp", sfSymbol: "delete.left", type: .modifier)
        map["DELETE"] = KeyDisplay(label: "Del", sfSymbol: "delete.right", type: .modifier)
        map["ESCAPE"] = KeyDisplay(label: "Esc", sfSymbol: "escape", type: .modifier)
        map["INSERT"] = KeyDisplay(label: "Ins", sfSymbol: nil, type: .modifier)

        // Navigation
        map["LEFT_ARROW"] = KeyDisplay(label: "", sfSymbol: "arrow.left", type: .modifier)
        map["RIGHT_ARROW"] = KeyDisplay(label: "", sfSymbol: "arrow.right", type: .modifier)
        map["UP_ARROW"] = KeyDisplay(label: "", sfSymbol: "arrow.up", type: .modifier)
        map["DOWN_ARROW"] = KeyDisplay(label: "", sfSymbol: "arrow.down", type: .modifier)
        map["HOME"] = KeyDisplay(label: "Home", sfSymbol: nil, type: .modifier)
        map["END"] = KeyDisplay(label: "End", sfSymbol: nil, type: .modifier)
        map["PAGE_UP"] = KeyDisplay(label: "PgUp", sfSymbol: nil, type: .modifier)
        map["PAGE_DOWN"] = KeyDisplay(label: "PgDn", sfSymbol: nil, type: .modifier)

        // Symbols
        map["SEMICOLON"] = KeyDisplay(label: ";", sfSymbol: nil, type: .symbol)
        map["SINGLE_QUOTE"] = KeyDisplay(label: "'", sfSymbol: nil, type: .symbol)
        map["DOUBLE_QUOTES"] = KeyDisplay(label: "\"", sfSymbol: nil, type: .symbol)
        map["COMMA_ALIAS"] = KeyDisplay(label: ",", sfSymbol: nil, type: .symbol)
        map["COMMA"] = KeyDisplay(label: ",", sfSymbol: nil, type: .symbol)
        map["PERIOD"] = KeyDisplay(label: ".", sfSymbol: nil, type: .symbol)
        map["SLASH"] = KeyDisplay(label: "/", sfSymbol: nil, type: .symbol)
        map["BACKSLASH"] = KeyDisplay(label: "\\", sfSymbol: nil, type: .symbol)
        map["GRAVE_ALIAS"] = KeyDisplay(label: "`", sfSymbol: nil, type: .symbol)
        map["MINUS_ALIAS"] = KeyDisplay(label: "-", sfSymbol: nil, type: .symbol)
        map["EQUAL_ALIAS"] = KeyDisplay(label: "=", sfSymbol: nil, type: .symbol)
        map["PLUS_ALIAS"] = KeyDisplay(label: "+", sfSymbol: nil, type: .symbol)
        map["LEFT_BRACKET"] = KeyDisplay(label: "[", sfSymbol: nil, type: .symbol)
        map["RIGHT_BRACKET"] = KeyDisplay(label: "]", sfSymbol: nil, type: .symbol)
        map["LEFT_BRACE"] = KeyDisplay(label: "{", sfSymbol: nil, type: .symbol)
        map["RIGHT_BRACE"] = KeyDisplay(label: "}", sfSymbol: nil, type: .symbol)
        map["LEFT_PARENTHESIS"] = KeyDisplay(label: "(", sfSymbol: nil, type: .symbol)
        map["RIGHT_PARENTHESIS"] = KeyDisplay(label: ")", sfSymbol: nil, type: .symbol)
        map["EXCLAMATION"] = KeyDisplay(label: "!", sfSymbol: nil, type: .symbol)
        map["AT_SIGN"] = KeyDisplay(label: "@", sfSymbol: nil, type: .symbol)
        map["HASH"] = KeyDisplay(label: "#", sfSymbol: nil, type: .symbol)
        map["DOLLAR"] = KeyDisplay(label: "$", sfSymbol: nil, type: .symbol)
        map["PERCENT"] = KeyDisplay(label: "%", sfSymbol: nil, type: .symbol)
        map["CARET_ALIAS"] = KeyDisplay(label: "^", sfSymbol: nil, type: .symbol)
        map["AMPERSAND"] = KeyDisplay(label: "&", sfSymbol: nil, type: .symbol)
        map["ASTERISK"] = KeyDisplay(label: "*", sfSymbol: nil, type: .symbol)
        map["UNDERSCORE"] = KeyDisplay(label: "_", sfSymbol: nil, type: .symbol)
        map["PIPE_ALIAS"] = KeyDisplay(label: "|", sfSymbol: nil, type: .symbol)
        map["TILDE_ALIAS"] = KeyDisplay(label: "~", sfSymbol: nil, type: .symbol)
        map["LESS_THAN"] = KeyDisplay(label: "<", sfSymbol: nil, type: .symbol)
        map["GREATER_THAN"] = KeyDisplay(label: ">", sfSymbol: nil, type: .symbol)
        map["QUESTION"] = KeyDisplay(label: "?", sfSymbol: nil, type: .symbol)
        map["NON_US_BACKSLASH"] = KeyDisplay(label: "\\", sfSymbol: nil, type: .symbol)
        map["NON_US_HASH"] = KeyDisplay(label: "#", sfSymbol: nil, type: .symbol)

        // Function keys
        for n in 1...24 {
            map["F\(n)"] = KeyDisplay(label: "F\(n)", sfSymbol: nil, type: .modifier)
        }

        // Media
        map["C_PLAY_PAUSE"] = KeyDisplay(label: "⏯", sfSymbol: nil, type: .modifier)
        map["C_NEXT_ALIAS"] = KeyDisplay(label: "⏭", sfSymbol: nil, type: .modifier)
        map["C_PREVIOUS"] = KeyDisplay(label: "⏮", sfSymbol: nil, type: .modifier)
        map["C_VOLUME_UP"] = KeyDisplay(label: "Vol+", sfSymbol: "speaker.wave.3", type: .modifier)
        map["C_VOLUME_DOWN"] = KeyDisplay(label: "Vol-", sfSymbol: "speaker.wave.1", type: .modifier)
        map["C_MUTE"] = KeyDisplay(label: "Mute", sfSymbol: "speaker.slash", type: .modifier)
        map["C_BRIGHTNESS_INC"] = KeyDisplay(label: "Bri+", sfSymbol: "sun.max", type: .modifier)
        map["C_BRIGHTNESS_DEC"] = KeyDisplay(label: "Bri-", sfSymbol: "sun.min", type: .modifier)

        // Printscreen / scroll lock
        map["PRINTSCREEN"] = KeyDisplay(label: "PrtSc", sfSymbol: nil, type: .modifier)
        map["SCROLLLOCK"] = KeyDisplay(label: "ScrLk", sfSymbol: nil, type: .modifier)
        map["PAUSE"] = KeyDisplay(label: "Pause", sfSymbol: nil, type: .modifier)

        // Keypad
        for n in 0...9 {
            map["KP_NUMBER_\(n)"] = KeyDisplay(label: "KP\(n)", sfSymbol: nil, type: .symbol)
            map["KP_N\(n)"] = KeyDisplay(label: "KP\(n)", sfSymbol: nil, type: .symbol)
        }
        map["KP_ENTER"] = KeyDisplay(label: "KP↵", sfSymbol: nil, type: .modifier)
        map["KP_PLUS"] = KeyDisplay(label: "KP+", sfSymbol: nil, type: .symbol)
        map["KP_MINUS"] = KeyDisplay(label: "KP-", sfSymbol: nil, type: .symbol)
        map["KP_MULTIPLY"] = KeyDisplay(label: "KP*", sfSymbol: nil, type: .symbol)
        map["KP_DIVIDE"] = KeyDisplay(label: "KP/", sfSymbol: nil, type: .symbol)
        map["KP_DOT"] = KeyDisplay(label: "KP.", sfSymbol: nil, type: .symbol)
        map["KP_EQUAL"] = KeyDisplay(label: "KP=", sfSymbol: nil, type: .symbol)
        map["KP_NUMLOCK"] = KeyDisplay(label: "NumLk", sfSymbol: nil, type: .modifier)

        // Application
        map["K_APPLICATION"] = KeyDisplay(label: "Menu", sfSymbol: nil, type: .modifier)
        map["K_APP"] = KeyDisplay(label: "Menu", sfSymbol: nil, type: .modifier)

        // Mouse movement
        map["MOVE_UP"] = KeyDisplay(label: "", sfSymbols: ["pointer.arrow", "arrow.up"], type: .mouse)
        map["MOVE_DOWN"] = KeyDisplay(label: "", sfSymbols: ["pointer.arrow", "arrow.down"], type: .mouse)
        map["MOVE_LEFT"] = KeyDisplay(label: "", sfSymbols: ["pointer.arrow", "arrow.left"], type: .mouse)
        map["MOVE_RIGHT"] = KeyDisplay(label: "", sfSymbols: ["pointer.arrow", "arrow.right"], type: .mouse)

        // Mouse scroll
        map["SCRL_UP"] = KeyDisplay(label: "", sfSymbols: ["scroll", "arrow.up"], type: .mouse)
        map["SCRL_DOWN"] = KeyDisplay(label: "", sfSymbols: ["scroll", "arrow.down"], type: .mouse)
        map["SCRL_LEFT"] = KeyDisplay(label: "", sfSymbols: ["scroll", "arrow.left"], type: .mouse)
        map["SCRL_RIGHT"] = KeyDisplay(label: "", sfSymbols: ["scroll", "arrow.right"], type: .mouse)

        // Mouse buttons
        map["LCLK"] = KeyDisplay(label: "LClick", sfSymbol: "pointer.arrow.click.2", type: .mouse)
        map["RCLK"] = KeyDisplay(label: "RClick", sfSymbol: "pointer.arrow.click", type: .mouse)
        map["MCLK"] = KeyDisplay(label: "MClick", sfSymbol: "pointer.arrow.click", type: .mouse)
        map["MB4"] = KeyDisplay(label: "MB4", sfSymbol: "pointer.arrow", type: .mouse)
        map["MB5"] = KeyDisplay(label: "MB5", sfSymbol: "pointer.arrow", type: .mouse)

        return map
    }()
}
