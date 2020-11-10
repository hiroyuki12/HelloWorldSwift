//
//  TeratailViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit
import SQLite3

struct TeratailArticlesStruct: Codable {
  var questions: [QuestionsStruct]
  
  struct QuestionsStruct: Codable {
    var id: Int
    var title: String
    var created: String
    var count_reply: Int
    var count_pv: Int
    var tags: [String]
    var user: UserStruct?

    struct UserStruct: Codable {
      var photo: String
//      var score: Int
    }
  }
}

class TeratrailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var db: OpaquePointer?
  
  var isLoading = false;
  
  var questions: [TeratailArticlesStruct.QuestionsStruct] = []
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  var tag = "Swift"
  
  let tagSwift      = "Swift"
  let tagFirebase   = "Firebase"
//  let tagFirestore  = "firestore"
  let tagFlutter    = "Flutter"
  
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
    let str1:String = "https://teratail.com/api/v1/tags/"
    let str2:String = String(tag)
    let str3:String = "/questions?page="
    let str4:String = String(page)
    let str5:String = "&limit="
    let str6:String = String(perPage)

    let str7:String = str1 + str2 + str3 + str4 + str5 + str6
    
    let url: URL = URL(string: str7)!
    
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
//      print ("response!!!!!")
//      print(response!)
      guard let data = data else {
        return
      }
      do {
        let teratailArticles = try JSONDecoder().decode(TeratailArticlesStruct.self, from: data)  // Codable
//        print("AA")
//        print(teratailArticles.questions[0])
        
        let articles2_tmp = self.questions  // 一時退避
        self.questions = articles2_tmp + teratailArticles.questions
        //print("self.questions Set End!")
        
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
    
    let question = questions[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as! UILabel
    textTitle.text = question.title // questions->title
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as! UILabel
    textDetailText.text = daysAgo(question.created)  // questions->created
    // セルに表示する画像を設定する
    let profileImageUrl = question.user?.photo  // questions->user?->photo
    let profileImage = cell.viewWithTag(1) as! UIImageView
    if profileImageUrl != nil {  // if profileImageUrl not nil
      let myUrl: URL? = URL(string: profileImageUrl!)
      profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    }
    // セルに表示する回答数とタグを設定する
    let tagsText = cell.viewWithTag(4) as! UILabel
    let replayCount = question.count_reply  // questions->count_reply
    let pvCount = question.count_pv  // questions->count_pv
    let count = question.tags.count
    let tag1name = "回答数 " + String(replayCount) + " / PV数 " + String(pvCount) + " / " + question.tags[0]
    tagsText.text = tag1name
    if(count > 1) {
      let tag2name = question.tags[1]
      tagsText.text = tag1name + "," + tag2name
      if(count > 2) {
        let tag3name = question.tags[2]
        tagsText.text = tag1name + "," + tag2name + "," + tag3name
        if(count > 3) {
          let tag4name = question.tags[3]
          tagsText.text = tag1name + "," + tag2name + "," + tag3name + "," + tag4name
          if(count > 4) {
            let tag5name = question.tags[4]
            tagsText.text = tag1name + "," + tag2name + "," + tag3name + "," + tag4name + "," + tag5name
          }
        }
      }
    }
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    //    print(data)
    let calendar = Calendar.current
    let dateComponents = DateComponents(calendar: calendar, year: Int(data[0...3]), month: Int(data[5...6]), day: Int(data[8...9]), hour: Int(data[11...12]), minute: Int(data[14...15]), second: Int(data[17...18]))
    if let date = calendar.date(from: dateComponents) {
      //print("\(date)      \(date.timeAgo())")
      return date.timeAgo()
    }
    return ""
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return questions.count
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

    let flutterSwiftAction = UIAlertAction(title: "Swift/Firebase/Flutter", style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        self.questions.removeAll()
        if(self.tag == self.tagSwift) {
          self.tag = self.tagFirebase
        }
        else if(self.tag == self.tagFirebase) {
          self.tag = self.tagFlutter
        }
//        else if(self.tag == self.tagFirestore) {
//          self.tag = self.tagFlutter
//        }
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
        self.questions.removeAll()
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
        self.questions.removeAll()
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
        self.questions.removeAll()
        self.tag = self.tagFlutter
        self.savedPage = 1
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
             "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
      })
    alertController.addAction(flutterPage1Action)
  
    let saveSwiftPageAction = UIAlertAction(title: "Save Swift Page ! " + String(self.savedPage), style: .default,
      handler:{
        (action:UIAlertAction!) -> Void in
        
        // mysql delete
        self.tapDelete(self.savedPage)
        // mysql insert
        self.tapSave(self.savedPage)
        
        self.sqliteSavedPage = self.savedPage
      })
    alertController.addAction(saveSwiftPageAction)
  
    let loadSwiftPageAction = UIAlertAction(title: "Load Swift Page ! " + String(self.sqliteSavedPage), style: .default,
    handler:{
      (action:UIAlertAction!) -> Void in
      
      self.questions.removeAll()
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
    questions.removeAll()
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
//      print("name:" + name + ", powerrank:" + String(powerrank))
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
    webView.url = "https://teratail.com/questions/" + String(questions[indexPath.row].id)
    
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

