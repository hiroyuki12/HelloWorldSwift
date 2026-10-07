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

struct QiitaArticleStruct: Codable {
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

class QiitaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var isLoading = false;
  
  var articles: [QiitaArticleStruct] = []  // Codable
  
  var sqliteSavedPage = 0
  var sqlliteSavedPerPage = 0
  
  let app = "qiita"
  
//  var tag = "Swift"
//  var tag = "Codex"
  var tag = "ClaudeCode"
//  var tag = "Fable5"
//    let tag = "flutter"
  
  let tagSwift      = "Swift"
  let tagXcode      = "Xcode"
  let tagiOS        = "iOS"
//  let tagFirebase   = "Firebase"
//  let tagFirestore  = "Firestore"
  let tagFlutter       = "Flutter"
  let tagReact         = "React"
  let tagCodex         = "Codex"
  let tagClaudeCode    = "ClaudeCode"
  let tagGemini        = "Gemini"
  let tagGitHubCopilot = "GitHubCopilot"
//  let tagFable5      = "Fable5"
  
  var savedPage = 1
  var perPage = 20
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    // セルの高さを設定
    table.rowHeight = 70
    
    myload(page: savedPage, perPage: perPage, tag: tag)
    textPage.text =  String(tag) + " Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    //print("myload (viewDidLoad)")
    
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
    let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
    let urlString = "https://qiita.com/api/v2/tags/\(encodedTag)/items?page=\(page)&per_page=\(perPage)"
    guard let url = URL(string: urlString) else {
      self.isLoading = false
      return
    }
    
    let requestedTag = tag
    let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
      guard let self = self else { return }
      guard let data = data else {
        DispatchQueue.main.async {
          self.isLoading = false
        }
        return
      }
      do {
        let qiitaArticles = try JSONDecoder().decode([QiitaArticleStruct].self, from: data)  // Codable
        
        DispatchQueue.main.async {
          // タグが切り替わっていないか確認し、メインスレッドで配列を更新 (Data Race防止)
          if requestedTag == self.tag {
            self.articles += qiitaArticles
            self.table.reloadData()
          }
          self.isLoading = false
        }
      }
      catch {
        DispatchQueue.main.async {
          self.isLoading = false
        }
      }
    })
    
    task.resume() //実行する
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    guard indexPath.row < articles.count else { return cell }
    let article = articles[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as? UILabel
    textTitle?.text = article.title
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as? UILabel
    textDetailText?.text = daysAgo(article.created_at)
    // セルに表示する画像を設定する
    let profileImageUrl = article.user.profile_image_url
    let profileImage = cell.viewWithTag(1) as? UIImageView
    profileImage?.image = nil
    let myUrl: URL? = URL(string: profileImageUrl)
    profileImage?.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
    // セルに表示するタグを設定する
    let tagsText = cell.viewWithTag(4) as? UILabel
    tagsText?.text = article.tags.prefix(5).map { $0.name }.joined(separator: ", ")
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    guard let date = DateParser.iso8601(data) ?? DateParser.localDateTime(data) else {
      return ""
    }
    return date.timeAgo()
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

    func addTagAction(title: String, tag: String, page: Int) {
      let tagAction = UIAlertAction(title: title, style: .default,
        handler:{ [weak self] (action:UIAlertAction!) -> Void in
          guard let self = self else { return }
          self.articles.removeAll()
          self.table.reloadData()
          self.tag = tag
          self.savedPage = page
          self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
          self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
               "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
        })
      alertController.addAction(tagAction)
    }

    addTagAction(title: "ClaudeCode", tag: tagClaudeCode, page: 1)
    addTagAction(title: "Codex", tag: tagCodex, page: 1)
    addTagAction(title: "Gemini", tag: tagGemini, page: 1)
    addTagAction(title: "GitHubCopilot", tag: tagGitHubCopilot, page: 1)
    addTagAction(title: "Swift", tag: tagSwift, page: 1)
    addTagAction(title: "React", tag: tagReact, page: 1)
  
    let saveSwiftPageAction = UIAlertAction(title: "Save " + self.tag + " Page ! " + String(self.savedPage), style: .default,
      handler:{ [weak self] (action:UIAlertAction!) -> Void in
        guard let self = self else { return }
        print("start tapSave.")
        print("savedPage: " + String(self.savedPage))
        
        self.tapSave(self.savedPage, self.tag + self.app)
        
        self.sqliteSavedPage = self.savedPage
        print("sqliteSavedPage: " + String(self.sqliteSavedPage))
      })
    alertController.addAction(saveSwiftPageAction)
  
    let loadSwiftPageAction = UIAlertAction(title: "Load " + self.tag + " Page ! " + String(self.sqliteSavedPage), style: .default,
      handler:{ [weak self] (action:UIAlertAction!) -> Void in
        guard let self = self else { return }
        self.articles.removeAll()
        self.table.reloadData()
        self.savedPage = self.sqliteSavedPage
        self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
        self.textPage.text =  String(self.tag) + " Page " + String(self.savedPage) +
              "/20posts/" + String((self.savedPage-1) * 20 + 1) + "〜"
        
        print ("finish tapLoad!")
      })
    alertController.addAction(loadSwiftPageAction)
  
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    // iPad/Macでキー操作から表示した場合に備えて、ポップオーバーの表示位置を指定する
    if let popover = alertController.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }

  // qキーで画面を閉じる、mキーでメニューを表示する
  override var keyCommands: [UIKeyCommand]? {
    let command = UIKeyCommand(input: "q", modifierFlags: [], action: #selector(tapClose(_:)))
    command.wantsPriorityOverSystemBehavior = true
    let menuCommand = UIKeyCommand(input: "m", modifierFlags: [], action: #selector(next(_:)))
    menuCommand.wantsPriorityOverSystemBehavior = true
    return [command, menuCommand]
  }

  // キー入力を受け取るためにファーストレスポンダーになる
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  // Closeボタンタップ時 / qキー押下時
  @IBAction func tapClose(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  // Storyboard互換用
  @IBAction func tapSave(_ sender: Any) {
    tapClose(sender)
  }
  
  // tagの保存ページを page で置き換える
  func tapSave(_ page: Int, _ tag: String) {
    PageStore.shared.save(page: page, for: tag)
  }
  
  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
  }
  
  func tapRead(_ page: Int, _ tag: String) {
    sqliteSavedPage = PageStore.shared.page(for: tag)
  }
  
  // Prevボタン押下
  @IBAction func prev(_ sender: Any) {
    guard savedPage > 1 else { return }
    articles.removeAll()
    table.reloadData()
    savedPage -= 1
    myload(page: savedPage, perPage: 20, tag: tag)
    
    textPage.text =  String(tag) + " Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < articles.count else { return }
    guard let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as? WebViewController else {
      return
    }
    webView.url = articles[indexPath.row].url
    self.present(webView, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentSize.height > 0 && self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading) {
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
