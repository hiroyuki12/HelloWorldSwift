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
  
  var isLoading = false;
  // 読み込み中にタグやページを切り替えた場合に、古いリクエストの結果を捨てるための番号
  private var loadGeneration = 0
  
  var questions: [TeratailArticlesStruct.QuestionsStruct] = []
  
  var sqliteSavedPage = 0
  
  let app = "Teratail"
  
  var tag = "Swift"
  
  let tagSwift      = "Swift"
  let tagFirebase   = "Firebase"
//  let tagFirestore  = "firestore"
  let tagFlutter    = "Flutter"
  let tagReact    = "React.js"
    
  var savedPage = 1
  var perPage = 20
  
  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // セルの高さを設定
    table.rowHeight = 70
    
    myload(page: 1, perPage: perPage, tag: tag)
  }
  
  override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
      isModalInPresentation = true  // 下にスワイプで閉じなくなる
  }
  
  func myload(page: Int , perPage: Int, tag: String) {
    var components = URLComponents(string: "https://teratail.com/api/v1/tags/")
    components?.path += tag + "/questions"
    components?.queryItems = [URLQueryItem(name: "page", value: String(page)),
                              URLQueryItem(name: "limit", value: String(perPage))]
    guard let url = components?.url else { return }
    
    isLoading = true
    let generation = loadGeneration
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
      // デコードはバックグラウンドで行い、配列の更新はメインスレッドで行う（データ競合防止）
      let newQuestions = data.flatMap { try? JSONDecoder().decode(TeratailArticlesStruct.self, from: $0) }?.questions
      DispatchQueue.main.async {
        guard let self = self, generation == self.loadGeneration else { return }
        if let newQuestions = newQuestions {
          self.questions += newQuestions
          self.table.reloadData()
        }
        // 失敗時も解除しないと、以降スクロールで次のページを読み込めなくなる
        self.isLoading = false
      }
    })
    
    task.resume() //実行する
  }
  
  // 一覧を空にして、指定したタグ・ページを読み込み直す
  private func reload(tag: String, page: Int) {
    loadGeneration += 1
    questions.removeAll()
    table.reloadData()
    self.tag = tag
    savedPage = page
    myload(page: savedPage, perPage: 20, tag: self.tag)
    updatePageLabel()
  }
  
  private func updatePageLabel() {
    textPage.text =  String(tag) + " Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    guard indexPath.row < questions.count else { return cell }
    let question = questions[indexPath.row]
    // セルに表示するタイトルを設定する
    let textTitle = cell.viewWithTag(2) as? UILabel
    textTitle?.text = question.title // questions->title
    // セルに表示する作成日を設定する
    let textDetailText = cell.viewWithTag(3) as? UILabel
    textDetailText?.text = daysAgo(question.created)  // questions->created
    // セルに表示する画像を設定する（画像がなければ再利用セルの古い画像を消す）
    let profileImage = cell.viewWithTag(1) as? UIImageView
    profileImage?.loadImageAsynchronously(url: question.user.flatMap { URL(string: $0.photo) }, defaultUIImage: nil)
    // セルに表示する回答数とタグ（最大5つ）を設定する
    let tagsText = cell.viewWithTag(4) as? UILabel
    var text = "回答数 " + String(question.count_reply) + " / PV数 " + String(question.count_pv)
    if !question.tags.isEmpty {
      text += " / " + question.tags.prefix(5).joined(separator: ",")
    }
    tagsText?.text = text
    return cell
  }
  
  func daysAgo(_ data: String) -> String {
    return DateParser.localDateTime(data)?.timeAgo() ?? ""
  }
  
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return questions.count
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    self.table.reloadData()
  }
  
  // Menuボタンタップ時
  @IBAction func next(_ sender: Any) {
    sqliteSavedPage = PageStore.shared.page(for: tag + app)
    
    popUp()
  }
  
  private func popUp() {
    let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

    let flutterSwiftAction = UIAlertAction(title: "Swift/React.js/Firebase/Flutter", style: .default,
      handler:{ [weak self] _ in
        guard let self = self else { return }
        let nextTag: String
        if(self.tag == self.tagSwift) {
          nextTag = self.tagReact
        }
        else if(self.tag == self.tagReact) {
          nextTag = self.tagFirebase
        }
        else if(self.tag == self.tagFirebase) {
          nextTag = self.tagFlutter
        }
        else {
          nextTag = self.tagSwift
        }
        self.reload(tag: nextTag, page: 1)
      })
    alertController.addAction(flutterSwiftAction)

    let swiftPage1Action = UIAlertAction(title: "Swift page1/20posts", style: .default,
      handler:{ [weak self] _ in
        guard let self = self else { return }
        self.reload(tag: self.tagSwift, page: 1)
      })
    alertController.addAction(swiftPage1Action)
  
    let swiftPage50Action = UIAlertAction(title: "Swift page50/20posts", style: .default,
      handler:{ [weak self] _ in
        guard let self = self else { return }
        self.reload(tag: self.tagSwift, page: 50)
      })
    alertController.addAction(swiftPage50Action)
  
    let flutterPage1Action = UIAlertAction(title: "Flutter page1/20posts", style: .default,
      handler:{ [weak self] _ in
        guard let self = self else { return }
        self.reload(tag: self.tagFlutter, page: 1)
      })
    alertController.addAction(flutterPage1Action)
  
    let saveSwiftPageAction = UIAlertAction(title: "Save " + self.tag + " Page ! " + String(self.savedPage), style: .default,
      handler:{ [weak self] _ in
        guard let self = self else { return }
        PageStore.shared.save(page: self.savedPage, for: self.tag + self.app)
        self.sqliteSavedPage = self.savedPage
      })
    alertController.addAction(saveSwiftPageAction)
  
    let loadSwiftPageAction = UIAlertAction(title: "Load " + self.tag + " Page ! " + String(self.sqliteSavedPage), style: .default,
      handler:{ [weak self] _ in
        guard let self = self, self.sqliteSavedPage > 0 else { return }
        self.reload(tag: self.tag, page: self.sqliteSavedPage)
      })
    alertController.addAction(loadSwiftPageAction)
  
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(cancelAction)

    // iPad/Macで表示した場合に備えて、ポップオーバーの表示位置を指定する
    if let popover = alertController.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }
  
  // qキーで画面を閉じる
  override var keyCommands: [UIKeyCommand]? {
    let command = UIKeyCommand(input: "q", modifierFlags: [], action: #selector(tapSave(_:)))
    command.wantsPriorityOverSystemBehavior = true
    return [command]
  }

  // キー入力を受け取るためにファーストレスポンダーになる
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }

  // Closeボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    //戻る
    dismiss(animated: true, completion: nil)
  }
  
  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
  }
  
  // Prevボタン押下
  @IBAction func prev(_ sender: Any) {
    guard savedPage > 1 else { return }
    reload(tag: tag, page: savedPage - 1)
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < questions.count,
          let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as? WebViewController else {
      return
    }
    webView.url = "https://teratail.com/questions/" + String(questions[indexPath.row].id)
    
    self.present(webView, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentSize.height > 0 && self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
      savedPage += 1
      myload(page: savedPage, perPage: 20, tag: tag)
      updatePageLabel()
    }
  }
  
}
