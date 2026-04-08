import SwiftUI

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    @State private var lines: [[CGPoint]] = []
    @State private var currentLine: [CGPoint] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Signature")
                .font(.headline)

            Canvas { context, size in
                for line in lines + [currentLine] {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.move(to: line[0])
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.primary), lineWidth: 2)
                }
            }
            .frame(height: 150)
            .border(Color.secondary.opacity(0.3))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentLine.append(value.location)
                    }
                    .onEnded { _ in
                        lines.append(currentLine)
                        currentLine = []
                        renderSignature()
                    }
            )

            HStack {
                Button("Clear") {
                    lines = []
                    currentLine = []
                    signatureData = nil
                }
                .buttonStyle(.bordered)

                if signatureData != nil {
                    Label("Signed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
        }
    }

    private func renderSignature() {
        // Render canvas to image
        let capturedLines = lines
        let renderer = ImageRenderer(content:
            Canvas { context, size in
                for line in capturedLines {
                    guard line.count > 1 else { continue }
                    var path = Path()
                    path.move(to: line[0])
                    for point in line.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.black), lineWidth: 2)
                }
            }
            .frame(width: 400, height: 150)
            .background(.white)
        )
        renderer.scale = 2.0

        #if os(macOS)
        if let nsImage = renderer.nsImage,
           let tiffData = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            signatureData = pngData
        }
        #else
        if let uiImage = renderer.uiImage,
           let pngData = uiImage.pngData() {
            signatureData = pngData
        }
        #endif
    }
}
