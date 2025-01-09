import SwiftUI

/// A SwiftUI TextView implementation that supports both scrolling and auto-sizing layouts
@available(iOS 17.0, *)
public struct TextView<PlaceholderView>: View where PlaceholderView : Equatable, PlaceholderView : View {
    @Environment(\.layoutDirection) private var layoutDirection
    
    @Binding private var text: NSAttributedString
    @Binding private var isEmpty: Bool
    
    @State private var calculatedHeight: CGFloat = 44
    
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
    
    /// Makes a new TextView with the specified configuration
    /// - Parameters:
    ///   - text: A binding to the text
    ///   - shouldEditInRange: A closure that's called before an edit it applied, allowing the consumer to prevent the change
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(
        _ text: Binding<String>,
        @ViewBuilder placeholderView: @escaping () -> PlaceholderView,
        isFocusing: Binding<Bool>? = nil,
        shouldEditInRange: ((Range<String.Index>, String) -> Bool)? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.placeholderView = placeholderView()
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
        
        allowRichText = false
    }
    
    /// Makes a new TextView that supports `NSAttributedString`
    /// - Parameters:
    ///   - text: A binding to the attributed text
    ///   - onEditingChanged: A closure that's called after an edit has been applied
    ///   - onCommit: If this is provided, the field will automatically lose focus when the return key is pressed
    public init(
        _ text: Binding<NSAttributedString>,
        @ViewBuilder placeholderView: @escaping () -> PlaceholderView,
        isFocusing: Binding<Bool>? = nil,
        onEditingChanged: (() -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.placeholderView = placeholderView()
        _text = text
        _isEmpty = Binding(
            get: { text.wrappedValue.string.isEmpty },
            set: { _ in }
        )
        
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.isFocusing = isFocusing
        
        allowRichText = true
    }
    
    public var body: some View {
        Representable(
            text: $text,
            calculatedHeight: Binding(
                get: {
                    calculatedHeight
                }, set: { newVal in
                    calculatedHeight = newVal < maxHeightUntilForceScrolling ? newVal : maxHeightUntilForceScrolling
                }
            ),
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
            isScrollingEnabled: calculatedHeight >= maxHeightUntilForceScrolling ? true : isScrollingEnabled,
            enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
            autoDetectionTypes: autoDetectionTypes,
            allowsRichText: allowRichText,
            onEditingChanged: onEditingChanged,
            shouldEditInRange: shouldEditInRange,
            onCommit: onCommit,
            insets: textViewInsets
        )
        .frame(
            minHeight: isScrollingEnabled ? 0 : calculatedHeight,
            maxHeight: min(maxHeightUntilForceScrolling, isScrollingEnabled ? .infinity : calculatedHeight)
        )
        .background(
            placeholderView
                .foregroundColor(Color(.placeholderText))
                .multilineTextAlignment(multilineTextAlignment)
                .font(Font(font))
                .padding(.horizontal, isScrollingEnabled ? 5 : 0)
                .padding(.vertical, isScrollingEnabled ? 8 : 0)
                .opacity(isEmpty ? 1 : 0),
            alignment: .topLeading
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
        onCommit: (() -> Void)? = nil
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
        onCommit: (() -> Void)? = nil
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
