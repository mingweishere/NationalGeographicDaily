import SwiftUI
import SwiftData
import Kingfisher

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var isFavorited = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            contentLayer
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadPhoto() }
        // Re-check favorite status whenever the displayed photo changes
        .task(id: viewModel.photoEntry?.id) {
            guard let entry = viewModel.photoEntry else { return }
            checkFavoriteStatus(for: entry)
        }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var contentLayer: some View {
        if let entry = viewModel.photoEntry {
            GeometryReader { geo in
                let heroH = max(360, geo.size.height * 0.60)
                ScrollView {
                    VStack(spacing: 0) {
                        heroSection(entry, height: heroH)
                        storySection(entry)
                    }
                }
                .ignoresSafeArea(edges: .top)
                .scrollIndicators(.hidden)
                .refreshable { await viewModel.loadPhoto() }
            }
        } else if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.4)
                .accessibilityLabel("Loading today's photo")
        } else if let err = viewModel.error {
            errorView(err)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.4)
                .accessibilityLabel("Loading today's photo")
        }
    }

    // MARK: - Hero image

    private func heroSection(_ entry: PhotoEntry, height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            heroImage(entry, height: height)
            heroScrim(height: height)
            heroOverlay(entry)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
        }
        .frame(height: height)
    }

    private func heroImage(_ entry: PhotoEntry, height: CGFloat) -> some View {
        KFImage(entry.imageURL)
            .resizable()
            .placeholder {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .overlay(ProgressView().tint(.white))
            }
            .fade(duration: 0.3)
            .cancelOnDisappear(true)
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .accessibilityLabel(entry.title)
            .accessibilityAddTraits(.isImage)
    }

    private func heroScrim(height: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, Color.black.opacity(0.92)],
            startPoint: UnitPoint(x: 0.5, y: 0.18),
            endPoint: .bottom
        )
        .frame(height: height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func heroOverlay(_ entry: PhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Photo of the Day")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(entry.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(entry.publicationDate.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            // Action buttons sit left-aligned below the title block
            actionButtons(for: entry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action buttons

    private func actionButtons(for entry: PhotoEntry) -> some View {
        HStack(spacing: 12) {
            overlayButton(
                systemImage: isFavorited ? "heart.fill" : "heart",
                tint: isFavorited ? .red : .white
            ) {
                toggleFavorite(for: entry)
            }
            .symbolEffect(.bounce, value: isFavorited)
            .accessibilityLabel(isFavorited ? "Remove from favorites" : "Add to favorites")
            .accessibilityHint(isFavorited
                ? "Removes this photo from your favorites collection"
                : "Saves this photo to your favorites collection")

            ShareLink(
                item: URL(string: "https://www.nationalgeographic.com/photo-of-the-day/")!,
                subject: Text(entry.title),
                message: Text("via National Geographic Photo of the Day")
            ) {
                overlayIconLabel(systemImage: "square.and.arrow.up", tint: .white)
            }
            .accessibilityLabel("Share photo")
            .accessibilityHint("Opens the share sheet for this photo and its story")
        }
    }

    // Circular frosted-glass badge — used as label for both Button and ShareLink.
    private func overlayIconLabel(systemImage: String, tint: Color) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
            )
    }

    private func overlayButton(
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            overlayIconLabel(systemImage: systemImage, tint: tint)
        }
    }

    // MARK: - Favorites logic

    private func checkFavoriteStatus(for entry: PhotoEntry) {
        let id = entry.id
        let descriptor = FetchDescriptor<FavoritePhoto>(
            predicate: #Predicate { $0.id == id }
        )
        isFavorited = ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    private func toggleFavorite(for entry: PhotoEntry) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let id = entry.id
        if isFavorited {
            let descriptor = FetchDescriptor<FavoritePhoto>(
                predicate: #Predicate { $0.id == id }
            )
            if let matches = try? modelContext.fetch(descriptor) {
                matches.forEach { modelContext.delete($0) }
            }
        } else {
            modelContext.insert(FavoritePhoto(from: entry))
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isFavorited.toggle()
        }
    }

    // MARK: - Story card

    private func storySection(_ entry: PhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The Story Behind the Photo")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Divider()

            Text(entry.description.isEmpty
                 ? "Visit nationalgeographic.com to read the full story behind today's photo."
                 : entry.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }

    // MARK: - Error state

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 24) {
            Image(systemName: error == .networkUnavailable
                  ? "antenna.radiowaves.left.and.right.slash"
                  : "exclamationmark.triangle")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.5))
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Couldn't Load Photo")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button("Try Again") {
                Task { await viewModel.loadPhoto() }
            }
            .buttonStyle(.bordered)
            .tint(.yellow)
            .accessibilityLabel("Try again")
            .accessibilityHint("Retries loading today's photo of the day")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .preferredColorScheme(.dark)
}
