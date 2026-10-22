import Foundation
import SwiftData

enum TransactionKind: String, CaseIterable, Identifiable {
    case expense = "Расход"
    case income = "Доход"
    var id: String { rawValue }
}

@Model
final class Transaction {
    var title: String
    var amount: Double
    var kindRaw: String
    var category: String
    var date: Date
    var note: String

    init(title: String, amount: Double, kind: TransactionKind, category: String, date: Date = .now, note: String = "") {
        self.title = title
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.category = category
        self.date = date
        self.note = note
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }
}
