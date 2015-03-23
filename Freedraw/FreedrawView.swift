import Cocoa
import WebKit

class FreedrawView: WebView {
    weak var document: Document?
}

// MARK: - Event Handling

extension FreedrawView {

    override func magnifyWithEvent(event: NSEvent) {
        let position = self.convertPoint(event.locationInWindow, fromView: nil)
        document?.callHook("dispatchMagnify", withArguments: [position.x, frame.height - position.y, event.magnification])
    }
}
