//
//  ViewController.swift
//  RxLogin
//
//  Created by siavash abbasalipour on 15/6/17.
//  Copyright © 2017 Siavash. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var nameLabel: UILabel!
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let usernameObserver = username.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map({
                self.username.text
            })
        let passwordObserver = password.rx.controlEvent(.editingDidEndOnExit).asObservable()
            .map({
                self.password.text
            })
        let loginObserver = Observable.combineLatest(usernameObserver,passwordObserver) { (username: $0, password: $1) }
            .filter {
                (($0.username ?? "").characters.count > 0) &&
                    (($0.password ?? "").characters.count > 0)
        }
        
        let flatMapLoginObserver = loginObserver.flatMapLatest {
            return LoginAPI.shared.doLoginWith(username: $0!, password: $1!).catchErrorJustReturn(LoginAPI.Account.empty)
            }.asDriver(onErrorJustReturn: LoginAPI.Account.empty)
        
        flatMapLoginObserver
            .map {"\($0.name)"}
            .drive(nameLabel.rx.text)
            .disposed(by: bag)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}



class LoginAPI {
    struct Account {
        let name: String
        let address: String
        let phone: String
        
        static let empty = Account(name: "", address: "", phone: "")
    }
    static var shared: LoginAPI {
        return LoginAPI()
    }
    func doLoginWith(username: String, password: String) -> Observable<Account> {
        return buildLoginRequestWith(username: username, password: password).map({ json in
            return Account(name: json[""].string ?? "",
                           address: json[""].string ?? "",
                           phone: json[""].string ?? "")
        })
    }
    
    private func buildLoginRequestWith(username: String, password: String) -> Observable<JSON> {
        let params: [String: Any] = ["AppleDeviceId":"", "Email":username,"Password":password,"AndroidUniqueId":""]
        let url = URL.init(string: "https://connectdev1.mobileden.com.au/api/prod/e72f1bbf-27f5-440a-a9da-de763d9aaa08/1/7wp28dKFv5APhzDoraUZKve8VSY6Z50H/Authentication/Login?returnUserDetails=true&?expiry=false")
        
        var request = URLRequest.init(url: url!)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        request.httpBody = jsonData
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        
        return session.rx.data(request: request).map { JSON(data: $0) }
    }
}
