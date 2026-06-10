/**
 Placeholder for block kinds this build doesn't know (recipes written by a
 newer app version). Harmless, quiet, themed — never blank, never a crash.
 The instance's config rides along untouched, so saving the recipe from this
 build loses nothing.
 */
import SwiftUI

public struct UnknownBlockView: View {
    let kind: BlockKind
    let style: ResolvedBlockStyle

    public init(kind: BlockKind, style: ResolvedBlockStyle) {
        self.kind = kind
        self.style = style
    }

    public var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 18, weight: .light))
            Text("Update Clay")
                .font(style.font(size: 11))
        }
        .foregroundStyle(style.secondaryColor)
    }
}
