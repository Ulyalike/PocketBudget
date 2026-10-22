import SwiftUI
import UIKit

struct TransactionCollectionScreen: View {
    @ObservedObject var viewModel: TransactionViewModel
    @AppStorage("budget_currency") private var currency = "EUR"
    @State private var selectedTransaction: Transaction?
    @State private var showingDetails = false

    /// Основное представление экрана с балансом и UIKit-коллекцией операций.
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    balanceCard(title: "Текущий баланс", amount: viewModel.balance, icon: "wallet.pass.fill", color: .green)
                    balanceCard(title: "Ожидаемый баланс", amount: viewModel.projectedBalance, icon: "calendar.badge.clock", color: .blue)
                }

                HStack(alignment: .top) {
                    Text("Операции").font(.headline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Нажмите для подробностей")
                        Text("Удерживайте для удаления")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 10)

            CollectionViewRepresentable(
                items: viewModel.transactions,
                currencyCode: currency,
                onSelect: { item in
                    selectedTransaction = item
                    showingDetails = true
                },
                onDelete: { item in viewModel.delete(item) }
            )
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear { viewModel.refresh() }
        .sheet(isPresented: $showingDetails, onDismiss: { selectedTransaction = nil }) {
            if let transaction = selectedTransaction {
                TransactionDetailView(transaction: transaction, currencyCode: currency) {
                    viewModel.delete(transaction)
                    showingDetails = false
                    selectedTransaction = nil
                }
                .presentationDetents([.medium, .large])
            }
        }
        .alert("Сообщение", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: { Text(viewModel.errorMessage ?? "") }
    }

    /// Создает карточку для отображения одного из видов баланса.
        /// - Parameters:
        ///   - title: Название карточки (например, "Текущий баланс").
        ///   - amount: Сумма баланса.
        ///   - icon: Имя системной иконки SF Symbols.
        ///   - color: Цвет иконки.
        /// - Returns: Представление карточки.
    private func balanceCard(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(color).font(.title3)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(amount, format: .currency(code: currency))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct TransactionDetailView: View {
    let transaction: Transaction
    let currencyCode: String
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss

    /// Представление деталей транзакции
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Название", value: transaction.title)
                    LabeledContent("Сумма") {
                        Text(transaction.amount, format: .currency(code: currencyCode))
                            .foregroundStyle(transaction.kind == .income ? .green : .primary)
                    }
                    LabeledContent("Тип", value: transaction.kind.rawValue)
                    LabeledContent("Категория", value: transaction.category)
                    LabeledContent("Дата", value: transaction.date.formatted(date: .abbreviated, time: .omitted))
                }

                if !transaction.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("Заметка") {
                        Text(transaction.note)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Удалить операцию", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private struct CollectionViewRepresentable: UIViewControllerRepresentable {
    let items: [Transaction]
    let currencyCode: String
    let onSelect: (Transaction) -> Void
    let onDelete: (Transaction) -> Void

    /// Создает и настраивает UIKit-контроллер
    func makeUIViewController(context: Context) -> TransactionCollectionViewController {
        let controller = TransactionCollectionViewController()
        controller.update(items, currencyCode: currencyCode, onSelect: onSelect, onDelete: onDelete)
        return controller
    }

    /// Обновляет данные в UIKit-контроллере при изменении состояния SwiftUI.
    func updateUIViewController(_ controller: TransactionCollectionViewController, context: Context) {
        controller.update(items, currencyCode: currencyCode, onSelect: onSelect, onDelete: onDelete)
    }
}

private final class TransactionCell: UICollectionViewCell {
    static let reuseID = "TransactionCell"
    private let icon = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let amountLabel = UILabel()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        icon.contentMode = .scaleAspectFit
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabel
        amountLabel.font = .systemFont(ofSize: 15, weight: .bold)
        stack.axis = .vertical
        stack.spacing = 4
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(detailLabel)
        let row = UIStackView(arrangedSubviews: [icon, stack, amountLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        icon.widthAnchor.constraint(equalToConstant: 38).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 38).isActive = true
        contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Конфигурирует ячейку коллекции данными транзакции.
        /// - Parameters:
        ///   - item: Транзакция для отображения.
        ///   - currencyCode: Код валюты для форматирования суммы.
        ///   - isPlaceholder: Флаг, указывающий, является ли ячейка заглушкой (для пустого состояния).
    func configure(_ item: Transaction, currencyCode: String, isPlaceholder: Bool = false) {
        titleLabel.text = item.title
        detailLabel.text = isPlaceholder ? item.category : "\(item.category) · \(item.date.formatted(date: .abbreviated, time: .omitted))"
        let income = item.kind == .income
        icon.image = UIImage(systemName: isPlaceholder ? "tray" : (income ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill"))
        icon.tintColor = isPlaceholder ? .secondaryLabel : (income ? .systemGreen : .systemPink)
        if isPlaceholder {
            amountLabel.text = ""
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            formatter.locale = Locale.current
            amountLabel.text = "\(income ? "+" : "−")\(formatter.string(from: NSNumber(value: item.amount)) ?? "\(item.amount)")"
        }
        amountLabel.textColor = income ? .systemGreen : .label
    }
}

private final class TransactionCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var items: [Transaction] = []
    private var currencyCode = "EUR"
    private var onSelect: ((Transaction) -> Void)?
    private var onDelete: ((Transaction) -> Void)?
    private var collectionView: UICollectionView!

    /// Вызывается после загрузки представления контроллера. Инициализирует и настраивает UICollectionView
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 16, bottom: 20, right: 16)
        layout.minimumLineSpacing = 10
        layout.estimatedItemSize = .zero
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TransactionCell.self, forCellWithReuseIdentifier: TransactionCell.reuseID)
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.contentInset.bottom = 16
    }

    /// Передает новые данные из SwiftUI в UIKit-контроллер и перезагружает коллекцию.
    /// - Parameters:
    ///   - newItems: Обновленный массив транзакций.
    ///   - currencyCode: Текущий код валюты.
    ///   - onSelect: Замыкание, вызываемое при выборе ячейки.
    ///   - onDelete: Замыкание, вызываемое при удалении ячейки.
    func update(_ newItems: [Transaction], currencyCode: String, onSelect: @escaping (Transaction) -> Void, onDelete: @escaping (Transaction) -> Void) {
        items = newItems
        self.currencyCode = currencyCode
        self.onSelect = onSelect
        self.onDelete = onDelete
        if isViewLoaded { collectionView.reloadData() }
    }
    
    /// Возвращает количество элементов в секции коллекции
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        max(items.count, 1)
    }

    /// Задает размер ячейки коллекции
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.bounds.width - 32, height: 76)
    }

    /// Настраивает и возвращает ячейку для конкретного индекса
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TransactionCell.reuseID, for: indexPath) as! TransactionCell
        if items.isEmpty {
            let placeholder = Transaction(title: "Пока нет операций", amount: 0, kind: .expense, category: "Добавьте первую запись")
            cell.configure(placeholder, currencyCode: currencyCode, isPlaceholder: true)
        } else {
            cell.configure(items[indexPath.item], currencyCode: currencyCode)
        }
        return cell
    }

    /// Обрабатывает нажатие на ячейку и вызывает замыкание onSelect
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !items.isEmpty else { return }
        onSelect?(items[indexPath.item])
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    /// Настраивает контекстное меню (долгое нажатие) для удаления операции
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !items.isEmpty else { return nil }
        let item = items[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Удалить операцию", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                    self?.onDelete?(item)
                }
            ])
        }
    }
}
