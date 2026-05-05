import SwiftUI

/// Caps content width on iPad / large screens so forms and centered layouts don't
/// stretch edge-to-edge. iPhone is unaffected.
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
