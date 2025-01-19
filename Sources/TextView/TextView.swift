import SwiftUI
import UIKit

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
@available(iOS 17.0, *)
public struct TextView<PlaceholderView>: View where PlaceholderView : Equatable, PlaceholderView : View {
    @Environment(\.layoutDirection) private var layoutDirection
    
    @Binding private var text: NSAttributedString
    @Binding private var isEmpty: Bool
    
    @State private var calculatedHeight: CGFloat = 44
    private var optionalCalculatedHeightBinding: Binding<CGFloat>?
    
    private var onEditingChanged: (() -> Void)?
    private var shouldEditInRange: ((Range<String.Index>, String) -> Bool)?
    private var onCommit: (() -> Void)?
    
    var isFocusing: Binding<Bool>?
    var placeholderView: PlaceholderView
    var foregroundColor: UIColor = .label
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var multilineTextAlignment: TextAlignment = .leading
    var font: UIFont = .preferredFont(forTextStyle: .body)
    var returnKeyType: UIReturnKeyType?
    var clearsOnInsertion: Bool = false
    var autocorrection: UITextAutocorrectionType = .default
    var truncationMode: NSLineBreakMode = .byTruncatingTail
    var isEditable: Bool = true
    var isSelectable: Bool = true
    var isScrollingEnabled: Bool = false
    var enablesReturnKeyAutomatically: Bool?
    var autoDetectionTypes: UIDataDetectorTypes = []
    var allowRichText: Bool
    var textViewInsets: EdgeInsets = .init()
    var maxHeightUntilForceScrolling: CGFloat = .infinity
    var preventSelectingText: Bool
    
    /// Makes a new TextView with the specified configuration
    /// - Parameters:
    ///   - text: A binding to the text
    ///   - shouldEditInRange: A closure that's called before an edit it applied, allowing the consumer to prevent the change
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(
        _ text: Binding<String>,
        @ViewBuilder placeholderView: @escaping () -> PlaceholderView,
        calculatedHeightBinding: Binding<CGFloat>,
        isFocusing: Binding<Bool>? = nil,
        shouldEditInRange: ((Range<String.Index>, String) -> Bool)? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil,
        preventSelectingText: Bool = false
    ) {
        self.placeholderView = placeholderView()
        self.isFocusing = isFocusing
        self.optionalCalculatedHeightBinding = calculatedHeightBinding
        _text = Binding(
            get: { NSAttributedString(string: text.wrappedValue) },
            set: { text.wrappedValue = $0.string }
        )
        
        _isEmpty = Binding(
            get: { text.wrappedValue.isEmpty },
            set: { _ in }
        )
        
        self.onCommit = onCommit
        self.shouldEditInRange = shouldEditInRange
        self.onEditingChanged = onEditingChanged
        self.preventSelectingText = preventSelectingText
        
        allowRichText = false
    }
    
    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(
        _ text: Binding<NSAttributedString>,
        allowRichText: Bool = true,
        @ViewBuilder placeholderView: @escaping () -> PlaceholderView,
        calculatedHeightBinding: Binding<CGFloat>,
        isFocusing: Binding<Bool>? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil,
        preventSelectingText: Bool = false
    ) {
        self.placeholderView = placeholderView()
        _text = text
        _isEmpty = Binding(
            get: { text.wrappedValue.string.isEmpty },
            set: { _ in }
        )
        
        self.optionalCalculatedHeightBinding = calculatedHeightBinding
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.isFocusing = isFocusing
        self.preventSelectingText = preventSelectingText
        
        self.allowRichText = allowRichText
    }
    
    var actualCalculatedHeight: CGFloat { optionalCalculatedHeightBinding?.wrappedValue ?? calculatedHeight }
    
    var calculatedHeightBinding: Binding<CGFloat> {
        Binding(
            get: {
                actualCalculatedHeight
            }, set: { newVal in
                let newHeight = newVal < maxHeightUntilForceScrolling ? newVal : maxHeightUntilForceScrolling
                let oldHeight = actualCalculatedHeight
                if oldHeight != newHeight {
                    if optionalCalculatedHeightBinding != nil  {
                        optionalCalculatedHeightBinding?.wrappedValue = newHeight
                    } else {
                        calculatedHeight = newHeight
                    }
                }
            }
        )
    }
    
    public var body: some View {
        Representable(
            text: $text,
            calculatedHeight: calculatedHeightBinding,
            isFocusing: isFocusing,
            foregroundColor: foregroundColor,
            autocapitalization: autocapitalization,
            multilineTextAlignment: multilineTextAlignment,
            font: font,
            returnKeyType: returnKeyType,
            clearsOnInsertion: clearsOnInsertion,
            autocorrection: autocorrection,
            truncationMode: truncationMode,
            isEditable: isEditable,
            isSelectable: isSelectable,
            isScrollingEnabled: actualCalculatedHeight >= maxHeightUntilForceScrolling ? true : isScrollingEnabled,
            enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
            autoDetectionTypes: autoDetectionTypes,
            allowsRichText: allowRichText,
            onEditingChanged: onEditingChanged,
            shouldEditInRange: shouldEditInRange,
            onCommit: onCommit,
            insets: textViewInsets,
            preventSelectingText: preventSelectingText
        )
        .frame(
            minHeight: isScrollingEnabled ? 0 : actualCalculatedHeight,
            maxHeight: min(maxHeightUntilForceScrolling, isScrollingEnabled ? .infinity : actualCalculatedHeight)
        )
        .background(
            ZStack {
                placeholderView
                    .foregroundColor(Color(.placeholderText))
                    .multilineTextAlignment(multilineTextAlignment)
                    .font(Font(font))
                    .opacity(isEmpty ? 1 : 0)
            }
                .animation(.default, value: isEmpty),
            alignment: .top
        )
    }
    
}

@available(iOS 17.0, *)
extension TextView where PlaceholderView == EmptyEquatableView {
    /// Makes a new TextView with the specified configuration
    /// - Parameters:
    ///   - text: A binding to the text
    ///   - shouldEditInRange: A closure that's called before an edit it applied, allowing the consumer to prevent the change
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    init(
        _ text: Binding<String>,
        isFocusing: Binding<Bool>? = nil,
        shouldEditInRange: ((Range<String.Index>, String) -> Bool)? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil,
        preventSelectingText: Bool = false
    ) {
        self.placeholderView = EmptyEquatableView()
        self.isFocusing = isFocusing
        _text = Binding(
            get: { NSAttributedString(string: text.wrappedValue) },
            set: { text.wrappedValue = $0.string }
        )
        
        _isEmpty = Binding(
            get: { text.wrappedValue.isEmpty },
            set: { _ in }
        )
        
        self.onCommit = onCommit
        self.shouldEditInRange = shouldEditInRange
        self.onEditingChanged = onEditingChanged
        self.preventSelectingText = preventSelectingText
        
        allowRichText = false
    }
    
    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    init(
        _ text: Binding<NSAttributedString>,
        isFocusing: Binding<Bool>? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil,
        preventSelectingText: Bool = false
    ) {
        self.placeholderView = EmptyEquatableView()
        _text = text
        _isEmpty = Binding(
            get: { text.wrappedValue.string.isEmpty },
            set: { _ in }
        )
        
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.isFocusing = isFocusing
        self.preventSelectingText = preventSelectingText
        
        allowRichText = true
    }
}

final class UIKitTextView: UITextView {
    
    override var keyCommands: [UIKeyCommand]? {
        return (super.keyCommands ?? []) + [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escape(_:)))
        ]
    }
    
    @objc private func escape(_ sender: Any) {
        resignFirstResponder()
    }
    
}

struct EmptyEquatableView: View, Equatable {
    var body: some View {
        EmptyView()
    }
}
