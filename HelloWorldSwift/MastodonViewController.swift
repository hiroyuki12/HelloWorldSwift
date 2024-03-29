  //
  //  MastodonViewController.swift
  //  HelloWorldSwift
  //
  //  Created by hiroyuki on 2020/11/27.
  //  Copyright © 2020 hiroyuki. All rights reserved.
  //

  import UIKit
  import Foundation
  import WebKit
  import SQLite3

  struct MastodonArticleStruct: Codable {
    var id: String
  //  var comments_count: Int
    var created_at: String
    var in_reply_to_account_id: String?
  //  var id: String
  //  var likes_count: Int
  //  var private: Bool  //
  //  var reactions_count: Int
//    var tags: [TagsStruct]
    var content: String
  //  var updated_at: String
    var uri: String
    var replies_count: Int?
    var reblogs_count: Int
    var favourites_count: Int
    var reblog: ReblogStruct?
    var account: AccountStruct
    
//    struct TagsStruct: Codable {
//      var name: String
//    }
    
    struct ReblogStruct: Codable {
      var uri: String
      var content: String
      var account: AccountStruct
    }
    struct AccountStruct: Codable {
      var id: String
      var acct: String
  //    var items_count: Int
  //    var permanent_id: Int
      var display_name: String
      var avatar: String
  //    var team_only: Bool
    }
  }
  
  class MastodonViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var textPage: UILabel!
    @IBOutlet weak var myImage: UIImageView!
    
    var db: OpaquePointer?
    
    var isLoading = false;
    
    var articles: [MastodonArticleStruct] = []  // Codable
    
    var sqliteSavedPage = 0
    var sqlliteSavedPerPage = 0
    
    let app = "qiita"
    
    var tag = "drikin"
  //    let tag = "flutter"
    
    let tagDrikin     = "drikin"
    let tagMazzo      = "mazzo"
    
    let tagGuru         = "mstdn.guru"
    let tagJp           = "mstdn.jp"
    let tagQiita        = "qiitadon"
    let tagPawoo        = "pawoo"
    let tagPawooAiIlust = "pawoo #ai"
    let tagSocial       = "social"
    let tagCloud        = "cloud"
    
    let tagFirebase   = "Firebase"
    let tagFirestore  = "Firestore"
    let tagFlutter    = "Flutter"
    
    var savedPage = 1
    var perPage = 20
    var maxId = "999999999999999999"
    
    // 起動時処理
    override func viewDidLoad() {
      super.viewDidLoad()

      // Do any additional setup after loading the view.
      // セルの高さを設定
      table.rowHeight = 110
      
      myload(page: savedPage, perPage: perPage, tag: tag)
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
    
    override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
        isModalInPresentation = true  // 下にスワイプで閉じなくなる
    }
    
    func myload(page: Int , perPage: Int, tag: String) {
      if page > 100 {
        return
      }
      var str1 = ""
      if tag == tagDrikin {
        str1 = "https://mstdn.guru/api/v1/accounts/1/statuses?max_id=" + self.maxId  // drikin
      }
      else if tag == tagMazzo {
        str1 = "https://mstdn.guru/api/v1/accounts/2/statuses?max_id=" + self.maxId  // mazzo
      }
      else if tag == tagGuru {
        str1 = "https://mstdn.guru/api/v1/timelines/public?local=true&max_id=" + self.maxId
      }
      else if tag == tagJp {
        str1 = "https://mstdn.jp/api/v1/timelines/public?local=true&max_id=" + self.maxId
      }
      else if tag == tagQiita {
        str1 = "https://qiitadon.com/api/v1/timelines/public?local=true&max_id=" + self.maxId  // qiitadon
      }
      else if tag == tagPawoo {
        str1 = "https://pawoo.net/api/v1/timelines/public?local=true&max_id=" + self.maxId  // pawoo
      }
      else if tag == tagPawooAiIlust {
        str1 = "https://pawoo.net/api/v1/timelines/tag/ai?limit=10"  // pawoo #AIイラスト
      }
      else if tag == tagSocial {
        str1 = "https://mstdn.social/api/v1/timelines/public?local=true&max_id=" + self.maxId  // pawoo
      }
      else if tag == tagCloud {
        str1 = "https://mastodon.cloud/api/v1/timelines/public?local=true&max_id=" + self.maxId  // pawoo
      }
      else {
        str1 = "https://mstdn.guru/api/v1/timelines/public?local=true&max_id=" + self.maxId
      }

//      let str2:String = String(tag)
//      let str3:String = "/items?page="
//      let str4:String = String(page)
//      let str5:String = "&per_page="
//      let str6:String = String(perPage)

      let str7:String = str1
      
      let url: URL = URL(string: str7)!
      
      let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
        guard let data = data else {
          return
        }
//        print("AA")
//        print(data)
        do {
          let mastodonArticles = try JSONDecoder().decode([MastodonArticleStruct].self, from: data)  // Codable
//          print("BB")
//          print(mastodonArticles[0])
//          print(mastodonArticles[0].account.id)
          
        if mastodonArticles.count > 19 {
          self.maxId = mastodonArticles[19].id
        }

          // 一時退避
          let articles_tmp = self.articles
          // 末尾に追加
          let articles = articles_tmp + mastodonArticles
          
          self.articles = articles
          //print("self.articles Set End!")
          
          DispatchQueue.main.async {
            self.table.reloadData()
            //print("reloadData End!")
            self.isLoading = false
            //print("self.isLoading = false End!")
          }
        }
        catch {
          print("error-1")
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
//      textTitle.text = article.content
      let tmpTitle = article.content
      let title1 = tmpTitle.replacingOccurrences(of: "<p>", with: "")
      let title2 = title1.replacingOccurrences(of: "</p>", with: "")
      let title3 = title2.replacingOccurrences(of: "<span>", with: "")
      let title4 = title3.replacingOccurrences(of: "</span>", with: "")
      let title5 = title4.replacingOccurrences(of: "%lt;", with: "<")
      let title6 = title5.replacingOccurrences(of: "<br />", with: "")
      let title7 = title6.replacingOccurrences(of: "<span class=\"h-card\">", with: "")
      let title8 = title7.replacingOccurrences(of: "<a href=\"https://mstdn.guru/", with: "")
      let title9 = title8.replacingOccurrences(of: "\" class=\"u-url mention\">", with: "")
      let title10 = title9.replacingOccurrences(of: "</a>", with: "")
      let title11 = title10.replacingOccurrences(of: "&amp;", with: "&")
      let title12 = title11.replacingOccurrences(of: "<a href=\"https://qiitadon.com/", with: "")
      let title13 = title12.replacingOccurrences(of: "&gt;", with: ">")
      let title14 = title13.replacingOccurrences(of: "\" class=\"mention hashtag\" rel=\"tag\">", with: "")
      let title15 = title14.replacingOccurrences(of: "tags/", with: "#")
      let title16 = title15.replacingOccurrences(of: "&quot;", with: "\"")
//      let title6 = title5.replacingOccurrences(of: "</span>", with: "")
      let titleFix = title16
      textTitle.text = titleFix
      
//      print(article.in_reply_to_account_id)
      if article.in_reply_to_account_id != nil {
        textTitle.text = "replied | " + titleFix
      }
      
      var flgBoosted = false
      
      if article.reblog != nil {
        let tmpTitle = article.reblog!.content
        let title1 = tmpTitle.replacingOccurrences(of: "<p>", with: "")
        let title2 = title1.replacingOccurrences(of: "</p>", with: "")
        let title3 = title2.replacingOccurrences(of: "<span>", with: "")
        let title4 = title3.replacingOccurrences(of: "</span>", with: "")
        let title5 = title4.replacingOccurrences(of: "%lt;", with: "<")
        let title6 = title5.replacingOccurrences(of: "<br />", with: "")
        let title7 = title6.replacingOccurrences(of: "<span class=\"h-card\">", with: "")
        let title8 = title7.replacingOccurrences(of: "<a href=\"https://mstdn.guru/", with: "")
        let title9 = title8.replacingOccurrences(of: "\" class=\"u-url mention\">", with: "")
        let title10 = title9.replacingOccurrences(of: "</a>", with: "")
        let title11 = title10.replacingOccurrences(of: "&amp;", with: "&")
        let title12 = title11.replacingOccurrences(of: "<a href=\"https://qiitadon.com/", with: "")
        let title13 = title12.replacingOccurrences(of: "&gt;", with: ">")
        let title14 = title13.replacingOccurrences(of: "\" class=\"mention hashtag\" rel=\"tag\">", with: "")
        let title15 = title14.replacingOccurrences(of: "tags/", with: "#")
        let title16 = title15.replacingOccurrences(of: "&quot;", with: "\"")
        let titleFix = title16
        if article.in_reply_to_account_id != nil {
          textTitle.text = "replied | " + titleFix
        }
        else {
          textTitle.text = "boosted | " + titleFix
          flgBoosted = true
        }
      }
      
      var profileImageUrl = article.account.avatar
      if flgBoosted {
        // セルに表示する画像を設定する
        profileImageUrl = (article.reblog?.account.avatar)!
      }
      let profileImage = cell.viewWithTag(1) as! UIImageView
      let myUrl: URL? = URL(string: profileImageUrl)
      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
      // セルに表示するuserName,作成日を設定する
      let textDetailText = cell.viewWithTag(3) as! UILabel
      if !flgBoosted {
        let userName = String(article.account.display_name)
        textDetailText.text = userName + " " + daysAgo(article.created_at)
      }
      else {
        let userName = String((article.reblog?.account.display_name)!)
        textDetailText.text = userName + " " + daysAgo(article.created_at)
      }
      // セルに表示するタグを設定する
      let tagsText = cell.viewWithTag(4) as! UILabel
//      let count = article.tags.count
      if(article.replies_count != nil) {
        tagsText.text = String(article.replies_count!) + " replies  " + String(article.reblogs_count) + " reblogs  " + String(article.favourites_count) + " favs"
      }
      else {
        tagsText.text = String(article.reblogs_count) + " reblogs  " + String(article.favourites_count) + " favs"
      }
//      var tags = ""
//      if(count > 0) {
//        tags = article.tags[0].name
//        if(count > 1) {
//          tags += "," + article.tags[1].name
//          if(count > 2) {
//            tags += "," + article.tags[2].name
//            if(count > 3) {
//              tags += "," + article.tags[3].name
//              if(count > 4) {
//                tags += "," + article.tags[4].name
//              }
//            }
//          }
//        }
//      }
//      tagsText.text = tags
      return cell
    }
    
    func daysAgo(_ data: String) -> String {
      //    print(data)
      let calendar = Calendar.current
      let hour = Int(data[11...12])! + 9
      if (hour < 24) {
        let dateComponents = DateComponents(calendar: calendar, year: Int(data[0...3]), month: Int(data[5...6]), day: Int(data[8...9]), hour: hour, minute: Int(data[14...15]), second: Int(data[17...18]))
        if let date = calendar.date(from: dateComponents) {
          //        print("\(date)      \(date.timeAgo())")
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
      return articles.count
    }
    
    // Loadボタン押下
    @IBAction func load(_ sender: Any) {
      self.table.reloadData()
      //print("reloadData(tap load button")
    }
    
    // Menuボタンタップ時
    @IBAction func next(_ sender: Any) {
      tapRead(self.savedPage, self.tag + self.app)
      
      popUp()
    }
    
    private func popUp() {
      let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

      let drikinMazzoAction = UIAlertAction(title: "drikin/mazzo", style: .default,
        handler:{
          (action:UIAlertAction!) -> Void in
          self.articles.removeAll()
          if self.tag == self.tagDrikin {
            self.tag = self.tagMazzo
          }
          else {
            self.tag = self.tagDrikin
          }
          self.savedPage = 1
          self.maxId = "999999999999999999"
          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
               "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
        })
      alertController.addAction(drikinMazzoAction)

      let guruJpAction = UIAlertAction(title: "mstdn.guru/mstdn.jp", style: .default,
        handler:{
          (action:UIAlertAction!) -> Void in
          self.articles.removeAll()
          if self.tag == self.tagGuru {
            self.tag = self.tagJp
          }
          else {
            self.tag = self.tagGuru
          }
          self.savedPage = 1
          self.maxId = "999999999999999999"
          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
               "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
        })
      alertController.addAction(guruJpAction)
//
        let pawooAction = UIAlertAction(title: "Pawoo", style: .default,
          handler:{
            (action:UIAlertAction!) -> Void in
            self.articles.removeAll()
            self.tag = self.tagPawoo
            self.savedPage = 1
            self.maxId = "999999999999999999"
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
                 "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
          })
        alertController.addAction(pawooAction)
//
      let pawooAiIlust = UIAlertAction(title: "Pawoo #ai", style: .default,
        handler:{
          (action:UIAlertAction!) -> Void in
          self.articles.removeAll()
          self.tag = self.tagPawooAiIlust
          self.savedPage = 1
          self.maxId = "999999999999999999"
          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
               "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
        })
      alertController.addAction(pawooAiIlust)
//
      let socialCloudAction = UIAlertAction(title: "mstdn.social/mastodon.cloud", style: .default,
        handler:{
          (action:UIAlertAction!) -> Void in
          self.articles.removeAll()
          if self.tag == self.tagSocial {
            self.tag = self.tagCloud
          }
          else {
            self.tag = self.tagSocial
          }
          self.savedPage = 1
          self.maxId = "999999999999999999"
          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
               "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"

        })
      alertController.addAction(socialCloudAction)
//
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
      alertController.addAction(cancelAction)

      present(alertController, animated: true, completion: nil)
    }

    func swiftPage1Action() {
      articles.removeAll()
      tag = tagFlutter
      savedPage = 1
      myload(page: savedPage, perPage: 20, tag: tag)
      textPage.text =  String(tag) + " Page " + String(savedPage) +
            "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    }
    
    // Closeボタンタップ時
    @IBAction func tapSave(_ sender: Any) {
      //戻る
      dismiss(animated: true, completion: nil)
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
  //      print("error preparing delte: \(errmsg)")
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
    func tapSave(_ page: Int, _ tag: String) {
      //creating a statement
      var stmt: OpaquePointer?
      //the insert query
      let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (\"" + tag + "\"," + String(page) + ")"
      //preparing the query
      if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
  //      let errmsg = String(cString: sqlite3_errmsg(db)!)
  //      print("error preparing insert: \(errmsg)")
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
    
    func tapRead(_ page: Int, _ tag: String) {
      sqliteSavedPage = 0
      //this is our select query
      let queryString = "SELECT * FROM Heroes Where name = \"" + tag + "\""
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
        let name = String(cString: sqlite3_column_text(stmt, 1))
        let powerrank = sqlite3_column_int(stmt, 2)
        print("name:" + name + ", powerrank:" + String(powerrank))
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
  //    webView.url = articles[indexPath.row].url as? String ?? "http://www.yahoo.co.jp"
      webView.url = articles[indexPath.row].uri
      
      if articles[indexPath.row].reblog != nil {
        webView.url = articles[indexPath.row].reblog?.uri
      }
      
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

