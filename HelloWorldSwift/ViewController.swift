//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import BoxSDK

class ViewController: UIViewController {
  
  @IBAction func tapSub(_ sender: Any) {
    let storyboard = UIStoryboard(name: "Sub", bundle: nil)
    let next = storyboard.instantiateViewController(withIdentifier: "SubViewController")
    self.present(next, animated: true)
  }
  
  @IBAction func tapAdd(_ sender: Any) {
    let next = self.storyboard!.instantiateViewController(withIdentifier: "AddViewController")
    self.present(next, animated: true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
    let client = BoxSDK.getClient(token: "BOX_DEVELOPER_TOKEN")
    //ダウンロード先URLを設定
    let directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let pathComponent = "123"  // 任意のdownload先ファイル名
    let url:URL = directoryURL.appendingPathComponent(pathComponent)
    
    client.files.download(fileId: "123", destinationURL: url) { (result: Result<Void, BoxSDKError>) in
      guard case .success = result else {
        print("Error downloading file")
        return
      }
      print("File downloaded successfully")
    }
    
    sleep(5)
    // To cancel download
    //    if someConditionIsSatisfied {
    //        task.cancel()
    //    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
  }
  
  
// ①セグエ実行前処理
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    /* WebKit View タップ時にGoolge表示
    print ("aaa")
    print (segue.identifier)
    // ②Segueの識別子確認
    //if segue.identifier == "MyWebView" {
      // ③遷移先ViewCntrollerの取得
      let webView = segue.destination as! WebViewController
      // ④遷移先に渡す値の設定
      webView.url = "http://www.google.com/"
    //}
     */
  }
  
    // Button 画面遷移
//    @IBAction func tapNextPage(_ sender: Any) {
//        // Storyboardのインスタンスを名前指定で取得する
//        let storyboard = UIStoryboard(name: "Sub", bundle: nil)
//        // Storyboard内で'is initial'に指定されているViewControllerを取得する
//        let nextVC = storyboard.instantiateInitialViewController() as! SubViewController
//        // FullScreenにする
//        nextVC.modalPresentationStyle = .fullScreen
//        // presentする
//        self.present(nextVC, animated: true, completion: nil)
//    }
}
