import SwiftUI

@available(iOS 17.0, *)
extension TextView {
    struct Representable: UIViewRepresentable, Equatable {
        static func == (lhs: TextView.Representable, rhs: TextView.Representable) -> Bool {
            lhs.foregroundColor == rhs.foregroundColor
            && lhs.autocapitalization == rhs.autocapitalization
            && lhs.multilineTextAlignment == rhs.multilineTextAlignment
            && lhs.font == rhs.font
            && lhs.returnKeyType == rhs.returnKeyType
            && lhs.clearsOnInsertion == rhs.clearsOnInsertion
            && lhs.autocorrection == rhs.autocorrection
            && lhs.truncationMode == rhs.truncationMode
            && lhs.isEditable == rhs.isEditable
            && lhs.isSelectable == rhs.isSelectable
            && lhs.isScrollingEnabled == rhs.isScrollingEnabled
            && lhs.enablesReturnKeyAutomatically == rhs.enablesReturnKeyAutomatically
            && lhs.autoDetectionTypes == rhs.autoDetectionTypes
            && lhs.allowsRichText == rhs.allowsRichText
            && lhs.insets == rhs.insets
            && lhs.maxHeight == rhs.maxHeight
        }

        @Binding var text: NSAttributedString
        @Binding var calculatedHeight: CGFloat
        var isFocusing: Binding<Bool>? = nil

        let foregroundColor: UIColor
        let autocapitalization: UITextAutocapitalizationType
        var multilineTextAlignment: TextAlignment
        let font: UIFont
        let returnKeyType: UIReturnKeyType?
        let clearsOnInsertion: Bool
        let autocorrection: UITextAutocorrectionType
        let truncationMode: NSLineBreakMode
        let isEditable: Bool
        let isSelectable: Bool
        let isScrollingEnabled: Bool
        let enablesReturnKeyAutomatically: Bool?
        var autoDetectionTypes: UIDataDetectorTypes = []
        var allowsRichText: Bool

        var onEditingChanged: (() -> Void)?
        var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?
        var onCommit: (() -> Void)?
        var insets: EdgeInsets = .init()
        var maxHeight: CGFloat = .infinity

        func makeUIView(context: Context) -> UIKitTextView {
            context.coordinator.textView
        }

        func updateUIView(_ view: UIKitTextView, context: Context) {
            context.coordinator.update(representable: self)
            context.coordinator.calculatedHeight = self.$calculatedHeight
            context.coordinator.isFocusing = self.isFocusing
        }

        @discardableResult func makeCoordinator() -> Coordinator {
            Coordinator(
                text: $text,
                calculatedHeight: $calculatedHeight,
                shouldEditInRange: shouldEditInRange,
                onEditingChanged: onEditingChanged,
                onCommit: onCommit
            )
        }

    }

}
