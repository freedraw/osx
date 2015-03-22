import Cocoa
import WebKit

@objc(NativeExport)
public protocol NativeExport: JSExport {
    func save()
    func require(path: NSString!) -> JSValue
}

@objc(Native)
public class Native: NSObject, NativeExport {
    weak var document: NSDocument?
    lazy var require: Require = Require(path: NSBundle.mainBundle().pathForResource("core", ofType: nil)!)
    
    init(document: NSDocument) {
        self.document = document
    }
    
    public func save() {
        document?.saveDocument(self)
    }
    
    public func require(path: NSString!) -> JSValue {
        return require.require(path)
    }
}
