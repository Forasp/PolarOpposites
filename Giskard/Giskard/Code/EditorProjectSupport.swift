//
//  EditorProjectSupport.swift
//  Giskard
//

import Foundation

struct BuildConfiguration: Codable, Equatable {
    var applicationName: String
    var bundleIdentifier: String
    var version: String
    var iconPath: String?
    var includedScenePaths: [String]
    var entryScenePath: String?

    static let fileName = "Giskard_Build_Configuration.json"
}

struct DebugRunManifest: Codable, Equatable {
    var projectName: String
    var projectPath: String
    var entryScenePath: String
    var includedScenePaths: [String]
    var buildConfiguration: BuildConfiguration
}

struct DebugRunLaunchPlan: Equatable {
    var manifestURL: URL
    var launcherURL: URL
    var arguments: [String]
}

enum EditorProjectSupport {
    static let debugRunFolderName = ".giskard/debug-run"
    static let defaultScriptTemplate = """
    function Begin(context)
    end

    function Tick(context)
    end

    function End(context)
    end
    """

    static func buildConfigurationURL(for projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(BuildConfiguration.fileName)
    }

    static func debugRunFolderURL(for projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(debugRunFolderName, isDirectory: true)
    }

    static func defaultBuildConfiguration(
        project: ProjectInformation,
        scenePaths: [String]? = nil
    ) -> BuildConfiguration {
        let discoveredScenePaths = scenePaths ?? discoverProjectFiles(withExtension: "scene", in: project.projectPath)
        let deduplicatedScenes = Array(NSOrderedSet(array: discoveredScenePaths)) as? [String] ?? discoveredScenePaths
        let entryScenePath = normalizedEntryScenePath(project.mainScenePath, availableScenes: deduplicatedScenes)

        return BuildConfiguration(
            applicationName: project.projectName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "GiskardGame",
            bundleIdentifier: suggestedBundleIdentifier(for: project),
            version: "0.1.0",
            iconPath: nil,
            includedScenePaths: deduplicatedScenes,
            entryScenePath: entryScenePath
        )
    }

    static func loadBuildConfiguration(project: ProjectInformation) -> BuildConfiguration {
        guard let projectRoot = project.projectPath else {
            return defaultBuildConfiguration(project: project, scenePaths: [])
        }

        let configURL = buildConfigurationURL(for: projectRoot)
        if let data = FileSys.shared.ReadFile(configURL.path),
           let decoded = try? JSONDecoder().decode(BuildConfiguration.self, from: data) {
            return normalized(decoded, project: project)
        }

        let fallback = defaultBuildConfiguration(project: project)
        saveBuildConfiguration(fallback, for: project)
        return fallback
    }

    @discardableResult
    static func saveBuildConfiguration(_ configuration: BuildConfiguration, for project: ProjectInformation) -> Bool {
        guard let projectRoot = project.projectPath else {
            return false
        }

        let normalizedConfiguration = normalized(configuration, project: project)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(normalizedConfiguration) else {
            return false
        }

        if normalizedConfiguration.entryScenePath != project.mainScenePath {
            project.mainScenePath = normalizedConfiguration.entryScenePath
            GiskardApp.persistCurrentProjectSettings()
        }

        return FileSys.shared.WriteFile(buildConfigurationURL(for: projectRoot).path, data: data)
    }

    static func ensureBuildConfigurationExists(for project: ProjectInformation) {
        _ = loadBuildConfiguration(project: project)
    }

    static func discoverProjectFiles(withExtension pathExtension: String, in rootURL: URL?) -> [String] {
        guard let rootURL else {
            return []
        }

        let didStartAccessing = rootURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                rootURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var results: [String] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == pathExtension.lowercased() else {
                continue
            }
            guard let relativePath = relativeProjectPath(for: fileURL, projectRoot: rootURL) else {
                continue
            }
            results.append(relativePath)
        }

        return results.sorted()
    }

    static func relativeProjectPath(for fileURL: URL, projectRoot: URL? = nil) -> String? {
        guard let rootURL = projectRoot ?? GiskardApp.getProject().projectPath else {
            return nil
        }

        let rootPath = rootURL.standardizedFileURL.path
        let filePath = fileURL.standardizedFileURL.path
        if filePath == rootPath {
            return ""
        }
        guard filePath.hasPrefix(rootPath + "/") else {
            return nil
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }

    static func absoluteProjectURL(for relativePath: String, projectRoot: URL? = nil) -> URL? {
        guard let rootURL = projectRoot ?? GiskardApp.getProject().projectPath else {
            return nil
        }
        return rootURL.appendingPathComponent(relativePath)
    }

    static func makeDebugRunLaunchPlan(
        project: ProjectInformation,
        bundleURL: URL
    ) throws -> DebugRunLaunchPlan {
        guard let projectRoot = project.projectPath else {
            throw DebugRunError.missingProjectRoot
        }

        let configuration = loadBuildConfiguration(project: project)
        guard !configuration.includedScenePaths.isEmpty else {
            throw DebugRunError.noIncludedScenes
        }
        guard let entryScenePath = configuration.entryScenePath,
              configuration.includedScenePaths.contains(entryScenePath) else {
            throw DebugRunError.invalidEntryScene
        }

        let buildFolderURL = debugRunFolderURL(for: projectRoot)
        try FileManager.default.createDirectory(at: buildFolderURL, withIntermediateDirectories: true)

        let manifest = DebugRunManifest(
            projectName: project.projectName ?? "Giskard Project",
            projectPath: projectRoot.path,
            entryScenePath: entryScenePath,
            includedScenePaths: configuration.includedScenePaths,
            buildConfiguration: configuration
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let manifestData = try encoder.encode(manifest)
        let manifestURL = buildFolderURL.appendingPathComponent("DebugRunManifest.json")
        try manifestData.write(to: manifestURL, options: .atomic)

        let launcherURL = buildFolderURL.appendingPathComponent("LaunchDebugRun.sh")
        let arguments = ["--giskard-debug-run-manifest", manifestURL.path]
        let launcher = launcherScript(bundlePath: bundleURL.path, arguments: arguments)
        try launcher.write(to: launcherURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: launcherURL.path
        )

        return DebugRunLaunchPlan(
            manifestURL: manifestURL,
            launcherURL: launcherURL,
            arguments: arguments
        )
    }

    static func loadDebugRunManifest(from url: URL) -> DebugRunManifest? {
        guard let data = FileSys.shared.ReadFile(url.path) ?? (try? Data(contentsOf: url)) else {
            return nil
        }
        return try? JSONDecoder().decode(DebugRunManifest.self, from: data)
    }

    private static func normalized(
        _ configuration: BuildConfiguration,
        project: ProjectInformation
    ) -> BuildConfiguration {
        let availableScenes = discoverProjectFiles(withExtension: "scene", in: project.projectPath)
        let includedScenes = configuration.includedScenePaths
            .filter { availableScenes.contains($0) }
            .deduplicated()

        let entryScenePath = normalizedEntryScenePath(
            configuration.entryScenePath ?? project.mainScenePath,
            availableScenes: includedScenes
        )

        return BuildConfiguration(
            applicationName: configuration.applicationName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? defaultBuildConfiguration(project: project, scenePaths: availableScenes).applicationName,
            bundleIdentifier: configuration.bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? suggestedBundleIdentifier(for: project),
            version: configuration.version.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "0.1.0",
            iconPath: configuration.iconPath?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            includedScenePaths: includedScenes,
            entryScenePath: entryScenePath
        )
    }

    private static func normalizedEntryScenePath(
        _ proposedPath: String?,
        availableScenes: [String]
    ) -> String? {
        if let proposedPath,
           availableScenes.contains(proposedPath) {
            return proposedPath
        }
        return availableScenes.first
    }

    private static func suggestedBundleIdentifier(for project: ProjectInformation) -> String {
        let author = (project.projectAuthor ?? "user")
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }
        let name = (project.projectName ?? "game")
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .filter { $0.isLetter || $0.isNumber }

        let authorComponent = author.isEmpty ? "user" : author
        let nameComponent = name.isEmpty ? "game" : name
        return "com.\(authorComponent).\(nameComponent)"
    }

    private static func launcherScript(bundlePath: String, arguments: [String]) -> String {
        let escapedBundlePath = shellEscaped(bundlePath)
        let escapedArguments = arguments.map(shellEscaped).joined(separator: " ")
        return """
        #!/bin/sh
        open -n \(escapedBundlePath) --args \(escapedArguments)
        """
    }

    private static func shellEscaped(_ string: String) -> String {
        "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

enum DebugRunError: LocalizedError {
    case missingProjectRoot
    case noIncludedScenes
    case invalidEntryScene

    var errorDescription: String? {
        switch self {
        case .missingProjectRoot:
            return "The current project does not have a root folder."
        case .noIncludedScenes:
            return "The build configuration does not include any scenes."
        case .invalidEntryScene:
            return "The build configuration entry scene must be one of the included scenes."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension Array where Element: Hashable {
    func deduplicated() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
