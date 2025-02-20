import SwiftUI
import UIKit

@available(iOS 17.0, *)
extension TextView.Representable {
    final class Coordinator: NSObject, UITextViewDelegate {
        
        internal var textView: UIKitTextView? = nil
        
        private var text: Binding<AttributedString>
        var calculatedHeight: Binding<CGFloat>
        var isFocusing: Binding<Bool>? = nil
        
        var onCommit: (() -> Void)?
        var onEditingChanged: (() -> Void)?
        var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?
        
        init(
            text: Binding<AttributedString>,
            calculatedHeight: Binding<CGFloat>,
            shouldEditInRange: ((Range<String.Index>, String) -> Bool)?,
            onEditingChanged: (() -> Void)?,
            onCommit: (() -> Void)?
        ) {
            self.text = text
            self.calculatedHeight = calculatedHeight
            self.shouldEditInRange = shouldEditInRange
            self.onEditingChanged = onEditingChanged
            self.onCommit = onCommit
            
            super.init()
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if let isFocusing {
                DispatchQueue.main.async {
                    isFocusing.wrappedValue = true
                }
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                text.wrappedValue = AttributedString(textView.attributedText)
            }
            recalculateHeight()
            onEditingChanged?()
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let onCommit, text == "\n" {
                onCommit()
                DispatchQueue.main.async {
                    textView.resignFirstResponder()
                }
                return false
            }
            
            return true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if let isFocusing, isFocusing.wrappedValue {
                DispatchQueue.main.async {
                    isFocusing.wrappedValue = false
                }
            }
        }
        
    }
    
}

@available(iOS 17.0, *)
extension TextView.Representable.Coordinator {
    
    func update(representable: TextView.Representable) {
        var nsAttributedString: NSAttributedString
        do {
            nsAttributedString = try NSAttributedString(representable.text)
        } catch(let error) {
            print(error.localizedDescription)
            nsAttributedString = .init()
        }
        DispatchQueue.main.async {
            textView?.attributedText = nsAttributedString
            textView?.font = representable.font
            textView?.adjustsFontForContentSizeCategory = true
            textView?.textColor = representable.foregroundColor
            textView?.autocapitalizationType = representable.autocapitalization
            textView?.autocorrectionType = representable.autocorrection
            textView?.isEditable = representable.isEditable
            textView?.isSelectable = representable.isSelectable
            textView?.isScrollEnabled = representable.isScrollingEnabled
            textView?.dataDetectorTypes = representable.autoDetectionTypes
            textView?.allowsEditingTextAttributes = representable.allowsRichText
            
            switch representable.multilineTextAlignment {
            case .leading:
                textView?.textAlignment = textView?.traitCollection.layoutDirection ~= .leftToRight ? .left : .right
            case .trailing:
                textView?.textAlignment = textView?.traitCollection.layoutDirection ~= .leftToRight ? .right : .left
            case .center:
                textView?.textAlignment = .center
            }
            
            if let value = representable.enablesReturnKeyAutomatically {
                textView?.enablesReturnKeyAutomatically = value
            } else {
                textView?.enablesReturnKeyAutomatically = onCommit == nil ? false : true
            }
            
            if let returnKeyType = representable.returnKeyType {
                textView?.returnKeyType = returnKeyType
            } else {
                textView?.returnKeyType = onCommit == nil ? .default : .done
            }
            
            textView?.textContainer.lineFragmentPadding = 0
            
            if textView?.textContainerInset.top != representable.insets.top ||
                textView?.textContainerInset.left != representable.insets.leading ||
                textView?.textContainerInset.bottom != representable.insets.bottom ||
                textView?.textContainerInset.right != representable.insets.trailing {
                textView?.textContainerInset = UIEdgeInsets(
                    top: representable.insets.top,
                    left: representable.insets.leading,
                    bottom: representable.insets.bottom,
                    right: representable.insets.trailing
                )
            }
        }
        
        recalculateHeight()
        textView?.setNeedsDisplay()
    }
    
    private func recalculateHeight() {
        if let newSize = textView?.sizeThatFits(CGSize(width: textView?.frame.width ?? 0, height: .greatestFiniteMagnitude)) {
            guard calculatedHeight.wrappedValue != newSize.height else { return }
            
            DispatchQueue.main.async { // call in next render cycle.
                self.calculatedHeight.wrappedValue = newSize.height
            }
        }
    }
    
}
