import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            NavigationStack {
                TransactionCollectionScreen(viewModel: makeViewModel())
                    .navigationTitle("Операции")
            }
            .tabItem { Label("Операции", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                AddTransactionView(viewModel: makeViewModel())
                    .navigationTitle("Новая операция")
            }
            .tabItem { Label("Добавить", systemImage: "plus.circle.fill") }

            NavigationStack {
                StatisticsView(viewModel: makeViewModel())
                    .navigationTitle("Статистика")
            }
            .tabItem { Label("Статистика", systemImage: "chart.pie.fill") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Настройки")
            }
            .tabItem { Label("Настройки", systemImage: "slider.horizontal.3") }
        }
        .tint(Color(red: 0.24, green: 0.72, blue: 0.40))
    }

    private func makeViewModel() -> TransactionViewModel {
        TransactionViewModel(repository: SwiftDataTransactionRepository(context: context))
    }
}
