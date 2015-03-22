import Cocoa

let ErrorDomain = "io.github.nathan.Freedraw.ErrorDomain"

enum ErrorCode: Int {
    case CannotCommunicate = 1
    case JSError
}
