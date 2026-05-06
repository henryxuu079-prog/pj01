import SwiftUI
import SwiftData
import PhotosUI

struct RecordEditorView: View {
    let travel: Travel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var recordDescription = ""
    @State private var timestamp: Date?
    @State private var locationName = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("记录标题", text: $title)
                }
                Section("描述") {
                    TextEditor(text: $recordDescription)
                        .frame(minHeight: 80)
                }
                Section("时间") {
                    DatePicker("拍摄时间", selection: Binding(
                        get: { timestamp ?? Date() },
                        set: { timestamp = $0 }
                    ))
                }
                Section("地点") {
                    TextField("地点名称", text: $locationName)
                }
                Section("照片") {
                    PhotosPicker(selection: $selectedPhotoItems, matching: .images) {
                        Label("选择照片", systemImage: "photo.on.rectangle.angled")
                    }
                }
            }
            .navigationTitle("新建记录")
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
        let record = TravelRecord(title: title, sortOrder: travel.records.count)
        record.recordDescription = recordDescription.isEmpty ? nil : recordDescription
        record.timestamp = timestamp
        record.locationName = locationName.isEmpty ? nil : locationName
        record.travel = travel
        modelContext.insert(record)

        Task {
            for item in selectedPhotoItems {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let path = try? FileStorageManager.shared.saveOriginal(imageData: data) else { continue }
                let photo = PhotoItem(originalImagePath: path)
                photo.record = record
                modelContext.insert(photo)
            }
        }

        dismiss()
    }
}

#Preview {
    RecordEditorView(travel: Travel(title: "预览旅行"))
}
