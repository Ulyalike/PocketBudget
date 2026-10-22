import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @AppStorage("budget_currency") private var currency = "EUR"

    private var actualTotal: Double { viewModel.incomeTotal + viewModel.expenseTotal }
    private var plannedTotal: Double { viewModel.plannedIncome + viewModel.plannedExpense }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ваш финансовый обзор").font(.title2.bold())
                    Text("Фактические операции отдельно от будущих планов")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 14) {
                    Label("На сегодня", systemImage: "checkmark.circle.fill")
                        .font(.headline).foregroundStyle(.green)
                    HStack(spacing: 12) {
                        summaryCard(title: "Доходы", value: viewModel.incomeTotal, color: .green)
                        summaryCard(title: "Расходы", value: viewModel.expenseTotal, color: .pink)
                    }
                    balanceLine(title: "Текущий баланс", value: viewModel.balance)
                    if actualTotal > 0 {
                        ratioBar(income: viewModel.incomeTotal, expense: viewModel.expenseTotal, total: actualTotal)
                    } else {
                        Text("Добавьте фактические операции, чтобы увидеть соотношение.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))

                VStack(alignment: .leading, spacing: 14) {
                    Label("Будущие операции", systemImage: "calendar.badge.clock")
                        .font(.headline).foregroundStyle(.blue)
                    HStack(spacing: 12) {
                        summaryCard(title: "Будущие доходы", value: viewModel.plannedIncome, color: .green)
                        summaryCard(title: "Будущие расходы", value: viewModel.plannedExpense, color: .pink)
                    }
                    balanceLine(title: "Ожидаемый баланс", value: viewModel.projectedBalance)
                    if plannedTotal == 0 {
                        Text("Пока нет запланированных операций. Укажите будущую дату при добавлении операции.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ratioBar(income: viewModel.plannedIncome, expense: viewModel.plannedExpense, total: plannedTotal)
                    }
                    Text("Ожидаемый баланс = текущий баланс + будущие доходы − будущие расходы.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(18)
                .background(Color.blue.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))
            }
            .padding()
        }
        .onAppear { viewModel.refresh() }
    }

    private func summaryCard(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func balanceLine(title: String, value: Double) -> some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text(value, format: .currency(code: currency))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(value >= 0 ? .green : .pink)
        }
    }

    private func ratioBar(income: Double, expense: Double, total: Double) -> some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                HStack(spacing: 3) {
                    Capsule().fill(.green).frame(width: max(income > 0 ? 4 : 0, proxy.size.width * income / total))
                    Capsule().fill(.pink).frame(width: max(expense > 0 ? 4 : 0, proxy.size.width * expense / total))
                }
            }
            .frame(height: 12)
            HStack {
                Text("Доходы \(percentage(income, total: total))%").foregroundStyle(.green)
                Spacer()
                Text("Расходы \(percentage(expense, total: total))%").foregroundStyle(.pink)
            }
            .font(.caption)
        }
    }

    private func percentage(_ value: Double, total: Double) -> Int {
        guard total > 0 else { return 0 }
        return Int((value / total * 100).rounded())
    }
}
