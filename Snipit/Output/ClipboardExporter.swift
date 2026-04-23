import AppKit

enum ClipboardExporter {
    static func export(view: NSView) {
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
        write(data: data)
        if PreferencesManager.shared.saveToFile { save(data: data) }
    }

    static func export(image: CGImage) {
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        write(data: data)
        if PreferencesManager.shared.saveToFile { save(data: data) }
    }

    private static func write(data: Data) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setData(data, forType: .png)
    }

    private static func save(data: Data) {
        let dir = PreferencesManager.shared.savePath
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let name = "Snipit_\(formatter.string(from: Date())).png"
        let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
        try? data.write(to: url)
    }
}
