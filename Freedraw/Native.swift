import Cocoa
import WebKit

@objc(NativeExport)
public protocol NativeExport: JSExport {
    func save()
    
    func pushCursor(name: NSString)
    func popCursor()

    func showConsole()
    
    func require(path: NSString) -> AnyObject

    func doJSBack()
}

@objc(Native)
public class Native: NSObject, NativeExport {
    weak var document: Document?
    lazy var require: Require = Require(path: NSBundle.mainBundle().pathForResource("core", ofType: nil)!)
    
    init(document: Document) {
        self.document = document
    }

    public func save() {
        document?.saveDocument(self)
    }

    var trackingArea: NSTrackingArea?
    public func pushCursor(name: NSString) {
        getNamedCursor(name).push()
    }

    public func popCursor() {
        NSCursor.pop()
    }

    func getNamedCursor(name: NSString) -> NSCursor {
        switch (name) {
        case "default": return NSCursor.arrowCursor()
        case "context-menu": return NSCursor.contextualMenuCursor()
        case "-webkit-grabbing": return NSCursor.closedHandCursor()
        case "crosshair": return NSCursor.crosshairCursor()
        case "-webkit-destroy": return NSCursor.disappearingItemCursor()
        case "copy": return NSCursor.dragCopyCursor()
        case "alias": return NSCursor.dragLinkCursor()
        case "text": return NSCursor.IBeamCursor()
        case "-webkit-grab": return NSCursor.openHandCursor()
        case "not-allowed", "no-drop": return NSCursor.operationNotAllowedCursor()
        case "pointer": return NSCursor.pointingHandCursor()
        case "s-resize": return NSCursor.resizeDownCursor()
        case "w-resize": return NSCursor.resizeLeftCursor()
        case "col-resize", "ew-resize": return NSCursor.resizeLeftRightCursor()
        case "e-resize": return NSCursor.resizeRightCursor()
        case "n-resize": return NSCursor.resizeUpCursor()
        case "row-resize", "ns-resize": return NSCursor.resizeUpCursor()
        case "vertical-text": return NSCursor.IBeamCursorForVerticalLayout()
        default: return NSCursor.arrowCursor()
        }
    }
    
    public func showConsole() {
        document?.webView.inspector().showConsole(self)
    }
    
    public func require(path: NSString) -> AnyObject {
        return require.require(path)
    }
    
    // MARK: - Communication with JavaScript
    
    var jsBlock: Optional<() -> Void>
    
    func doJS(block: () -> Void) {
        jsBlock = block
        document?.webView.stringByEvaluatingJavaScriptFromString("Native.doJSBack()")
        jsBlock = nil
    }
    
    public func doJSBack() {
        jsBlock!()
    }
}
