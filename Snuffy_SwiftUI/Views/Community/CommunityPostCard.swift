import SwiftUI
import AVKit

struct CommunityPostCard: View {
    let post: CommunityPost
    var onLike: () -> Void
    var onComment: () -> Void

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header (Avatar + Name + Handle)
            HStack(spacing: 12) {
                authorAvatar
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    let handle = "@\(post.userName.lowercased().replacingOccurrences(of: " ", with: "_"))"
                    Text(handle)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // MARK: - Media Container
            Group {
                if post.mediaType == .image, let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color(red: 1.0, green: 0.9, blue: 0.93)
                                ProgressView().tint(snuffyPink)
                            }
                        case .success(let image):
                            Color.clear
                                .overlay(
                                    image.resizable().scaledToFill()
                                )
                                .clipped()
                        case .failure:
                            ZStack {
                                Color(red: 1.0, green: 0.9, blue: 0.93)
                                Image(systemName: "photo").font(.largeTitle).foregroundColor(snuffyPink)
                            }
                        @unknown default: EmptyView()
                        }
                    }
                } else if post.mediaType == .video, let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                    VideoPlayer(player: AVPlayer(url: url))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: post.mediaURL != nil ? 320 : 0) // Collapse if no media
            .clipped()
            .cornerRadius(20)
            .padding(.horizontal, 16)

            // MARK: - Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(3)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            } else {
                Spacer().frame(height: 16)
            }

            // MARK: - Action Bar (like · comment · share)
            HStack(spacing: 24) {
                // Like
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(post.isLikedByCurrentUser ? snuffyPink : .black)
                            .scaleEffect(post.isLikedByCurrentUser ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: post.isLikedByCurrentUser)
                        Text("\(post.likesCount)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)

                // Comment
                Button(action: onComment) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(.black)
                        Text("\(post.commentsCount)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(.plain)

                // Share
                Button {
                    sharePost()
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: snuffyPink.opacity(0.15), radius: 15, x: 0, y: 8)
    }

    // MARK: - Author Avatar
    @ViewBuilder
    private var authorAvatar: some View {
        ZStack {
            if let urlStr = post.authorAvatarURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                            .frame(width: 44, height: 44).clipShape(Circle())
                    } else {
                        initialsCircle
                    }
                }
            } else {
                initialsCircle
            }
        }
        .overlay(
            Circle()
                .stroke(snuffyPink, lineWidth: 2)
                .frame(width: 50, height: 50)
        )
        .padding(3) // Padding to account for the stroke ring
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(snuffyPink)
            Text(post.userName.prefix(1).uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
    }

    // MARK: - Share Sheet
    private func sharePost() {
        let text = "Check out this post on Snuffy: \(post.caption)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let seconds = -timeIntervalSinceNow
        if seconds < 60       { return "Just now" }
        if seconds < 3600     { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400    { return "\(Int(seconds / 3600))h ago" }
        if seconds < 604800   { return "\(Int(seconds / 86400))d ago" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: self)
    }
}
