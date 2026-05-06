import SwiftUI
import SwiftData
import PhotosUI

struct RecordEditorView: View {
    var travel: Travel?
    var existingRecord: TravelRecord?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var recordDescription = ""
    @State private var timestamp: Date?
    @State private var locationName = ""
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var capturedImageData: Data?
    @State private var showCamera = false
    @State private var photoCount = 0
    @State private var isSaving = false

    var isEditing: Bool { existingRecord != nil }

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
                Section {
                    HStack(spacing: 16) {
                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: 0,
                            matching: .images
                        ) {
                            Label("相册", systemImage: "photo.on.rectangle.angled")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .onChange(of: selectedPhotoItems) { _, _ in
                            photoCount = selectedPhotoItems.count
                        }

                        #if os(iOS)
                        Button {
                            showCamera = true
                        } label: {
                            Label("拍照", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .buttonStyle(.plain)

                    if photoCount > 0 {
                        Text("已选择 \(photoCount) 张照片")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if capturedImageData != nil {
                        Text("已拍摄 1 张照片")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("照片")
                }
            }
            .navigationTitle(isEditing ? "编辑记录" : "新建记录")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.isEmpty || isSaving)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(capturedImageData: $capturedImageData)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedImageData) { _, _ in
                if capturedImageData != nil {
                    photoCount += 1
                }
            }
            #endif
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        guard let record = existingRecord else { return }
        title = record.title
        recordDescription = record.recordDescription ?? ""
        timestamp = record.timestamp
        locationName = record.locationName ?? ""
    }

    private func save() {
        isSaving = true

        if let record = existingRecord {
            record.title = title
            record.recordDescription = recordDescription.isEmpty ? nil : recordDescription
            record.timestamp = timestamp
            record.locationName = locationName.isEmpty ? nil : locationName
        }

        Task {
            let targetRecord: TravelRecord
            if let existing = existingRecord {
                targetRecord = existing
            } else {
                guard let travel else { dismiss(); return }
                let newRecord = TravelRecord(title: title, sortOrder: travel.records.count)
                newRecord.recordDescription = recordDescription.isEmpty ? nil : recordDescription
                newRecord.timestamp = timestamp
                newRecord.locationName = locationName.isEmpty ? nil : locationName
                newRecord.travel = travel
                modelContext.insert(newRecord)
                targetRecord = newRecord
            }

            for item in selectedPhotoItems {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let path = try? FileStorageManager.shared.saveOriginal(imageData: data) else { continue }
                let photo = PhotoItem(originalImagePath: path)
                photo.record = targetRecord
                modelContext.insert(photo)
                populateMetadata(for: photo)
            }
            if let data = capturedImageData,
               let path = try? FileStorageManager.shared.saveOriginal(imageData: data) {
                let photo = PhotoItem(originalImagePath: path)
                photo.record = targetRecord
                modelContext.insert(photo)
                populateMetadata(for: photo)
            }

            dismiss()
        }
    }

    private func populateMetadata(for photo: PhotoItem) {
        let imageURL = FileStorageManager.shared.url(for: photo.originalImagePath)
        let exif = ImageProcessingService.shared.extractEXIF(from: imageURL)

        photo.takenDate = exif.takenDate
        photo.cameraModel = exif.cameraModel
        photo.lensModel = exif.lensModel
        photo.focalLength = exif.focalLength.map { String(format: "%.0fmm", $0) }
        photo.aperture = exif.aperture.map { String(format: "f/%.1f", $0) }
        photo.shutterSpeed = exif.shutterSpeed.map { formatShutterSpeed($0) }
        photo.iso = exif.iso
        photo.imageWidth = exif.width
        photo.imageHeight = exif.height

        if locationName.isEmpty, let lat = exif.latitude, let lon = exif.longitude {
            photo.latitude = lat
            photo.longitude = lon
            Task.detached {
                if let name = await LocationService.shared.reverseGeocode(latitude: lat, longitude: lon) {
                    await MainActor.run { photo.locationName = name }
                }
            }
        }

        if let thumbPath = try? FileStorageManager.shared.generateThumbnail(for: photo.originalImagePath) {
            photo.thumbnailImagePath = thumbPath
        }
    }

    private func formatShutterSpeed(_ value: Double) -> String {
        if value < 1 {
            "1/\(Int(1.0 / value))"
        } else {
            String(format: "%.1f\"", value)
        }
    }
}

#Preview {
    RecordEditorView(travel: Travel(title: "预览"))
}
