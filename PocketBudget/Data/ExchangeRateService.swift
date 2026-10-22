import Foundation



struct ExchangeRateResponse: Decodable {
    let result: String
    let base_code: String
    let rates: [String: Double]
}

protocol ExchangeRateServiceProtocol {
    /// Загружает актуальные курсы валют относительно указанной базовой валюты
    /// - Parameter base: Трехбуквенный код базовой валюты (например, "EUR", "USD")
    /// - Returns: Объект `ExchangeRateResponse`, содержащий словарь курсов валют
    func fetchRates(base: String) async throws -> ExchangeRateResponse
}

struct ExchangeRateService: ExchangeRateServiceProtocol {
    /// Выполняет сетевой запрос к API `open.er-api.com` для получения курсов валют.
    /// - Parameter base: Код базовой валюты.
    /// - Returns: Декодированный ответ сервера.
    /// - Throws: `URLError` при проблемах с сетью или `DecodingError` при неверном формате.
    func fetchRates(base: String) async throws -> ExchangeRateResponse {
        let code = base.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "EUR"
        guard let url = URL(string: "https://open.er-api.com/v6/latest/\(code)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
    }
}
