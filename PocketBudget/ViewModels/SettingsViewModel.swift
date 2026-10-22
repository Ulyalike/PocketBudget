import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    /// Словарь загруженных курсов валют (код валюты: значение курса).
    @Published private(set) var rates: [String: Double] = [:]
    /// Базовая валюта, относительно которой запрашиваются курсы.
    @Published private(set) var baseCode = "EUR"
    /// Флаг, указывающий на процесс загрузки данных.
    @Published var isLoading = false
    /// Текст ошибки для отображения пользователю (если загрузка не удалась).
    @Published var errorMessage: String?
    private let service: ExchangeRateServiceProtocol

    /// Инициализирует ViewModel с внедрением сервиса курсов валют.
    /// - Parameter service: Сервис для загрузки курсов (по умолчанию `ExchangeRateService`).
    init(service: ExchangeRateServiceProtocol = ExchangeRateService()) {
        self.service = service
    }

    /// Асинхронно загружает курсы валют с публичного API и обновляет состояние экрана.
    func loadRates() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.fetchRates(base: baseCode)
            rates = response.rates
        } catch {
            errorMessage = "Не удалось загрузить курсы. Проверьте подключение к интернету."
        }
    }
}
