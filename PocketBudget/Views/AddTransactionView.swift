import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("budget_currency") private var currency = "EUR"

    @State private var title = ""
    @State private var amount = ""
    @State private var kind: TransactionKind = .expense
    @State private var category = "Еда"
    @State private var date = Date.now
    @State private var note = ""

    private let categories = ["Еда", "Транспорт", "Дом", "Покупки", "Здоровье", "Развлечения", "Зарплата", "Другое"]

    private var currencySymbol: String {
        switch currency {
        case "USD":
            return "$"
        case "RUB":
            return "₽"
        case "GBP":
            return "£"
        default:
            return "€"
        }
    }

    /// Основное представление формы добавления новой транзакции.
    var body: some View {
        Form {
            Section("Тип операции") {
                Picker("Тип", selection: $kind) {
                    ForEach(TransactionKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Детали") {
                TextField("Название", text: $title)
                TextField("Сумма (\(currencySymbol))", text: $amount).keyboardType(.decimalPad)
                Picker("Категория", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                DatePicker("Дата", selection: $date, displayedComponents: .date)
                TextField("Заметка (необязательно)", text: $note, axis: .vertical)
            }
            Section {
                Button {
                    let normalized = amount.replacingOccurrences(of: ",", with: ".")
                    guard let value = Double(normalized), value > 0, !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    viewModel.add(title: title.trimmingCharacters(in: .whitespaces), amount: value, kind: kind, category: category, date: date, note: note)
                    title = ""; amount = ""; note = ""
                    dismiss()
                } label: {
                    HStack { Spacer(); Text("Сохранить операцию").fontWeight(.semibold); Spacer() }
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(amount.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
            }
        }
    }
}
