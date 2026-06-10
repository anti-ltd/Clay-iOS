import SwiftUI
import iUXiOS

@main
struct ClayApp: App {
    @State private var model = AppModel()

    init() {
        PhotoPickerRegistration.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                // The brand is dark glass; the ambient backdrop and glass
                // surfaces assume it. Light mode renders .primary text as
                // near-black on black.
                .preferredColorScheme(.dark)
        }
    }
}
