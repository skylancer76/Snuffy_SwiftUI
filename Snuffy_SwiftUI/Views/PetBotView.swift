//
//  PetBotView.swift
//  Snuffy_SwiftUI
//  Created by Bhumika Sharma

import SwiftUI
import Combine
import PhotosUI
import UIKit

struct PetBotView: View {
    @StateObject private var vm = PetBotViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var isInputFocused: Bool
    @State private var scrollAnchor = ""

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Custom header (matches booking-info / caretaker-profile)
            customHeader
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // MARK: - Chat messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 8) {

                        if vm.isLoadingData {
                            loadingDataBanner
                        }

                        ForEach(vm.messages) { msg in
                            ChatBubbleView(message: msg, snuffyPink: snuffyPink)
                                .id(msg.id)
                        }

                        if vm.isThinking {
                            TypingBubbleView(snuffyPink: snuffyPink)
                                .id("TYPING")
                        }

                        // Invisible anchor at bottom
                        Color.clear.frame(height: 1).id("BOTTOM")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
                .onChange(of: vm.isThinking) { _, thinking in
                    if thinking {
                        withAnimation { proxy.scrollTo("TYPING", anchor: .bottom) }
                    }
                }
                .onAppear {
                    proxy.scrollTo("BOTTOM", anchor: .bottom)
                }
            }

            // MARK: - Input bar
            inputBar
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }

    // MARK: - Custom header

    /// Floating back chevron + centered Snuffy-Bot badge, matching the
    /// header pattern used by BookingsInfo / CaretakerProfile screens.
    private var customHeader: some View {
        ZStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                Spacer()
            }

            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(snuffyPink).frame(width: 28, height: 28)
                    HStack(spacing: -3) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(-15))
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(15))
                    }
                }
                Text("Snuffy Bot")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
    }

    // MARK: - Loading banner

    private var loadingDataBanner: some View {
        HStack(spacing: 8) {
            ProgressView().tint(snuffyPink).scaleEffect(0.8)
            Text("Loading your pet profiles…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Input bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            // Image preview strip
            if let img = selectedImage {
                HStack(spacing: 10) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(snuffyPink.opacity(0.4), lineWidth: 1)
                        )
                    Button {
                        selectedImage = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
            }

            HStack(spacing: 8) {
                // Photo picker
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundStyle(snuffyPink)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .onChange(of: photoItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            selectedImage = img
                        }
                    }
                }

                TextField("Ask about your pet…", text: $inputText, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.system(size: 16))
                    .focused($isInputFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Button {
                    let text = inputText
                    let img  = selectedImage
                    inputText     = ""
                    selectedImage = nil
                    photoItem     = nil
                    Task { await vm.send(text, image: img) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(canSend ? snuffyPink : Color(uiColor: .tertiaryLabel))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .animation(.easeInOut(duration: 0.15), value: canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .overlay(Divider(), alignment: .top)
    }

    private var canSend: Bool {
        let hasText = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return (hasText || selectedImage != nil) && !vm.isThinking && !vm.isLoadingData
    }
}

// MARK: - Chat Bubble

struct ChatBubbleView: View {
    let message: PetBotMessage
    let snuffyPink: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                ZStack {
                    Circle().fill(snuffyPink).frame(width: 28, height: 28)
                    HStack(spacing: -2) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 6, weight: .bold)).foregroundColor(.white)
                            .rotationEffect(.degrees(-15))
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                            .rotationEffect(.degrees(15))
                    }
                }
                .alignmentGuide(.bottom) { d in d[.bottom] }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Attached image
                if let data = message.imageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                // Text bubble (skip if empty)
                if !message.text.isEmpty {
                    bubbleContent
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.isUser
                            ? snuffyPink
                            : Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .clipShape(BubbleShape(isUser: message.isUser))
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .textSelection(.enabled)
                }
            }

            if !message.isUser { Spacer(minLength: 48) }
        }
        .padding(.vertical, 2)
    }

    /// Render bot replies as markdown (bold/italic/code/links + bullets), and
    /// keep user messages as plain text (we never want their input
    /// accidentally interpreted).
    @ViewBuilder
    private var bubbleContent: some View {
        if message.isUser {
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
        } else {
            MarkdownMessageView(raw: message.text)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Markdown rendering

/// Lightweight markdown renderer tuned for the chat surface.
/// Splits the bot reply into blocks (paragraphs + bullet lists) and renders
/// each block as an `AttributedString` so inline markdown (`**bold**`,
/// `*italic*`, `` `code` ``, links) lights up while bullets become real
/// bullet rows instead of literal `*` characters.
struct MarkdownMessageView: View {
    let raw: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let str):
                    Text(attributed(str))
                        .fixedSize(horizontal: false, vertical: true)
                case .bulletList(let items):
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("•")
                                Text(attributed(item))
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
            }
        }
    }

    private enum Block { case paragraph(String); case bulletList([String]) }

    private var blocks: [Block] {
        let lines = raw.replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")

        var out: [Block] = []
        var paragraphBuf: [String] = []
        var bulletBuf: [String] = []

        func flushParagraph() {
            let joined = paragraphBuf.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty { out.append(.paragraph(joined)) }
            paragraphBuf.removeAll()
        }
        func flushBullets() {
            if !bulletBuf.isEmpty { out.append(.bulletList(bulletBuf)) }
            bulletBuf.removeAll()
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                flushParagraph(); flushBullets()
                continue
            }
            if let item = bulletItem(from: trimmed) {
                flushParagraph()
                bulletBuf.append(item)
            } else {
                flushBullets()
                paragraphBuf.append(trimmed)
            }
        }
        flushParagraph(); flushBullets()
        return out
    }

    /// Strip the leading `*`/`-`/`•` bullet marker (and an optional second
    /// `*` from `* **bold:**` patterns the model emits) and return the
    /// remaining text. Returns `nil` if the line isn't a bullet.
    private func bulletItem(from line: String) -> String? {
        guard let first = line.first, "*-•".contains(first) else { return nil }
        var rest = line.dropFirst()
        // Require whitespace after the marker so we don't munch `**bold**`.
        guard let next = rest.first, next == " " || next == "\t" else { return nil }
        rest = rest.drop(while: { $0 == " " || $0 == "\t" })
        return String(rest)
    }

    private func attributed(_ s: String) -> AttributedString {
        var opts = AttributedString.MarkdownParsingOptions()
        opts.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: s, options: opts))
            ?? AttributedString(s)
    }
}

// MARK: - Typing indicator bubble

struct TypingBubbleView: View {
    let snuffyPink: Color
    @State private var phase = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle().fill(snuffyPink).frame(width: 28, height: 28)
                HStack(spacing: -2) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 6, weight: .bold)).foregroundColor(.white)
                        .rotationEffect(.degrees(-15))
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 8, weight: .bold)).foregroundColor(.white)
                        .rotationEffect(.degrees(15))
                }
            }

            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.35 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(BubbleShape(isUser: false))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)

            Spacer(minLength: 48)
        }
        .padding(.vertical, 2)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                Task { @MainActor in phase = (phase + 1) % 3 }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - Bubble shape

struct BubbleShape: Shape {
    let isUser: Bool
    private let r: CGFloat = 18
    private let tail: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        if isUser {
            // Rounded left side, tail at bottom-right
            p.move(to: CGPoint(x: w - tail, y: h))
            p.addLine(to: CGPoint(x: r, y: h))
            p.addArc(center: CGPoint(x: r, y: h - r), radius: r,
                     startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            p.addLine(to: CGPoint(x: 0, y: r))
            p.addArc(center: CGPoint(x: r, y: r), radius: r,
                     startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            p.addLine(to: CGPoint(x: w - r, y: 0))
            p.addArc(center: CGPoint(x: w - r, y: r), radius: r,
                     startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: w, y: h - tail))
            p.addQuadCurve(to: CGPoint(x: w - tail, y: h),
                           control: CGPoint(x: w, y: h))
        } else {
            // Tail at bottom-left
            p.move(to: CGPoint(x: tail, y: h))
            p.addQuadCurve(to: CGPoint(x: 0, y: h - tail),
                           control: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: r))
            p.addArc(center: CGPoint(x: r, y: r), radius: r,
                     startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            p.addLine(to: CGPoint(x: w - r, y: 0))
            p.addArc(center: CGPoint(x: w - r, y: r), radius: r,
                     startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
            p.addLine(to: CGPoint(x: w, y: h - r))
            p.addArc(center: CGPoint(x: w - r, y: h - r), radius: r,
                     startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            p.addLine(to: CGPoint(x: tail, y: h))
        }
        p.closeSubpath()
        return p
    }
}
