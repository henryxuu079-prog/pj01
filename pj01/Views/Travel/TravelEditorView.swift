import SwiftUI
import SwiftData

struct TravelEditorView: View {
    var existingTravel: Travel?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var summary = ""

    var isEditing: Bool { existingTravel != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("旅行名称", text: $title)
                }
                Section("日期") {
                    DatePicker("开始日期", selection: Binding(
                        get: { startDate ?? Date() },
                        set: { startDate = $0 }
                    ), displayedComponents: .date)
                    DatePicker("结束日期", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: .date)
                }
                Section("概述") {
                    TextEditor(text: $summary)
                        .frame(minHeight: 100)
                }
            }
            .datePickerStyle(.graphical)
            .navigationTitle(isEditing ? "编辑旅行" : "新建旅行")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let travel = existingTravel else { return }
        title = travel.title
        startDate = travel.startDate
        endDate = travel.endDate
        summary = travel.summary ?? ""
    }

    private func save() {
        if let travel = existingTravel {
            travel.title = title
            travel.startDate = startDate
            travel.endDate = endDate
            travel.summary = summary.isEmpty ? nil : summary
            travel.updatedAt = Date()
        } else {
            let travel = Travel(title: title, startDate: startDate, endDate: endDate)
            travel.summary = summary.isEmpty ? nil : summary
            modelContext.insert(travel)
        }
        dismiss()
    }
}

#Preview {
    TravelEditorView()
}
