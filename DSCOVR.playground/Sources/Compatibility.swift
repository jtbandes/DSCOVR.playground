// This file provides definitions that help with cross-platform compatibility.

#if os(OSX)
    import AppKit
    public typealias NativeView = NSView
    public typealias NativeImage = NSImage
    public typealias NativeFont = NSFont
    public typealias NativeColor = NSColor
    private let regularWeight = NSFontWeightRegular
#else
    import UIKit
    public typealias NativeView = UIView
    public typealias NativeImage = UIImage
    public typealias NativeFont = UIFont
    public typealias NativeColor = UIColor
    private let regularWeight = UIFontWeightRegular
#endif


extension NativeFont
{
    static func monospacedDigitSystemFont() -> NativeFont
    {
        return monospacedDigitSystemFontOfSize(0, weight: regularWeight)
    }
}


extension NativeImage
{
    /// An object that can be used as a CALayer’s `contents`.
    var layerContents: AnyObject {
        #if os(OSX)
        return self
        #else
        return self.CGImage!
        #endif
    }
}
