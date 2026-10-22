import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var rates: [String: Double] = [:]
    @Published private(set) var baseCode = "EUR"
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let service: ExchangeRateServiceProtocol

    init(service: ExchangeRateServiceProtocol = ExchangeRateService()) {
        self.service = service
    }

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
