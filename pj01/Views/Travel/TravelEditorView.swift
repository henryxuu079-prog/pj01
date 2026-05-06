import SwiftUI
import SwiftData

struct TravelEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var summary = ""

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
                    ))
                    DatePicker("结束日期", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ))
                }
                Section("概述") {
                    TextEditor(text: $summary)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("新建旅行")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func save() {
        let travel = Travel(title: title, startDate: startDate, endDate: endDate)
        travel.summary = summary.isEmpty ? nil : summary
        modelContext.insert(travel)
        dismiss()
    }
}

#Preview {
    TravelEditorView()
}
