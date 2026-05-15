import SwiftUI
import SwiftData
import Kingfisher

struct FavoritesView: View {
    @Query(sort: \FavoritePhoto.savedDate, order: .reverse)
    private var favorites: [FavoritePhoto]

    @State private var viewerPhoto: PhotoEntry?

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        Group {
            if favorites.isEmpty {
                emptyState
            } else {
                gallery
            }
        }
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
        .fullScreenCover(item: $viewerPhoto) { entry in
            ImmersiveViewerView(entry: entry)
        }
    }

    // MARK: - Gallery

    private var gallery: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(favorites) { photo in
                    NavigationLink {
                        PhotoDetailView(photo: photo)
                    } label: {
                        FavoriteCell(photo: photo)
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            viewerPhoto = photo.asPhotoEntry
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .padding(6)
                        .accessibilityLabel("View \(photo.title) full screen")
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("No Favorites Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Tap the heart on today's photo to save it here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grid cell

struct FavoriteCell: View {
    let photo: FavoritePhoto

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = photo.imageURL {
                KFImage(url)
                    .resizable()
                    .placeholder {
                        Rectangle().fill(Color(.systemGray5))
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
            }

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(photo.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(8)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .accessibilityLabel(photo.title)
        .accessibilityHint("Opens full detail view")
    }
}
