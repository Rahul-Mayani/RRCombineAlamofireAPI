//
//  ViewController.swift
//  ExampleApp
//
//  Created by Rahul Mayani on 12/05/21.
//

import UIKit
import Combine
import RRCombineAlamofireAPI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
     
        /// Example 1
        /// Loader start
        let userIds = [1, 2, 3]
        Just(userIds)
            .setFailureType(to: Error.self)
            .flatMap { (values) -> AnyPublisher<[User], Error> in
                let tasks = values.publisher.flatMap { userId in
                                 RRCombineAlamofireAPI.shared.setURL("https://jsonplaceholder.typicode.com/users/\(userId)")
                                        .map { $0 }
                                        .decode(type: User.self, decoder: JSONDecoder())
                                        .setDeferred()
                            }
                return Publishers.MergeMany(tasks).collect().setDeferred()
            }
            .subscribeAndReceivedData { (allUsers) in
                print("Got users:")
                /// Loader stop
            }
        
        /// Example 2
        /// Loader start
        RRCombineAlamofireAPI.shared.setURL("https://jsonplaceholder.typicode.com/users/1")
            .flatMap { response -> AnyPublisher<Data, Error> in
                let data = User.decodeJsonData(response)
                print(data?.username ?? "")
                return RRCombineAlamofireAPI.shared.setURL("https://jsonplaceholder.typicode.com/users/2")
                        //.delay(for: .seconds(1), scheduler: RunLoop.main)
                        .setDeferred()
            }
            .subscribeAndReceivedData { (response) in
                guard let data = response as? Data else { return }
                let user = User.decodeJsonData(data)
                print(user?.username ?? "")
                /// Loader stop
            }
    }
}
