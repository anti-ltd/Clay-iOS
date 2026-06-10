import Foundation

/// Constants shared between the app and the widget extension. The two
/// processes are isolated and share state only through the App Group.
public enum ClayKit {
    public static let appGroupID = "group.ltd.anti.clay"
    public static let urlScheme = "clay"
}
