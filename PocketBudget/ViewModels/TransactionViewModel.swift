import Foundation
import SwiftData
import Combine

@MainActor
final class TransactionViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published var errorMessage: String?
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
        refresh()
    }

    func refresh() {
        do { transactions = try repository.fetchAll() }
        catch { errorMessage = "Не удалось загрузить операции: \(error.localizedDescription)" }
    }

    func add(title: String, amount: Double, kind: TransactionKind, category: String, date: Date, note: String) {
        let item = Transaction(title: title, amount: amount, kind: kind, category: category, date: date, note: note)
        do { try repository.add(item); refresh() }
        catch { errorMessage = "Не удалось сохранить операцию: \(error.localizedDescription)" }
    }

    func delete(_ transaction: Transaction) {
        do { try repository.delete(transaction); refresh() }
        catch { errorMessage = "Не удалось удалить операцию: \(error.localizedDescription)" }
    }

    private var todayTransactions: [Transaction] {
        transactions.filter { Calendar.current.startOfDay(for: $0.date) <= Calendar.current.startOfDay(for: .now) }
    }

    var futureTransactions: [Transaction] {
        transactions.filter { Calendar.current.startOfDay(for: $0.date) > Calendar.current.startOfDay(for: .now) }
    }

    var incomeTotal: Double { todayTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    var expenseTotal: Double { todayTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    var balance: Double { incomeTotal - expenseTotal }

    var plannedIncome: Double { futureTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    var plannedExpense: Double { futureTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    var projectedBalance: Double { balance + plannedIncome - plannedExpense }
}
