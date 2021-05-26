# RRCombineAlamofireAPI


[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/Rahul-Mayani/RRCombineAlamofireAPI/blob/master/LICENSE)
[![iOS](https://img.shields.io/badge/Platform-iOS-purpel.svg?style=flat)](https://developer.apple.com/ios/)

[![SPM](https://img.shields.io/badge/SPM-orange.svg?style=flat)](https://swift.org/package-manager/)

[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://developer.apple.com/swift/)


Alamofire API Request by Combine framework


## Installation

#### Dependency
`Alamofire`


#### Manually
1. Download and drop `Source` folder with files in your project.
2. Add your API end point URL in your project.
3. Congratulations!  


#### SPM (Swift Package Manager)
In Xcode, use the menu File > Swift Packages > Add Package Dependency... and enter the package URL `https://github.com/Rahul-Mayani/RRCombineAlamofireAPI`.


## Usage example
To run the example project, clone the repo, and run spm from the Example directory first.


```swift

/// Uses
let createCustomSession = Session()
let request =  RRCombineAlamofireAPI.shared
                  .setSessionManager(createCustomSession) //`Session` creates and manages Alamofire's `Request` types during their lifetimes.
                  .setHttpMethod(.get) // httpMethod: GET, POST, PUT & DELETE
                  .setURL("Your API URL")
                  .setHeaders([:]) // a dictionary of parameters to apply to a `HTTPHeaders`.
                  .setParameter([:]) // a dictionary of parameters to apply to a `URLRequest`.

request.subscribe(on: DispatchQueue.global())
    .receive(on: DispatchQueue.main)
    .sink { (completion) in
       switch completion {
       case .finished:
           break
       case .failure(let error):
           print(error.localizedDescription)
       }
    } receiveValue: { (response) in
        /// The response of data type is Data.
        /// <#T##Here: decode JSON Data into your custom model structure / class#>
        print(response)
    }
    .cancel()


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


It's not part of SPM
////  subscribeAndReceivedData & Deferred as Publisher extension functions for reuse
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

```

## Contribute 

We would love you for the contribution to **RRCombineAlamofireAPI**, check the ``LICENSE`` file for more info.


## License

RRCombineAlamofireAPI is available under the MIT license. See the LICENSE file for more info.

