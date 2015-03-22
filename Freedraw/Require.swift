import Cocoa
import WebKit

@objc(RequireExport)
public protocol RequireExport: JSExport {
    func require(path: String) -> JSValue
}

let root: String = NSBundle.mainBundle().pathForResource("core/src", ofType: nil)!
var cache: Dictionary<String, JSValue> = Dictionary()

@objc(Require)
public class Require: NSObject, RequireExport {
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    public func require(file: String) -> JSValue {
        let fp = file.hasPrefix("./")
            ? path.stringByAppendingPathComponent(file[advance(file.startIndex,2)..<file.endIndex])
            : root.stringByAppendingPathComponent(file)
        let filePath = fp.pathExtension == "" ? fp + ".js" : fp
        
        if let m = cache[filePath] {
            return m
        }
        
        let context = JSContext.currentContext()
        var err: NSError?
        let source = NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding, error: &err)
        
        if let err = err {
            let reason = err.localizedFailureReason ?? "unknown reason"
            let message = "Cannot require '\(file)' (i.e., '\(filePath)'): \(reason)"
            context.exception = JSValue(newErrorFromMessage: message, inContext: context)
            return JSValue(undefinedInContext: context)
        }
        

        let wrappedSource = "var require = this.require.bind(this);" + source! + ";exports"
        let req = Require(path: fp.stringByDeletingLastPathComponent)
        let result = context.evaluateScript(wrappedSource, withThisObject: JSValue(object:req, inContext:context), sourceURL: NSURL(fileURLWithPath: filePath), startingLineNumber: 1)
        cache.updateValue(result, forKey: filePath)
        return result
    }
}