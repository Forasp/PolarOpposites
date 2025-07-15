//
//  ProjectInformation.swift
//  Giskard
//
//  Created by Timothy Powell on 7/15/25.
//

import Foundation

class ProjectInformation: Codable {
    var projectVersion: Int?
    var projectName: String?
    var projectAuthor: String?
    var projectPath: String?
    var description: String?
    var creationDate: String?

    init(
        projectVersion: Int? = nil,
        projectName: String? = nil,
        projectAuthor: String? = nil,
        projectPath: String? = nil,
        description: String? = nil,
        creationDate: String? = nil
    ) {
        self.projectVersion = projectVersion
        self.projectName = projectName
        self.projectAuthor = projectAuthor
        self.projectPath = projectPath
        self.description = description
        self.creationDate = creationDate
    }

    public func toJSONData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }

    public func toJSONString() throws -> String {
        let data = try toJSONData()
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func fromJSONData(_ data: Data) throws -> ProjectInformation {
        let decoder = JSONDecoder()
        return try decoder.decode(ProjectInformation.self, from: data)
    }

    public static func fromJSONFile(url: URL) throws -> ProjectInformation {
        let data = try Data(contentsOf: url)
        return try fromJSONData(data)
    }
}
