//
//  LoginService.swift
//  RxLogin
//
//  Created by siavash abbasalipour on 29/6/17.
//  Copyright © 2017 Siavash. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxSwiftUtilities
import SwiftyJSON

enum AuthenticationStatus {
    case none
    case error(AuthenticationError)
    case authorise(AccountModel)
}
enum AuthenticationError: Error {
    case server
    case badReponse
    case badCredentials
}
typealias JSONDictionary = [String: Any]
class LoginService {
    
    let status = Variable(AuthenticationStatus.none)
    
    static var shared = LoginService()
    
    fileprivate init() {}
    
    func login(with email: String, password: String) -> Observable<AuthenticationStatus> {
        let params: [String: Any] = ["AppleDeviceId":"", "Email":email,"Password":password,"AndroidUniqueId":""]
        let url = URL.init(string: "[]")
        
        var request = URLRequest.init(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        request.httpBody = jsonData
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        
        return session.rx.json(request: request)
            .map {
                guard let json = $0 as? JSONDictionary else {
                        return .error(.badReponse)
                }
                if let fname = json["FirstName"] as? String, let lname = json["LastName"] as? String {
                    let ac = AccountModel.init(firstName: fname, lastName: lname, email: email)
                    return .authorise(ac)
                } else {
                    return .error(.badReponse)
                }
        }
    }
}
