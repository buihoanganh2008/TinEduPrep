import Foundation

enum StudyCatalog {
    static let contentVersion = "1.0.0"

    static let lessons: [StudyLesson] = load("lessons")
    static let questions: [QuizQuestion] = load("questions")
    static let practicalCases: [PracticalCase] = load("practical_cases")

    private static func load<T: Decodable>(_ fileName: String) -> [T] {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            assertionFailure("Missing study content file: \(fileName).json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            assertionFailure("Unable to decode study content file \(fileName).json: \(error)")
            return []
        }
    }
}
