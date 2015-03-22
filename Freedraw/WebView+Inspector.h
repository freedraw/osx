#import <WebKit/WebKit.h>

@class WebInspector;

@interface WebView (Inspector)

- (WebInspector *)inspector;

@end
