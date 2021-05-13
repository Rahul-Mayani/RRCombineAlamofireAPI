//
//  Extension.swift
//  ExampleApp
//
//  Created by Rahul Mayani on 12/05/21.
//

import Foundation
import Combine

extension Decodable {
    static func decodeJsonData(_ data: Data) -> Self? {
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch let error {
            debugPrint(error.localizedDescription)
            //UIAlertController
            return nil
        }
    }
}

extension Publisher {
    // MARK: - Subscribe And Received Data From Server -
    func subscribeAndReceivedData(_ qos: DispatchQoS = .background, data: @escaping((Any) -> ())) {
        subscribe(on: DispatchQueue( label: "rrcombine.queue.\(qos)", qos: qos, attributes: [.concurrent], target: nil))
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                    /// UIAlertController
                }
                /// Loader stop
            } receiveValue: { response in
                data(response)
            }.cancel()
    }
    // MARK: - Deferred -
    func setDeferred() -> AnyPublisher<Self.Output, Self.Failure> {
        Deferred { self }
            .eraseToAnyPublisher()
    }
}
