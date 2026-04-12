import AppKit
import MapKit

final class PinDot: MKAnnotationView {
    var photo: PhotoItem?
    var onHover: ((PhotoItem, PinDot, Bool) -> Void)?
    private var tracking: NSTrackingArea?

    override init(annotation: (any MKAnnotation)?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        wantsLayer = true
        centerOffset = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area: NSTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        guard let photo else { return }
        onHover?(photo, self, true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        guard let photo else { return }
        onHover?(photo, self, false)
    }

    func apply(photo: PhotoItem, isSelected: Bool, isRef: Bool) {
        self.photo = photo
        let size: CGFloat = photo.source == .reference ? (isRef ? 10 : 3.5) : 14
        resize(size)
        if photo.source == .reference {
            applyReference(isSelected: isSelected, isRef: isRef)
        } else {
            applyTarget(isSelected: isSelected)
        }
    }

    private func resize(_ size: CGFloat) {
        if frame.size.width != size || frame.size.height != size {
            setFrameSize(NSSize(width: size, height: size))
        }
        bounds = NSRect(origin: .zero, size: NSSize(width: size, height: size))
        layer?.cornerRadius = size / 2
    }

    private func applyReference(isSelected: Bool, isRef: Bool) {
        applyStyle(
            fill: NSColor.black,
            borderWidth: isRef ? 2.5 : (isSelected ? 1.5 : 0),
            borderColor: isRef ? NSColor.systemYellow.cgColor : (isSelected ? NSColor.white.cgColor : nil)
        )
    }

    private func applyTarget(isSelected: Bool) {
        let color: NSColor = isSelected ? .systemGreen : .systemOrange
        let borderColor: CGColor = isSelected ? NSColor.white.cgColor : NSColor.black.withAlphaComponent(0.3).cgColor
        applyStyle(fill: color, borderWidth: isSelected ? 2.5 : 1, borderColor: borderColor)
    }

    private func applyStyle(fill: NSColor, borderWidth: CGFloat, borderColor: CGColor?) {
        layer?.backgroundColor = fill.cgColor
        layer?.borderWidth = borderWidth
        layer?.borderColor = borderColor
    }
}
