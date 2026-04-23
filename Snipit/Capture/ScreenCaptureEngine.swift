import ScreenCaptureKit
import AppKit

enum CaptureError: LocalizedError {
    case noDisplay
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No display found to capture."
        case .captureFailed: return "Screen capture failed. Check Screen Recording permission in System Settings."
        }
    }
}

private extension CGImage {
    /// Re-draws into an explicit sRGB context, normalising any wide-gamut colour space.
    func toSRGB() -> CGImage? {
        guard let cs = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bmi = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                                       | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let ctx = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: 0,
                                  space: cs, bitmapInfo: bmi.rawValue) else { return nil }
        ctx.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }
}

enum ScreenCaptureEngine {
    /// Captures the main display and returns a full-resolution CGImage (Retina-aware).
    static func captureMainDisplay() async throws -> CGImage {
        // Request permission if needed
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
            // Give user a moment to grant, then check again
            try await Task.sleep(nanoseconds: 500_000_000)
            guard CGPreflightScreenCaptureAccess() else { throw CaptureError.captureFailed }
        }

        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        guard let display = content.displays.first else { throw CaptureError.noDisplay }

        // Exclude our own app windows from the capture
        let ourBundle = Bundle.main.bundleIdentifier ?? ""
        let ourWindows = content.windows.filter {
            $0.owningApplication?.bundleIdentifier == ourBundle
        }

        let filter = SCContentFilter(display: display, excludingWindows: ourWindows)

        let config = SCStreamConfiguration()
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        config.width = Int(CGFloat(display.width) * scale)
        config.height = Int(CGFloat(display.height) * scale)
        config.scalesToFit = false
        config.showsCursor = false
        // Force sRGB so colors match regardless of display color profile (P3, etc.)
        config.colorSpaceName = CGColorSpace.sRGB

        let raw = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        // Convert to sRGB CGImage so NSImage always renders with correct colors
        return raw.toSRGB() ?? raw
    }
}
