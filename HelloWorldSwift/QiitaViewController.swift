//
//  QiitaViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation

struct QiitaUser: Codable {
    let id: String
    let imageUrl: String // ①
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "profile_image_url" // ②
    }
}

struct QiitaArticle: Codable {
    let title: String
    let url: String
    let user: QiitaUser // ⓵
}

class QiitaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet weak var tableView: UITableView!
    
  var articles: [[String: Any]] = []
  
  let tag = "swift"
//    let _tag = "flutter"

  let tagFlutter  = "flutter"
  let tagSwift    = "swift"
  
  var savedPage = 1
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let article = articles[indexPath.row]
    // セルに表示する値を設定する
    cell.textLabel!.text = articles[indexPath.row]["title"]! as? String
    
    return cell
  }
    
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return articles.count
  }

  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    myload(page: 1, perPage: 15)
    print("myload (viewDidLoad)")
    
    print("viewDidLoad End!")
  }
  
  func myload(page: Int , perPage: Int) {
    let str1:String = "http://qiita.com/api/v2/tags/Swift/items?page="
    let str2:String = String(page)
    let str3:String = "&per_page="
    let str4:String = String(perPage)

    let str5:String = str1 + str2 + str3 + str4
    
    let url: URL = URL(string: str5)!

    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
      do {
        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
        let articles = json.map { (article) -> [String: Any] in
            return article as! [String: Any]
        }
//        print(json)
//        print(articles[0]["title"]!)
//        print(articles[1]["title"]!)

//        extract articles
//        for entry in articles {
//            print(entry["title"]!)
//        }
//
//        print("count: \(json.count)") //追加
        
        self.articles = articles //追加
        print("savePage : \(self.savedPage)")
        print("self.articles Set End!")
        
        DispatchQueue.main.async {
          self.tableView.reloadData()
          print("reloadData End!")
        }
      }
      catch {
          print(error)
      }
    })
    
    task.resume() //実行する
    
    print("myload End!")
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    self.tableView.reloadData()
    print("reloadData(tap load button")
  }
  
  // Nextボタン押下
  @IBAction func next(_ sender: Any) {
    savedPage += 1
    myload(page: savedPage, perPage: 15)
    print("myload(tap next button)")
  }
  
  @IBAction func prev(_ sender: Any) {
    savedPage -= 1
    myload(page: savedPage, perPage: 15)
    print("myload(tap prev button)")
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
