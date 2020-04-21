//
//  AddViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/20.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

// 内容を保存するための変数
var TodoKobetsunonakami = [String]()

class AddViewController: UIViewController {
  @IBOutlet weak var TodoTextField: UITextField!
  @IBOutlet weak var TodoAddButton: UIButton!
  
  // Saveボタン押下時
  @IBAction func TodoAddButton(_ sender: Any) {
    
    let dt = Date()
    let dateFormatter = DateFormatter()
    // DateFormatter を使用して書式とロケールを指定する
    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
    print(dateFormatter.string(from: dt))
    
    TodoKobetsunonakami.append(TodoTextField.text! + "°C  " + dateFormatter.string(from: dt))
    
    Log.write(TodoTextField.text! + "°C  " + dateFormatter.string(from: dt) + "\n")
    
    TodoTextField.text = ""
    UserDefaults.standard.set( TodoKobetsunonakami, forKey: "TodoList" )
    
//    let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.example.KeepADiary")
//    let documentsURL = containerURL?.appendingPathComponent("Documents")
//    let fileURL = documentsURL?.appendingPathComponent("my.diary")
//     
//    /* write */
//    let todayText = Date().description
//    do {
//        //try todayText.write(to: fileURL!, atomically: true, encoding: .utf8)
//        try todayText.write(to: fileURL!, atomically: true, encoding: .utf8)
//    }
//    catch {
//        print("write error")
//    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
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
