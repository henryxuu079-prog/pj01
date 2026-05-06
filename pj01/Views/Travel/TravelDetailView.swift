import SwiftUI
import SwiftData

struct TravelDetailView: View {
    let travel: Travel

    @Environment(\.modelContext) private var modelContext
    @State private var showRecordEditor = false

    var sortedRecords: [TravelRecord] {
        travel.records.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            if let summary = travel.summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 10)], spacing: 10) {
                ForEach(sortedRecords) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecordCardView(record: record)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteRecord(record)
                        } label: {
                            Label("删除记录", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle(travel.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showRecordEditor = true
                } label: {
                    Label("添加记录", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showRecordEditor) {
            RecordEditorView(travel: travel)
        }
    }

    private func deleteRecord(_ record: TravelRecord) {
        for photo in record.photos {
            try? FileStorageManager.shared.deleteFile(at: photo.originalImagePath)
            if let thumb = photo.thumbnailImagePath {
                try? FileStorageManager.shared.deleteFile(at: thumb)
            }
        }
        modelContext.delete(record)
    }
}

struct RecordCardView: View {
    let record: TravelRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            thumbnailImage
                .aspectRatio(4/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                if let location = record.locationName {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var thumbnailImage: some View {
        if let firstPhoto = record.photos.first {
            let image = FileStorageManager.shared.loadImage(from: firstPhoto.originalImagePath)
                ?? Image(systemName: "photo")
            return AnyView(image.resizable())
        }
        return AnyView(
            Rectangle()
                .fill(.quaternary)
                .overlay(Image(systemName: "camera.fill").font(.title2).foregroundStyle(.secondary))
        )
    }
}

#Preview {
    NavigationStack {
        TravelDetailView(travel: Travel(title: "预览", startDate: Date()))
    }
}
