import Cocoa
import WebKit

class FreedrawView: WebView {
    weak var document: Document?
}

// MARK: - Event Handling

extension FreedrawView {

    override func magnifyWithEvent(event: NSEvent) {
        document?.callHook("dispatchMagnify", forEvent: event, withArguments: [event.magnification])
    }
}
