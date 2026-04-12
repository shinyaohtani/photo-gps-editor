import AppKit

final class PreviewZone {
    private var mouseMonitor: Any?

    func ensure(_ action: @escaping () -> Void) {
        guard mouseMonitor == nil else { return }
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { event in
            action()
            return event
        }
    }

    func remove() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
    }

    func isInside(mousePos: NSPoint, anchorRect: NSRect?, panel: NSPanel?) -> Bool {
        let anchorHit: Bool = anchorRect?.insetBy(dx: -12, dy: -12).contains(mousePos) == true
        let panelHit: Bool = panelRect(panel)?.insetBy(dx: -6, dy: -6).contains(mousePos) == true
        return anchorHit || panelHit
    }

    func mousePos() -> NSPoint {
        NSEvent.mouseLocation
    }

    func panelRect(_ panel: NSPanel?) -> NSRect? {
        panel?.frame
    }
}
