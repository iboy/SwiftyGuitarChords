// Updated Aliasses.swift for better cross-platform color handling

#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(macOS)

/// Alias for NSImage
public typealias SWIFTImage = NSImage

/// Alias for NSColor
public typealias SWIFTColor = NSColor

/// Alias for NSFont
public typealias SWIFTFont = NSFont

// Dynamic colors that adapt to appearance changes
public var dynamicPrimaryColor: SWIFTColor { NSColor.labelColor }
public var dynamicBackgroundColor: SWIFTColor { NSColor.windowBackgroundColor }

#else

/// Alias for UIImage
public typealias SWIFTImage = UIImage

/// Alias for UIColor
public typealias SWIFTColor = UIColor

/// Alias for UIFont
public typealias SWIFTFont = UIFont

// Dynamic colors that adapt to appearance changes
public var dynamicPrimaryColor: SWIFTColor { UIColor.label }
public var dynamicBackgroundColor: SWIFTColor { UIColor.systemBackground }

#endif
