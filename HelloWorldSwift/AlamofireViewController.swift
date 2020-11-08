//
//  AlamofireViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/31.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Alamofire
//import SwiftyJSON

class AlamofireViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    let urlString:String = "https://api.github.com/users/octocat"
//    let urlString:String = "http://qiita.com/api/v2/tags/swift/items"
    
    //データの取得
    //URLにアクセスし、返ってきた値を受け取る。
    //返ってきた値をプログラムで扱える形に変換
    Alamofire.request(urlString).responseJSON{ response in
      guard let object = response.result.value else {
        return
      }
//      print("取得したデータ")
//      print(object)
      
//      let json = JSON(object)
//      print("JSON形式に変換後")
//      print(json)
      
      //forEachでそれぞれのデータにアクセスする。
      //        json["results"].forEach { (_, json) in
      //            print("memo:サイトTitle",json["title"].stringValue)
      //            print("memo:WebサイトURL",json["website"].stringValue)
      //
      //           //配列に情報を入れる
      //            self.siteTitle.append(json["title"].stringValue)
      //            self.siteURL.append(json["website"].stringValue)
      //        }
      //        print("memo:テーブルリロード")
      //        self.tableView.reloadData()
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
