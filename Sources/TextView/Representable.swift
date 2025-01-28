import SwiftUI
import UIKit

@available(iOS 17.0, *)
extension TextView {
    struct Representable: UIViewRepresentable, Equatable {
        static func == (lhs: TextView<PlaceholderView>.Representable, rhs: TextView<PlaceholderView>.Representable) -> Bool {
            return lhs.foregroundColor == rhs.foregroundColor &&
            lhs._text.wrappedValue == rhs._text.wrappedValue &&
            lhs._calculatedHeight.wrappedValue == rhs._calculatedHeight.wrappedValue &&
            lhs._isFocusing.wrappedValue == rhs._isFocusing.wrappedValue &&
            lhs.autocapitalization == rhs.autocapitalization &&
            lhs.multilineTextAlignment == rhs.multilineTextAlignment &&
            lhs.font == rhs.font &&
            lhs.returnKeyType == rhs.returnKeyType &&
            lhs.clearsOnInsertion == rhs.clearsOnInsertion &&
            lhs.autocorrection == rhs.autocorrection &&
            lhs.truncationMode == rhs.truncationMode &&
            lhs.isEditable == rhs.isEditable &&
            lhs.isSelectable == rhs.isSelectable &&
            lhs.isScrollingEnabled == rhs.isScrollingEnabled &&
            lhs.enablesReturnKeyAutomatically == rhs.enablesReturnKeyAutomatically &&
            lhs.autoDetectionTypes == rhs.autoDetectionTypes &&
            lhs.allowsRichText == rhs.allowsRichText &&
            lhs.insets == rhs.insets &&
            lhs.unselectText == rhs.unselectText
        }
        
        @Binding var text: AttributedString
        @Binding var calculatedHeight: CGFloat
        @Binding var isFocusing: Bool
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
        var unselectText: Bool = false
        
        func makeUIView(context: Context) -> UIKitTextView {
            let textView = UIKitTextView()
            textView.backgroundColor = .clear
            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            textView.delegate = context.coordinator
            
            context.coordinator.textView = textView
            return textView
        }
        
        func updateUIView(_ textView: UIKitTextView, context: Context) {
            let selectedRange = textView.selectedRange
            context.coordinator.update(representable: self)
            context.coordinator.calculatedHeight = self.$calculatedHeight
            context.coordinator.isFocusing = self._isFocusing
            DispatchQueue.main.async {
                if isFocusing && !textView.isFirstResponder {
                    textView.becomeFirstResponder()
                } else if !isFocusing && textView.isFirstResponder {
                    DispatchQueue.main.async {
                        textView.resignFirstResponder()
                    }
                }
            }
            textView.selectedRange = unselectText ? .init(location: selectedRange.lowerBound, length: 0) : selectedRange
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


