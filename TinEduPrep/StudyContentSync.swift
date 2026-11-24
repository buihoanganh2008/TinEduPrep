import Foundation

struct StudyContentManifest: Codable, Sendable {
    let version: String
    let lessons: String
    let questions: String
    let practicalCases: String
}

struct StudyContentBundle: Codable, Sendable {
    let version: String
    let lessons: [StudyLesson]
    let questions: [QuizQuestion]
    let practicalCases: [PracticalCase]
}

enum StudyContentConfiguration {
    static var remoteManifestURL: URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "StudyContentManifestURL") as? String,
            !value.isEmpty,
            !value.contains("$(")
        else {
            return nil
        }

        return URL(string: value)
    }
}

enum StudyContentSyncError: LocalizedError {
    case invalidResponse
    case invalidVersion
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Máy chủ nội dung trả về phản hồi không hợp lệ."
        case .invalidVersion:
            return "Phiên bản nội dung không hợp lệ."
        case .invalidContent:
            return "Nội dung mới không vượt qua kiểm tra an toàn."
        }
    }
}

struct StudyContentSyncService: Sendable {
    let manifestURL: URL?

    var isConfigured: Bool {
        manifestURL != nil
    }

    func fetchLatest(than currentVersion: String) async throws -> StudyContentBundle? {
        guard let manifestURL else { return nil }

        let manifestData = try await download(from: manifestURL)
        let manifest = try JSONDecoder().decode(StudyContentManifest.self, from: manifestData)

        guard isNewerVersion(manifest.version, than: currentVersion) else {
            return nil
        }

        guard
            let lessonsURL = URL(string: manifest.lessons, relativeTo: manifestURL)?.absoluteURL,
            let questionsURL = URL(string: manifest.questions, relativeTo: manifestURL)?.absoluteURL,
            let practicalCasesURL = URL(string: manifest.practicalCases, relativeTo: manifestURL)?.absoluteURL
        else {
            throw StudyContentSyncError.invalidResponse
        }

        async let lessonsData = download(from: lessonsURL)
        async let questionsData = download(from: questionsURL)
        async let practicalCasesData = download(from: practicalCasesURL)

        let decoder = JSONDecoder()
        let lessons = try await decoder.decode([StudyLesson].self, from: lessonsData)
        let questions = try await decoder.decode([QuizQuestion].self, from: questionsData)
        let practicalCases = try await decoder.decode([PracticalCase].self, from: practicalCasesData)
        let bundle = StudyContentBundle(
            version: manifest.version,
            lessons: lessons,
            questions: questions,
            practicalCases: practicalCases
        )

        guard bundle.isValid else {
            throw StudyContentSyncError.invalidContent
        }

        return bundle
    }

    private func download(from url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard
            let httpResponse = response as? HTTPURLResponse,
            200..<300 ~= httpResponse.statusCode
        else {
            throw StudyContentSyncError.invalidResponse
        }

        return data
    }

    private func isNewerVersion(_ candidate: String, than current: String) -> Bool {
        let candidateParts = candidate.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        guard candidateParts.count == candidate.split(separator: ".").count,
              currentParts.count == current.split(separator: ".").count
        else {
            return false
        }

        let count = max(candidateParts.count, currentParts.count)
        for index in 0..<count {
            let candidatePart = index < candidateParts.count ? candidateParts[index] : 0
            let currentPart = index < currentParts.count ? currentParts[index] : 0

            if candidatePart != currentPart {
                return candidatePart > currentPart
            }
        }

        return false
    }
}

private extension StudyContentBundle {
    var isValid: Bool {
        let lessonIDs = lessons.map(\.id)
        let questionIDs = questions.map(\.id)
        let practicalCaseIDs = practicalCases.map(\.id)

        return !version.isEmpty
            && lessonIDs.allSatisfy { !$0.isEmpty }
            && questionIDs.allSatisfy { !$0.isEmpty }
            && practicalCaseIDs.allSatisfy { !$0.isEmpty }
            && Set(lessonIDs).count == lessonIDs.count
            && Set(questionIDs).count == questionIDs.count
            && Set(practicalCaseIDs).count == practicalCaseIDs.count
    }
}

enum StudyContentStorage {
    private static let fileName = "study-content-cache.json"

    private static var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    static func load() -> StudyContentBundle? {
        guard
            let fileURL,
            let data = try? Data(contentsOf: fileURL),
            let bundle = try? JSONDecoder().decode(StudyContentBundle.self, from: data),
            bundle.isValid
        else {
            return nil
        }

        return bundle
    }

    static func save(_ bundle: StudyContentBundle) {
        guard let fileURL, let data = try? JSONEncoder().encode(bundle) else { return }

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // The bundled content remains available when cache persistence fails.
        }
    }
}
