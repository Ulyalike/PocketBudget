import Foundation

struct ExchangeRateResponse: Decodable {
    let result: String
    let base_code: String
    let rates: [String: Double]
}

protocol ExchangeRateServiceProtocol {
    func fetchRates(base: String) async throws -> ExchangeRateResponse
}

struct ExchangeRateService: ExchangeRateServiceProtocol {
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
