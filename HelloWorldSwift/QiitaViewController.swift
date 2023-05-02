//
//  QiitaViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3

class QiitaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var articles: [[String: Any]] = []
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  var tag = "swift"
//    let tag = "flutter"
  
  let tagSwift    = "swift"
  let tagFlutter  = "flutter"
  
  var savedPage = 1
  var perPage = 20
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    // セルの高さを設定
    table.rowHeight = 70
    
    myload(page: 1, perPage: perPage, tag: tag)
    print("myload (viewDidLoad)")
    
    //sqlite start
    let fileUrl = try!
      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("HeroDatabase.sqlite")
    if sqlite3_open(fileUrl.path, &db) != SQLITE_OK{
      print("Error opening database. HeroDatabase.sqlite")
      return
    }
    let createTableQuery = "create table if not exists Heroes (id integer primary key autoincrement, name text, powerrank integer)"
    if sqlite3_exec(db, createTableQuery, nil, nil, nil) !=
      SQLITE_OK{
      print("Error createing table Heros")
      return
    }
    print("SQLite Everything is fine!")
    //sqlite end
    
//    let target = self.navigationController?.value(forKey: "_cachedInteractionController")
//    let recognizer = UIPanGestureRecognizer(target: target, action: Selector(("handleNavigationTransition:")))
//    self.view.addGestureRecognizer(recognizer)
    
    print("viewDidLoad End!")
  }
  
  func myload(page: Int , perPage: Int, tag: String) {
    let str1:String = "http://qiita.com/api/v2/tags/"
    let str2:String = String(tag)
    let str3:String = "/items?page="
    let str4:String = String(page)
    let str5:String = "&per_page="
    let str6:String = String(perPage)

    let str7:String = str1 + str2 + str3 + str4 + str5 + str6
    
    let url: URL = URL(string: str7)!
    //print ("AAA")
    //print (str7)
    
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
      do {
        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
        
        // 一時退避
        let articles_tmp = self.articles
        // 末尾に追加
        let articles = articles_tmp + json.map { (article) -> [String: Any] in
            return article as! [String: Any]
        }
//        print(json)
//        print(articles[0]["user"]!)
        //print("BBB")
        //print(articles[0]["title"]!)
//        print(articles[0]["url"]!)
//        print(articles[1]["title"]!)

//        extract articles
//        for entry in articles {
//            print(entry["title"]!)
//        }
//
//        print("count: \(json.count)") //追加
        
        self.articles = articles //追加
        //print("savePage : \(self.savedPage)")
        //print("self.articles Set End!")
        
        DispatchQueue.main.async {
          self.table.reloadData()
          print("reloadData End!")
          self.isLoading = false
          print("self.isLoading = false End!")
        }
      }
      catch {
          print(error)
      }
    })
    
    task.resume() //実行する
    
    //print("myload End!")
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let article = articles[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as! UILabel
    textTitle.text = article["title"]! as? String
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    textDetailText.text = article["created_at"]! as? String
//    print ("AAA")
//    print (article["user"])  //ok
    // セルに表示する画像を設定する
    let articleUser = article["user"] as AnyObject?
    let profileImageUrl = articleUser?["profile_image_url"]
//    print ("BBB")
//    print (profileImageUrl)  //ok
    let profileImage = cell.viewWithTag(1) as! UIImageView
    let myUrl: URL? = URL(string: profileImageUrl as! String)
    profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    // セルに表示する画像を設定する
//    let img = UIImage(named: imgArray[indexPath.row] as! String)
//    cell.imageView?.image = img
    
    return cell
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return articles.count
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    self.table.reloadData()
    //print("reloadData(tap load button")
  }
  
  // Flutterボタンタップ時
  @IBAction func next(_ sender: Any) {
    articles.removeAll()
    tag = tagFlutter
    savedPage = 1
    myload(page: savedPage, perPage: 20, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage) +
          "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // Saveボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    dismiss(animated: true, completion: nil)

    /* //savedPage  //現在のページ
    print("start tapSave.")
    print("savedPage: " + String(savedPage))
    
    // mysql delete
    tapDelete(savedPage)
    // mysql insert
    tapSave(savedPage)
    
    sqliteSavedPage = savedPage;
    print("sqliteSavedPage: " + String(sqliteSavedPage)) */
  }
  
  // nameが1のデータをdelete。引数のpageは未使用。
  func tapDelete(_ page: Int) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "DELETE FROM  Heroes WHERE name = ?"
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing delte: \(errmsg)")
      return
    }
    //binding the parameters 1つ目の?に1をセット
    if sqlite3_bind_text(stmt, 1, "1", -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding: \(errmsg)")
        return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure deleting hero: \(errmsg)")
        return
    }
    print ("finish tapDelete!")
  }
  
  // nameが1、powerrankが引数のpageの文字列で、insert
  func tapSave(_ page: Int) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (1,?)"
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing insert: \(errmsg)")
      return
    }
    //binding the parameters 1つ目の?に2をセット
    if sqlite3_bind_text(stmt, 1, String(page), -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding: \(errmsg)")
        return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure inserting hero: \(errmsg)")
        return
    }
    print ("finish tapSave!")
  }
  
  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
    tapRead(savedPage)
    
    articles.removeAll()
    //savedPage = 1
    myload(page: savedPage, perPage: 20, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage) +
          "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    
    print ("finish tapLoad!")
  }
  
  func tapRead(_ page: Int) {
    //this is our select query
    let queryString = "SELECT * FROM Heroes"
    //statement pointer
    var stmt:OpaquePointer?
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("error preparing insert: \(errmsg)")
        return
    }
    //traversing through all the records
    while(sqlite3_step(stmt) == SQLITE_ROW){
      //let id = sqlite3_column_int(stmt, 0)
      let name = String(cString: sqlite3_column_text(stmt, 1))
      let powerrank = sqlite3_column_int(stmt, 2)
      print("name:" + name + ", powerrank:" + String(powerrank))
        //adding values to list
//        heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
      savedPage = Int(powerrank)
    }
    print ("finish tapRead!")
  }
  
  
  // Prevボタン押下
  @IBAction func prev(_ sender: Any) {
    savedPage -= 1
    myload(page: savedPage, perPage: 20, tag: tag)
    
    textPage.text =  "swift Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    print (indexPath)  // 1つ目が[0,0]、２つ目が[0,1]
//    popUp()
    
    let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as! WebViewController
    webView.url = articles[indexPath.row]["url"]! as? String ?? "http://www.yahoo.co.jp"
    
    self.present(webView, animated: true, completion: nil)
  }
  
  
  private func popUp() {
    let alertController = UIAlertController(title: "確認", message: "本当に実行しますか", preferredStyle: .actionSheet)

    let yesAction = UIAlertAction(title: "はい", style: .default, handler: nil)
    alertController.addAction(yesAction)

    let noAction = UIAlertAction(title: "いいえ", style: .default, handler: nil)
    alertController.addAction(noAction)

    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
      isLoading = true
      savedPage += 1
      myload(page: savedPage, perPage: 20, tag: tag)
      //print("myload(List End)")
      
      textPage.text =  String(tag) + " Page " + String(savedPage) +
        "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
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

// 指定URLから画像を読み込み、セットする
// defaultUIImageには、URLからの読込に失敗した時の画像を指定する
extension UIImageView {
  func loadImageAsynchronously(url: URL?, defaultUIImage: UIImage? = nil) -> Void {
    if url == nil {
      self.image = defaultUIImage
      return
    }

    DispatchQueue.global().async {
      do {
        let imageData: Data? = try Data(contentsOf: url!)
        DispatchQueue.main.async {
          if let data = imageData {
            self.image = UIImage(data: data)
          } else {
            self.image = defaultUIImage
          }
        }
      }
      catch {
        DispatchQueue.main.async {
          self.image = defaultUIImage
        }
      }
    }
  }
}

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

//extension ViewController: UITableViewDelegate {
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let storyboard = UIStoryboard(name: "WebViewController", bundle: nil)
//    let webViewController = storyboard.instantiateInitialViewController() as! WebViewController
//    // ③indexPathを使用してarticlesから選択されたarticleを取得
//    //let article = articles[indexPath.row]
//    // ④urlとtitleを代入
//    webViewController.url = "http://www.google.com/"
//    //webViewController.url = article.url
//    //webViewController.title = article.title
//    navigationController?.pushViewController(webViewController, animated: true)
//  }
//}

