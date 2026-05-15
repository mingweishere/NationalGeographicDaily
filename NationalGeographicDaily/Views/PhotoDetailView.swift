import SwiftUI
import SwiftData
import Kingfisher

struct PhotoDetailView: View {
    let photo: FavoritePhoto

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    storySection
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    ShareLink(
                        item: URL(string: "https://www.nationalgeographic.com/photo-of-the-day/")!,
                        subject: Text(photo.title),
                        message: Text("via National Geographic Photo of the Day")
                    )
                    .accessibilityLabel("Share photo")
                    .accessibilityHint("Opens the share sheet for this photo and its story")

                    Button {
                        modelContext.delete(photo)
                        dismiss()
                    } label: {
                        Image(systemName: "heart.slash")
                            .foregroundStyle(.red)
                    }
                    .accessibilityLabel("Remove from favorites")
                    .accessibilityHint("Removes this photo from your favorites collection")
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        GeometryReader { proxy in
            let h = proxy.size.height
            ZStack(alignment: .bottom) {
                Group {
                    if let url = photo.imageURL {
                        KFImage(url)
                            .resizable()
                            .placeholder { Rectangle().fill(Color(.systemGray6)) }
                            .fade(duration: 0.3)
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color(.systemGray6))
                            .accessibilityHidden(true)
                    }
                }
                .frame(width: proxy.size.width, height: h)
                .clipped()
                .accessibilityLabel(photo.title)
                .accessibilityAddTraits(.isImage)

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.92)],
                    startPoint: UnitPoint(x: 0.5, y: 0.18),
                    endPoint: .bottom
                )
                .frame(height: h)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("National Geographic")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(photo.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(photo.publicationDate.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .frame(width: proxy.size.width, height: h)
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
    }

    // MARK: - Story

    private var storySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The Story Behind the Photo")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Divider()

            Text(photo.photoDescription.isEmpty
                 ? "Visit nationalgeographic.com to read the full story behind this photo."
                 : photo.photoDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(6)

            Text("Saved \(photo.savedDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
}
