//
//  APIService.swift
//  empowerPlant
//
//  Simplified API Service for irrigation integration
//

import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://127.0.0.1:8080/api/v1"
    
    private init() {}
    
    private func createRequest(endpoint: String, method: String = "GET") -> URLRequest {
        let url = URL(string: "\(baseURL)/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
    
    // Get irrigation status
    func getIrrigationStatus(completion: @escaping (Result<IrrigationStatus, Error>) -> Void) {
        let request = createRequest(endpoint: "irrigation/status")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey : "No data in response"])
                completion(.failure(error))
                return
            }
            
            do {
                let apiResponse = try JSONDecoder().decode(APIResponse<IrrigationStatus>.self, from: data)
                if let status = apiResponse.data, apiResponse.success {
                    completion(.success(status))
                } else {
                    let error = NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey : apiResponse.message])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Add more methods for other API calls...
}

