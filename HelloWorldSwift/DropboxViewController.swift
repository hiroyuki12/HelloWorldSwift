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
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    //画像表示エリアの記載
    myImageView.frame = CGRect(x: 10, y: 500, width: 200, height: 120)
    self.view.addSubview(myImageView)
    
    self.filenames = []
    
    if let filename = self.filename {
      let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Dropbox.DropboxPhotoWatch123")
      if let fileURL = containerURL?.appendingPathComponent(filename) {
        print("Finding file at URL: \(fileURL)")
        if let data = try? Data(contentsOf: fileURL) {
          print("Image found in cache.")
          self.myImageView.image = UIImage(data: data)  // Display image
        } else {
          print("Image not cached!")
        }
      }
    }
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

        // in case you want to cancel the request
//        if someConditionIsSatisfied {
//            request.cancel()
//        }
    }
  }
  
  var count = 0
  var maxCount = 500
//  var fileName = "/携帯/docomoF505i/100f505i-1/f10000"//10.jpg"
//  var fileName = "/アプリ/Photo Watch/"//1396713410486.jpg"
  var fileName = "/アプリ/Photo Watch/1396713410486.jpg"
  var fileExt = ".jpg"
  
  // Downloadボタンタップ時
  @IBAction func TapDownload(_ sender: Any) {
    downloadDropboxFile()
  }
  
  @objc func downloadDropboxFile() {
    if let client = DropboxClientsManager.authorizedClient {
      // List contents of app folder
      _ = client.files.listFolder(path: "/アプリ/Photo Watch/").response { response, error in
        if let result = response {
          print("Folder contents:")
          print("result.entries.count")
          print(result.entries.count)  // 500
          for entry in result.entries {
            // Check that file is a photo (by file extension)
            if entry.name.hasSuffix(".jpg") || entry.name.hasSuffix(".png") {
              // Add photo!
              self.filenames?.append(entry.name)
            }
          }
        }
      }
    }
//
//    // logout
//    // Clear the app group of all files
//    if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.Dropbox.DropboxPhotoWatch123") {
//
//      // Fetch all files in the app group
//      do {
//        let fileURLArray = try FileManager.default.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: [URLResourceKey.nameKey], options: [])
//
//        print("fileURLArray.count")
//        print(fileURLArray.count)
//        for fileURL in fileURLArray {
//          // Check that file is a photo (by file extension)
//          if fileURL.absoluteString.hasSuffix(".jpg") || fileURL.absoluteString.hasSuffix(".png") {
//
//            //                    do {
//            // Delete the photo from the app group
//            //try FileManager.default.removeItem(at: fileURL)
//            print(fileURL)
//            //                    } catch _ as NSError {
//            //                        // Do nothing with the error
//            //                    }
//          }
//        }
//      } catch _ as NSError {
//        // Do nothing with the error
//      }
//    }
    
    //
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
      //      print("count")
      //      print(String(count))
      //表示更新
      CountLabel.text = String(count) + " / " + String(maxCount)
      DropboxPath.text = String(fileName)
//      client.files.download(path: fileName + String(count) + fileExt, destination: destination).response { response, error in
        client.files.download(path: fileName, destination: destination).response { response, error in
        if let (metadata, url) = response {
          print("Downloaded file name: \(metadata.name)")
          do {
            let data = try Data(contentsOf: url)  //urlをData型に変換
            let img = UIImage(data: data)  //Data型に変換したurlをUIImageに変換
            let iv:UIImageView = UIImageView(image:img)  //UIImageをivに変換
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
            
            var tagViewB = 27
            iv.tag = tagViewB
            var fetchedViewB = self.view.viewWithTag(tagViewB)
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
  
  // Nextボタンタップ時
  @IBAction func TapNext(_ sender: Any) {
    
    count = count + 1
    
    print(count)
    print("self.filenames![?]")
    print(self.filenames![count])
    
    fileName = "/アプリ/Photo Watch/" + self.filenames![count]
    /*
    if fileName == "/携帯/docomoF505i/100f505i-1/f10000" {
      if(count == 31) { count = 33 }
      if(count == 70) {  //69
        fileName = "/携帯/docomoF505i/100f505i-2/f10000"
        count = 10
        maxCount = 43
      }
    }
    if fileName == "/携帯/docomoF505i/100f505i-2/f10000" && count == 44 {  //43
      fileName = "/携帯/softbank705SH/Image0"
      count = 14
      maxCount = 88
    }
    if fileName == "/携帯/softbank705SH/Image0" {
      if(count==16){count=17}
      if(count==18){count=19}
      if(count==20){count=25}
      if(count==27){count=29}
      if(count==30){count=31}
      if(count==32){count=34}
      if(count==35){count=38}
      if(count==40){count=41}
      if(count==43){count=44}
      if(count==45){count=46}
      if(count==48){count=52}
      if(count==53){count=54}
      if(count==55){count=59}
      if(count==60){count=61}
      if(count==65){count=66}
      if(count==68){count=69}
      if(count==72){count=74}
      if(count==75){count=76}
      if(count==78){count=79}
      if(count==84){count=85}
      if(count == 89) { //88
        fileName = "/携帯/photo/Image1"
        count = 10
        maxCount = 85
      }
    }
    if fileName == "/携帯/photo/Image1" {
      if(count==13){count=14}
      if(count==18){count=19}
      if(count==20){count=21}
      if(count==24){count=26}
      if(count==27){count=34}
      if(count==35){count=36}
      if(count==38){count=39}
      if(count==46){count=48}
      if(count==51){count=52}
      if(count==54){count=60}
      if(count==69){count=71}
      if(count==73){count=74}
      if(count==86){  //85
        fileName = "/Photos/2011-03-iphone/IMG_10"
        count = 12
        maxCount = 99
      }
    }
    if fileName == "/Photos/2011-03-iphone/IMG_10" {
      if(count==17){count=20}
      if(count==21){count=23}
      if(count==24){count=27}
      if(count==29){count=30}
      if(count==37){count=39}
      if(count==41){count=42}
      if(count==44){count=45}
      if(count==48){count=49}
      if(count==50){count=51}
      if(count==59){count=60}
      if(count==61){count=66}
      if(count==89){count=90}
      if count == 100 {  //99
        fileName = "/Photos/2011-03-iphone/IMG_11"
        count = 10
        maxCount = 91
      }
    }
    if fileName == "/Photos/2011-03-iphone/IMG_11" {
      if(count==14){count=19}
      if(count==23){count=24}
      if(count==27){count=31}
      if(count==34){count=35}
      if(count==36){count=38}
      if(count==48){count=49}
      if(count==55){count=56}
      if(count==83){count=87}
      if count == 92 {  //91
        fileName = "/Photos/2011-03-iphone/IMG_12"
        count = 10
        maxCount = 99
      }
    }
    if fileName == "/Photos/2011-03-iphone/IMG_12" {
      if(count==11){count=19}
      if(count==20){count=23}
      if(count==32){count=34}
      if(count==37){count=39}
      if(count==41){count=47}
      if(count==49){count=50}
      if(count==52){count=55}
      if(count==56){count=57}
      if(count==67){count=70}
      if(count==73){count=77}
      if(count==80){count=81}
      if(count==82){count=96}
      if count == 100 {  //99
        fileName = "/Photos/2011-03-iphone/IMG_13"
        count = 10
        maxCount = 97
      }
    }
    if fileName == "/Photos/2011-03-iphone/IMG_13" {
      if(count==14){count=24}
      if(count==25){count=28}
      if(count==29){count=32}
      if(count==35){count=39}
      if(count==41){count=44}
      if(count==46){count=49}
      if(count==58){count=60}
      if(count==62){count=63}
      if(count==64){count=66}
      if(count==73){count=87}
      if(count==88){count=89}
      if(count==92){count=95}
      if count == 98 {  //97
        fileName = "/Photos/2011-03-iphone/IMG_14"
        count = 10
        maxCount = 0
      }
    }
     */
      
    //CountLabel.text = String(count)
    downloadDropboxFile()
  }
  
  @IBAction func TapBack(_ sender: Any) {
    count = count - 1
    
    print(count)
    print("self.filenames![?]")
    print(self.filenames![count])
    
    fileName = "/アプリ/Photo Watch/" + self.filenames![count]
    
    downloadDropboxFile()
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
