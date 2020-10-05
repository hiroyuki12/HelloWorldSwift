//
//  DropboxViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/05.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import BoxSDK

class BoxViewController: UIViewController {
  @IBOutlet weak var textField: UITextField!
  //イメージビューを追加
  let myImageView = UIImageView()
  @IBOutlet weak var CountLabel: UILabel!
  @IBOutlet weak var BoxPath: UILabel!
  
  var fileIds: Array<String>?
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
      isModalInPresentation = true  // 下にスワイプで閉じなくする
  }
  
  // SignInボタンタップ時
  @IBAction func TapSignIn(_ sender: Any) {
    signInDropbox()
  }
  
  @objc func signInDropbox(){
  }
  
  // Saveボタンタップ時
  @IBAction func TapSave(_ sender: Any) {
    saveText()
  }
  @objc func saveText() {
  }
  
  // Uploadボタンタップ時
  @IBAction func TapUpload(_ sender: Any) {
    uploadToDropbox()
  }
  @objc func uploadToDropbox() {
  }
  
  var count = -1
  var maxCount:UInt32 = 2000
  var fileId = "726956988746"
  var folderId = "123846554439"
  var flgFolderChange = true
  var finishListFolder = false
  
  // Downloadボタンタップ時
  @IBAction func TapDownload(_ sender: Any) {
    downloadBoxFile()
  }
  
  @objc func downloadBoxFile() {
    let client = BoxSDK.getClient(token: "BOX_DEVELOPER_TOKEN")
    
    if(flgFolderChange) {
      flgFolderChange = false
      self.stopTimer()
      //        // List contents of app folder
      client.folders.listItems(folderId: folderId, sort: .name, direction: .ascending) { results in
        switch results {
        case let .success(iterator):
          self.fileIds = []
          for _ in 1 ... 100 {  //1,000の時sleep(10) , 10の時sleep(5)
            iterator.next { result in
              switch result {
              case let .success(item):
                switch item {
                case let .file(file):
                  //print("File \(file.name) (ID: \(file.id)) is in the folder")
                  if file.name!.hasSuffix(".jpg") || file.name!.hasSuffix(".png") {
                    // Add photo!
                    self.fileIds?.append(file.id)
                  }
                case .folder(_):
                  print("") //Subfolder \(folder.name) (ID: \(folder.id)) is in the folder")
                case .webLink(_):
                  print("") //Web link \(webLink.name) (ID: \(webLink.id)) is in the folder")
                }
              case let .failure(error):
                print(error)
              }
            }
          }
        case let .failure(error):
          print(error)
        }
      }
      sleep(5)
      
      self.maxCount = UInt32(self.fileIds!.count)
      self.finishListFolder = true
      self.CountLabel.text = String(self.count+1) + " / " + String(self.maxCount)
      self.startTimer()
    }
    
    //ダウンロード処理
    //ダウンロード先URLを設定
    let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let pathComponent = fileId  // 任意のdownload先ファイル名
    let url:URL = directoryURL.appendingPathComponent(pathComponent)
    
    print("Downloaded fileId: \(pathComponent)")
    //表示更新
    if(finishListFolder) {
      CountLabel.text = String(count+1) + " / " + String(maxCount)
    }
    else {
      CountLabel.text = "loading... wait"
    }
    BoxPath.text = String(fileId)
    
    client.files.download(fileId: fileId, destinationURL: url) { (result: Result<Void, BoxSDKError>) in
      guard case .success = result else {
        print("Error downloading file")
        return
      }
      print("File downloaded successfully")
    }
    
    sleep(2)
    
    do {
      let data = try Data(contentsOf: url)  //urlをData型に変換
      let img = UIImage(data: data)  //Data型に変換したurlをUIImageに変換
      let iv:UIImageView = UIImageView(image:img)  //UIImageをivに変換
      //try FileManager.default.removeItem(at: url)  //downloadしたファイルを削除
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
  }
  
  func startTimer() {
    timer = Timer.scheduledTimer(
      timeInterval: 4.0,
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
      if(folderId == "123846554439") {// /
        folderId = "123846894623"  // /1
      }
      else if(folderId == "123846894623") {  // /1
        folderId = "123846554439"  // /
      }
      flgFolderChange = true
      count = 0
    }
    print(count)
    //print("self.filenames![?]")
    
    if(flgFolderChange){
      if(folderId == "123846894623") {
        fileId = "726968292185"
      }
      else if(folderId == "123846554439") {
        fileId = "726956988746"
      }
    }
    else {
      fileId = self.fileIds![count]
    }
    
    downloadBoxFile()
  }
  
  // Backボタンタップ時
  @IBAction func TapBack(_ sender: Any) {
//    count = count - 1
//
//    print(count)
//    print("self.filenames![?]")
//    print(self.fileIds![count])
//
//    fileId = "/アプリ/Photo Watch/" + folderId + self.fileIds![count]
//
//    downloadBoxFile()
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
