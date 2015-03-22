import Cocoa
import WebKit

@objc(NativeExport)
public protocol NativeExport: JSExport {
    func save()
    
    func showConsole()
    
    func require(path: NSString!) -> JSValue
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
    
    public func showConsole() {
        self.document?.webView.inspector().showConsole(self)
    }
    
    public func require(path: NSString!) -> JSValue {
        return require.require(path)
    }
}
