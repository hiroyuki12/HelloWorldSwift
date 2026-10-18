//
//  MisskeyViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/27.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import WebKit

// Dropbox 画面と同じスライドショーに、Misskey を表示する WebView を加えた画面
class MisskeyViewController: DropboxSlideshowViewController {
  @IBOutlet weak var wkWebView: WKWebView!

  // SignInボタンで Misskey を表示する
  override func signIn() {
    if let url = URL(string: "https://misskey.io/") {
      wkWebView.load(URLRequest(url: url))
      wkWebView.allowsBackForwardNavigationGestures = true  // スワイプで進む、戻るを有効にする
    }
  }
}
