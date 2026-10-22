import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @AppStorage("budget_currency") private var currency = "EUR"
    @AppStorage("budget_theme") private var theme = "light"
    @AppStorage("budget_user_name") private var userName = ""

    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool

    private let allRateRows: [(code: String, label: String)] = [
        ("USD", "Доллар США"),
        ("GBP", "Фунт стерлингов"),
        ("RUB", "Российский рубль"),
        ("EUR", "Евро")
    ]

    private var rateRows: [(code: String, label: String)] {
        allRateRows.filter { $0.code != currency }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(
                            LinearGradient(colors: [Color.green, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        Image(systemName: "person.fill").font(.system(size: 30, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 68, height: 68)

                    VStack(alignment: .leading, spacing: 7) {
                        if isEditingName {
                            HStack(spacing: 8) {
                                TextField("Введите ваше имя", text: $userName)
                                    .font(.title3.bold())
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .focused($isNameFieldFocused)
                                    .submitLabel(.done)
                                    .onSubmit { finishEditingName() }

                                Button("Готово") {
                                    finishEditingName()
                                }
                                .font(.caption.weight(.semibold))
                            }
                        } else {
                            HStack(spacing: 8) {
                                Text(userName.isEmpty ? "Введите ваше имя" : userName)
                                    .font(.title3.bold())
                                    .foregroundStyle(userName.isEmpty ? Color.secondary : Color.primary)

                                Spacer()

                                Button("Изменить") {
                                    isEditingName = true
                                    DispatchQueue.main.async {
                                        isNameFieldFocused = true
                                    }
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }

                        Text("Ваш личный финансовый профиль")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Персонализация") {
                Picker("Валюта", selection: $currency) {
                    Text("Евро (€)").tag("EUR")
                    Text("Доллар США ($)").tag("USD")
                    Text("Рубль (₽)").tag("RUB")
                    Text("Фунт (£)").tag("GBP")
                }
                Toggle("Тёмная тема", isOn: Binding(
                    get: { theme == "dark" },
                    set: { theme = $0 ? "dark" : "light" }
                ))
            }

            Section("Курсы валют · онлайн") {
                if viewModel.isLoading {
                    ProgressView("Загружаем курсы…")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                    Button("Повторить загрузку") { Task { await viewModel.loadRates() } }
                } else {
                    ForEach(rateRows, id: \.code) { item in
                        rateRow(item.code, label: item.label)
                    }
                    Button("Обновить курсы") { Task { await viewModel.loadRates() } }
                }
            }

            Section("О приложении") {
                LabeledContent("Версия", value: "1.1.0 · Учебный проект")
                Label("Операции хранятся локально на устройстве", systemImage: "externaldrive.fill")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .task { await viewModel.loadRates() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    finishEditingName()
                }
            }
        }
    }

    private func finishEditingName() {
        isNameFieldFocused = false
        isEditingName = false
    }

    @ViewBuilder
    private func rateRow(_ code: String, label: String) -> some View {
        if let value = crossRate(for: code) {
            LabeledContent(label, value: "\(value.formatted(.number.precision(.fractionLength(2)))) \(currency) за 1 \(code)")
        } else {
            LabeledContent(label, value: "Нет данных")
        }
    }

    private func crossRate(for code: String) -> Double? {
        let target: Double
        if code == viewModel.baseCode {
            target = 1.0
        } else if let r = viewModel.rates[code], r > 0 {
            target = r
        } else {
            return nil
        }

        let baseRate: Double
        if currency == viewModel.baseCode {
            baseRate = 1.0
        } else if let r = viewModel.rates[currency], r > 0 {
            baseRate = r
        } else {
            return nil
        }

        return baseRate / target
    }
}
