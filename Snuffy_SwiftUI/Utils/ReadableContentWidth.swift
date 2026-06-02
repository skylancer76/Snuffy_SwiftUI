import SwiftUI

struct ReadableContentWidth: ViewModifier {
    var max: CGFloat = 560

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: max)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

extension View {
    func readableContentWidth(_ max: CGFloat = 560) -> some View {
        modifier(ReadableContentWidth(max: max))
    }
}
