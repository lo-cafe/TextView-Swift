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
                self.text.wrappedValue = AttributedString(textView.attributedText)
            }
            recalculateHeight()
            onEditingChanged?()
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if let onCommit, text == "\n" {
                onCommit()
                DispatchQueue.main.async {
                    self.textView?.resignFirstResponder()
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
            self.textView?.attributedText = nsAttributedString
            self.textView?.font = representable.font
            self.textView?.adjustsFontForContentSizeCategory = true
            self.textView?.textColor = representable.foregroundColor
            self.textView?.autocapitalizationType = representable.autocapitalization
            self.textView?.autocorrectionType = representable.autocorrection
            self.textView?.isEditable = representable.isEditable
            self.textView?.isSelectable = representable.isSelectable
            self.textView?.isScrollEnabled = representable.isScrollingEnabled
            self.textView?.dataDetectorTypes = representable.autoDetectionTypes
            self.textView?.allowsEditingTextAttributes = representable.allowsRichText
            
            switch representable.multilineTextAlignment {
            case .leading:
                self.textView?.textAlignment = self.textView?.traitCollection.layoutDirection ~= .leftToRight ? .left : .right
            case .trailing:
                self.textView?.textAlignment = self.textView?.traitCollection.layoutDirection ~= .leftToRight ? .right : .left
            case .center:
                self.textView?.textAlignment = .center
            }
            
            if let value = representable.enablesReturnKeyAutomatically {
                self.textView?.enablesReturnKeyAutomatically = value
            } else {
                self.textView?.enablesReturnKeyAutomatically = self.onCommit == nil ? false : true
            }
            
            if let returnKeyType = representable.returnKeyType {
                self.textView?.returnKeyType = returnKeyType
            } else {
                self.textView?.returnKeyType = self.onCommit == nil ? .default : .done
            }
            
            self.textView?.textContainer.lineFragmentPadding = 0
            
            if self.textView?.textContainerInset.top != representable.insets.top ||
                self.textView?.textContainerInset.left != representable.insets.leading ||
                self.textView?.textContainerInset.bottom != representable.insets.bottom ||
                self.textView?.textContainerInset.right != representable.insets.trailing {
                self.textView?.textContainerInset = UIEdgeInsets(
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
