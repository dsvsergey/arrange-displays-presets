import AppKit

/// Draws a miniature of a preset's arrangement for its menu item:
/// the built-in display is filled, external ones are outlined,
/// and the main display (menu bar) has a bar along its top edge.
enum PresetPreview {
    private static let canvas = NSSize(width: 40, height: 20)
    /// Used when a preset from an older version has no size and the display is not connected.
    private static let fallbackSize = CGSize(width: 1440, height: 900)

    static func image(for preset: Preset, connected: [ConnectedDisplay]) -> NSImage? {
        let current = Dictionary(connected.map { ($0.uuid, $0) }, uniquingKeysWith: { a, _ in a })
        let screens: [(rect: CGRect, builtin: Bool, main: Bool)] = preset.displays.map { p in
            let size: CGSize
            if let w = p.width, let h = p.height {
                size = CGSize(width: CGFloat(w), height: CGFloat(h))
            } else {
                size = current[p.uuid]?.size ?? fallbackSize
            }
            let builtin = p.builtin ?? current[p.uuid]?.isBuiltin ?? false
            return (CGRect(origin: CGPoint(x: CGFloat(p.x), y: CGFloat(p.y)), size: size), builtin, p.x == 0 && p.y == 0)
        }
        guard let bounds = screens.map(\.rect).reduce(nil, { $0?.union($1) ?? $1 }),
              bounds.width > 0, bounds.height > 0 else { return nil }

        let scale = min(canvas.width / bounds.width, canvas.height / bounds.height)
        let offset = CGPoint(x: (canvas.width - bounds.width * scale) / 2,
                             y: (canvas.height - bounds.height * scale) / 2)

        let image = NSImage(size: canvas, flipped: false) { _ in
            NSColor.black.set()
            for screen in screens {
                // Display coordinates grow downwards, the image's grow upwards.
                let r = screen.rect
                let rect = NSRect(x: offset.x + (r.minX - bounds.minX) * scale,
                                  y: offset.y + (bounds.maxY - r.maxY) * scale,
                                  width: r.width * scale,
                                  height: r.height * scale)
                    .insetBy(dx: 1, dy: 1) // keeps adjacent displays visually apart
                guard rect.width > 0, rect.height > 0 else { continue }

                if screen.builtin {
                    NSBezierPath(roundedRect: rect, xRadius: 1.5, yRadius: 1.5).fill()
                } else {
                    let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 1.5, yRadius: 1.5)
                    path.lineWidth = 1
                    path.stroke()
                }
                if screen.main {
                    let bar = NSRect(x: rect.minX, y: rect.maxY - 2.5, width: rect.width, height: 1)
                    if screen.builtin {
                        // Cut the bar out of the filled shape so it stays visible.
                        NSColor.clear.set()
                        bar.insetBy(dx: 1.5, dy: 0).fill(using: .copy)
                        NSColor.black.set()
                    } else {
                        bar.fill()
                    }
                }
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Arrangement of \(preset.name)"
        return image
    }
}
