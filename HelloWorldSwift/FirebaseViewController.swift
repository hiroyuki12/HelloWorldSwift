//
//  FirebaseViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/26.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Firebase

class FirebaseViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    let ref = Database.database().reference()

    // Add
//    // KeyValue型の配列を用意しておきます。
//    let page = ["savedPage":"1"]
//    // データを追加します。idは自動で設定してくれます。
//    ref.child("Page").childByAutoId().setValue(page)
      
    // Update
//    // 先程のIDを指定します。(人によって変わるので、自分のDatabaseからコピペしてね)
//    let id = "-M5pJ7f2Dx34sAdNqUzl"
//    // 先程のIDを指定してデータを上書きします。
//    ref.child("Page/\(id)/savedPage").setValue("2")
      
    // Delete
//    // 先程のIDを指定します。(人によって変わるので、自分のDatabaseからコピペしてね)
//    let id = "-M5pJ7f2Dx34sAdNqUzl"
//    // 先程のIDを指定してデータを削除します。
//    ref.child("Page/\(id)").removeValue()
      
    // Select
    // データの変更を監視(observe)してるため、変更されればリアルタイムで実行されます。
    ref.child("Page").observe(.value) { (snapshot) in
      // Page直下のデータの数だけ繰り返す。
      for data in snapshot.children {
        let snapData = data as! DataSnapshot

        // Dictionary型にキャスト
        let page = snapData.value as! [String: Any]
        print(page)
      }
    }
  }
  
  @IBAction func tapMail(_ sender: Any) {
    
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
