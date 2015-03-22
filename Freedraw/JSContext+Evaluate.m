#import <JavaScriptCore/JavaScriptCore.h>
#import "JSContext+Evaluate.h"

@implementation JSContext (Evaluate)

- (JSValue *)evaluateScript:(NSString *)script withThisObject:(JSValue *)thisObject sourceURL:(NSURL *)sourceURL startingLineNumber:(int)startingLineNumber;
{
    JSValueRef exceptionValue = NULL;
    JSStringRef scriptJS = JSStringCreateWithCFString((__bridge CFStringRef) script);
    JSStringRef sourceURLJS = sourceURL ? JSStringCreateWithCFString((__bridge CFStringRef) [sourceURL absoluteString]) : NULL;
    JSValueRef result = JSEvaluateScript(self.JSGlobalContextRef, scriptJS, thisObject ? (JSObjectRef) thisObject.JSValueRef : NULL, sourceURLJS, startingLineNumber, &exceptionValue);
    JSStringRelease(scriptJS);
    if (sourceURLJS) JSStringRelease(sourceURLJS);

    if (exceptionValue) {
        self.exceptionHandler(self, [JSValue valueWithJSValueRef:exceptionValue inContext:self]);
        return [JSValue valueWithUndefinedInContext:self];
    }

    return [JSValue valueWithJSValueRef:result inContext:self];
}

- (JSValue *)evaluateScript:(NSString *)script withSourceURL:(NSURL *)sourceURL startingLineNumber:(int)startingLineNumber;
{
    return [self evaluateScript:script withThisObject:nil sourceURL:sourceURL startingLineNumber:startingLineNumber];
}

@end
