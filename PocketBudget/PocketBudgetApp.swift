import SwiftUI
import SwiftData

@main
struct PocketBudgetApp: App {
    @AppStorage("budget_theme") private var theme = "light"

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(theme == "dark" ? .dark : .light)
        }
        .modelContainer(for: Transaction.self)
    }
}
