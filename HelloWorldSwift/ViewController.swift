//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController {
  
  @IBAction func tapGoogleSignIn(_ sender: Any) {
    GIDSignIn.sharedInstance()?.delegate = self
    GIDSignIn.sharedInstance()?.presentingViewController = self
    GIDSignIn.sharedInstance()?.signIn()
  }
  
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
    if let user = GIDSignIn.sharedInstance()?.currentUser {
      print("currentUser.profile.email: \(user.profile!.email!)")
    } else {
      // 次回起動時にはこちらのログが出力される
      print("currentUser is nil")
    }
    
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

// GIDSignInDelegateへの適合とメソッドの追加を行う
extension ViewController: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            // ログイン成功した場合
            print("signIned user email: \(user!.profile!.email!)")
        } else {
            // ログイン失敗した場合
            print("error: \(error!.localizedDescription)")
        }
    }
}
