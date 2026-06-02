import SwiftUI

struct CommunityCommentsView: View {
    let post: CommunityPost
    var onCommentAdded: (() -> Void)?

    @StateObject private var viewModel: CommunityCommentsViewModel
    @FocusState private var isInputFocused: Bool
    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    init(post: CommunityPost, onCommentAdded: (() -> Void)? = nil) {
        self.post = post
        self.onCommentAdded = onCommentAdded
        _viewModel = StateObject(wrappedValue: CommunityCommentsViewModel(
            postId: post.id,
            onCommentAdded: onCommentAdded
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("\(viewModel.comments.count)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            Divider()

            if viewModel.isLoading {
                Spacer()
                ProgressView().tint(snuffyPink)
                Spacer()
            } else if viewModel.comments.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(snuffyPink.opacity(0.4))
                    Text("No comments yet. Be the first!")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.comments) { comment in
                            CommentRow(comment: comment, snuffyPink: snuffyPink)
                            Divider().padding(.leading, 56)
                        }
                    }
                    .padding(.bottom, 80)
                }
            }

            // Input bar
            Divider()
            HStack(spacing: 10) {
                TextField("Write a comment…", text: $viewModel.newCommentText, axis: .vertical)
                    .font(.system(size: 14))
                    .lineLimit(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(20)
                    .focused($isInputFocused)

                Button {
                    viewModel.addComment(postId: post.id)
                    isInputFocused = false
                } label: {
                    if viewModel.isPosting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 38, height: 38)
                .background(snuffyPink)
                .clipShape(Circle())
                .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || viewModel.isPosting)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Comment Row
private struct CommentRow: View {
    let comment: CommunityComment
    let snuffyPink: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(snuffyPink)
                Text(comment.userName.prefix(1).uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(comment.timestamp.timeAgoDisplay())
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Text(comment.text)
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
