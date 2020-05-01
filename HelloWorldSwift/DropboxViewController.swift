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
  //イメージビューを追加
  let myImageView = UIImageView()
  
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
    
    //ダウンロードボタンを追加
    let downloadButton = UIButton(type: UIButton.ButtonType.system)
    downloadButton.frame = CGRect(x: 10, y: 220, width: 100, height: 30)
    downloadButton.setTitle("Download", for: .normal)
    downloadButton.addTarget(self, action: #selector(self.downloadDropboxFile), for: .touchUpInside)
    self.view.addSubview(downloadButton)

    //画像表示エリアの記載
    myImageView.frame = CGRect(x: 10, y: 500, width: 200, height: 120)
    self.view.addSubview(myImageView)
    
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
  @objc func downloadDropboxFile() {
     //ダウンロード処理
     if let client = DropboxClientsManager.authorizedClient {
       //ダウンロード先URLを設定
       let destination : (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
         let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
         let UUID = Foundation.UUID().uuidString
         var fileName = ""
         if let suggestedFilename = response.suggestedFilename {
             fileName = suggestedFilename
         }
         let pathComponent = "\(UUID)-\(fileName)"
         return directoryURL.appendingPathComponent(pathComponent)
       }
       //画面描画処理
       client.files.download(path: "/携帯/docomoF505i/100f505i-1/f1000001.jpg", destination: destination).response { response, error in
         if let (metadata, url) = response {
           print("Downloaded file name: \(metadata.name)")
           do {
             //urlをData型に変換
             let data = try Data(contentsOf: url)
             //Data型に変換したurlをUIImageに変換
             let img = UIImage(data: data)
             //UIImageをivに変換
             let iv:UIImageView = UIImageView(image:img)
             //変換したivをviewに追加
             self.view.addSubview(iv)
             //表示位置決定
             iv.layer.position = CGPoint(x: self.view.bounds.width/2, y: 400.0)
           } catch let err {
             print("Error : \(err.localizedDescription)")
           }
         } else {
           print(error!)
         }
       }
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
