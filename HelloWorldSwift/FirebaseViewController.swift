//
//  FirebaseViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/26.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore
import FirebaseAuth

class FirebaseViewController: UIViewController {
  @IBOutlet weak var txtId: UITextField!
  @IBOutlet weak var txtContent: UITextField!
  @IBOutlet weak var txtCreateDate: UITextField!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    let ref = Database.database().reference()

    // Add
//    // KeyValue型の配列を用意しておきます。
//    let bluray = ["id":"1", "content": "content", "create": "2020/11/02"]
//    let bluray = ["id":"2", "content": "映像研には手を出すな", "create": "2020/11/02"]
//    // データを追加します。idは自動で設定してくれます。
//    ref.child("Bluray").childByAutoId().setValue(bluray)
      
    // Update
//    // 先程のIDを指定します。(人によって変わるので、自分のDatabaseからコピペしてね)
//    let id = "-ML6J9jCekcNI30l23Ia"
//    // 先程のIDを指定してデータを上書きします。
//    ref.child("Bluray/\(id)/content").setValue("content")
      
    // Delete
//    // 先程のIDを指定します。(人によって変わるので、自分のDatabaseからコピペしてね)
//    let id = "-M5pJ7f2Dx34sAdNqUzl"
//    // 先程のIDを指定してデータを削除します。
//    ref.child("Page/\(id)").removeValue()
      
    
    
    // Select
    // データの変更を監視(observe)してるため、変更されればリアルタイムで実行されます。
//    ref.child("Bluray").observe(.value) { (snapshot) in
//      // Users直下のデータの数だけ繰り返す。
//      for data in snapshot.children {
//        let snapData = data as! DataSnapshot
//        // Dictionary型にキャスト
//        let bluray = snapData.value as! [String: Any]
//        if let id = bluray["id"] {
//          if id as! String == "2" {
//            print(bluray)
//          }
//        }
//      }
//    }
    
    print("finished !!!")
  }
  
  @IBAction func tapAdd(_ sender: Any) {
    let ref = Database.database().reference()

    // Add
//    // KeyValue型の配列を用意しておきます。
    let bluray = ["id":txtId.text, "content": txtContent.text, "crate": txtCreateDate.text]
//    // データを追加します。idは自動で設定してくれます。
    ref.child("Bluray").childByAutoId().setValue(bluray)
    
    txtContent.text = ""
  }
  
  
  @IBAction func tapFirestore(_ sender: Any) {
    creatUserCollectionAutomaticDocument()
  }
  
  // 「users」コレクションの作成（ドキュメント名指定）
  func creatUserCollectionDesignationDocument() {
    // FIRFirestoreインスタンスの作成
    let db = Firestore.firestore()
    
    // "users"という名称のコレクションを作成
    // "hoge"という名称のドキュメントを作成
    // ["name": "hoge"]というデータを保存
    db.collection("users").document("hoge").setData(["name": "hoge"]) { error in
      if let error = error {
        print("エラーが起きました")
      }
      else {
        print("ドキュメント「hoge」が保存できました")
      }
    }
  }
  // usersコレクションの作成（ドキュメント名自動）
  func creatUserCollectionAutomaticDocument() {
    let db = Firestore.firestore()
    db.collection("users").addDocument(data: ["name": "hoge"]) { error in
      if let error = error { print("エラーが起きました") }
      else { print("ドキュメントが保存できました") }
    }
  }
  
  @IBAction func tapSignUp(_ sender: Any) {
    Auth.auth().createUser(withEmail: "hiroyuki12@gmail.com", password: "pass") { [weak self] result, error in
        guard let self = self else { return }
        if let user = result?.user {
            let req = user.createProfileChangeRequest()
            req.displayName = "hiroyuki"
            req.commitChanges() { [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    user.sendEmailVerification() { [weak self] error in
                        guard let self = self else { return }
                        if error == nil {
                            // 仮登録完了画面へ遷移する処理
                        }
                        self.showErrorIfNeeded(error)
                    }
                }
                self.showErrorIfNeeded(error)
            }
        }
        self.showErrorIfNeeded(error)
    }
  }
  
  private func showErrorIfNeeded(_ errorOrNil: Error?) {
      // エラーがなければ何もしません
      guard let error = errorOrNil else { return }
      
      let message = "エラーが起きました" // ここは後述しますが、とりあえず固定文字列
      let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
      present(alert, animated: true, completion: nil)
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
