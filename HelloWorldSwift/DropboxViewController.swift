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
  @IBOutlet weak var CountLabel: UILabel!
  @IBOutlet weak var DropboxPath: UILabel!
  
  var filenames: Array<String>?
  var filename: String?
  
  var timer: Timer!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    //画像表示エリアの記載
    myImageView.frame = CGRect(x: 10, y: 500, width: 200, height: 120)
    self.view.addSubview(myImageView)
  }
  
  override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくなる
  }
  
  // SignInボタンタップ時
  @IBAction func TapSignIn(_ sender: Any) {
    signInDropbox()
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
  
  // Saveボタンタップ時
  @IBAction func TapSave(_ sender: Any) {
    saveText()
  }
  @objc func saveText() {
    let tmpURL = NSURL(fileURLWithPath: NSTemporaryDirectory())
    let fileURL = tmpURL.appendingPathComponent("sample.txt")!
    do {
      try textField.text?.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
      print("Save text file")
    } catch {
      // 失敗
    }
  }
  
  // Uploadボタンタップ時
  @IBAction func TapUpload(_ sender: Any) {
    uploadToDropbox()
  }
  @objc func uploadToDropbox() {
    if let client = DropboxClientsManager.authorizedClient {
      let fileData = "testing data example".data(using: String.Encoding.utf8, allowLossyConversion: false)!

      _ = client.files.upload(path: "/sample.txt", input: fileData)
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

//         in case you want to cancel the request
//        if someConditionIsSatisfied {
//            request.cancel()
//        }
    }
  }
  
  var count = -1
  var maxCount:UInt32 = 2000  // 2,000より大きいとエラー
  var fileName = "/アプリ/Photo Watch/1396713410486.jpg"
//  var fileName = "/携帯/docomoF505i/100f505i-1/f1000001.jpg"
  var folderName = ""
  var flgFolderChange = true
  var finishListFolder = false
  
  // Downloadボタンタップ時
  @IBAction func TapDownload(_ sender: Any) {
    downloadDropboxFile()
  }
  
  @objc func downloadDropboxFile() {
    if let client = DropboxClientsManager.authorizedClient {
      if(flgFolderChange) {
        flgFolderChange = false
        self.stopTimer()
        // List contents of app folder
        _ = client.files.listFolder(path: "/アプリ/Photo Watch/" + folderName, limit:2000).response { response, error in
//          _ = client.files.listFolder(path: "/携帯/docomoF505i/100f505i-1/" + folderName, limit:2000).response { response, error in
          if let result = response {
            print("Folder contents:")
            print("result.entries.count")
            print(result.entries.count)  // 500
            self.filenames = []
            for entry in result.entries {
              // Check that file is a photo (by file extension)
              if entry.name.hasSuffix(".jpg") || entry.name.hasSuffix(".png") {
                // Add photo!
                self.filenames?.append(entry.name)
              }
            }
            self.maxCount = UInt32(self.filenames!.count)
            self.finishListFolder = true
            self.CountLabel.text = String(self.count+1) + " / " + String(self.maxCount)
            self.startTimer()
          }
        }
      }
    }
    
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
        let pathComponent = "Dropbox-\(fileName)-\(UUID)" // filename download
        return directoryURL.appendingPathComponent(pathComponent)
      }
      //画面描画処理
      //      print("count")
      //      print(String(count))
      //表示更新
      if(finishListFolder) {
        CountLabel.text = String(count+1) + " / " + String(maxCount)
      }
      else {
        CountLabel.text = "loading... wait"
      }
      DropboxPath.text = String(fileName)
//      client.files.download(path: fileName + String(count) + fileExt, destination: destination).response { response, error in
        client.files.download(path: fileName, destination: destination).response { response, error in
        if let (metadata, url) = response {
          print("Downloaded file name: \(metadata.name)")
          //print(url)  //ダウンロード先
          do {
            let data = try Data(contentsOf: url)  //urlをData型に変換
            let img = UIImage(data: data)  //Data型に変換したurlをUIImageに変換
            let iv:UIImageView = UIImageView(image:img)  //UIImageをivに変換
            try FileManager.default.removeItem(at: url)  //downloadしたファイルを削除
            let maxSize: CGFloat = 390.0
            var tmpWidth = 0
            var tmpHeight = 0
            if img!.size.width >= img!.size.height {
              tmpWidth = Int((maxSize / img!.size.height) * img!.size.width)
              tmpHeight = Int(maxSize)
            } else {
              tmpWidth = Int(maxSize)
              tmpHeight = Int((maxSize / img!.size.width) * img!.size.height)
            }
//            let rect:CGRect = CGRect(x:0, y:0, width:390, height:520)  //サイズを変更
            let rect:CGRect = CGRect(x:0, y:0, width:tmpWidth, height:tmpHeight)  //サイズを変更
            iv.frame = rect
            
            let tagViewB = 123
            iv.tag = tagViewB
            let fetchedViewB = self.view.viewWithTag(tagViewB)
            fetchedViewB?.removeFromSuperview()
            
            self.view.addSubview(iv)  //変換したivをviewに追加
            iv.layer.position = CGPoint(x: self.view.bounds.width/2, y: 360.0)  //表示位置決定
          } catch let err {
            print("Error : \(err.localizedDescription)")
          }
        } else {
          print(error!)
        }
      }
    }
  }
  
  func startTimer() {
    timer = Timer.scheduledTimer(
      timeInterval: 2.0,
      target: self,
      selector: #selector(self.TapNext),
      userInfo: nil,
      repeats: true)
  }
  
  func stopTimer() {
    if timer != nil {
      timer.invalidate()
    }
  }

  // Nextボタンタップ時
  @IBAction func TapNext(_ sender: Any) {
    count = count + 1
    
    if(count == self.maxCount) {
      if(folderName == "") {
        folderName = "1/"
      }
      else if(folderName == "1/") {
        folderName = ""
      }
      flgFolderChange = true
      count = 0
    }
    print(count)
    //print("self.filenames![?]")
    
    if(flgFolderChange){
      if(folderName == "1/") {
        fileName = "/アプリ/Photo Watch/" + folderName + "IMG_20150604_235340.jpg"
//        filename = "/携帯/docomoF505i/100f505i-1/" + folderName + "f1000012.jpg"
      }
      else if(folderName == "") {
        fileName = "/アプリ/Photo Watch/" + folderName + "1396713410486.jpg"
//        filename = "/携帯/docomoF505i/100f505i-1/" + folderName + "f1000001.jpg"
      }
    }
    else {
      fileName = "/アプリ/Photo Watch/" + folderName + self.filenames![count]
//      fileName = "/携帯/docomoF505i/100f505i-1/" + folderName + self.filenames![count]
    }
    
    downloadDropboxFile()
  }
  
  // Backボタンタップ時
  @IBAction func TapBack(_ sender: Any) {
    count = count - 1
    
    print(count)
    print("self.filenames![?]")
    print(self.filenames![count])
    
    fileName = "/アプリ/Photo Watch/" + folderName + self.filenames![count]
    
    downloadDropboxFile()
  }
  
  // Closeボタンタップ時
  @IBAction func tapClose(_ sender: Any) {
    stopTimer()
    //戻る
    dismiss(animated: true, completion: nil)
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
