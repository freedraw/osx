#import <JavaScriptCore/JavaScriptCore.h>

@interface JSContext (Evaluate)

- (JSValue *)evaluateScript:(NSString *)script withThisObject:(JSValue *)thisObject sourceURL:(NSURL *)sourceURL startingLineNumber:(int)startingLineNumber;
- (JSValue *)evaluateScript:(NSString *)script withSourceURL:(NSURL *)sourceURL startingLineNumber:(int)startingLineNumber;

@end
