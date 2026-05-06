import SwiftUI

struct PosterStylePicker: View {
    let photo: PhotoItem

    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var position: PosterTextPosition = .overlay
    @State private var fontSize: Double = 24
    @State private var fontName: String = ""
    @State private var colorHex: String = "#FFFFFF"
    @State private var frameStyle: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("文字") {
                    TextField("照片描述", text: $text)
                }
                Section("位置") {
                    Picker("文字位置", selection: $position) {
                        Text("叠加在图片上").tag(PosterTextPosition.overlay)
                        Text("图片下方画框").tag(PosterTextPosition.caption)
                    }
                    .pickerStyle(.segmented)
                }
                Section("字体") {
                    Picker("字体样式", selection: $fontName) {
                        Text("系统衬线体").tag("")
                        Text("手写体").tag("Handwriting")
                        Text("艺术体").tag("Artistic")
                    }
                    HStack {
                        Text("字号")
                        Slider(value: $fontSize, in: 12...72, step: 1)
                        Text("\(Int(fontSize))")
                            .monospacedDigit()
                    }
                }
                Section("颜色") {
                    ColorPicker("文字颜色", selection: Binding(
                        get: { Color(hex: colorHex) },
                        set: { colorHex = $0.toHex() }
                    ))
                }
                Section("画框") {
                    Picker("画框样式", selection: $frameStyle) {
                        Text("无").tag("")
                        Text("古典").tag("classic")
                        Text("现代").tag("modern")
                        Text("胶片").tag("film")
                    }
                }
            }
            .navigationTitle("海报样式")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") { apply() }
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func loadExisting() {
        text = photo.posterText ?? ""
        position = photo.posterTextPositionEnum
        fontSize = photo.posterTextSize ?? 24
        fontName = photo.posterFontName ?? ""
        colorHex = photo.posterTextColorHex ?? "#FFFFFF"
        frameStyle = photo.posterFrameStyle ?? ""
    }

    private func apply() {
        photo.posterText = text.isEmpty ? nil : text
        photo.posterTextPosition = position.rawValue
        photo.posterTextSize = fontSize
        photo.posterFontName = fontName.isEmpty ? nil : fontName
        photo.posterTextColorHex = colorHex
        photo.posterFrameStyle = frameStyle.isEmpty ? nil : frameStyle
        dismiss()
    }
}

