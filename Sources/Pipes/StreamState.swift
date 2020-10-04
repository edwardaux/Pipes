import Foundation

public enum StreamState {
    case connectedWaiting
    case connectedNotWaiting
    case notConnected
    case notDefined

    var isConnected: Bool {
        return self == .connectedWaiting || self == .connectedNotWaiting
    }
}
