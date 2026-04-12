import SwiftUI

struct PhotoRow: View {
    var photo: PhotoItem
    var isSelected: Bool
    var store: PhotoSession

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.body)
            thumb
            detail
            Spacer()
        }
    }

    private var thumb: some View {
        Group {
            if let thumb: NSImage = store.film.thumbnail(for: photo) {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipped()
                    .cornerRadius(3)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(photo.filename)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)
            Text(photo.subtitle ?? "")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(photo.source == .reference ? "Reference" : "Target")
                .font(.caption2)
                .foregroundColor(photo.source == .reference ? .blue : .orange)
            coord
        }
    }

    private var coord: some View {
        Group {
            if photo.hasValidCoordinate {
                Text(String(format: "%.5f, %.5f", photo.coordinate.latitude, photo.coordinate.longitude))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.green)
            } else {
                Text("No GPS")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
    }
}
