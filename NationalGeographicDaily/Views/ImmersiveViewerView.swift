import SwiftUI
import Kingfisher

struct ImmersiveViewerView: View {
    let entry: PhotoEntry
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragOffset: CGFloat = 0
    @State private var showChrome = true
    @State private var showMetadata = false
    @State private var isMagnifying = false
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            imageLayer
            metadataPanelLayer
            if showChrome { chromeLayer }
        }
        .statusBarHidden(true)
        .ignoresSafeArea()
        .onAppear { scheduleHideChrome() }
        .onDisappear { hideTask?.cancel() }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        Color.black
            .opacity(max(0.3, 1.0 - dragOffset / 300 * 0.7))
            .ignoresSafeArea()
    }

    // MARK: - Image

    private var imageLayer: some View {
        KFImage(entry.imageURL)
            .resizable()
            .placeholder {
                ProgressView().tint(.white)
            }
            .cancelOnDisappear(true)
            .scaledToFit()
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height + dragOffset)
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .highPriorityGesture(TapGesture(count: 2).onEnded { handleDoubleTap() })
            .onTapGesture { handleSingleTap() }
            .accessibilityLabel(entry.title)
            .accessibilityAddTraits(.isImage)
    }

    // MARK: - Chrome

    private var chromeLayer: some View {
        ZStack {
            // Top bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .accessibilityLabel("Close")

                    Spacer()

                    ShareLink(
                        item: entry.imageURL,
                        subject: Text(entry.title),
                        message: Text("via National Geographic Photo of the Day")
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .accessibilityLabel("Share photo")
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
                Spacer()
            }

            // Bottom bar — hidden when metadata panel is open
            if !showMetadata {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showMetadata = true
                            }
                            resetHideChrome()
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                        .accessibilityLabel("Show photo info")
                        .padding(.trailing, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.25)))
    }

    // MARK: - Metadata panel

    private var metadataPanelLayer: some View {
        VStack(spacing: 0) {
            Spacer()
            metadataPanel
        }
        .offset(y: showMetadata ? 0 : 280)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showMetadata)
    }

    private var metadataPanel: some View {
        let photographer = MetadataParser.extractPhotographer(from: entry.description)
        let location = MetadataParser.extractLocation(from: entry.description)
        let camera = MetadataParser.extractCamera(from: entry.description)

        return VStack(alignment: .leading, spacing: 0) {
            // Drag handle
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 36, height: 4)
                Spacer()
            }
            .padding(.top, 12)
            .padding(.bottom, 16)

            // Dismiss tapping the handle area
            Group {
                metadataRow(icon: "camera", label: "Camera", value: camera)
                metadataRow(icon: "person", label: "Photographer", value: photographer)
                metadataRow(icon: "mappin", label: "Location", value: location)
                metadataRow(icon: "calendar", label: "Date",
                            value: entry.publicationDate.formatted(date: .long, time: .omitted))
                metadataRow(icon: "photo", label: "Resolution", value: "—")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20
            )
            .fill(.ultraThinMaterial)
        )
        .onTapGesture { /* absorb taps so image gesture doesn't fire through panel */ }
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                isMagnifying = true
                resetHideChrome()
                scale = min(max(lastScale * value, 1.0), 5.0)
            }
            .onEnded { _ in
                lastScale = scale
                if scale < 1.05 {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                isMagnifying = false
                scheduleHideChrome()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isMagnifying else { return }
                resetHideChrome()
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                } else {
                    dragOffset = max(0, value.translation.height)
                }
            }
            .onEnded { value in
                guard !isMagnifying else { return }
                if scale > 1.0 {
                    lastOffset = offset
                } else {
                    let velocity = value.velocity.height
                    if dragOffset > 120 || velocity > 800 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
                scheduleHideChrome()
            }
    }

    // MARK: - Tap handlers

    private func handleDoubleTap() {
        resetHideChrome()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            if scale > 1.0 {
                scale = 1.0
                lastScale = 1.0
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.5
                lastScale = 2.5
            }
        }
        scheduleHideChrome()
    }

    private func handleSingleTap() {
        if showMetadata {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showMetadata = false
            }
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            showChrome.toggle()
        }
        if showChrome { scheduleHideChrome() }
    }

    // MARK: - Chrome auto-hide

    private func scheduleHideChrome() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, !showMetadata else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                showChrome = false
            }
        }
    }

    private func resetHideChrome() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showChrome = true
        }
        scheduleHideChrome()
    }
}

#Preview {
    ImmersiveViewerView(
        entry: PhotoEntry(
            id: "preview",
            title: "Among the Stars",
            publicationDate: Date(),
            imageURL: URL(string: "https://i.natgeofe.com/n/4f5aaece-3300-41a4-b2a8-ed2708a0a27c/domestic-dog_thumb_4x3.jpg")!,
            description: "Photograph by Jane Smith. Taken near Mount Everest with a Canon EOS R5."
        )
    )
}
