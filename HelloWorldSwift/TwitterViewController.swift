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

class TwitterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  var oauthswift: OAuthSwift?
  
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var jsonArray: [JSON] = []
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  let app = "twitter"
  
  var screenName = "twitter"
  
  var screenNameTwitter = "twitter"
  var screenNameTwitterJp = "twitterjp"
  
  let tagSwift      = "Swift"
  let tagFirebase   = "Firebase"
  let tagFirestore  = "Firestore"
  let tagFlutter    = "Flutter"
  
  var savedPage = 1
  var perPage = 20
  var maxId = "0"
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    //    doOAuthTwitter()
    
//    let swifter = Swifter(consumerKey: Constants.twitterAPIkey,
//                          consumerSecret: Constants.twitterAPIsecretKey,
//                          oauthToken: Constants.twitterAccessToken,
//                          oauthTokenSecret: Constants.twitterAccessTokenSecret)
    
    // こっちは、連携中のユーザーのフォローしてるユーザーのツイートを時系列順に。
    //    swifter.getHomeTimeline(count: 5,success: { json in
    //        // 成功時の処理
    //        print(json)
    //    }, failure: { error in
    //        // 失敗時の処理
    //        print(error)
    //    })
    
    // こっちは、@~~~で指定したユーザーのツイートを時系列順に取得。
//    swifter.getTimeline(for: .screenName("naoya_ito"),success: { json in
//      // 成功時の処理
//      print(json)
//    }, failure: { error in
//      // 失敗時の処理
//      print(error)
//    })
    
    // Do any additional setup after loading the view.
    // セルの高さを設定
//    table.rowHeight = 380  // 70
    table.estimatedRowHeight = 5
    table.rowHeight = UITableView.automaticDimension
    
    myload(page: savedPage, perPage: perPage, tag: screenName)
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
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    var rowHeight = 0
    
    var w = 0.0
    var h = 0.0
    
    let myUrl2 = jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][0]["media_url"].string
    if myUrl2 != nil {
      w = jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][0]["sizes"]["large"]["w"].double ?? 0
      h = jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][0]["sizes"]["large"]["h"].double ?? 0
    }
    
    let myUrl = jsonArray[indexPath.row]["entities"]["media"][0]["media_url"].string
    if myUrl != nil {
      w = jsonArray[indexPath.row]["entities"]["media"][0]["sizes"]["large"]["w"].double ?? 0
      h = jsonArray[indexPath.row]["entities"]["media"][0]["sizes"]["large"]["h"].double ?? 0
    }
    
    if w != 0.0 {
      if w < h {
        if h / w < 1.2 {
          rowHeight = Int(Double(662) * h / w)
        }
        else {
//          rowHeight = 760
          rowHeight = Int(Double(462) * h / w)
        }
      }
      else {
//        rowHeight = 380
        if w / h < 1.2 {
          rowHeight = Int(Double(552) * w / h)
        }
        else if w / h < 1.7 {
          rowHeight = Int(Double(292) * w / h)
        }
        else {
          rowHeight = Int(Double(192) * w / h)
        }
      }
      
      return CGFloat(rowHeight)
    }
    else {
      rowHeight = 90
      return CGFloat(rowHeight)
    }
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
//
//                              let swifter = Swifter(consumerKey: Constants.twitterAPIkey,
//                                                consumerSecret: Constants.twitterAPIsecretKey,
//                                                oauthToken: credential.oauthToken,
//                                                oauthTokenSecret: credential.oauthTokenSecret)
                              
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
    let swifter = Swifter(consumerKey: Constants.twitterAPIkey,
                          consumerSecret: Constants.twitterAPIsecretKey,
                          oauthToken: Constants.twitterAccessToken,
                          oauthTokenSecret: Constants.twitterAccessTokenSecret)
    
//    if self.maxId == "99" {
//      // こっちは、連携中のユーザーのフォローしてるユーザーのツイートを時系列順に。
//      swifter.getHomeTimeline(count: 40,success: { json in
//        // 成功時の処理
//        print(json)
//
//        guard let json2 = json.array else {
//          return
//        }
//
//        self.maxId = json2[json2.count-1]["id_str"].string ?? ""
//
//        self.jsonArray = json2
//        self.table.reloadData()
//        //print("reloadData End!")
//        self.isLoading = false
//        //print("self.isLoading = false End!")
//      }, failure: { error in
//        // 失敗時の処理
//        print(error)
//      })
//    }

    if self.maxId == "0" {
      //    こっちは、@~~~で指定したユーザーのツイートを時系列順に取得。
      swifter.getTimeline(for: .screenName(self.screenName),count: 200,excludeReplies: true,tweetMode: .extended, success: { json in
        // 成功時の処理
        guard let json2 = json.array else {
          return
        }
        print(json2[0])
        print(json2.count)
        let id = json2[json2.count-1]["id"].string ?? ""
        self.maxId = json2[json2.count-1]["id_str"].string ?? ""
        
        self.jsonArray = json2
        self.table.reloadData()
        //print("reloadData End!")
        self.isLoading = false
        //print("self.isLoading = false End!")
        
      }, failure: { error in
        // 失敗時の処理
        print(error)
      })
    }
    else {
      //    こっちは、@~~~で指定したユーザーのツイートを時系列順に取得。
      swifter.getTimeline(for: .screenName(self.screenName), count: 200,maxID: maxId,excludeReplies: true,tweetMode: .extended, success: { json in
        // 成功時の処理
        guard let json2 = json.array else {
          return
        }
        
        if json2.count > 0 {
          self.maxId = json.array?[json2.count-1]["id_str"].string ?? ""
        }
        print(json2.count)
        self.jsonArray += json2
        
        self.table.reloadData()
        //print("reloadData End!")
        self.isLoading = false
        //print("self.isLoading = false End!")
        
      }, failure: { error in
        // 失敗時の処理
        print(error)
      })
    }
    //print("myload End!")
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let userName = String(jsonArray[indexPath.row]["user"]["name"].string ?? "")
    
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as! UILabel
    var text = jsonArray[indexPath.row]["full_text"].string ?? ""
    
    if text.starts(with: "@")
    {
      text = "Replying to " + text
    }
    else if text.starts(with: "RT")
    {
      let arr:[String] = text.components(separatedBy: " ")
      text = userName + " Retweeted | " + arr[2]
    }
    textTitle.text = text
    // セルに表示するLike数とRetweet数を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    let favCount = jsonArray[indexPath.row]["favorite_count"].integer ?? 0
    var favCountString = ""
    if favCount > 999 { favCountString = String(favCount / 1000) + "K" }
    else { favCountString = String(favCount) }
    
    let retweetCount = jsonArray[indexPath.row]["retweet_count"].integer ?? 0
    var retweetCountString = ""
    if retweetCount > 999 { retweetCountString = String(retweetCount / 1000) + "K" }
    else { retweetCountString = String(retweetCount) }
    
    textDetailText.text = favCountString + " Likes  " + retweetCountString + " Retweets"
    // セルに表示するprofile画像を設定する
    let profileImage = cell.viewWithTag(1) as! UIImageView
    let myUrl: URL? = URL(string: jsonArray[indexPath.row]["user"]["profile_image_url"].string ?? "")
    profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    
    let isQuoteStatus = jsonArray[indexPath.row]["is_quote_status"].bool
//    print(text)
//    print(isQuoteStatus)
    
    guard isQuoteStatus != nil else {
      return cell
    }
    // セルに表示する画像1を設定する
    let profileImage2 = cell.viewWithTag(5) as! UIImageView
    if(!isQuoteStatus!) {
      let myUrl2: URL? = URL(string: jsonArray[indexPath.row]["entities"]["media"][0]["media_url"].string ?? "")
      profileImage2.loadImageAsynchronously(url: myUrl2, defaultUIImage: nil)
    }
    else {
      let myUrl2: URL? = URL(string: jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][0]["media_url"].string ?? "")
      profileImage2.loadImageAsynchronously(url: myUrl2, defaultUIImage: nil)
    }
    
    // セルに表示する画像2を設定する
    let profileImage3 = cell.viewWithTag(6) as! UIImageView
    if(!isQuoteStatus!) {
      let myUrl3: URL? = URL(string: jsonArray[indexPath.row]["extended_entities"]["media"][1]["media_url"].string ?? "")
      profileImage3.loadImageAsynchronously(url: myUrl3, defaultUIImage: nil)
    }
    else {
      let myUrl3: URL? = URL(string: jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][1]["media_url"].string ?? "")
      profileImage3.loadImageAsynchronously(url: myUrl3, defaultUIImage: nil)
    }
    
    // セルに表示する画像3を設定する
    let profileImage4 = cell.viewWithTag(7) as! UIImageView
    if(!isQuoteStatus!) {
      let myUrl4: URL? = URL(string: jsonArray[indexPath.row]["extended_entities"]["media"][2]["media_url"].string ?? "")
      profileImage4.loadImageAsynchronously(url: myUrl4, defaultUIImage: nil)
    }
    else {
      let myUrl4: URL? = URL(string: jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][2]["media_url"].string ?? "")
      profileImage4.loadImageAsynchronously(url: myUrl4, defaultUIImage: nil)
    }
    
    // セルに表示する画像4を設定する
    let profileImage5 = cell.viewWithTag(8) as! UIImageView
    if(!isQuoteStatus!) {
      let myUrl5: URL? = URL(string: jsonArray[indexPath.row]["extended_entities"]["media"][3]["media_url"].string ?? "")
      profileImage5.loadImageAsynchronously(url: myUrl5, defaultUIImage: nil)
    }
    else {
      let myUrl5: URL? = URL(string: jsonArray[indexPath.row]["quoted_status"]["extended_entities"]["media"][3]["media_url"].string ?? "")
      profileImage5.loadImageAsynchronously(url: myUrl5, defaultUIImage: nil)
    }
    
    // セルに表示する作成日を設定する
    let tagsText = cell.viewWithTag(4) as! UILabel
    tagsText.text = userName + " " + daysAgo(jsonArray[indexPath.row]["created_at"].string ?? "")
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    //print(data)
    let calendar = Calendar.current
    
    var month = 0
    if(data[4...6] == "Oct") { month = 10 }
    else if(data[4...6] == "Nov") { month = 11 }
    else if(data[4...6] == "Dec") { month = 12 }
    else if(data[4...6] == "Jan") { month = 1 }
    else if(data[4...6] == "Feb") { month = 2 }
    else if(data[4...6] == "Mar") { month = 3 }
    else if(data[4...6] == "Apr") { month = 4 }
    else if(data[4...6] == "May") { month = 5 }
    else if(data[4...6] == "Jun") { month = 6 }
    else if(data[4...6] == "Jul") { month = 7 }
    else if(data[4...6] == "Aug") { month = 8 }
    else if(data[4...6] == "Sep") { month = 9 }
    
    let hour = Int(data[11...12])! + 9
    if (hour < 24) {
      let dateComponents = DateComponents(calendar: calendar, year: Int(data[26...29]), month: month, day: Int(data[8...9]), hour: hour, minute: Int(data[14...15]), second: Int(data[17...18]))
      if let date = calendar.date(from: dateComponents) {
        //print("\(date)      \(date.timeAgo())")
        return date.timeAgo()
      }
    }
    else {
      let hour = Int(data[11...12])! + 9 - 24
      let day = Int(data[8...9])! + 1  // 31 + 1
      let dateComponents = DateComponents(calendar: calendar, year: Int(data[26...29]), month: month, day: day, hour: hour, minute: Int(data[14...15]), second: Int(data[17...18]))
      if let date = calendar.date(from: dateComponents) {
        //print("\(date)      \(date.timeAgo())")
        return date.timeAgo()
      }
    }
    
    return ""
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return jsonArray.count
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
  }
  
  // Menuボタンタップ時
  @IBAction func next(_ sender: Any) {
    tapRead(self.savedPage, self.screenName + self.app)
    
    popUp()
  }
  
  private func popUp() {
    let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

    let flutterSwiftAction = UIAlertAction(title: "Twitter/Twitter Japan", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.jsonArray.removeAll()
        self.maxId = "0"
        if(self.screenName == self.screenNameTwitter) {
          self.screenName = self.screenNameTwitterJp
        }
        else {
          self.screenName = self.screenNameTwitter
        }
        self.savedPage = 1
        self.myload(page: self.savedPage, perPage: 20, tag: self.screenName)
        self.textPage.text =  String(self.screenName) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(flutterSwiftAction)
//
//    let saveSwiftPageAction = UIAlertAction(title: "Save " + self.tag + " Page ! " + String(self.savedPage), style: .default,
//      handler:{
//        (action:UIAlertAction!) -> Void in
//        //savedPage  //現在のページ
//        print("start tapSave.")
//        print("savedPage: " + String(self.savedPage))
//
//        // mysql delete
//        self.tapDelete(self.savedPage, self.tag + self.app)
//        // mysql insert
//        self.tapSave(self.savedPage, self.tag + self.app)
//
//        self.sqliteSavedPage = self.savedPage;
//        print("sqliteSavedPage: " + String(self.sqliteSavedPage))
//
//      })
//    alertController.addAction(saveSwiftPageAction)
//
//    let loadSwiftPageAction = UIAlertAction(title: "Load " + self.tag + " Page ! " + String(self.sqliteSavedPage), style: .default,
//    handler:{
//      (action:UIAlertAction!) -> Void in
//
//      self.tweets.removeAll()
//      self.savedPage = self.sqliteSavedPage
//      self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
//      self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
//            "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
//
//      print ("finish tapLoad!")
//
//    })
//    alertController.addAction(loadSwiftPageAction)
  
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    present(alertController, animated: true, completion: nil)
  }

  func swiftPage1Action() {
//    tweets.removeAll()
    screenName = tagFlutter
    savedPage = 1
    myload(page: savedPage, perPage: 20, tag: screenName)
    textPage.text =  String(screenName) + " Page " + String(savedPage) +
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
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    print (indexPath)  // 1つ目が[0,0]、２つ目が[0,1]
//    popUp()
    
    let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as! WebViewController
    webView.url = "https://twitter.com/Twitter/status/" + String(jsonArray[indexPath.row]["id_str"].string ?? "")
    
    self.present(webView, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
      isLoading = true
      savedPage += 1
      myload(page: savedPage, perPage: 20, tag: screenName)
      //print("myload(List End)")
      
      textPage.text =  String(screenName) + " Page " + String(savedPage) +
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

