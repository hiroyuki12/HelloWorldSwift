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

class WebViewController: UIViewController, WKNavigationDelegate {
  @IBOutlet weak var wkWebView: WKWebView!
  
  // ①表示するURLを持っておく public 外部から変更
  var url: String?
  private var initialHost: String?

  // qキーで画面を閉じる
  override var keyCommands: [UIKeyCommand]? {
    let command = UIKeyCommand(input: "q", modifierFlags: [], action: #selector(tapClose(_:)))
    // WKWebViewより先にキー入力を受け取る
    command.wantsPriorityOverSystemBehavior = true
    return [command]
  }

  // キー入力を受け取るためにファーストレスポンダーになる
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    wkWebView.navigationDelegate = self
    if let urlString = self.url, let url = URL(string: urlString), url.isHTTPOrHTTPS {
      initialHost = url.host?.lowercased()
      let request = URLRequest(url: url)
      wkWebView.load(request)
      // スワイプで進む、戻るを有効にする
      wkWebView.allowsBackForwardNavigationGestures = true
    }
  }
  
  // 同じホストのHTTPSだけをアプリ内で表示する。外部リンクはURLが見えるブラウザへ渡す。
  static func allowsEmbeddedNavigation(_ url: URL, host: String?) -> Bool {
    guard let host = host else { return false }
    return url.scheme?.lowercased() == "https" && url.host?.lowercased() == host
      && url.user == nil && url.password == nil && (url.port == nil || url.port == 443)
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    guard let destination = navigationAction.request.url else {
      decisionHandler(.cancel)
      return
    }
    if Self.allowsEmbeddedNavigation(destination, host: initialHost), navigationAction.targetFrame != nil {
      decisionHandler(.allow)
    } else {
      decisionHandler(.cancel)
      // サブフレームから外部アプリを自動起動しない。
      if navigationAction.targetFrame?.isMainFrame != false, destination.isHTTPOrHTTPS {
        UIApplication.shared.open(destination, options: [:])
      }
    }
  }

  func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
               decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
    guard let destination = navigationResponse.response.url else {
      decisionHandler(.cancel)
      return
    }
    let allowed = Self.allowsEmbeddedNavigation(destination, host: initialHost)
    decisionHandler(allowed ? .allow : .cancel)
    if !allowed, navigationResponse.isForMainFrame, destination.isHTTPOrHTTPS {
      UIApplication.shared.open(destination, options: [:])
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
    guard let shareWebsite = wkWebView.url, shareWebsite.isHTTPOrHTTPS else { return }
    let shareText = wkWebView.title
    
    let activityItems: [Any] = [shareText ?? "", shareWebsite]
    
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
    
    // iPad 表示時のクラッシュ防止
    if let popover = activityVC.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    // UIActivityViewControllerを表示
    self.present(activityVC, animated: true, completion: nil)
  }
  
  @IBAction func tapSafari(_ sender: Any) {
    guard let url2 = wkWebView.url, url2.isHTTPOrHTTPS else { return }
    UIApplication.shared.open(url2, options: [:], completionHandler: nil)
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
