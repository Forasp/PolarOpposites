//
//  ImageInspectorView.swift
//  Giskard
//
//  Created by Timothy Powell on 2/18/26.
//

import SwiftUI
import AppKit
import ImageIO

struct ImageInspectorView: View {
    @State private var imageURL: URL? = GiskardApp.selectedImageFileURL
    @State private var imageData: Data? = nil

    private var fileName: String {
        imageURL?.lastPathComponent ?? "No image selected"
    }

    private var fileSizeText: String {
        guard let imageURL else { return "-" }
        let values = try? imageURL.resourceValues(forKeys: [.fileSizeKey])
        guard let size = values?.fileSize else { return "-" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private var dimensionsText: String {
        guard let imageData else { return "-" }
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return "-"
        }
        return "\(width) x \(height)"
    }

    private var previewImage: NSImage? {
        guard let imageData else { return nil }
        return NSImage(data: imageData)
    }

    private func refreshImageData() {
        guard let imageURL else {
            imageData = nil
            return
        }
        imageData = FileSys.shared.ReadFile(imageURL.path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image")
                .font(.headline)

            Group {
                HStack {
                    Text("File Name")
                    Spacer()
                    Text(fileName).foregroundColor(.secondary)
                }
                HStack {
                    Text("File Size")
                    Spacer()
                    Text(fileSizeText).foregroundColor(.secondary)
                }
                HStack {
                    Text("Dimensions")
                    Spacer()
                    Text(dimensionsText).foregroundColor(.secondary)
                }
            }
            .font(.caption)

            Divider()

            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                Text("Select a .png file to preview.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding()
        .onAppear {
            imageURL = GiskardApp.selectedImageFileURL
            refreshImageData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .inspectorSelectionChanged)) { _ in
            imageURL = GiskardApp.selectedImageFileURL
            refreshImageData()
        }
    }
}

#Preview {
    ImageInspectorView()
}
