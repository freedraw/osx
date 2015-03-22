import Cocoa
import WebKit

protocol NativeExport: JSExport {
    func save()
}

class Native: NativeExport {
    weak var document: NSDocument?
    
    init(document: NSDocument) {
        self.document = document
    }
    
    func save() {
    }
}
