//
//  HatenaBookmarkFavoriteViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/15.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3

class HatenaBookmarkFavoriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var keyToken = Constants.key
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var articles: [[String: Any]] = []
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  var tag = "Fav"
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
    //print("myload (viewDidLoad)")
    
    //sqlite start
    let fileUrl = try!
      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("HeroDatabase.sqlite")
    if sqlite3_open(fileUrl.path, &db) != SQLITE_OK{
      //print("Error opening database. HeroDatabase.sqlite")
      return
    }
    let createTableQuery = "create table if not exists Heroes (id integer primary key autoincrement, name text, powerrank integer)"
    if sqlite3_exec(db, createTableQuery, nil, nil, nil) !=
        SQLITE_OK{
      //print("Error createing table Heros")
      return
    }
    //print("SQLite Everything is fine!")
    //sqlite end
    
    //    let target = self.navigationController?.value(forKey: "_cachedInteractionController")
    //    let recognizer = UIPanGestureRecognizer(target: target, action: Selector(("handleNavigationTransition:")))
    //    self.view.addGestureRecognizer(recognizer)
    
    //print("viewDidLoad End!")
  }
  
  func myload(page: Int , perPage: Int, tag: String) {
    //    let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https%3A%2F%2Fb.hatena.ne.jp%2Ffedora9%2Ffavorite.rss%3Fkey%3D"  keyToken
    
    let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https://b.hatena.ne.jp/fedora9/favorite.rss?key=" + keyToken
    
    //    let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https://b.hatena.ne.jp/fedora9/favorite.rss?key="  keyToken  "&limit=2"  // NG
    
    //    let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https://b.hatena.ne.jp/hotentry/it.rss"
    //        let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https://b.hatena.ne.jp/hotentry/hotentry.rss"  // NG -> add key
    //    let str1:String = "https://api.rss2json.com/v1/api.json?rss_url=https://b.hatena.ne.jp/hotentry.rss?key="  keyToken
    
    
    //    let str3:String = String(page)
    //    let str3:String = "&order=desc&sort=activity&tagged="
    //    let str4:String = String(tag)
    //    let str5:String = "&site=ja.stackoverflow"
    //    let str2:String = "&limit=30"
    //    let str6:String = String(perPage)
    
    let str7:String = str1
    
    let url: URL = URL(string: str7)!
    print(url)
    
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
      //      print ("response!!!!!")
      //      print(response!)
      do {
        // ([String : Any]) 3 key/value pairs
        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
        
        //print(json)  // ok
        //        print("json questions  !!!!!!!!!!!!!")
        //print(json["questions"]!)  // ok
        
        // ([Dictionary<String, Any>.Element]) 3 values
        let articles = json.map { (article) in
          return article
        }
        
        //print(articles)  // ok
        
        // itemsのデータをself.articlesに入れる(meta,questions,tags)
        for (key, value) in articles {
          if(key == "items") {
            //print("\(key) -> \(value)")
            let items = value as! [Any]
            
            //print(questions)
            
            var items2 =  items.map { (article) -> [String: Any] in
              return article as! [String: Any]
            }
            
            //          print(questions2[0]["title"]!)
            
            // 一時退避
            let articles_tmp = self.articles
            // 末尾に追加
            items2 = articles_tmp + items2
            
            self.articles = items2 //追加
          }
        }
        
        //        print(articles[1]["title"]!)
        //        print("BBBBBB")
        
        //        print("count: \(json.count)") //追加
        
        //print("savePage : \(self.savedPage)")
        //print("self.articles Set End!")
        
        DispatchQueue.main.async {
          self.table.reloadData()
          //print("reloadData End!")
          self.isLoading = false
          //print("self.isLoading = false End!")
        }
      }
      catch {
        //print(error)
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
    let tmpTitle = article["title"]! as? String // items->title
    let title1 = tmpTitle?.replacingOccurrences(of: "&#39;", with: "'")
    let title2 = title1?.replacingOccurrences(of: "&quot;", with: "\"")
    textTitle.text = title2
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    textDetailText.text = article["pubDate"]! as? String  // items->pubDate
    // セルに表示する画像を設定する
    //https://cdn.profile-image.st-hatena.com/users/laiso/profile.gif
    let author:String = article["author"] as! String
    let profileImageUrl = "https://cdn.profile-image.st-hatena.com/users/" + String(author) + "/profile.gif"// items->thumbnail
    let profileImage = cell.viewWithTag(1) as! UIImageView
    if profileImageUrl != nil {  // if profileImageUrl not nil
      let myUrl: URL? = URL(string: profileImageUrl as! String)
      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    }
    // セルに表示する回答数とタグを設定する
    let tagsText = cell.viewWithTag(4) as! UILabel
    //    let replayCount = article["answer_count"] as? Int  // items->answer_count
    //    let pvCount = article["view_count"] as? Int  // items->view_count
    //    var arr = article["tags"] as? [String]  // items->tags
    //    let count = arr!.count
    ////    let tag1name = arr?.first!
    //    let tag1name = "回答数 "  String(replayCount!)  " / PV数 "  String(pvCount!)
    //       " / "  (arr?[0])!
    tagsText.text = author
    //    if(count > 1) {
    //      arr?.removeFirst()
    //      let tag2name = arr?[0]
    //      tagsText.text = tag1name  ","  tag2name!
    //      if(count > 2) {
    //        arr?.removeFirst()
    //        let tag3name = arr?[0]
    //        tagsText.text = tag1name  ","  tag2name!  ","  tag3name!
    //        if(count > 3) {
    //          arr?.removeFirst()
    //          let tag4name = arr?[0]
    //          tagsText.text = tag1name  ","  tag2name!  ","  tag3name!  ","  tag4name!
    //          if(count > 4) {
    //            arr?.removeFirst()
    //            let tag5name = arr?[0]
    //            tagsText.text = tag1name  ","  tag2name!  ","  tag3name!  ","  tag4name!  ","  tag5name!
    //          }
    //        }
    //      }
    //    }
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
  
  // Menuボタンタップ時
  @IBAction func next(_ sender: Any) {
    tapRead(self.savedPage)
    
    popUp()
  }
  
  private func popUp() {
    let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
    
    let flutterSwiftAction = UIAlertAction(title: "Flutter/Swift", style: .default,
                                           handler:{
                                            (action:UIAlertAction!) -> Void in
                                            self.articles.removeAll()
                                            if(self.tag == self.tagSwift) {
                                              self.tag = self.tagFlutter
                                            }
                                            else {
                                              self.tag = self.tagSwift
                                            }
                                            //      self.savedPage = 1
                                            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text = String(self.tag) + " Page " + String(self.savedPage) +
                                            "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                           })
    alertController.addAction(flutterSwiftAction)
    
    let swiftPage1Action = UIAlertAction(title: "Swift page1/20posts", style: .default,
                                         handler:{
                                          (action:UIAlertAction!) -> Void in
                                          self.articles.removeAll()
                                          self.tag = self.tagSwift
                                          self.savedPage = 1
                                          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage)
                                          "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                         })
    alertController.addAction(swiftPage1Action)
    
    let swiftPage50Action = UIAlertAction(title: "Swift page50/20posts", style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
                                            self.articles.removeAll()
                                            self.tag = self.tagSwift
                                            self.savedPage = 50
                                            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
                                            "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                          })
    alertController.addAction(swiftPage50Action)
    
    let flutterPage1Action = UIAlertAction(title: "Flutter page1/20posts", style: .default,
                                           handler:{
                                            (action:UIAlertAction!) -> Void in
                                            self.articles.removeAll()
                                            self.tag = self.tagFlutter
                                            self.savedPage = 1
                                            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage)
                                            "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                           })
    alertController.addAction(flutterPage1Action)
    
    let saveSwiftPageAction = UIAlertAction(title: "Save Swift Page ! " + String(self.savedPage), style: .default,
                                            handler:{
                                              (action:UIAlertAction!) -> Void in
                                              //savedPage  //現在のページ
                                              //        print("start tapSave.")
                                              //        print("savedPage: "  String(self.savedPage))
                                              
                                              // mysql delete
                                              self.tapDelete(self.savedPage)
                                              // mysql insert
                                              self.tapSave(self.savedPage)
                                              
                                              self.sqliteSavedPage = self.savedPage;
                                              //        print("sqliteSavedPage: "  String(self.sqliteSavedPage))
                                              
                                            })
    alertController.addAction(saveSwiftPageAction)
    
    let loadSwiftPageAction = UIAlertAction(title: "Load Swift Page ! " + String(self.sqliteSavedPage), style: .default,
                                            handler:{
                                              (action:UIAlertAction!) -> Void in
                                              
                                              self.articles.removeAll()
                                              self.savedPage = self.sqliteSavedPage
                                              self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                              self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
                                              "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                              
                                              //      print ("finish tapLoad!")
                                              
                                            })
    alertController.addAction(loadSwiftPageAction)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true, completion: nil)
  }
  
  func swiftPage1Action() {
    articles.removeAll()
    tag = tagFlutter
    savedPage = 1
    myload(page: savedPage, perPage: 20, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage)
    "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // Closeボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    
    //戻る
    dismiss(animated: true, completion: nil)
    /*
     //savedPage  //現在のページ
     print("start tapSave.")
     print("savedPage: "  String(savedPage))
     
     // mysql delete
     tapDelete(savedPage)
     // mysql insert
     tapSave(savedPage)
     
     sqliteSavedPage = savedPage;
     print("sqliteSavedPage: "  String(sqliteSavedPage))
     */
    
  }
  
  // nameが1のデータをdelete。引数のpageは未使用。
  func tapDelete(_ page: Int) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "DELETE FROM  Heroes WHERE name = ?"
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      //      let errmsg = String(cString: sqlite3_errmsg(db)!)
      //      print("error preparing delte: \(errmsg)")
      return
    }
    //binding the parameters 1つ目の?に1をセット
    if sqlite3_bind_text(stmt, 1, "1", -1, nil) != SQLITE_OK{
      //        let errmsg = String(cString: sqlite3_errmsg(db)!)
      //        print("failure binding: \(errmsg)")
      return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
      //        let errmsg = String(cString: sqlite3_errmsg(db)!)
      //        print("failure deleting hero: \(errmsg)")
      return
    }
    //    print ("finish tapDelete!")
  }
  
  // nameが1、powerrankが引数のpageの文字列で、insert
  func tapSave(_ page: Int) {
    //creating a statement
    var stmt: OpaquePointer?
    //the insert query
    let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (1,?)"
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      //      let errmsg = String(cString: sqlite3_errmsg(db)!)
      //      print("error preparing insert: \(errmsg)")
      return
    }
    //binding the parameters 1つ目の?に2をセット
    if sqlite3_bind_text(stmt, 1, String(page), -1, nil) != SQLITE_OK{
      //        let errmsg = String(cString: sqlite3_errmsg(db)!)
      //        print("failure binding: \(errmsg)")
      return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
      //        let errmsg = String(cString: sqlite3_errmsg(db)!)
      //        print("failure inserting hero: \(errmsg)")
      return
    }
    //    print ("finish tapSave!")
  }
  
  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
    tapRead(savedPage)
    
    articles.removeAll()
    //savedPage = 1
    myload(page: savedPage, perPage: 20, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage)
    "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    
    //    print ("finish tapLoad!")
  }
  
  func tapRead(_ page: Int) {
    //this is our select query
    let queryString = "SELECT * FROM Heroes"
    //statement pointer
    var stmt:OpaquePointer?
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      //        let errmsg = String(cString: sqlite3_errmsg(db)!)
      //        print("error preparing insert: \(errmsg)")
      return
    }
    //traversing through all the records
    while(sqlite3_step(stmt) == SQLITE_ROW){
      //let id = sqlite3_column_int(stmt, 0)
      //      let name = String(cString: sqlite3_column_text(stmt, 1))
      let powerrank = sqlite3_column_int(stmt, 2)
      //      print("name:"  name  ", powerrank:"  String(powerrank))
      //adding values to list
      //        heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
      sqliteSavedPage = Int(powerrank)
    }
    //    print ("finish tapRead!")
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
    webView.url = articles[indexPath.row]["link"] as? String
    
    self.present(webView, animated: true, completion: nil)
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
