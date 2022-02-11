//
//  BoxViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/05.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

#if os(iOS)
  import AuthenticationServices
#endif
import UIKit
import BoxSDK

class BoxViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
  private var sdk: BoxSDK!
  private var client2: BoxClient!
  private var folderItems: [FolderItem] = []
  private let initialPageSize: Int = 100
  
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
    sdk = BoxSDK(clientId: Constants.clientId, clientSecret: Constants.clientSecret)
    //画像表示エリアの記載
    myImageView.frame = CGRect(x: 10, y: 500, width: 200, height: 120)
    self.view.addSubview(myImageView)
  }
  
  override func viewWillLayoutSubviews() {  // isModalInPresentationにtrueを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくする
  }
  
  // SignInボタンタップ時
  @IBAction func TapSignIn(_ sender: Any) {
    signInDropbox()
  }
  
  @objc func signInDropbox(){
    getOAuthClient()
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
    signInDropbox()
    downloadBoxFile()
  }
  
  @objc func downloadBoxFile() {
    //let client = BoxSDK.getClient(token: "BOX_DEVELOPER_TOKEN")
    guard let client = self.client2 else { return }
      
    // List contents of app folder
    if(flgFolderChange) {
      flgFolderChange = false
      self.stopTimer()
      // List contents of app folder
      client.folders.listItems(folderId: folderId, usemarker: false, marker: "", offset: 0, limit: 100, sort: .name, direction: .ascending) { results in
        switch results {  // switch 1
        case let .success(iterator):
          self.fileIds = []
          for _ in 1 ... 2000 {  //2,000の時sleep(18), 1,000の時sleep(10) , 10の時sleep(5)
            iterator.next { result in
              switch result {  // switch 2
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
              case let .failure(error):  // switch 2
                print("error failure 1")
                print(error)
              }
            }
          }
        case let .failure(error):  // switch 1
          print("error failure 2")
          print(error)
          return
        }
      }
      
//      sleep(1)
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
      try FileManager.default.removeItem(at: url)  //downloadしたファイルを削除
      let maxSize: CGFloat = 390.0
      var tmpWidth = 0
      var tmpHeight = 0
      guard let img2 = img else { return }
      if img2.size.width >= img2.size.height {
        tmpWidth = Int((maxSize / img2.size.height) * img2.size.width)
        tmpHeight = Int(maxSize)
      } else {
        tmpWidth = Int(maxSize)
        tmpHeight = Int((maxSize / img2.size.width) * img2.size.height)
      }
//      let rect:CGRect = CGRect(x:0, y:0, width:390, height:520)  //サイズを変更
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
    print("TapNext")
    
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
      if(self.fileIds?.count ?? 0 > 0) {
        fileId = self.fileIds![count]
      }
      else {
        self.CountLabel.text = "Error"
      }
    }
    
    guard let fileIds2 = self.fileIds else { return }
    self.maxCount = UInt32(fileIds2.count)
    self.finishListFolder = true
    self.CountLabel.text = String(self.count+1) + " / " + String(self.maxCount)
    
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


// MARK: - Helpers
extension BoxViewController {
  func getOAuthClient() {
    if #available(iOS 13, *) {
      sdk.getOAuth2Client(tokenStore: KeychainTokenStore(), context:self) { [weak self] result in
        switch result {
        case let .success(client):
          self?.client2 = client
          //self?.getSinglePageOfFolderItems()
          print("success sdk.getOAuth2Client !!!!!!!!!!!!!")
        case let .failure(error):
          print("error in getOAuth2Client: \(error)")
          self?.addErrorView(with: error)
        }
      }
    } else {
      sdk.getOAuth2Client(tokenStore: KeychainTokenStore()) { [weak self] result in
        switch result {
        case let .success(client):
          self?.client2 = client
          //self?.getSinglePageOfFolderItems()
        case let .failure(error):
          print("error in getOAuth2Client: \(error)")
          self?.addErrorView(with: error)
        }
      }
    }
  }
  
  func getSinglePageOfFolderItems() {
//    client2.folders.listItems(
//      folderId: BoxSDK.Constants.rootFolder,
//      usemarker: true,
//      fields: ["modified_at", "name", "extension"]
//    ){ [weak self] result in
//      guard let self = self else {return}
//
//      switch result {
//      case let .success(items):
//        self.folderItems = []
//
//        for i in 1...self.initialPageSize {
//          print ("Request Item #\(String(format: "%03d", i)) |")
//          items.next { result in
//            switch result {
//            case let .success(item):
//              print ("    Got Item #\(String(format: "%03d", i)) | \(item.debugDescription))")
//              DispatchQueue.main.async {
//                self.folderItems.append(item)
//                //self.tableView.reloadData()
//                self.navigationItem.rightBarButtonItem?.title = "Refresh"
//              }
//            case let .failure(error):
//              print ("     No Item #\(String(format: "%03d", i)) | \(error.message)")
//              return
//            }
//          }
//        }
//      case let .failure(error):
//        self.addErrorView(with: error)
//      }
//    }
  }
}

private extension BoxViewController {

  func addErrorView(with error: Error) {
//    DispatchQueue.main.async { [weak self] in
//      guard let self = self else { return }
//      self.view.addSubview(self.errorView)
//      let safeAreaLayoutGuide = self.view.safeAreaLayoutGuide
//      NSLayoutConstraint.activate([
//        self.errorView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
//        self.errorView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
//        self.errorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
//        self.errorView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
//      ])
//      self.errorView.displayError(error)
//    }
  }

  func removeErrorView() {
//    if !view.subviews.contains(errorView) {
//      return
//    }
//    DispatchQueue.main.async {
//      self.errorView.removeFromSuperview()
//    }
  }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
/// Extension for ASWebAuthenticationPresentationContextProviding conformance
extension BoxViewController {
  @available(iOS 13.0, *)
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return self.view.window ?? ASPresentationAnchor()
  }
}

