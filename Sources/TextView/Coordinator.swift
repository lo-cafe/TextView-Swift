import SwiftUI

@available(iOS 17.0, *)
extension TextView.Representable {
    final class Coordinator: NSObject, UITextViewDelegate {

        internal let textView: UIKitTextView

        private var originalText: NSAttributedString = .init()
        private var text: Binding<NSAttributedString>
        var calculatedHeight: Binding<CGFloat>
        var isFocusing: Binding<Bool>? = nil

        var onCommit: (() -> Void)?
        var onEditingChanged: (() -> Void)?
        var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?

        init(text: Binding<NSAttributedString>,
             calculatedHeight: Binding<CGFloat>,
             shouldEditInRange: ((Range<String.Index>, String) -> Bool)?,
             onEditingChanged: (() -> Void)?,
             onCommit: (() -> Void)?
        ) {
            textView = UIKitTextView()
            textView.backgroundColor = .clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

            self.text = text
            self.calculatedHeight = calculatedHeight
            self.shouldEditInRange = shouldEditInRange
            self.onEditingChanged = onEditingChanged
            self.onCommit = onCommit

            super.init()
            textView.delegate = self
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if let isFocusing {
                isFocusing.wrappedValue = true
            }
            originalText = text.wrappedValue
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = NSAttributedString(attributedString: textView.attributedText)
            recalculateHeight()
            onEditingChanged?()
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if onCommit != nil, text == "\n" {
                onCommit?()
                originalText = NSAttributedString(attributedString: textView.attributedText)
                textView.resignFirstResponder()
                return false
            }

            return true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // this check is to ensure we always commit text when we're not using a closure
            if onCommit != nil {
                text.wrappedValue = originalText
            }
            if let isFocusing {
                isFocusing.wrappedValue = false
            }
        }

    }

}

@available(iOS 17.0, *)
extension TextView.Representable.Coordinator {

    func update(representable: TextView.Representable) {
        textView.attributedText = representable.text
        textView.font = representable.font
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = representable.foregroundColor
        textView.autocapitalizationType = representable.autocapitalization
        textView.autocorrectionType = representable.autocorrection
        textView.isEditable = representable.isEditable
        textView.isSelectable = representable.isSelectable
        textView.isScrollEnabled = representable.isScrollingEnabled
        textView.dataDetectorTypes = representable.autoDetectionTypes
        textView.allowsEditingTextAttributes = representable.allowsRichText

        switch representable.multilineTextAlignment {
        case .leading:
            textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .left : .right
        case .trailing:
            textView.textAlignment = textView.traitCollection.layoutDirection ~= .leftToRight ? .right : .left
        case .center:
            textView.textAlignment = .center
        }

        if let value = representable.enablesReturnKeyAutomatically {
            textView.enablesReturnKeyAutomatically = value
        } else {
            textView.enablesReturnKeyAutomatically = onCommit == nil ? false : true
        }

        if let returnKeyType = representable.returnKeyType {
            textView.returnKeyType = returnKeyType
        } else {
            textView.returnKeyType = onCommit == nil ? .default : .done
        }

        if !representable.isScrollingEnabled {
            textView.textContainer.lineFragmentPadding = 0
            textView.textContainerInset = UIEdgeInsets(
                top: representable.insets.top, 
                left: representable.insets.leading, 
                bottom: representable.insets.bottom, 
                right: representable.insets.trailing
            )
        }

        recalculateHeight()
        textView.setNeedsDisplay()
    }

    private func recalculateHeight() {
        let newSize = textView.sizeThatFits(CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude))
        guard calculatedHeight.wrappedValue != newSize.height else { return }

        DispatchQueue.main.async { // call in next render cycle.
            self.calculatedHeight.wrappedValue = newSize.height
        }
    }

}