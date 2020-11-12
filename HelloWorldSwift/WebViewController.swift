//
//  WebViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import WebKit
import Accounts

class WebViewController: UIViewController {
  @IBOutlet weak var wkWebView: WKWebView!
  
  // ①表示するURLを持っておく public 外部から変更
  var url: String!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    //print("Hello!")
    //print(url)
    
    if let url = URL(string: self.url!) {
      //if let url = URL(string: "https://www.apple.com/jp/swift/") {  // URL文字列の表記間違いなどで、URL()がnilになる場合があるため、nilにならない場合のみ以下のload()が実行されるようにしている
      let request = URLRequest(url: url)
      //self.wkWebView.load(URLRequest(url: url))
      wkWebView.load(request)
      // スワイプで進む、戻るを有効にする
      wkWebView.allowsBackForwardNavigationGestures = true
    }
  }
  
  override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくなる
  }
  
  @IBAction func tapClose(_ sender: Any) {
    //戻る
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func tapBack(_ sender: Any) {
    wkWebView.goBack()
  }
  
  
  @IBAction func tapShare(_ sender: Any) {
    // 共有する項目
    let shareText = wkWebView.title
    let shareWebsite = NSURL(string: url)!
//    let shareImage = UIImage(named: "shareSample.png")!
    
    let activityItems = [shareText, shareWebsite] as [Any]
    
    // 初期化処理
    let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    
    // 使用しないアクティビティタイプ
    let excludedActivityTypes = [
      UIActivity.ActivityType.postToFacebook,
      UIActivity.ActivityType.postToTwitter,
      UIActivity.ActivityType.message,
      UIActivity.ActivityType.saveToCameraRoll,
      UIActivity.ActivityType.print
    ]
    
    activityVC.excludedActivityTypes = excludedActivityTypes
    
    // UIActivityViewControllerを表示
    self.present(activityVC, animated: true, completion: nil)
    
  }
  
  @IBAction func tapSafari(_ sender: Any) {
    let url2 = NSURL(string: url)
    if UIApplication.shared.canOpenURL(url2 as! URL) {
      UIApplication.shared.open(url2! as URL, options: [:], completionHandler: nil)
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
