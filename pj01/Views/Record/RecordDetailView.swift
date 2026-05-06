import SwiftUI

struct RecordDetailView: View {
    let record: TravelRecord

    @State private var selectedPhoto: PhotoItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.title)
                        .font(.title.bold())
                    if let description = record.recordDescription {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    if let location = record.locationName {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal)

                // Photos as posters
                ForEach(record.photos) { photo in
                    PosterCanvasView(photo: photo)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
