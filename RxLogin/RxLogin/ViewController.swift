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
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loginBtn.setTitleColor(.white, for: .normal)
        loginBtn.setTitleColor(.lightGray, for: .disabled)
        
        let vm = LoginViewModel.init(email: username.rx.text.orEmpty.asDriver(), password: password.rx.text.orEmpty.asDriver())
        
        vm.credintialValid
        .drive(onNext: { (valid) in
            self.loginBtn.isEnabled = valid
        })
        .addDisposableTo(bag)
        loginBtn.rx.tap
            .withLatestFrom(vm.credintialValid)
            .filter{ $0 }
            .flatMapLatest { [unowned self] valid -> Observable<AuthenticationStatus> in
                vm.login(with: self.username.text!, password: self.password.text!)
                .trackActivity(vm.activity)
                .observeOn(SerialDispatchQueueScheduler(qos: .userInteractive))
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [unowned self] autenticationStatus in
                switch autenticationStatus {
                case .none:
                    break
                case .authorise(let ac):
                    print("\(ac.firstName) - \(ac.lastName)")
                    self.nameLabel.text = ("\(ac.firstName) - \(ac.lastName)")
                    break
                case .error(let error):
                    self.nameLabel.text = "Error \(error)"
                    print(error)
                }
            })
        .addDisposableTo(bag)
        vm.activity
            .distinctUntilChanged()
            .drive(onNext: { [unowned self] active in
                self.spinner.isHidden = !active
            })
            .addDisposableTo(bag)
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
