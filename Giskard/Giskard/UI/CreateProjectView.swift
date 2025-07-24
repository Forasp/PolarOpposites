//
//  CreateProjectView.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import SwiftUI

struct CreateProjectTextField: View {
    var fieldName: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(fieldName)
                .frame(width: 100, alignment: .trailing) // Adjust width as needed
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .bold()
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.horizontal, 10)
                }
                TextField("", text: $text)
            }
            .padding(.horizontal, -10)
            .padding(.vertical, 4)
        }
    }
}

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var projectName = ""
    @State private var projectAuthor = ""
    @State private var projectPath = ""
    @State private var description = ""
    @State private var showFileChooser = false
    @State private var baseFolderURL: URL?
    
    var body: some View {
        Form {
            CreateProjectTextField(fieldName: "Project Name", placeholder: "Obviously The Greatest Game Ever", text: $projectName)
            CreateProjectTextField(fieldName: "Author", placeholder: "Your Name Here", text: $projectAuthor)
            CreateProjectTextField(fieldName: "Description", placeholder: "It's an FPS/RTS/RPG/Racing/Flight/Casual/MMO/Competitive/Side-Scroller.", text: $description)
            HStack {
                TextField("Project Path", text: (projectPath.count > 0 ? $projectPath : .constant("Please select a folder where your project will be created.")))
                    .frame(minWidth: 500, idealWidth: 500)
                Button("Choose…") {
                    showFileChooser = true
                }
            }
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Create Project") {
                    guard let baseURL = baseFolderURL else { return }
                    let sanitizedProjectName = projectName.replacingOccurrences(of: " ", with: "")
                    let folderURL = baseURL.appendingPathComponent(sanitizedProjectName)
                    
                    var didStartAccessing = false
                    if baseURL.startAccessingSecurityScopedResource() {
                        didStartAccessing = true
                    }

                    defer {
                        if didStartAccessing {
                            baseURL.stopAccessingSecurityScopedResource()
                        }
                    }
                        
                    do {
                        // Create the project directory if it doesn't exist
                        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                        
                        // Create ProjectInformation instance
                        let projectInfo = ProjectInformation(
                            projectVersion: 1,
                            projectName: projectName,
                            projectAuthor: projectAuthor,
                            projectPath: folderURL,
                            description: description,
                            creationDate: ISO8601DateFormatter().string(from: Date())
                        )
                        
                        // Encode to JSON
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = .prettyPrinted
                        
                        let data = try encoder.encode(projectInfo)
                        
                        // Write the settings file
                        let settingsURL = folderURL.appendingPathComponent("Giskard_Project_Settings")
                        try data.write(to: settingsURL)
                        
                        GiskardApp.loadProject(projectInfo);
                        
                        dismiss()
                    } catch {
                        // Handle error (show alert or log)
                        print("Failed to create project: \(error.localizedDescription)")
                    }
                }
                .disabled(projectName.isEmpty || projectAuthor.isEmpty || projectPath.isEmpty)
            }
            .padding(.top)
        }
        .frame(minWidth: 500, idealWidth: 500)
        .padding()
        .fileImporter(isPresented: $showFileChooser, allowedContentTypes: [.folder], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                let allowedDirectories = [
                    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!,
                    FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!,
                    FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                ]
                baseFolderURL = url
                let sanitizedProjectName = projectName.replacingOccurrences(of: " ", with: "")
                let projectURL = url.appendingPathComponent(sanitizedProjectName)
                projectPath = projectURL.path
            }
        }
        .frame(minWidth: 650, idealWidth: 650)
    }
}

#Preview {
    CreateProjectView()
}
