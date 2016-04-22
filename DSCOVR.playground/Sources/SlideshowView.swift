import Foundation
import QuartzCore
#if os(OSX)
    import AppKit
#endif

/// A view which animates between a series of images with captions.
/// Setting the `slides` property to an array of slides will automatically start the animation.
public class SlideshowView: NativeView
{
    public struct Slide
    {
        public let caption: String
        public let image: NativeImage
        
        public init(caption: String, image: NativeImage) {
            self.caption = caption
            self.image = image
        }
    }
    
    /// The text layer which displays the caption.
    private let captionLayer: CATextLayer
    
    /// A multiplier for the animation speed.
    /// This value specifies the number of slides displayed per second (1 by default).
    public var speed: Float {
        get { return mainLayer.speed }
        set { mainLayer.speed = newValue }
    }
    
    /// The slides being displayed by the slideshow.
    public var slides: [Slide] = [] {
        didSet {
            mainLayer.removeAllAnimations()
            captionLayer.removeAllAnimations()
            
            let anim = CAKeyframeAnimation()
            anim.duration = CFTimeInterval(slides.count)
            anim.removedOnCompletion = false
            anim.repeatCount = .infinity
            anim.calculationMode = kCAAnimationDiscrete
            anim.fillMode = kCAFillModeBoth
            
            anim.keyPath = "contents"
            anim.values = slides.map{ $0.image.layerContents }
            mainLayer.addAnimation(anim, forKey: nil)
            
            anim.keyPath = "string"
            anim.values = slides.map{ $0.caption }
            captionLayer.addAnimation(anim, forKey: nil)
        }
    }
    
    
    private var mainLayer: CALayer {
        // On OS X self.layer is Optional, but on iOS it’s not.
        // We can bridge the gap with an implicitly unwrapped optional.
        return layer as CALayer!
    }
    
    
    @available(*, unavailable) public required init?(coder: NSCoder) { fatalError() }
    public override init(frame frameRect: CGRect)
    {
        captionLayer = CATextLayer()
        captionLayer.font = NativeFont.monospacedDigitSystemFont()
        captionLayer.fontSize = 16
        captionLayer.foregroundColor = NativeColor.whiteColor().CGColor
        captionLayer.wrapped = true
        
        super.init(frame: frameRect)
        #if os(OSX)
            layer = CALayer()
            layer?.contentsGravity = kCAGravityResizeAspect
            wantsLayer = true
            captionLayer.delegate = self
        #else
            contentMode = .ScaleToFill
        #endif
        
        mainLayer.addSublayer(captionLayer)
        captionLayer.frame = CGRect(x: 5, y: 5, width: frameRect.width-10, height: frameRect.height-10)
    }
    
    #if os(OSX)
    public override var flipped: Bool { return true }
    #endif
    
    /// Adjust the captionLayer’s contentsScale to render text properly on retina displays.
    #if os(OSX)
    public override func layer(layer: CALayer, shouldInheritContentsScale newScale: CGFloat, fromWindow window: NSWindow) -> Bool
    {
        return true
    }
    #else
    public override func didMoveToWindow()
    {
        super.didMoveToWindow()
        captionLayer.contentsScale = window?.screen.scale ?? 1
    }
    #endif
}
