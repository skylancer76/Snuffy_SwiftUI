import SwiftUI

struct ArticleReaderView: View {
    let article: CaregiverArticle
    @Environment(\.dismiss) private var dismiss

    private let snuffyPink = Color(red: 1.0, green: 0.4, blue: 0.6)

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [snuffyPink.opacity(0.4), Color(UIColor.systemGray6)],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(article.iconColor.opacity(0.18))
                            .frame(width: 110, height: 110)
                        Image(systemName: article.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(article.iconColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 70)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(article.category)
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(article.iconColor)

                        Text(article.title)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(article.readTime)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)

                    articleBody
                        .padding(.horizontal, 24)
                        .padding(.bottom, 60)
                }
            }

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
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .navigationBarHidden(true)
    }

    // Render the body with very simple paragraph + **bold** support so the article
    // model can keep its content as a plain string.
    private var articleBody: some View {
        let paragraphs = article.body.components(separatedBy: "\n\n")
        return VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, para in
                paragraphView(para)
            }
        }
    }

    @ViewBuilder
    private func paragraphView(_ text: String) -> some View {
        if text.hasPrefix("**") && text.hasSuffix("**") {
            // Standalone bold paragraph = sub-heading
            let stripped = String(text.dropFirst(2).dropLast(2))
            Text(stripped)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
        } else if let attr = try? AttributedString(markdown: text) {
            Text(attr)
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
