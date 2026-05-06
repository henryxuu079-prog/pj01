import SwiftUI
import SwiftData

struct TravelListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Travel.startDate, order: .reverse) private var travels: [Travel]
    @State private var showEditor = false

    var body: some View {
        List {
            ForEach(travels) { travel in
                NavigationLink(destination: TravelDetailView(travel: travel)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(travel.title)
                            .font(.headline)
                        if let start = travel.startDate {
                            Text(start, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteTravels)
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

    private func deleteTravels(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(travels[index])
        }
    }
}

#Preview {
    NavigationStack {
        TravelListView()
    }
    .modelContainer(for: [Travel.self, TravelRecord.self, PhotoItem.self], inMemory: true)
}
