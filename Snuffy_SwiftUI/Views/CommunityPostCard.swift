//
//  CommunityPostCard.swift
//  Snuffy_SwiftUI
//
//  Created by Bhumika Sharma on 30/03/26.
//

import SwiftUI
import AVKit

struct CommunityPostCard: View {
    let post: CommunityPost
    var onLike: () -> Void
    var onComment: () -> Void

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header (avatar + name + time)
            HStack(spacing: 10) {
                authorAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                    Text(post.timestamp.timeAgoDisplay())
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // MARK: - Media
            if post.mediaType == .image, let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color(red: 1.0, green: 0.9, blue: 0.93)
                            ProgressView().tint(snuffyPink)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    case .failure:
                        ZStack {
                            Color(red: 1.0, green: 0.9, blue: 0.93)
                            Image(systemName: "photo").font(.largeTitle).foregroundColor(snuffyPink)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                    @unknown default: EmptyView()
                    }
                }
            } else if post.mediaType == .video, let urlStr = post.mediaURL, let url = URL(string: urlStr) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
            }

            // MARK: - Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.85))
                    .lineLimit(4)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
            }

            // MARK: - Action Bar (like · comment · share)
            HStack(spacing: 20) {
                // Like
                Button(action: onLike) {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(post.isLikedByCurrentUser ? snuffyPink : .gray)
                            .scaleEffect(post.isLikedByCurrentUser ? 1.15 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: post.isLikedByCurrentUser)
                        Text("\(post.likesCount)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)

                // Comment
                Button(action: onComment) {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        Text("\(post.commentsCount)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Share
                Button {
                    sharePost()
                } label: {
                    Image(systemName: "paperplane")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }

    // MARK: - Author Avatar
    @ViewBuilder
    private var authorAvatar: some View {
        if let urlStr = post.authorAvatarURL, let url = URL(string: urlStr) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                        .frame(width: 38, height: 38).clipShape(Circle())
                } else {
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        ZStack {
            Circle().fill(snuffyPink)
            Text(post.userName.prefix(1).uppercased())
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 38, height: 38)
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
