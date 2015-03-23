import Cocoa
import WebKit

class Document: NSDocument {

    @IBOutlet weak var webView: WebView!

    var native: Native?
    var hooks: JSValue?
    var jsLoadedFile = false

    override init() {
        super.init()
        native = Native(document: self)
    }

    override func windowControllerDidLoadNib(windowController: NSWindowController) {
        super.windowControllerDidLoadNib(windowController)
        if let url = NSBundle.mainBundle().URLForResource("main", withExtension: "html", subdirectory: "core") {
            webView.drawsBackground = false
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
        Require.clearCache()
        let window = frame.windowObject.JSValue()
        hooks = JSValue(newObjectInContext: window.context)

        window.setValue(native, forProperty: "Native")
        window.setValue(hooks, forProperty: "Hooks")
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
        return callHook("getData", withArguments: [typeName as NSString], error: outError)?.toString().dataUsingEncoding(NSUTF8StringEncoding)
    }

    override func readFromURL(url: NSURL, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        jsLoadedFile = false
        return true
    }

    func jsDone() {
        if let url = fileURL {
            var error: NSError?
            let contents = NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding, error: &error)
            if error == nil && contents != nil {
                callHook("loadData", withArguments: [fileType!, contents!], error: &error)
            }
            if let error = error {
//                close()
                presentError(error)
            }
            jsLoadedFile = true
        }
    }

    override var entireFileLoaded: Bool {
        return jsLoadedFile
    }

    func callHook(name: String, withArguments args: [AnyObject], error outError: NSErrorPointer) -> JSValue? {
        if hooks == nil {
            if outError != nil {
                outError.memory = NSError(domain: ErrorDomain, code: ErrorCode.CannotCommunicate.rawValue, userInfo: [
                    NSLocalizedFailureReasonErrorKey: NSLocalizedString("Cannot communicate with JavaScriptCore.", comment: "")])
            }
            return nil
        }
        let context = hooks!.context
        var result: JSValue?
        let exc = native!.doJS {
            result = self.hooks!.invokeMethod(name, withArguments: args)
        }
        if exc != nil {
            if outError != nil {
                outError.memory = NSError(domain: ErrorDomain, code: ErrorCode.JSError.rawValue, userInfo: [
                    NSLocalizedFailureReasonErrorKey: NSString(format: NSLocalizedString("JavaScript error: %@.", comment: ""), exc!.toString()),
                    NSLocalizedRecoverySuggestionErrorKey: exc!.valueForProperty("stack").toString()])
            }
            return nil
        }
        return result!
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
