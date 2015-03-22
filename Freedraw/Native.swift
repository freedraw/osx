import Cocoa
import WebKit

@objc(NativeExport)
public protocol NativeExport: JSExport {
    func save()
}

@objc(Native)
public class Native: NSObject, NativeExport {
    weak var document: NSDocument?
    
    init(document: NSDocument) {
        self.document = document
    }
    
    public func save() {
        document?.saveDocument(self)
    }
}
