//
//  LoginViewModel.swift
//  RxLogin
//
//  Created by siavash abbasalipour on 29/6/17.
//  Copyright © 2017 Siavash. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxSwiftUtilities


struct LoginViewModel {
    
    let activity = ActivityIndicator()
    
    var account: Driver<AccountModel>?
    let credintialValid: Driver<Bool>
    
    init(email: Driver<String>, password: Driver<String>) {
        
        let emailValid = email
            .distinctUntilChanged()
            .throttle(0.3)
            .map{ $0.utf8.count > 3}
        
        let passwordValid = password
            .distinctUntilChanged()
            .throttle(0.3)
            .map { $0.utf8.count > 3}
        
        credintialValid = Driver.combineLatest(emailValid, passwordValid) { $0 && $1 }
    }
    
    func login(with email: String, password: String) -> Observable<AuthenticationStatus> {
        return LoginService.shared.login(with: email,password: password)
    }
    
}

struct AccountModel {
    let firstName: String
    let lastName: String
    let email: String
}
