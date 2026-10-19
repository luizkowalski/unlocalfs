import Foundation

extension FormatStyle where Self == ByteCountFormatStyle {
    static var size: Self { .byteCount(style: .file, spellsOutZero: false) }
}
