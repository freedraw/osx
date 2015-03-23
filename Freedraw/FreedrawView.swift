import Cocoa
import WebKit

class FreedrawView: WebView {
    weak var document: Document?
}

// MARK: - Event Handling

extension FreedrawView {

    override func beginGestureWithEvent(event: NSEvent) {
        document?.callHook("dispatchGestureStart", forEvent: event)
    }

    override func endGestureWithEvent(event: NSEvent) {
        document?.callHook("dispatchGestureEnd", forEvent: event)
    }

    override func magnifyWithEvent(event: NSEvent) {
        document?.callHook("dispatchMagnify", forEvent: event, withArguments: [event.magnification])
    }
}
