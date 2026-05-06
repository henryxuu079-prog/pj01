import SwiftUI
import SwiftData

struct TravelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 12)], spacing: 12) {
                ForEach(travels) { travel in
                    NavigationLink(destination: TravelDetailView(travel: travel)) {
                        TravelCardView(travel: travel)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            modelContext.delete(travel)
                        } label: {
                            Label("删除旅行", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle("旅行")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditor = true
                } label: {
                    Label("新建旅行", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            TravelEditorView()
        }
    }
}

struct TravelCardView: View {
    let travel: Travel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            coverImage
                .aspectRatio(4/3, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(travel.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if let start = travel.startDate {
                    Text(start, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var coverImage: some View {
        if let path = travel.coverImagePath,
           let image = FileStorageManager.shared.loadImage(from: path) {
            return AnyView(image.resizable())
        }
        if let firstPhoto = travel.records.first?.photos.first {
            return AnyView(
                (FileStorageManager.shared.loadImage(from: firstPhoto.originalImagePath) ?? Image(systemName: "photo"))
                    .resizable()
            )
        }
        return AnyView(
            Rectangle()
                .fill(.quaternary)
                .overlay(Image(systemName: "airplane.departure").font(.title).foregroundStyle(.secondary))
        )
    }
}

#Preview {
    NavigationStack {
        TravelListView()
    }
    .modelContainer(for: [Travel.self, TravelRecord.self, PhotoItem.self], inMemory: true)
}
