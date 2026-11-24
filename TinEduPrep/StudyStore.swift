import Foundation
import Observation

@MainActor
@Observable
final class StudyStore {
    private(set) var lessons: [StudyLesson] = StudyCatalog.lessons
    private(set) var questions: [QuizQuestion] = StudyCatalog.questions
    private(set) var practicalCases: [PracticalCase] = StudyCatalog.practicalCases
    private(set) var contentVersion = StudyCatalog.contentVersion
    private(set) var isCheckingForContent = false
    private(set) var contentSyncMessage: String?

    var completedLessonIDs: Set<String> = []
    var bookmarkedLessonIDs: Set<String> = []
    var attemptedQuestionIDs: Set<String> = []
    var incorrectQuestionIDs: Set<String> = []
    var completedPracticalCaseIDs: Set<String> = []
    var quizScores: [Int] = []

    private let progressKey = "tinEduPrep.studyProgress"
    private let contentSyncService = StudyContentSyncService(
        manifestURL: StudyContentConfiguration.remoteManifestURL
    )

    var isContentSyncConfigured: Bool {
        contentSyncService.isConfigured
    }

    init() {
        loadCachedContent()
        loadProgress()
    }

    func refreshCatalog() {
        if let cachedContent = StudyContentStorage.load() {
            apply(cachedContent)
        } else {
            apply(
                StudyContentBundle(
                    version: StudyCatalog.contentVersion,
                    lessons: StudyCatalog.lessons,
                    questions: StudyCatalog.questions,
                    practicalCases: StudyCatalog.practicalCases
                )
            )
        }
    }

    func updateContentIfNeeded() async {
        guard contentSyncService.isConfigured, !isCheckingForContent else { return }

        isCheckingForContent = true
        defer { isCheckingForContent = false }

        do {
            guard let updatedContent = try await contentSyncService.fetchLatest(than: contentVersion) else {
                contentSyncMessage = "Nội dung đã là phiên bản mới nhất."
                return
            }

            apply(updatedContent)
            StudyContentStorage.save(updatedContent)
            contentSyncMessage = "Đã cập nhật nội dung ôn tập."
        } catch {
            contentSyncMessage = "Chưa thể kiểm tra nội dung mới. Vẫn dùng dữ liệu hiện có."
        }
    }

    var totalLessonCount: Int { lessons.count }

    var completedLessonCount: Int {
        completedLessonIDs.intersection(lessons.map(\.id)).count
    }

    var learningProgress: Double {
        guard totalLessonCount > 0 else { return 0 }
        return Double(completedLessonCount) / Double(totalLessonCount)
    }

    var correctAnswerCount: Int {
        max(0, attemptedQuestionIDs.count - incorrectQuestionIDs.count)
    }

    var averageQuizScore: Int {
        guard !quizScores.isEmpty else { return 0 }
        return quizScores.reduce(0, +) / quizScores.count
    }

    var bookmarkedLessons: [StudyLesson] {
        lessons.filter { bookmarkedLessonIDs.contains($0.id) }
    }

    var incorrectQuestions: [QuizQuestion] {
        questions.filter { incorrectQuestionIDs.contains($0.id) }
    }

    func lessons(for category: StudyCategory) -> [StudyLesson] {
        lessons.filter { $0.category == category }
    }

    func questions(for category: StudyCategory?) -> [QuizQuestion] {
        guard let category else { return questions }
        return questions.filter { $0.category == category }
    }

    func toggleLessonCompleted(_ lesson: StudyLesson) {
        if completedLessonIDs.contains(lesson.id) {
            completedLessonIDs.remove(lesson.id)
        } else {
            completedLessonIDs.insert(lesson.id)
        }
        saveProgress()
    }

    func toggleBookmark(for lesson: StudyLesson) {
        if bookmarkedLessonIDs.contains(lesson.id) {
            bookmarkedLessonIDs.remove(lesson.id)
        } else {
            bookmarkedLessonIDs.insert(lesson.id)
        }
        saveProgress()
    }

    func recordAnswer(for question: QuizQuestion, choice: QuizChoice) {
        attemptedQuestionIDs.insert(question.id)
        if choice.isCorrect {
            incorrectQuestionIDs.remove(question.id)
        } else {
            incorrectQuestionIDs.insert(question.id)
        }
        saveProgress()
    }

    func recordQuizScore(_ score: Int) {
        quizScores.append(score)
        saveProgress()
    }

    func markPracticalCaseCompleted(_ practicalCase: PracticalCase) {
        completedPracticalCaseIDs.insert(practicalCase.id)
        saveProgress()
    }

    func resetProgress() {
        completedLessonIDs.removeAll()
        bookmarkedLessonIDs.removeAll()
        attemptedQuestionIDs.removeAll()
        incorrectQuestionIDs.removeAll()
        completedPracticalCaseIDs.removeAll()
        quizScores.removeAll()
        saveProgress()
    }

    private func saveProgress() {
        let snapshot = StudyProgressSnapshot(
            completedLessonIDs: Array(completedLessonIDs),
            bookmarkedLessonIDs: Array(bookmarkedLessonIDs),
            attemptedQuestionIDs: Array(attemptedQuestionIDs),
            incorrectQuestionIDs: Array(incorrectQuestionIDs),
            completedPracticalCaseIDs: Array(completedPracticalCaseIDs),
            quizScores: quizScores
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: progressKey)
    }

    private func loadProgress() {
        guard
            let data = UserDefaults.standard.data(forKey: progressKey),
            let snapshot = try? JSONDecoder().decode(StudyProgressSnapshot.self, from: data)
        else {
            return
        }

        completedLessonIDs = Set(snapshot.completedLessonIDs)
        bookmarkedLessonIDs = Set(snapshot.bookmarkedLessonIDs)
        attemptedQuestionIDs = Set(snapshot.attemptedQuestionIDs)
        incorrectQuestionIDs = Set(snapshot.incorrectQuestionIDs)
        completedPracticalCaseIDs = Set(snapshot.completedPracticalCaseIDs)
        quizScores = snapshot.quizScores
    }

    private func loadCachedContent() {
        guard let cachedContent = StudyContentStorage.load() else { return }
        guard isNewerOrEqual(cachedContent.version, than: contentVersion) else { return }
        apply(cachedContent)
    }

    private func apply(_ content: StudyContentBundle) {
        lessons = content.lessons
        questions = content.questions
        practicalCases = content.practicalCases
        contentVersion = content.version
    }

    private func isNewerOrEqual(_ candidate: String, than current: String) -> Bool {
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

        return true
    }
}
