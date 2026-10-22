import Foundation
import SwiftData
import Combine

@MainActor
final class TransactionViewModel: ObservableObject {
    /// Массив всех операций, загруженных из базы данных.
    @Published private(set) var transactions: [Transaction] = []
    /// Текст ошибки для отображения пользователю (если операция не удалась).
    @Published var errorMessage: String?

    private let repository: TransactionRepository

    /// Инициализирует ViewModel с внедрением репозитория и сразу загружает данные.
    /// - Parameter repository: Репозиторий для работы с базой данных.
    init(repository: TransactionRepository) {
        self.repository = repository
        refresh()
    }

    /// Обновляет локальный массив транзакций, запрашивая данные из репозитория.
    func refresh() {
        do { transactions = try repository.fetchAll() }
        catch { errorMessage = "Не удалось загрузить операции: \(error.localizedDescription)" }
    }

    /// Создает и сохраняет новую транзакцию.
    /// - Parameters:
    ///   - title: Название операции.
    ///   - amount: Сумма операции (должна быть больше нуля).
    ///   - kind: Тип операции (доход/расход).
    ///   - category: Категория.
    ///   - date: Дата операции.
    ///   - note: Текстовая заметка (необязательно).
    func add(title: String, amount: Double, kind: TransactionKind, category: String, date: Date, note: String) {
        let item = Transaction(title: title, amount: amount, kind: kind, category: category, date: date, note: note)
        do { try repository.add(item); refresh() }
        catch { errorMessage = "Не удалось сохранить операцию: \(error.localizedDescription)" }
    }

    /// Удаляет переданную транзакцию из базы данных и обновляет список.
    /// - Parameter transaction: Удаляемая транзакция.
    func delete(_ transaction: Transaction) {
        do { try repository.delete(transaction); refresh() }
        catch { errorMessage = "Не удалось удалить операцию: \(error.localizedDescription)" }
    }

    /// Массив транзакций за сегодня и прошлые дни (фактические).
    private var todayTransactions: [Transaction] {
        transactions.filter { Calendar.current.startOfDay(for: $0.date) <= Calendar.current.startOfDay(for: .now) }
    }

    /// Массив транзакций на будущие даты (запланированные).
    var futureTransactions: [Transaction] {
        transactions.filter { Calendar.current.startOfDay(for: $0.date) > Calendar.current.startOfDay(for: .now) }
    }

    /// Общая сумма фактических доходов.
    var incomeTotal: Double { todayTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    /// Общая сумма фактических расходов.
    var expenseTotal: Double { todayTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    /// Текущий баланс (доходы минус расходы).
    var balance: Double { incomeTotal - expenseTotal }

    /// Общая сумма будущих доходов.
    var plannedIncome: Double { futureTransactions.filter { $0.kind == .income }.reduce(0) { $0 + $1.amount } }
    /// Общая сумма будущих расходов.
    var plannedExpense: Double { futureTransactions.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount } }
    /// Ожидаемый баланс с учетом будущих операций.
    var projectedBalance: Double { balance + plannedIncome - plannedExpense }
}
