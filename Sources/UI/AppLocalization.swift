import Foundation

enum AppLocalization {
    static var table: String {
        isJapanese ? "Localizable_ja" : "Localizable"
    }

    static func text(_ key: String, comment: String = "") -> String {
        NSLocalizedString(key, tableName: table, bundle: .main, comment: comment)
    }

    static func text(_ key: String, _ arguments: CVarArg..., comment: String = "") -> String {
        let format = NSLocalizedString(key, tableName: table, bundle: .main, comment: comment)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    static var isJapanese: Bool {
        Locale.current.language.languageCode?.identifier == "ja"
    }
}
