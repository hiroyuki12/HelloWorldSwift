//
//  FeedlyViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/27.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3

class FeedlyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var articles: [[String: Any]] = []
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  var tag = "hbfav"
//    let tag = "flutter"
  
  let tagHbfav    = "hbfav"
  let tagZennSwift  = "zennSwift"
  let tagHatenaStuff  = "hatenastuff"
  
  var savedPage = 1
  var perPage = 20
  var continuation = "99999999999999"
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    // セルの高さを設定
    table.rowHeight = 70
    
    myload(page: 1, perPage: perPage, tag: tag)
    
    //sqlite start
    let fileUrl = try!
      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("HeroDatabase.sqlite")
    if sqlite3_open(fileUrl.path, &db) != SQLITE_OK{
      return
    }
    let createTableQuery = "create table if not exists Heroes (id integer primary key autoincrement, name text, powerrank integer)"
    if sqlite3_exec(db, createTableQuery, nil, nil, nil) !=
      SQLITE_OK{
      return
    }
    //sqlite end
    
//    let target = self.navigationController?.value(forKey: "_cachedInteractionController")
//    let recognizer = UIPanGestureRecognizer(target: target, action: Selector(("handleNavigationTransition:")))
//    self.view.addGestureRecognizer(recognizer)
    
  }
  
  func myload(page: Int , perPage: Int, tag: String) {
//    let str1:String = "https://api.stackexchange.com/2.2/questions?page="
//    let str2:String = String(page)
//    let str3:String = "&order=desc&sort=activity&tagged="
//    let str4:String = String(tag)
//    let str2:String = "global.uncategorized"
    var category:String = ""
    if tag == tagHbfav {
      category = "c59b3cef-0fa1-414c-8aca-dc9678aaa85f"
    }
    else if tag == tagZennSwift {
      category = "01328fc1-f342-4bae-b459-d613ff670195"
    }
    else {
      category = "9b810adf-9db6-4600-8377-b04aec630ffc"
    }
    
//    let str2:String = "c59b3cef-0fa1-414c-8aca-dc9678aaa85f"  // hbfav2 category
//    let str2:String = "9b810adf-9db6-4600-8377-b04aec630ffc"  // hatenastuff category
    
    let str1:String = "https://cloud.feedly.com/v3/streams/contents?streamId=user/" + Constants.feedlyUserId + "/category/" + category + "&continuation=" + continuation
//    let str1:String = "https://cloud.feedly.com/v3/streams/contents?streamId=user/" + Constants.feedlyUserId + "/category/hbfav&continuation=" + continuation
    
//    let str5:String = "&limit="
//    let str6:String = String(perPage)

    let str7:String = str1
    
    let url: URL = URL(string: str7)!
    var request = URLRequest(url: url)
    request.setValue(Constants.feedlyDeveloperToken, forHTTPHeaderField: "Authorization")
    let task: URLSessionTask  = URLSession.shared.dataTask(with: request, completionHandler: {data, response, error in
      do {
        // ([String : Any]) 3 key/value pairs
        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
        
        
        // ([Dictionary<String, Any>.Element]) 3 values
        let articles = json.map { (article) in
          return article
        }
        
        // itemsのデータをself.articlesに入れる(meta,questions,tags)
        for (key, value) in articles {
          if(key == "items") {
            let items = value as! [Any]
            
            var items2 =  items.map { (article) -> [String: Any] in
                return article as! [String: Any]
            }
              
            if items2.count > 19 {
              self.continuation = String((items2[19]["published"] as? Int)!)
            }
            
            var url2:String = ""
            let array = items2[0]["alternate"] as! NSArray
            for roop in array {
              let next = roop as! NSDictionary
              let url = next["href"] as? String
              if let url = url {
                url2 = url
                self.getBookmarkCount(value: url2)
              }
            }
            
            // 一時退避
            let articles_tmp = self.articles
            // 末尾に追加
            items2 = articles_tmp + items2
            self.articles = items2 //追加
          }
        }
      
        DispatchQueue.main.async {
          self.table.reloadData()
          self.isLoading = false
        }
      }
      catch {
      }
    })
    
    task.resume() //実行する
  }
  
  func getBookmarkCount(value: String) {
    let url: URL = URL(string: "https://bookmark.hatenaapis.com/count/entry?url=" + value)!
    let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
      guard let data = data else {
        return
      }
      do {
        let count = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
      }
      catch {
      }
    })
    task.resume()
    
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let article = articles[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as! UILabel
    let tmpTitle = article["title"]! as? String // items->title
//    tmpTitle = tmpTitle?.replacingOccurrences(of: "&#39;", with: "'")
//    tmpTitle = tmpTitle?.replacingOccurrences(of: "&quot;", with: "\"")
//    tmpTitle = tmpTitle?.replacingOccurrences(of: "&lt;", with: "<")
//    tmpTitle = tmpTitle?.replacingOccurrences(of: "&gt;", with: ">")
//    tmpTitle = tmpTitle?.replacingOccurrences(of: "&amp;", with: "&")
    textTitle.text = tmpTitle
    // セルに表示するブックマーク数を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    let engagement = article["engagement"] as? Int
//    textDetailText.text = " "
    
    var url2:String = ""
    let array = article["alternate"] as! NSArray
    for roop in array {
      let next = roop as! NSDictionary
      let url = next["href"] as? String
      if let url = url {
        url2 = url
      }
    }
    
    if let engagement = engagement {
      textDetailText.text = String(engagement) + " engagement " + url2
    }
    else {
      if tag == tagHbfav {
        textDetailText.text = url2
      }
      else {
        textDetailText.text = ""
      }
    }
    
//    let createDate = Date(timeIntervalSince1970: timeInterval)
//    textDetailText.text = DateUtils.stringFromDate(date: createDate, format: "yyyy-MM-dd HH:mm:ss Z")
//    textDetailText.text = DateUtils.stringFromDate(date: createDate, format: "yyyy-MM-dd HH:mm:ss")
//    textDetailText.text = daysAgo(DateUtils.stringFromDate(date: createDate, format: "yyyy-MM-dd HH:mm:ss"))
    // セルに表示する画像を設定する
    var author = ""
    if article["author"] != nil {
      author = (article["author"]! as? String)! // items->creation_date
//    if(author != nil) {  // Farorite
      let profileImageUrl = "https://cdn.profile-image.st-hatena.com/users/" + author + "/profile.gif"// items->thumbnail
      let profileImage = cell.viewWithTag(1) as! UIImageView
      let myUrl: URL? = URL(string: profileImageUrl)
      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    }
    else {
      if tag == tagZennSwift {
        var profileImage = cell.viewWithTag(1) as! UIImageView
        let myUrl: URL? = URL(string: "https://storage.googleapis.com/zenn-topics/swift.png?hl=ja")
        profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
      
        let arr:[String] = url2.components(separatedBy: "/")
        author = arr[3]
      }
    }
    // セルに表示する作成日を設定する
    let tagsText = cell.viewWithTag(4) as! UILabel
    let dateUnix = (article["published"]! as? Double)! / 1000 // published millisecond
    let date = NSDate(timeIntervalSince1970: dateUnix)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let dateStr: String = formatter.string(from: date as Date)
    tagsText.text = author + " " + daysAgo(dateStr)
    
//    let replayCount = article["answer_count"] as? Int  // items->answer_count
//    let pvCount = article["view_count"] as? Int  // items->view_count
//    var arr = article["tags"] as? [String]  // items->tags
//    let count = arr!.count
////    let tag1name = arr?.first!
//    let tag1name = "回答数 " + String(replayCount!) + " / PV数 " + String(pvCount!)
//      + " / " + (arr?[0])!
//    tagsText.text = tag1name
//    if(count > 1) {
//      arr?.removeFirst()
//      let tag2name = arr?[0]
//      tagsText.text = tag1name + "," + tag2name!
//      if(count > 2) {
//        arr?.removeFirst()
//        let tag3name = arr?[0]
//        tagsText.text = tag1name + "," + tag2name! + "," + tag3name!
//        if(count > 3) {
//          arr?.removeFirst()
//          let tag4name = arr?[0]
//          tagsText.text = tag1name + "," + tag2name! + "," + tag3name! + "," + tag4name!
//          if(count > 4) {
//            arr?.removeFirst()
//            let tag5name = arr?[0]
//            tagsText.text = tag1name + "," + tag2name! + "," + tag3name! + "," + tag4name! + "," + tag5name!
//          }
//        }
//      }
//    }
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    let calendar = Calendar.current
    let dateComponents = DateComponents(calendar: calendar, year: Int(data[0...3]), month: Int(data[5...6]), day: Int(data[8...9]), hour: Int(data[11...12]), minute: Int(data[14...15]), second: Int(data[17...18]))
    if let date = calendar.date(from: dateComponents) {
      return date.timeAgo()
    }
    return ""
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return articles.count
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    self.table.reloadData()
  }
  
  // Menuボタンタップ時
  @IBAction func next(_ sender: Any) {
    tapRead(self.savedPage, self.tag)
    
    popUp()
  }
  
  private func popUp() {
    let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

    let flutterSwiftAction = UIAlertAction(title: "hbfav/zennSwift/HatenaStuff", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.articles.removeAll()
        if self.tag == self.tagHbfav {
          self.tag = self.tagZennSwift
        }
        else if self.tag == self.tagZennSwift {
          self.tag = self.tagHatenaStuff
        }
        else {
          self.tag = self.tagHbfav
        }
        self.savedPage = 1
        self.continuation = "99999999999999"
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(flutterSwiftAction)

    let swiftPage1Action = UIAlertAction(title: "hbfav page1/20posts", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.articles.removeAll()
        self.tag = self.tagHbfav
        self.savedPage = 1
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(swiftPage1Action)
  
    let swiftPage50Action = UIAlertAction(title: "hbfav page50/20posts", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.articles.removeAll()
        self.tag = self.tagHbfav
        self.savedPage = 50
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(swiftPage50Action)
  
    let flutterPage1Action = UIAlertAction(title: "HatenaStuff page1/20posts", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.articles.removeAll()
        self.tag = self.tagHatenaStuff
        self.savedPage = 1
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(flutterPage1Action)
  
    let saveSwiftPageAction = UIAlertAction(title: "Save " + self.tag + " Page ! " + String(self.savedPage), style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        //savedPage  //現在のページ
        
        // mysql delete
        self.tapDelete(self.savedPage, self.tag)
        // mysql insert
        self.tapSave(self.savedPage, self.tag)
        
        self.sqliteSavedPage = self.savedPage;

      })
    alertController.addAction(saveSwiftPageAction)
  
    let loadSwiftPageAction = UIAlertAction(title: "Load " + self.tag + " Page ! " + String(self.sqliteSavedPage), style: .default,
    handler:{
      (action:UIAlertAction!) -> Void in
      
      self.articles.removeAll()
      self.savedPage = self.sqliteSavedPage
      self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
      self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
            "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      

    })
    alertController.addAction(loadSwiftPageAction)
  
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
  }

  func swiftPage1Action() {
    articles.removeAll()
    tag = tagHatenaStuff
    savedPage = 1
    myload(page: savedPage, perPage: 20, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage) +
          "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // Closeボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    
    //戻る
    dismiss(animated: true, completion: nil)
    /*
    //savedPage  //現在のページ
    
    // mysql delete
    tapDelete(savedPage)
    // mysql insert
    tapSave(savedPage)
    
    sqliteSavedPage = savedPage;
    */
    
  }
  
  // nameがtagのデータをdelete。引数のpageは未使用。
  func tapDelete(_ page: Int, _ tag: String) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "DELETE FROM  Heroes WHERE name = " + "\"" + tag + "\""
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
//      let errmsg = String(cString: sqlite3_errmsg(db)!)
      return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
//        let errmsg = String(cString: sqlite3_errmsg(db)!)
        return
    }
  }
  
  // nameが1、powerrankが引数のpageの文字列で、insert
  func tapSave(_ page: Int, _ tag: String) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (\"" + tag + "\"," + String(page) + ")"
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
//      let errmsg = String(cString: sqlite3_errmsg(db)!)
      return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
//        let errmsg = String(cString: sqlite3_errmsg(db)!)
        return
    }
  }
  
  override func viewWillLayoutSubviews() {  // isModalInPresentationにtrueを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくする
  }
  
  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
//    tapRead(savedPage)
    
//    articles.removeAll()
//    //savedPage = 1
//    myload(page: savedPage, perPage: 20, tag: tag)
//    textPage.text =  String(tag) + " Page " + String(savedPage) +
//          "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    
  }
  
  func tapRead(_ page: Int, _ tag: String) {
    sqliteSavedPage = 0
    //this is our select query
    let queryString = "SELECT * FROM Heroes Where name = \"" + tag + "\""
    //statement pointer
    var stmt:OpaquePointer?
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
//        let errmsg = String(cString: sqlite3_errmsg(db)!)
        return
    }
    //traversing through all the records
    while(sqlite3_step(stmt) == SQLITE_ROW){
      //let id = sqlite3_column_int(stmt, 0)
      let name = String(cString: sqlite3_column_text(stmt, 1))
      let powerrank = sqlite3_column_int(stmt, 2)
        //adding values to list
//        heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
      sqliteSavedPage = Int(powerrank)
    }
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
// 1つ目が[0,0]、２つ目が[0,1]
//    popUp()
    
    let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as! WebViewController
    //    webView.url = articles[indexPath.row]["link"] as? String
    let array = articles[indexPath.row]["alternate"] as! NSArray
    for roop in array {
      let next = roop as! NSDictionary
      webView.url = next["href"] as? String
    }
    self.present(webView, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
      isLoading = true
      savedPage += 1
      myload(page: savedPage, perPage: 20, tag: tag)
      
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
//extension UIImageView {
//  func loadImageAsynchronously(url: URL?, defaultUIImage: UIImage? = nil) -> Void {
//    if url == nil {
//      self.image = defaultUIImage
//      return
//    }
//
//    DispatchQueue.global().async {
//      do {
//        let imageData: Data? = try Data(contentsOf: url!)
//        DispatchQueue.main.async {
//          if let data = imageData {
//            self.image = UIImage(data: data)
//          } else {
//            self.image = defaultUIImage
//          }
//        }
//      }
//      catch {
//        DispatchQueue.main.async {
//          self.image = defaultUIImage
//        }
//      }
//    }
//  }
//}

//struct TeratrailUser: Codable {
//  let id: String
//  let imageUrl: String // ①
//
//  enum CodingKeys: String, CodingKey {
//      case id
//      case imageUrl = "profile_image_url" // ②
//  }
//}
//
//struct TeratrailArticle: Codable {
//  let title: String
//  let url: String
//  let user: TeratrailUser // ⓵
//}

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

