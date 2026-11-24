import Foundation

enum StudyCategory: String, CaseIterable, Codable, Identifiable {
    case general
    case pedagogy
    case informatics
    case practical

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .general:
            return "Kiến thức chung"
        case .pedagogy:
            return "Nghiệp vụ sư phạm"
        case .informatics:
            return "Chuyên môn Tin học"
        case .practical:
            return "Luyện vòng 2"
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "building.columns.fill"
        case .pedagogy:
            return "person.2.fill"
        case .informatics:
            return "desktopcomputer"
        case .practical:
            return "rectangle.and.pencil.and.ellipsis"
        }
    }

    var tintName: String {
        switch self {
        case .general:
            return "blue"
        case .pedagogy:
            return "orange"
        case .informatics:
            return "purple"
        case .practical:
            return "green"
        }
    }

    var shortDescription: String {
        switch self {
        case .general:
            return "Nắm chắc nền tảng pháp luật và quy định về viên chức."
        case .pedagogy:
            return "Luyện thiết kế bài dạy và xử lý tình huống sư phạm."
        case .informatics:
            return "Củng cố kiến thức Tin học theo định hướng chương trình mới."
        case .practical:
            return "Chuẩn bị trình bày, minh họa kỹ năng và phản biện."
        }
    }
}

struct LessonSection: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let body: String
    let keyPoints: [String]
}

struct StudyLesson: Codable, Hashable, Identifiable {
    let id: String
    let category: StudyCategory
    let title: String
    let summary: String
    let estimatedMinutes: Int
    let sections: [LessonSection]
    let source: String
}

struct QuizChoice: Codable, Hashable, Identifiable {
    let id: String
    let text: String
    let isCorrect: Bool
}

struct QuizQuestion: Codable, Hashable, Identifiable {
    let id: String
    let category: StudyCategory
    let prompt: String
    let choices: [QuizChoice]
    let explanation: String
    let difficulty: String
}

struct PracticalCase: Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let category: StudyCategory
    let scenario: String
    let expectedOutcome: String
    let preparationSteps: [String]
    let followUpQuestions: [String]
}

struct StudyProgressSnapshot: Codable {
    var completedLessonIDs: [String] = []
    var bookmarkedLessonIDs: [String] = []
    var attemptedQuestionIDs: [String] = []
    var incorrectQuestionIDs: [String] = []
    var completedPracticalCaseIDs: [String] = []
    var quizScores: [Int] = []
}
