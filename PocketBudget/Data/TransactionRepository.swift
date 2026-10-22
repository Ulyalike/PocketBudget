import Foundation
import SwiftData

@MainActor
protocol TransactionRepository {
    func fetchAll() throws -> [Transaction]
    func add(_ transaction: Transaction) throws
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
