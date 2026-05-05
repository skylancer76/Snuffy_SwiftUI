import UIKit

extension UIApplication {
    private static var dismissKeyboardGestureInstalled = false

    func installDismissKeyboardOnTap() {
        guard !UIApplication.dismissKeyboardGestureInstalled else { return }
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }

        let tap = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        tap.requiresExclusiveTouchType = false
        window.addGestureRecognizer(tap)
        UIApplication.dismissKeyboardGestureInstalled = true
    }
}
