import Cocoa
import WebKit

class Document: NSDocument {
    
    @IBOutlet weak var webView: WebView!
    
    var native: Native?
    
    override init() {
        super.init()
        native = Native(document: self)
    }

    override func windowControllerDidLoadNib(windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        if let url = NSBundle.mainBundle().URLForResource("main", withExtension: "html", subdirectory: "core") {
            webView.frameLoadDelegate = self
            webView.mainFrame.loadRequest(NSURLRequest(URL: url))
        } else {
            let alert = NSAlert()
            alert.messageText = "Cannot find core/main.html"
            alert.informativeText = "This file is the entry point for Freedraw. Is the core submodule up-to-date?"
            alert.runModal()
            NSApplication.sharedApplication().terminate(self)
        }
    }

    override func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        frame.windowObject.JSValue().setValue(native, forProperty: "Native")
    }

    override var windowNibName: String? {
        return "Document"
    }
    
}

// MARK: - Saving/Loading
extension Document {
    
    override class func autosavesInPlace() -> Bool {
        return true
    }

    override func dataOfType(typeName: String, error outError: NSErrorPointer) -> NSData? {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }

    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
    }
}

// MARK: - Menu Items
extension Document {

    @objc
    func showDeveloperTools(sender: AnyObject?) {
        webView.inspector().show(self)
    }
    
    @objc
    func showJavaScriptConsole(sender: AnyObject?) {
        webView.inspector().showConsole(self)
    }
    
    @objc
    func forceReload(sender: AnyObject?) {
        webView.reloadFromOrigin(sender)
    }
}
