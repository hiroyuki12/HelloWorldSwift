//
//  WebViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
  @IBOutlet weak var wkWebView: WKWebView!
  
  // ①表示するURLを持っておく public 外部から変更
  var url: String!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
    print("Hello!")
    //print(url)
    
    if let url = URL(string: self.url!) {
    //if let url = URL(string: "https://www.apple.com/jp/swift/") {  // URL文字列の表記間違いなどで、URL()がnilになる場合があるため、nilにならない場合のみ以下のload()が実行されるようにしている
      let request = URLRequest(url: url)
      //self.wkWebView.load(URLRequest(url: url))
      wkWebView.load(request)
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
