import SwiftUI

struct StoryExplainerView: View {
    let title: String
    let story: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedLevel: ReadingLevel = .standard
    @State private var generatedText: String?
    @State private var isLoading = true   // show spinner immediately on open
    @State private var errorMessage: String?
    @State private var currentTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Reading Level", selection: $selectedLevel) {
                    ForEach(ReadingLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()

                ScrollView {
                    contentArea
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Deeper Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { startFetch() }
        .onChange(of: selectedLevel) { _, _ in startFetch() }
        .onDisappear { currentTask?.cancel() }
    }

    // MARK: - Content states

    @ViewBuilder
    private var contentArea: some View {
        if isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Generating deeper story…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Generating deeper story")
        } else if let message = errorMessage {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)

                Button {
                    startFetch()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Retry generating story")
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        } else if let text = generatedText {
            Text(text)
                .font(.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Fetch

    private func startFetch() {
        currentTask?.cancel()
        withAnimation(.easeInOut(duration: 0.15)) {
            isLoading = true
            errorMessage = nil
            generatedText = nil
        }

        currentTask = Task {
            do {
                let text = try await StoryExplainerService.shared.explain(
                    story: story,
                    title: title,
                    level: selectedLevel
                )
                guard !Task.isCancelled else { return }
                withAnimation {
                    generatedText = text
                    isLoading = false
                }
            } catch is CancellationError {
                // Intentionally cancelled — leave UI as-is
            } catch let appError as AppError {
                guard !Task.isCancelled else { return }
                withAnimation {
                    errorMessage = appError.errorDescription ?? "Something went wrong."
                    isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                withAnimation {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    StoryExplainerView(
        title: "Among the Stars",
        story: "Dragonflies in the night sky near the Orinoco River in Puerto Carreño, Colombia."
    )
}
