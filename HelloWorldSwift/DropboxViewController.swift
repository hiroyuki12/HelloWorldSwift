//
//  DropboxViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/27.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import SwiftyDropbox

class DropboxViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

      // Do any additional setup after loading the view.
    // ログインボタンを追加
    let signInButton = UIButton(type: UIButton.ButtonType.system)
    signInButton.frame = CGRect(x: 10, y: 190, width: 100, height: 30)
    signInButton.setTitle("Sign In",  for: .normal)
    signInButton.addTarget(self, action: #selector(self.signInDropbox), for: .touchUpInside)
    self.view.addSubview(signInButton)
  }
  @objc func signInDropbox(){
    if let _ = DropboxClientsManager.authorizedClient {
      //既にログイン済みだとクラッシュするのでログアウト
      DropboxClientsManager.unlinkClients()
    }
    DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                  controller: self,
                                                  openURL: { (url: URL) -> Void in
                                                    UIApplication.shared.openURL(url)
    })
  }
    
  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destination.
      // Pass the selected object to the new view controller.
  }
  */

}
