//
//  GoogleNewsViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/20.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3

class GoogleNewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var keyToken = Constants.key
  
  var feedUrl = URL(string: "https://news.google.com/rss?hl=ja&gl=JP&ceid=JP:ja")!
  let feedUrlFavorite = URL(string: "https://news.google.com/rss?hl=ja&gl=JP&ceid=JP:ja")!
  let feedUrlHotentry = URL(string: "http://b.hatena.ne.jp/hotentry.rss")
  let feedUrlIT = URL(string: "http://b.hatena.ne.jp/hotentry/it.rss")
  
  var feedItems = [GoogleFeedItem]()
  
  var currentElementName : String! // RSSパース中の現在の要素名
  
  // Favorite
  let ITEM_ELEMENT_NAME = "item"
  let TITLE_ELEMENT_NAME = "title"
  let LINK_ELEMENT_NAME   = "link"
//  let BOOKMARKCOUNT_ELEMENT_NAME   = "hatena:bookmarkcount"
//  let CREATOR_ELEMENT_NAME   = "dc:creator"
  let DATE_ELEMENT_NAME   = "pubDate"
  
  // Hotentry
  let IMAGE_ELEMENT_NAME   = "hatena:imageurl"
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  var tag = "Fav"
  
  let tagFav    = "Fav"
  let tagHotentry  = "Hotentry"
  let tagIT  = "IT"
  
  var savedPage = 1
  var perPage = 20
  
  var parser: XMLParser!
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    parser = XMLParser(contentsOf: feedUrl)
    parser.delegate = self
    parser.parse()
    
    // セルの高さを設定
    table.rowHeight = 70
    
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
    
    //print("viewDidLoad End!")
  }
  
  func myload() {
    
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let feedItem = self.feedItems[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as! UILabel
    textTitle.text = feedItem.title
    // セルに表示するブックマーク数を設定する
//    let textDetailText = cell.viewWithTag(3) as! UILabel
//    textDetailText.text = feedItem.bookmarkcount + " users"
    // セルに表示する画像を設定する
    //https://cdn.profile-image.st-hatena.com/users/laiso/profile.gif
//    if(feedItem.creator != nil) {  // Farorite
//      let profileImageUrl = "https://cdn.profile-image.st-hatena.com/users/" + feedItem.creator + "/profile.gif"// items->thumbnail
//      let profileImage = cell.viewWithTag(1) as! UIImageView
//      let myUrl: URL? = URL(string: profileImageUrl)
//      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
//    }
//    if(feedItem.imageurl != nil) {  // Hotentry, IT
//      let profileImageUrl = feedItem.imageurl! // items->thumbnail
//      let profileImage = cell.viewWithTag(1) as! UIImageView
//      let myUrl: URL? = URL(string: profileImageUrl)
//      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
//    }
    // セルに表示するブックマークしたユーザー、日を設定する
    let tagsText = cell.viewWithTag(4) as! UILabel
//    tagsText.text = daysAgo(feedItem.pubDate)
    tagsText.text = feedItem.pubDate
    //    let replayCount = article["answer_count"] as? Int  // items->answer_count
    //    let pvCount = article["view_count"] as? Int  // items->view_count
    //    var arr = article["tags"] as? [String]  // items->tags
    //    let count = arr!.count
    ////    let tag1name = arr?.first!
    //    let tag1name = "回答数 "  String(replayCount!)  " / PV数 "  String(pvCount!)
    //       " / "  (arr?[0])!
//    tagsText.text = feedItem.creator + " " + feedItem.date + "+09.00"
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
  
  func daysAgo(_ data: String) -> String {
    //    print(data)
    let calendar = Calendar.current
    
    let hour = Int(data[11...12])! + 9
    if (hour < 24) {
      let dateComponents = DateComponents(calendar: calendar, year: Int(data[0...3]), month: Int(data[5...6]), day: Int(data[8...9]), hour: hour, minute: Int(data[14...15]), second: Int(data[17...18]))
      if let date = calendar.date(from: dateComponents) {
        //print("\(date)      \(date.timeAgo())")
        return date.timeAgo()
      }
    }
    else {
      let hour = Int(data[11...12])! + 9 - 24
      let day = Int(data[8...9])! + 1  // 31 + 1
      let dateComponents = DateComponents(calendar: calendar, year: Int(data[0...3]), month: Int(data[5...6]), day: day, hour: hour, minute: Int(data[14...15]), second: Int(data[17...18]))
      if let date = calendar.date(from: dateComponents) {
        //print("\(date)      \(date.timeAgo())")
        return date.timeAgo()
      }
    }
    
    return ""
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.feedItems.count
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
    
    let flutterSwiftAction = UIAlertAction(title: "Fav/Hotentry/IT", style: .default,
                                           handler:{
                                            (action:UIAlertAction!) -> Void in
//                                            self.articles.removeAll()
                                            self.feedItems.removeAll()
                                            if(self.tag == self.tagFav) {
                                              self.tag = self.tagHotentry
                                              self.feedUrl = self.feedUrlHotentry!
                                            }
                                            else if(self.tag == self.tagHotentry) {
                                              self.tag = self.tagIT
                                              self.feedUrl = self.feedUrlIT!
                                            }
                                            else {
                                              self.tag = self.tagFav
                                              self.feedUrl = self.feedUrlFavorite
                                            }
                                            //      self.savedPage = 1
                                            self.parser = XMLParser(contentsOf: self.feedUrl)
                                            self.parser.delegate = self
                                            self.parser.parse()
                                            self.table.reloadData()
                                            //self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text = String(self.tag) + " Page " + String(self.savedPage) +
                                              "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                           })
    alertController.addAction(flutterSwiftAction)
    
    let swiftPage1Action = UIAlertAction(title: "Swift page1/20posts", style: .default,
                                         handler:{
                                          (action:UIAlertAction!) -> Void in
//                                          self.articles.removeAll()
                                          self.tag = self.tagFav
                                          self.savedPage = 1
                                          //self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
                                          "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                         })
    alertController.addAction(swiftPage1Action)
    
    let swiftPage50Action = UIAlertAction(title: "Swift page50/20posts", style: .default,
                                          handler:{
                                            (action:UIAlertAction!) -> Void in
//                                            self.articles.removeAll()
                                            self.tag = self.tagFav
                                            self.savedPage = 50
                                            //self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
                                              "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
                                          })
    alertController.addAction(swiftPage50Action)
    
    let flutterPage1Action = UIAlertAction(title: "Flutter page1/20posts", style: .default,
                                           handler:{
                                            (action:UIAlertAction!) -> Void in
//                                            self.articles.removeAll()
                                            self.tag = self.tagHotentry
                                            self.savedPage = 1
                                            //self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
                                            self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
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
                                              
//                                              self.articles.removeAll()
                                              self.savedPage = self.sqliteSavedPage
                                              //self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
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
  }
  
  // Closeボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    //戻る
    dismiss(animated: true, completion: nil)
    
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
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    //    print (indexPath)  // 1つ目が[0,0]、２つ目が[0,1]
    //    popUp()
    
    let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as! WebViewController
    let feedItem = self.feedItems[indexPath.row]
    webView.url = feedItem.link
    
    if(webView.url.hasPrefix("http")) {
      self.present(webView, animated: true, completion: nil)
    }
    else {
      print(feedItem.link)
    }
    
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    if(tag == tagHotentry || tag == tagIT) {
//        if (self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
//          isLoading = true
//          savedPage += 1
//          print(savedPage)
//          let url = "http://b.hatena.ne.jp/hotentry.rss?page=" + String(savedPage)
//          self.feedUrl = URL(string: url)!
//          self.parser = XMLParser(contentsOf: self.feedUrl)
//          self.parser.delegate = self
//          self.parser.parse()
//          self.table.reloadData()
//          //myload(page: savedPage, perPage: 20, tag: tag)
//          //print("myload(List End)")
//
//          textPage.text =  String(tag) + " Page " + String(savedPage) +
//            "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
//        }
//    }
  }
  
  func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    self.currentElementName = nil
    print(elementName)
    if elementName == ITEM_ELEMENT_NAME {
      self.feedItems.append(GoogleFeedItem())
    } else {
      currentElementName = elementName
    }
  }
  
  func parser(_ parser: XMLParser, foundCharacters string: String) {
    if self.feedItems.count > 0 {
      let lastItem = self.feedItems[self.feedItems.count - 1]
      switch self.currentElementName {
      case TITLE_ELEMENT_NAME:
        let tmpString = lastItem.title
        lastItem.title = (tmpString != nil) ? tmpString! + string : string
      case LINK_ELEMENT_NAME:
        lastItem.link = string
      case DATE_ELEMENT_NAME:
        lastItem.pubDate = string
      default: break
      }
    }
  }
  
  func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    self.currentElementName = nil
  }
  
  func parserDidEndDocument(_ parser: XMLParser) {
    //      self.tableView.reloadData()
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

class GoogleFeedItem {
  var title: String!
  var link: String!
  var pubDate: String!
}
