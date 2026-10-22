import Foundation
import SwiftData

@MainActor
protocol TransactionRepository {
    /// Извлекает все транзакции из локального хранилища.
    /// - Returns: Массив объектов `Transaction`, отсортированный по дате (сначала новые).
    /// - Throws: Ошибку при неудачном выполнении запроса в SwiftData.
    func fetchAll() throws -> [Transaction]
    
    /// Добавляет новую транзакцию в хранилище и сохраняет контекст.
    /// - Parameter transaction: Объект `Transaction` для добавления.
    /// - Throws: Ошибку, если не удалось сохранить контекст.
    func add(_ transaction: Transaction) throws
    
    /// Удаляет указанную транзакцию из хранилища и сохраняет контекст.
    /// - Parameter transaction: Объект `Transaction` для удаления.
    /// - Throws: Ошибку, если не удалось сохранить контекст.
    func delete(_ transaction: Transaction) throws
}

@MainActor
final class SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func fetchAll() throws -> [Transaction] {
        try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }

    func add(_ transaction: Transaction) throws {
        context.insert(transaction)
        try context.save()
    }

    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }
}
