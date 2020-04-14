//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
  }
  
// ①セグエ実行前処理
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    print ("aaa")
//    print (segue.identifier)
    // ②Segueの識別子確認
    //if segue.identifier == "MyWebView" {
      // ③遷移先ViewCntrollerの取得
      let webView = segue.destination as! WebViewController
      // ④遷移先に渡す値の設定
      webView.url = "http://www.google.com/"
    //}
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

