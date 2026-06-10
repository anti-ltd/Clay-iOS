/**
 `DeepLink`: typed `clay://` URLs shared by the widget extension (which only
 builds them) and the app (which routes them).

   clay://recipe/<uuid>   — open a recipe in the editor (widget tap)
   clay://enable/<need>   — run the permission flow for a data need
                            (widget permission placeholder tap)
 */
import Foundation

public enum DeepLink: Hashable, Sendable {
    case recipe(UUID)
    case enable(String)

    public var url: URL {
        switch self {
        case .recipe(let id):
            URL(string: "\(ClayKit.urlScheme)://recipe/\(id.uuidString)")!
        case .enable(let need):
            URL(string: "\(ClayKit.urlScheme)://enable/\(need)")!
        }
    }

    public init?(url: URL) {
        guard url.scheme == ClayKit.urlScheme else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        switch (url.host, path.first) {
        case ("recipe", let raw?):
            guard let id = UUID(uuidString: raw) else { return nil }
            self = .recipe(id)
        case ("enable", let raw?):
            self = .enable(raw)
        default:
            return nil
        }
    }
}
