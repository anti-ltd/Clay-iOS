/**
 The "tap to enable" state for a permission-gated block whose data need is
 denied or undetermined. Themed like real content — never a blank or broken
 widget. In the widget, the entry view routes the container's `widgetURL`
 to the requirement's deep link so a tap lands in the in-app request flow.
 */
import SwiftUI

public struct PermissionPlaceholderBlock: View {
    let requirement: PermissionRequirement
    let style: ResolvedBlockStyle
    let family: WidgetFamilyKey

    public init(requirement: PermissionRequirement, style: ResolvedBlockStyle, family: WidgetFamilyKey) {
        self.requirement = requirement
        self.style = style
        self.family = family
    }

    public var body: some View {
        VStack(spacing: 3) {
            Image(systemName: requirement.symbolName)
                .font(.system(size: family.isAccessory ? 14 : 20, weight: .light))
                .foregroundStyle(style.tintColor ?? style.primaryColor)
            if family != .accessoryCircular {
                Text("Tap to enable \(requirement.title)")
                    .font(style.font(size: 11))
                    .foregroundStyle(style.secondaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}
