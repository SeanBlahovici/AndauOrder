import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum PDFGenerator {

    @MainActor
    static func saveOrderPDF(formData: OrderFormData) {
        let view = OrderPDFView(formData: formData)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0

        let pdfData = NSMutableData()
        renderer.render { size, renderContext in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &box, nil) else {
                return
            }
            context.beginPDFPage(nil)
            renderContext(context)
            context.endPDFPage()
            context.closePDF()
        }

        guard pdfData.length > 0 else { return }

        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        let customerName = formData.customer.fullName.isEmpty
            ? "Order"
            : formData.customer.fullName.replacingOccurrences(of: " ", with: "_")
        let dateStr = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            return f.string(from: formData.date)
        }()
        panel.nameFieldStringValue = "Andau_\(customerName)_\(dateStr).pdf"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? pdfData.write(to: url, options: .atomic)
            }
        }
        #else
        // iOS: Share via UIActivityViewController
        let data = pdfData as Data
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootVC = window.rootViewController else { return }

        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        rootVC.present(activityVC, animated: true)
        #endif
    }
}
