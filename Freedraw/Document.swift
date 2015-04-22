import Cocoa
import WebKit

class Document: NSDocument {

    @IBOutlet weak var webView: FreedrawView!

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
            webView.document = self
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
}

// MARK: - JS Hooks
extension Document {

    func callHook(name: String, withArguments args: [AnyObject], error outError: NSErrorPointer = nil) -> JSValue? {
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

    func callHook(name: String, forEvent event: NSEvent, withArguments args: [AnyObject]) {
        let position = webView.convertPoint(event.locationInWindow, fromView: nil)
        let flags = event.modifierFlags
        let shiftKey = NSNumber(bool: flags & NSEventModifierFlags.ShiftKeyMask != nil)
        let ctrlKey = NSNumber(bool: flags & NSEventModifierFlags.ControlKeyMask != nil)
        let altKey = NSNumber(bool: flags & NSEventModifierFlags.AlternateKeyMask != nil)
        let metaKey = NSNumber(bool: flags & NSEventModifierFlags.CommandKeyMask != nil)
        callHook(name, withArguments: [
            position.x,
            webView.frame.height - position.y,
            shiftKey,
            ctrlKey,
            altKey,
            metaKey] + args)
    }

    func callHook(name: String, forEvent event: NSEvent) {
        callHook(name, forEvent: event, withArguments: [])
    }
}

// MARK: - Menu Items
extension Document {

    @objc
    func jsAction(sender: AnyObject?) {
        if let item = sender as? NSMenuItem {
            callHook("runCommand", withArguments: [item.representedObject as! NSString])
        }
    }

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
