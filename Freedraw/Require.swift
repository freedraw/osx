import Cocoa
import WebKit

@objc(RequireExport)
public protocol RequireExport: JSExport {
    func require(path: NSString) -> AnyObject
}

let root: String = NSBundle.mainBundle().pathForResource("core/src", ofType: nil)!
var cache: Dictionary<String, AnyObject> = Dictionary()

@objc(Require)
public class Require: NSObject, RequireExport {
    let path: String
    
    init(path: String) {
        self.path = path
    }
    
    public func require(file: NSString) -> AnyObject {
        let fp = file.hasPrefix("./")
            ? path.stringByAppendingPathComponent(file.substringFromIndex(2))
            : root.stringByAppendingPathComponent(file)

        var isDirectory: ObjCBool = false
        NSFileManager.defaultManager().fileExistsAtPath(fp, isDirectory: &isDirectory)

        let filePath: String! = isDirectory ? fp.stringByAppendingPathComponent("_index.js") :
            fp.pathExtension == "" ? fp.stringByAppendingPathExtension("js") : fp

        if let m: AnyObject = cache[filePath] {
            return m
        }

        let context = JSContext.currentContext()
        var err: NSError?
        let source = NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding, error: &err)

        if let err = err {
            let reason = err.localizedFailureReason ?? "Unknown reason."
            let message = "Cannot require '\(file)' (i.e., '\(filePath)'): \(reason)"
            context.exception = JSValue(newErrorFromMessage: message, inContext: context)
            return JSValue(undefinedInContext: context)
        }

        if filePath.pathExtension == "js" {
            let wrappedSource = join("\n", [
                "(function(require, exports) {",
                source! as String,
                ";return exports",
                "}.call(self, this.require.bind(this), {}))"
            ])
            let req = Require(path: fp.stringByDeletingLastPathComponent)
            let result = context.evaluateScript(wrappedSource, withThisObject: JSValue(object:req, inContext:context), sourceURL: NSURL(fileURLWithPath: filePath), startingLineNumber: 1)
            cache[filePath] = result!
            return result!
        }
        
        if filePath.pathExtension == "json" {
            let result: AnyObject? = NSJSONSerialization.JSONObjectWithData(source!.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments, error: &err)
            if let err = err {
                let reason = err.localizedFailureReason ?? "Unknown reason."
                let message = "Cannot parse JSON from '\(file)' (i.e., '\(filePath)'): \(reason)"
                context.exception = JSValue(newErrorFromMessage: message, inContext: context)
                return JSValue(undefinedInContext: context)
            }
            cache[filePath] = result!
            return result!
        }
        
        cache[filePath] = source!
        return source!
    }
    
    class func clearCache() {
        cache.removeAll(keepCapacity: true)
    }
}
