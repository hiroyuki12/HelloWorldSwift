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

    // アップロードボタンを追加
    let uploadButton = UIButton(type: UIButton.ButtonType.system)
    uploadButton.frame = CGRect(x: 10, y: 390, width: 100, height: 30)
    uploadButton.setTitle("Upload", for: .normal)
    uploadButton.addTarget(self, action: #selector(self.uploadToDropbox), for: .touchUpInside)
    self.view.addSubview(uploadButton)
    
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
      print("fileURL")
      print(fileURL)
      try textField.text?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
      print("Save text file")
    } catch {
      // 失敗
    }
  }
  @objc func uploadToDropbox() {
      if let client = DropboxClientsManager.authorizedClient {
        let fileData = "testing data example".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        
        let request = client.files.upload(path: "/sample.txt", input: fileData)
            .response { response, error in
                if let response = response {
                    print(response)
                } else if let error = error {
                    print(error)
                }
            }
            .progress { progressData in
                print(progressData)
            }

        // in case you want to cancel the request
//        if someConditionIsSatisfied {
//            request.cancel()
//        }
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
