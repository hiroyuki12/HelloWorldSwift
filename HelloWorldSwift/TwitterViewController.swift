//
//  TwitterViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/11/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3
import Swifter
import OAuthSwift

struct TweetStruct: Codable {
//  var coediting: Bool
//  var comments_count: Int
  var created_at: String
//  var id: String
//  var likes_count: Int
//  var private: Bool  //
//  var reactions_count: Int
  var tags: [TagsStruct]
  var title: String
//  var updated_at: String
  var url: String
  var user: UserStruct
  
  struct TagsStruct: Codable {
    var name: String
  }
  struct UserStruct: Codable {
    var id: String
//    var items_count: Int
//    var permanent_id: Int
    var profile_image_url: String
//    var team_only: Bool
  }
}

class TwitterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  var oauthswift: OAuthSwift?
  
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var articles: [TweetStruct] = []  // Codable
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  let app = "qiita"
  
  var tag = "Swift"
//    let tag = "flutter"
  
  let tagSwift      = "Swift"
  let tagFirebase   = "Firebase"
  let tagFirestore  = "Firestore"
  let tagFlutter    = "Flutter"
  
  var savedPage = 1
  var perPage = 20
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    doOAuthTwitter()
    
    print("start")
    let TWITTER_CONSUMER_KEY = Constants.twitterAPIkey
    let TWITTER_CONSUMER_SECRET = Constants.twitterAPIsecretKey
    let TWITTER_ACCESS_TOKEN = Constants.twitterAccessToken
    let TWITTER_ACCESS_TOKEN_SECRET = Constants.twitterAccessTokenSecret
//    let accessToken = SwifterCredential.OAuthAccessToken(key: TWITTER_ACCESS_TOKEN, secret: TWITTER_ACCESS_TOKEN_SECRET)
//    let credential = SwifterCredential(accessToken: accessToken)
    let swifter = Swifter(consumerKey: TWITTER_CONSUMER_KEY, consumerSecret: TWITTER_CONSUMER_SECRET)
//    swifter.client.credential = credential
//    swifter.postStatusUpdate("swifter-test", inReplyToStatusID: nil, lat: nil, long: nil, placeID: nil, displayCoordinates: nil, trimUser: nil, success: {
//        (status) in
//        print(status)
//    }) {
//        (error) in
//        print(error)
//    }
    
    //login処理
    // swifter構造体の宣言
//    let swifter = Swifter(consumerKey: Constants.twitterAPIkey, consumerSecret: Constants.twitterAPIsecretKey, appOnly: true)
    
//    swifter.authorize(
//        withCallback: URL(string:"app-HelloWorldSwift://success")!,
//        presentingFrom: self,
//        success: { accessToken, response in
//            guard let accessToken = accessToken else {
//                return
//            }
//            let oAuthToken = accessToken.key
//            let secret = accessToken.secret
////            UserDefaults.standard.set(oAuthToken, forKey: "oAuthToken")
////            UserDefaults.standard.set(secret, forKey: "secret")
//    }, failure: { error in
//        print(error)
//     })
    
    // のちに使う変数
//    var twitterTokenKey:String!
//    var twitterTokenSecret:String!
//
//    swifter.authorize(
//      withCallback: URL(string: Constants.twitterCallbackURL)!,
//      presentingFrom: self,
//      success: { accessToken, response in
//        print(response)
//        guard let accessToken = accessToken else { return }
//        twitterTokenKey = accessToken.key
//        twitterTokenSecret = accessToken.secret
//      }, failure: { error in
//        print(error)
//      }
//    )
    
    // こっちは、連携中のユーザーのフォローしてるユーザーのツイートを時系列順に。
    swifter.getHomeTimeline(count: 5,success: { json in
        // 成功時の処理
        print(json)
    }, failure: { error in
        // 失敗時の処理
        print(error)
    })

    // こっちは、@~~~で指定したユーザーのツイートを時系列順に取得。
//    swifter.getTimeline(for: .screenName("naoya"),success: { json in
//        // 成功時の処理
//        print(json)
//    }, failure: { error in
//        // 失敗時の処理
//        print(error)
//    })
    
    // Do any additional setup after loading the view.
    // セルの高さを設定
    table.rowHeight = 70
    
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
  
  // OAuth1ログイン処理
  func doOAuthTwitter(){
    
    let oauthswift = OAuth1Swift(
      consumerKey: Constants.twitterAPIkey,
      consumerSecret: Constants.twitterAPIsecretKey,
      requestTokenUrl: "https://api.twitter.com/oauth/request_token",
      authorizeUrl:    "https://api.twitter.com/oauth/authorize",
      accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
    )
    self.oauthswift = oauthswift
    oauthswift.authorizeURLHandler = getURLHandler()
    
    // コールバック処理
    oauthswift.authorize(withCallbackURL: URL(string: "TwitterLoginSampleOAuth://")!,
                         completionHandler:
                          { result in
                            switch result {
                            case .success(let (credential, _, _)):
                              print(credential.oauthToken)
                              print(credential.oauthTokenSecret)
                              self.showAlert(credential: credential)
                              print("success")
                            case .failure(let error):
                              print(error.localizedDescription)
                              print("failure")
                            }
                          }
    )
  }
  
  // ログイン画面起動に必要な処理
  //
  // - Returns: OAuthSwiftURLHandlerType
  func getURLHandler() -> OAuthSwiftURLHandlerType {
    if #available(iOS 9.0, *) {
      let handler = SafariURLHandler(viewController: self, oauthSwift: self.oauthswift!)
      handler.presentCompletion = {
        print("Safari presented")
      }
      handler.dismissCompletion = {
        print("Safari dismissed")
      }
      return handler
    }
    return OAuthSwiftOpenURLExternally.sharedInstance
  }
  
  // アラート表示
  //
  // - Parameter credential: OAuthSwiftCredential
  func showAlert(credential: OAuthSwiftCredential) {
    var message = "oauth_token:\(credential.oauthToken)"
    if !credential.oauthTokenSecret.isEmpty {
      message += "\n\noauth_token_secret:\(credential.oauthTokenSecret)"
    }
    let alert = UIAlertController(title: "ログイン",
                                  message: message,
                                  preferredStyle: UIAlertController.Style.alert)
    alert.addAction(UIAlertAction(title: "OK",
                                  style: UIAlertAction.Style.default, handler: nil))
    self.present(alert, animated: true, completion: nil)
  }
  override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくなる
  }
  
  func myload(page: Int , perPage: Int, tag: String) {
    if page > 100 {
      return
    }
    let str1:String = "http://qiita.com/api/v2/tags/"
    let str2:String = String(tag)
    let str3:String = "/items?page="
    let str4:String = String(page)
    let str5:String = "&per_page="
    let str6:String = String(perPage)

    let str7:String = str1 + str2 + str3 + str4 + str5 + str6
    
    let url: URL = URL(string: str7)!
    
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
      guard let data = data else {
        return
      }
      do {
        let qiitaArticles = try JSONDecoder().decode([TweetStruct].self, from: data)  // Codable
        
        // 一時退避
        let articles_tmp = self.articles
        // 末尾に追加
        let articles = articles_tmp + qiitaArticles
        
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
    textTitle.text = article.title
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    textDetailText.text = daysAgo(article.created_at)
    // セルに表示する画像を設定する
    let profileImageUrl = article.user.profile_image_url
    let profileImage = cell.viewWithTag(1) as! UIImageView
    let myUrl: URL? = URL(string: profileImageUrl)
    profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    // セルに表示するタグを設定する
    /*let tagsText = cell.viewWithTag(4) as! UILabel
    let count = article.tags.count
    tagsText.text = ""
    var tags = ""
    if(count > 0) {
      tags = article.tags[0].name
      if(count > 1) {
        tags += "," + article.tags[1].name
        if(count > 2) {
          tags += "," + article.tags[2].name
          if(count > 3) {
            tags += "," + article.tags[3].name
            if(count > 4) {
              tags += "," + article.tags[4].name
            }
          }
        }
      }
    }
    tagsText.text = tags*/
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    //    print(data)
    let calendar = Calendar.current
    
    let zero = data.startIndex
    let startCharacterIndex0 = data.index(zero, offsetBy: 0)
    let endCharacterIndex3 = data.index(zero, offsetBy: 3)
    let startCharacterIndex5 = data.index(zero, offsetBy: 5)
    let endCharacterIndex6 = data.index(zero, offsetBy: 6)
    let startCharacterIndex8 = data.index(zero, offsetBy: 8)
    let endCharacterIndex9 = data.index(zero, offsetBy: 9)
    let startCharacterIndex11 = data.index(zero, offsetBy:11)
    let endCharacterIndex12 = data.index(zero, offsetBy: 12)
    let startCharacterIndex14 = data.index(zero, offsetBy: 14)
    let endCharacterIndex15 = data.index(zero, offsetBy: 15)
    let startCharacterIndex17 = data.index(zero, offsetBy: 17)
    let endCharacterIndex18 = data.index(zero, offsetBy: 18)
      
    let dateComponents = DateComponents(calendar: calendar, year: Int(data[startCharacterIndex0...endCharacterIndex3]), month: Int(data[startCharacterIndex5...endCharacterIndex6]), day: Int(data[startCharacterIndex8...endCharacterIndex9]), hour: Int(data[startCharacterIndex11...endCharacterIndex12]), minute: Int(data[startCharacterIndex14...endCharacterIndex15]), second: Int(data[startCharacterIndex17...endCharacterIndex18]))
    if let date = calendar.date(from: dateComponents) {
      //        print("\(date)      \(date.timeAgo())")
      //return date.timeAgo()
      return ""
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

    let flutterSwiftAction = UIAlertAction(title: "Swift/Firebase/Firestore/Flutter", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.articles.removeAll()
        if(self.tag == self.tagSwift) {
          self.tag = self.tagFirebase
        }
        else if(self.tag == self.tagFirebase) {
          self.tag = self.tagFirestore
        }
        else if(self.tag == self.tagFirestore) {
          self.tag = self.tagFlutter
        }
        else {
          self.tag = self.tagSwift
        }
        self.savedPage = 1
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
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
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
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
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(flutterPage1Action)
  
    let saveSwiftPageAction = UIAlertAction(title: "Save " + self.tag + " Page ! " + String(self.savedPage), style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        //savedPage  //現在のページ
        print("start tapSave.")
        print("savedPage: " + String(self.savedPage))
        
        // mysql delete
        self.tapDelete(self.savedPage, self.tag + self.app)
        // mysql insert
        self.tapSave(self.savedPage, self.tag + self.app)
        
        self.sqliteSavedPage = self.savedPage;
        print("sqliteSavedPage: " + String(self.sqliteSavedPage))

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
      
      print ("finish tapLoad!")

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
    webView.url = articles[indexPath.row].url
    
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
