import SwiftUI
import Kingfisher

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            contentLayer
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadPhoto() }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var contentLayer: some View {
        if let entry = viewModel.photoEntry {
            photoScrollView(entry)
        } else if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.4)
        } else if let err = viewModel.error {
            errorView(err)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.4)
        }
    }

    // MARK: - Photo scroll layout

    private func photoScrollView(_ entry: PhotoEntry) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection(entry)
                storySection(entry)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollIndicators(.hidden)
    }

    // MARK: - Hero image

    private func heroSection(_ entry: PhotoEntry) -> some View {
        ZStack(alignment: .bottom) {
            heroImage(entry)
            heroGradient
            heroOverlay(entry)
        }
        .frame(height: 520)
    }

    private func heroImage(_ entry: PhotoEntry) -> some View {
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
            .frame(height: 520)
            .clipped()
            .accessibilityLabel(entry.title)
            .accessibilityAddTraits(.isImage)
    }

    private var heroGradient: some View {
        LinearGradient(
            colors: [.clear, Color.black.opacity(0.9)],
            startPoint: UnitPoint(x: 0.5, y: 0.25),
            endPoint: .bottom
        )
        .frame(height: 520)
        .allowsHitTesting(false)
    }

    private func heroOverlay(_ entry: PhotoEntry) -> some View {
        HStack(alignment: .bottom, spacing: 16) {
            titleBlock(entry)
            Spacer(minLength: 12)
            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private func titleBlock(_ entry: PhotoEntry) -> some View {
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
                .lineLimit(3)

            Text(entry.publicationDate.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 18) {
            Button {
                // Wired in Step 4 — favorites
            } label: {
                Image(systemName: "heart")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Add to favorites")
            .accessibilityHint("Saves this photo to your favorites collection")

            Button {
                // Wired in Step 5 — share sheet
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Share photo")
            .accessibilityHint("Opens the share sheet for this photo and its story")
        }
    }

    // MARK: - Story card

    private func storySection(_ entry: PhotoEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 16) {
                Text("The Story Behind the Photo")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(entry.description.isEmpty ? "No description available for this photo." : entry.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(6)
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Error state

    private func errorView(_ error: AppError) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.5))

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
