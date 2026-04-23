import Foundation

final class PreferencesManager {
    static let shared = PreferencesManager()

    // Default: ⌃⌥A — kVK_ANSI_A = 0, controlKey|optionKey = 4096|2048 = 6144
    private let defaultKeyCode: UInt32 = 0
    private let defaultModifiers: UInt32 = 6144

    var hotkeyKeyCode: UInt32 {
        get {
            let v = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
            return v == 0 ? defaultKeyCode : UInt32(v)
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: "hotkeyKeyCode") }
    }

    var hotkeyModifiers: UInt32 {
        get {
            let v = UserDefaults.standard.integer(forKey: "hotkeyModifiers")
            return v == 0 ? defaultModifiers : UInt32(v)
        }
        set { UserDefaults.standard.set(Int(newValue), forKey: "hotkeyModifiers") }
    }

    var saveToFile: Bool {
        get { UserDefaults.standard.bool(forKey: "saveToFile") }
        set { UserDefaults.standard.set(newValue, forKey: "saveToFile") }
    }

    var savePath: String {
        get {
            let v = UserDefaults.standard.string(forKey: "savePath") ?? ""
            if v.isEmpty {
                return (NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true).first ?? NSHomeDirectory()) + "/Screenshots"
            }
            return v
        }
        set { UserDefaults.standard.set(newValue, forKey: "savePath") }
    }

    private init() {}
}
