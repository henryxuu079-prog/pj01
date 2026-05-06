import SwiftUI
import SwiftData

struct TravelDetailView: View {
    let travel: Travel

    @State private var showRecordEditor = false

    var body: some View {
        List {
            if let summary = travel.summary {
                Section("概述") {
                    Text(summary)
                }
            }

            Section("记录") {
                ForEach(travel.records.sorted { $0.sortOrder < $1.sortOrder }) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.title)
                                    .font(.headline)
                                if let location = record.locationName {
                                    Text(location)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if let timestamp = record.timestamp {
                                Text(timestamp, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
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
}
