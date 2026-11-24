import SwiftUI

struct HomeView: View {
    @Environment(StudyStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    welcomeHeader
                    progressCard
                    contentSyncCard
                    quickActions
                    categorySection
                    featuredLesson
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trang chủ")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vững Tin")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)
            Text("Ôn thi viên chức Tin học")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Mỗi ngày một bước, vững vàng hơn cho vòng thi sắp tới.")
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(.top, 4)
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tiến độ học tập")
                        .font(.headline)
                    Text("Đã hoàn thành \(store.completedLessonCount)/\(store.totalLessonCount) bài học")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(store.learningProgress * 100))%")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.indigo)
            }

            ProgressView(value: store.learningProgress)
                .tint(.indigo)
                .scaleEffect(y: 1.4)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    private var contentSyncCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: store.isContentSyncConfigured ? "arrow.triangle.2.circlepath" : "icloud.slash")
                .font(.title3.weight(.semibold))
                .foregroundStyle(store.isContentSyncConfigured ? .green : .secondary)
                .frame(width: 38, height: 38)
                .background((store.isContentSyncConfigured ? Color.green : Color.secondary).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Nội dung ôn tập")
                    .font(.subheadline.weight(.semibold))
                Text(store.contentSyncMessage ?? (store.isContentSyncConfigured
                    ? "Tự động kiểm tra khi mở app"
                    : "Đang dùng dữ liệu offline phiên bản \(store.contentVersion)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if store.isContentSyncConfigured {
                Button {
                    Task {
                        await store.updateContentIfNeeded()
                    }
                } label: {
                    if store.isCheckingForContent {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(store.isCheckingForContent)
                .accessibilityLabel("Kiểm tra nội dung mới")
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink(destination: StudyLibraryView()) {
                QuickActionCard(title: "Ôn bài", subtitle: "Đọc nội dung", icon: "book.fill", color: .blue)
            }
            .buttonStyle(.plain)

            NavigationLink(destination: MockExamView()) {
                QuickActionCard(title: "Thi thử", subtitle: "Luyện tốc độ", icon: "timer", color: .orange)
            }
            .buttonStyle(.plain)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Chủ đề ôn tập", actionTitle: "Xem tất cả")

            ForEach(StudyCategory.allCases) { category in
                NavigationLink(destination: StudyLibraryView(category: category)) {
                    CategoryRow(
                        category: category,
                        itemCount: category == .practical ? store.practicalCases.count : store.lessons(for: category).count
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredLesson: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Bài học gợi ý")

            if let lesson = store.lessons.first {
                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: lesson.category.icon)
                            .font(.title2)
                            .foregroundStyle(categoryColor(lesson.category))
                            .frame(width: 44, height: 44)
                            .background(categoryColor(lesson.category).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(lesson.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(lesson.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Label("\(lesson.estimatedMinutes) phút", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct StudyLibraryView: View {
    @Environment(StudyStore.self) private var store
    @State private var searchText = ""
    private let category: StudyCategory?

    init(category: StudyCategory? = nil) {
        self.category = category
    }

    private var filteredLessons: [StudyLesson] {
        store.lessons.filter { lesson in
            let matchesCategory = category == nil || lesson.category == category
            let matchesSearch = searchText.isEmpty
                || lesson.title.localizedCaseInsensitiveContains(searchText)
                || lesson.summary.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if category == nil {
                    Section("Chủ đề") {
                        ForEach(StudyCategory.allCases) { item in
                            NavigationLink(destination: StudyLibraryView(category: item)) {
                                CategoryRow(
                                    category: item,
                                    itemCount: item == .practical ? store.practicalCases.count : store.lessons(for: item).count
                                )
                            }
                        }
                    }
                }

                if category == .practical {
                    Section("Tình huống thực hành") {
                        ForEach(store.practicalCases) { practicalCase in
                            NavigationLink(destination: PracticalCaseDetailView(practicalCase: practicalCase)) {
                                PracticalCaseRow(practicalCase: practicalCase)
                            }
                        }
                    }
                } else {
                    Section(category?.displayName ?? "Tất cả bài học") {
                        if filteredLessons.isEmpty {
                            ContentUnavailableView("Không tìm thấy bài học", systemImage: "magnifyingglass", description: Text("Thử từ khóa khác."))
                        } else {
                            ForEach(filteredLessons) { lesson in
                                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                                    LessonRow(lesson: lesson)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(category?.displayName ?? "Ôn tập")
            .searchable(text: $searchText, prompt: "Tìm bài học")
        }
    }
}

struct LessonDetailView: View {
    @Environment(StudyStore.self) private var store
    let lesson: StudyLesson

    private var isCompleted: Bool {
        store.completedLessonIDs.contains(lesson.id)
    }

    private var isBookmarked: Bool {
        store.bookmarkedLessonIDs.contains(lesson.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(lesson.category.displayName, systemImage: lesson.category.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(categoryColor(lesson.category))
                    Text(lesson.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(lesson.summary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Label("Khoảng \(lesson.estimatedMinutes) phút", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(lesson.sections.enumerated()), id: \.element.id) { index, section in
                    LessonSectionCard(number: index + 1, section: section)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Nguồn tham khảo", systemImage: "doc.text")
                        .font(.subheadline.weight(.semibold))
                    Text(lesson.source)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Nội dung cần được đối chiếu với thông báo tuyển dụng chính thức của từng kỳ.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.indigo.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.toggleLessonCompleted(lesson)
                } label: {
                    Label(
                        isCompleted ? "Đánh dấu chưa hoàn thành" : "Đánh dấu đã hoàn thành",
                        systemImage: isCompleted ? "arrow.uturn.backward" : "checkmark.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bài học")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.toggleBookmark(for: lesson)
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(isBookmarked ? "Bỏ lưu bài học" : "Lưu bài học")
            }
        }
    }
}

struct MockExamView: View {
    @Environment(StudyStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    examHeader
                    quizSection
                    practicalSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Thi thử")
        }
    }

    private var examHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Luyện để vững tin")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("Chọn chủ đề để làm nhanh một bộ câu hỏi hoặc luyện trình bày vòng 2.")
                .foregroundStyle(.secondary)
            HStack(spacing: 18) {
                Label("\(store.questions.count) câu hỏi", systemImage: "checklist")
                Label("\(store.practicalCases.count) tình huống", systemImage: "person.fill.questionmark")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.indigo)
        }
    }

    private var quizSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Trắc nghiệm theo chủ đề")

            NavigationLink(destination: QuizView(title: "Đề tổng hợp", questions: Array(store.questions.shuffled().prefix(8)))) {
                ExamActionRow(title: "Đề tổng hợp", subtitle: "8 câu · Có chấm điểm", icon: "sparkles", color: .indigo)
            }
            .buttonStyle(.plain)

            ForEach(StudyCategory.allCases) { category in
                let categoryQuestions = store.questions(for: category)
                NavigationLink(destination: QuizView(title: category.displayName, questions: Array(categoryQuestions.shuffled().prefix(min(6, categoryQuestions.count))))) {
                    ExamActionRow(
                        title: category.displayName,
                        subtitle: "\(categoryQuestions.count) câu · Luyện theo chủ đề",
                        icon: category.icon,
                        color: categoryColor(category)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var practicalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Luyện thực hành vòng 2")

            ForEach(store.practicalCases) { practicalCase in
                NavigationLink(destination: PracticalCaseDetailView(practicalCase: practicalCase)) {
                    PracticalCaseRow(practicalCase: practicalCase)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct QuizView: View {
    @Environment(StudyStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let title: String
    let questions: [QuizQuestion]

    @State private var questionIndex = 0
    @State private var selectedChoiceID: String?
    @State private var showingExplanation = false
    @State private var score = 0
    @State private var finished = false

    private var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(questionIndex) else { return nil }
        return questions[questionIndex]
    }

    var body: some View {
        Group {
            if finished {
                QuizResultView(score: score, total: questions.count, onDismiss: { dismiss() })
            } else if let question = currentQuestion {
                quizContent(question: question)
            } else {
                ContentUnavailableView("Chưa có câu hỏi", systemImage: "questionmark.folder")
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func quizContent(question: QuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Câu \(questionIndex + 1)/\(questions.count)")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(question.difficulty)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.indigo)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.indigo.opacity(0.1))
                        .clipShape(Capsule())
                }

                ProgressView(value: Double(questionIndex + 1), total: Double(max(questions.count, 1)))
                    .tint(.indigo)

                Text(question.prompt)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    ForEach(question.choices) { choice in
                        ChoiceButton(
                            choice: choice,
                            selectedChoiceID: selectedChoiceID,
                            showingAnswer: showingExplanation
                        ) {
                            select(choice, for: question)
                        }
                    }
                }

                if showingExplanation {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Giải thích", systemImage: "lightbulb.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.orange)
                        Text(question.explanation)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Button(questionIndex + 1 == questions.count ? "Xem kết quả" : "Câu tiếp theo") {
                        goToNextQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func select(_ choice: QuizChoice, for question: QuizQuestion) {
        guard !showingExplanation else { return }
        selectedChoiceID = choice.id
        showingExplanation = true
        if choice.isCorrect {
            score += 1
        }
        store.recordAnswer(for: question, choice: choice)
    }

    private func goToNextQuestion() {
        if questionIndex + 1 < questions.count {
            questionIndex += 1
            selectedChoiceID = nil
            showingExplanation = false
        } else {
            let percentage = questions.isEmpty ? 0 : Int((Double(score) / Double(questions.count)) * 100)
            store.recordQuizScore(percentage)
            finished = true
        }
    }
}

struct QuizResultView: View {
    let score: Int
    let total: Int
    let onDismiss: () -> Void

    private var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((Double(score) / Double(total)) * 100)
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: percentage >= 70 ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 68))
                .foregroundStyle(percentage >= 70 ? .green : .orange)

            Text(percentage >= 70 ? "Làm tốt lắm!" : "Tiếp tục cố gắng!")
                .font(.title.weight(.bold))

            Text("Bạn đạt \(score)/\(total) câu đúng")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("\(percentage)%")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.indigo)

            Text("Hãy xem lại câu sai và thử lại sau khi củng cố phần kiến thức còn yếu.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Quay lại danh sách thi thử", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct PracticalCaseDetailView: View {
    @Environment(StudyStore.self) private var store
    let practicalCase: PracticalCase

    private var isCompleted: Bool {
        store.completedPracticalCaseIDs.contains(practicalCase.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(practicalCase.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                InfoBlock(title: "Tình huống", icon: "text.quote", color: .indigo) {
                    Text(practicalCase.scenario)
                }

                InfoBlock(title: "Mục tiêu cần đạt", icon: "target", color: .green) {
                    Text(practicalCase.expectedOutcome)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("Khung chuẩn bị", systemImage: "list.number")
                        .font(.headline)
                    ForEach(Array(practicalCase.preparationSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.indigo)
                                .clipShape(Circle())
                            Text(step)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Label("Câu hỏi phản biện gợi ý", systemImage: "questionmark.bubble")
                        .font(.headline)
                    ForEach(practicalCase.followUpQuestions, id: \.self) { question in
                        Text("• \(question)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.markPracticalCaseCompleted(practicalCase)
                } label: {
                    Label(
                        isCompleted ? "Đã đánh dấu đã luyện" : "Đánh dấu đã luyện",
                        systemImage: isCompleted ? "checkmark.circle.fill" : "circle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Luyện vòng 2")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProgressDashboardView: View {
    @Environment(StudyStore.self) private var store
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Theo dõi tiến độ")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Nhìn lại quá trình học để chọn phần cần ưu tiên.")
                            .foregroundStyle(.secondary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Bài đã học", value: "\(store.completedLessonCount)/\(store.totalLessonCount)", icon: "book.fill", color: .blue)
                        MetricCard(title: "Câu đã làm", value: "\(store.attemptedQuestionIDs.count)", icon: "checklist", color: .purple)
                        MetricCard(title: "Câu sai", value: "\(store.incorrectQuestionIDs.count)", icon: "exclamationmark.triangle.fill", color: .orange)
                        MetricCard(title: "Điểm TB", value: "\(store.averageQuizScore)%", icon: "chart.bar.fill", color: .green)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Theo chủ đề")
                            .font(.headline)
                        ForEach(StudyCategory.allCases) { category in
                            CategoryProgressRow(
                                category: category,
                                completed: store.lessons(for: category).filter { store.completedLessonIDs.contains($0.id) }.count,
                                total: store.lessons(for: category).count
                            )
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    if !store.incorrectQuestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Câu hỏi cần ôn lại", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                            Text("Bạn có \(store.incorrectQuestions.count) câu trả lời sai đang chờ củng cố.")
                                .foregroundStyle(.secondary)
                            NavigationLink(destination: SavedContentView(initialTab: .incorrect)) {
                                Text("Mở danh sách câu sai")
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Xóa toàn bộ tiến độ", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tiến độ")
            .alert("Xóa tiến độ?", isPresented: $showingResetAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    store.resetProgress()
                }
            } message: {
                Text("Các bài đã hoàn thành, bookmark và điểm thi thử sẽ được xóa khỏi thiết bị.")
            }
        }
    }
}

struct SavedContentView: View {
    enum SavedTab: String, CaseIterable, Identifiable {
        case bookmarked = "Đã lưu"
        case incorrect = "Câu sai"

        var id: String { rawValue }
    }

    @Environment(StudyStore.self) private var store
    @State private var selectedTab: SavedTab

    init(initialTab: SavedTab = .bookmarked) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Danh sách", selection: $selectedTab) {
                    ForEach(SavedTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                List {
                    switch selectedTab {
                    case .bookmarked:
                        if store.bookmarkedLessons.isEmpty {
                            ContentUnavailableView("Chưa có bài lưu", systemImage: "bookmark", description: Text("Nhấn biểu tượng bookmark trong bài học để lưu lại."))
                        } else {
                            ForEach(store.bookmarkedLessons) { lesson in
                                NavigationLink(destination: LessonDetailView(lesson: lesson)) {
                                    LessonRow(lesson: lesson)
                                }
                            }
                        }
                    case .incorrect:
                        if store.incorrectQuestions.isEmpty {
                            ContentUnavailableView("Chưa có câu sai", systemImage: "checkmark.circle", description: Text("Các câu trả lời sai sẽ xuất hiện ở đây."))
                        } else {
                            ForEach(store.incorrectQuestions) { question in
                                QuestionReviewRow(question: question)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Đã lưu")
        }
    }
}

private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SectionTitle: View {
    let title: String
    var actionTitle: String?

    init(title: String, actionTitle: String? = nil) {
        self.title = title
        self.actionTitle = actionTitle
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            if let actionTitle {
                Text(actionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }
        }
    }
}

private struct CategoryRow: View {
    let category: StudyCategory
    let itemCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.headline)
                .foregroundStyle(categoryColor(category))
                .frame(width: 42, height: 42)
                .background(categoryColor(category).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(itemCount) \(category == .practical ? "tình huống" : "bài học") · \(category.shortDescription)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
    }
}

private struct LessonRow: View {
    @Environment(StudyStore.self) private var store
    let lesson: StudyLesson

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: lesson.category.icon)
                .foregroundStyle(categoryColor(lesson.category))
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.subheadline.weight(.semibold))
                Text(lesson.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 10) {
                    Label("\(lesson.estimatedMinutes) phút", systemImage: "clock")
                    if store.completedLessonIDs.contains(lesson.id) {
                        Label("Đã học", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LessonSectionCard: View {
    let number: Int
    let section: LessonSection

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.indigo)
                    .clipShape(Circle())
                Text(section.title)
                    .font(.headline)
            }

            Text(section.body)
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.keyPoints, id: \.self) { point in
                    Label(point, systemImage: "checkmark")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ExamActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PracticalCaseRow: View {
    @Environment(StudyStore.self) private var store
    let practicalCase: PracticalCase

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "rectangle.and.pencil.and.ellipsis")
                .foregroundStyle(.green)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading, spacing: 5) {
                Text(practicalCase.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(practicalCase.scenario)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if store.completedPracticalCaseIDs.contains(practicalCase.id) {
                    Label("Đã luyện", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ChoiceButton: View {
    let choice: QuizChoice
    let selectedChoiceID: String?
    let showingAnswer: Bool
    let action: () -> Void

    private var isSelected: Bool { selectedChoiceID == choice.id }

    private var borderColor: Color {
        guard showingAnswer else { return isSelected ? .indigo : Color.gray.opacity(0.25) }
        if choice.isCorrect { return .green }
        if isSelected { return .red }
        return Color.gray.opacity(0.2)
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: markerIcon)
                    .foregroundStyle(markerColor)
                Text(choice.text)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected || (showingAnswer && choice.isCorrect) ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(showingAnswer)
    }

    private var markerIcon: String {
        if showingAnswer && choice.isCorrect { return "checkmark.circle.fill" }
        if showingAnswer && isSelected { return "xmark.circle.fill" }
        return isSelected ? "largecircle.fill.circle" : "circle"
    }

    private var markerColor: Color {
        if showingAnswer && choice.isCorrect { return .green }
        if showingAnswer && isSelected { return .red }
        return isSelected ? .indigo : .secondary
    }

    private var backgroundColor: Color {
        if showingAnswer && choice.isCorrect { return Color.green.opacity(0.1) }
        if showingAnswer && isSelected { return Color.red.opacity(0.1) }
        return isSelected ? Color.indigo.opacity(0.08) : Color(.systemBackground)
    }
}

private struct InfoBlock<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CategoryProgressRow: View {
    let category: StudyCategory
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Label(category.displayName, systemImage: category.icon)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(categoryColor(category))
        }
    }
}

private struct QuestionReviewRow: View {
    let question: QuizQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(question.prompt)
                .font(.subheadline.weight(.semibold))
            Text(question.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Text(question.category.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.indigo)
        }
        .padding(.vertical, 4)
    }
}

private func categoryColor(_ category: StudyCategory) -> Color {
    switch category {
    case .general:
        return .blue
    case .pedagogy:
        return .orange
    case .informatics:
        return .purple
    case .practical:
        return .green
    }
}
