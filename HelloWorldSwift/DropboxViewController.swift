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
  @IBOutlet weak var textField: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()

      // Do any additional setup after loading the view.
    // ログインボタンを追加
    let signInButton = UIButton(type: UIButton.ButtonType.system)
    signInButton.frame = CGRect(x: 10, y: 190, width: 100, height: 30)
    signInButton.setTitle("Sign In",  for: .normal)
    signInButton.addTarget(self, action: #selector(self.signInDropbox), for: .touchUpInside)
    self.view.addSubview(signInButton)
    
    // テキスト保存ボタンを追加
    let saveButton = UIButton(type: UIButton.ButtonType.system)
    saveButton.frame = CGRect(x: 10, y: 290, width: 100, height: 30)
    saveButton.setTitle("Save", for: .normal)
    saveButton.addTarget(self, action: #selector(self.saveText), for: .touchUpInside)
    self.view.addSubview(saveButton)
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
  @objc func saveText() {
    let tmpURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
//    let fileURLx = tmpURL.URLByAppendingPathComponent("sample.txt")
    let fileURL = tmpURL.appendingPathComponent("sample.txt")!
    do {
//      try textField.text?.writeToURL(fileURL, atomically: true, encoding: NSUTF8StringEncoding)
      
      try textField.text?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
      print("Save text file")
    } catch {
      // 失敗
    }
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
