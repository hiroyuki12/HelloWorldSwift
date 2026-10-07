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
    var url: String?
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
      var url: String?
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
    
    var isLoading = false;
    // 読み込み中にサーバーを切り替えた場合に、古いリクエストの結果を捨てるための番号
    private var loadGeneration = 0
    
    var articles: [MastodonArticleStruct] = []  // Codable
    
    var sqliteSavedPage = 0
    
    let app = "mastodon"
    
    var tag = "mstdn.jp"
    
    let tagDrikin     = "drikin"
    let tagMazzo      = "mazzo"
      
    let tagJp           = "mstdn.jp"
    let tagGuru         = "mstdn.guru"
    let tagQiita        = "qiitadon"
    let tagPawoo        = "pawoo"
    let tagPawooAiIlust = "pawoo #ai"
    let tagSocial       = "mstdn.social"
    let tagCloud        = "mastodon.cloud"
    
    var savedPage = 1
    var perPage = 20
    var maxId = ""
    
    // 起動時処理
    override func viewDidLoad() {
      super.viewDidLoad()

      // セルの高さを設定
      table.rowHeight = 110
      
      myload(page: savedPage, perPage: perPage, tag: tag)
      updatePageLabel()
    }
    
    override func viewWillLayoutSubviews() {  // 2: isModalInPresentationに1: のプロパティを代入
        isModalInPresentation = true  // 下にスワイプで閉じなくなる
    }
    
    func myload(page: Int , perPage: Int, tag: String) {
      if page > 100 {
        return
      }
      var str1 = ""
      if tag == tagJp {
          str1 = "https://mstdn.jp/api/v1/timelines/public?local=true&limit=" + String(perPage)
      }
      else if tag == tagDrikin {
        str1 = "https://mstdn.guru/api/v1/accounts/1/statuses?limit=" + String(perPage)  // drikin
      }
      else if tag == tagMazzo {
        str1 = "https://mstdn.guru/api/v1/accounts/2/statuses?limit=" + String(perPage)  // mazzo
      }
      else if tag == tagGuru {
        str1 = "https://mstdn.guru/api/v1/timelines/public?local=true&limit=" + String(perPage)
      }
      else if tag == tagQiita {
        str1 = "https://qiitadon.com/api/v1/timelines/public?local=true&limit=" + String(perPage)  // qiitadon
      }
      else if tag == tagPawoo {
        str1 = "https://pawoo.net/api/v1/timelines/public?local=true&limit=" + String(perPage)  // pawoo
      }
      else if tag == tagPawooAiIlust {
        str1 = "https://pawoo.net/api/v1/timelines/tag/ai?limit=10"  // pawoo #AIイラスト
      }
      else if tag == tagSocial {
        str1 = "https://mstdn.social/api/v1/timelines/public?local=true&limit=" + String(perPage)
      }
      else if tag == tagCloud {
        str1 = "https://mastodon.cloud/api/v1/timelines/public?local=true&limit=" + String(perPage)
      }
      else {
        str1 = "https://mstdn.social/api/v1/timelines/public?local=true&limit=" + String(perPage)
      }
      if !self.maxId.isEmpty {
        str1 += "&max_id=" + self.maxId
      }

      guard let url = URL(string: str1) else { return }
      
      isLoading = true
      let generation = loadGeneration
      let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, response, error in
        // デコードはバックグラウンドで行い、配列と maxId の更新はメインスレッドで行う（データ競合防止）
        var mastodonArticles: [MastodonArticleStruct]?
        if let data = data {
          do {
            mastodonArticles = try JSONDecoder().decode([MastodonArticleStruct].self, from: data)  // Codable
          }
          catch {
            print(error)
          }
        }
        DispatchQueue.main.async {
          guard let self = self, generation == self.loadGeneration else { return }
          if let mastodonArticles = mastodonArticles {
            if let lastArticle = mastodonArticles.last {
              self.maxId = lastArticle.id
            }
            self.articles += mastodonArticles
            self.table.reloadData()
          }
          else {
            self.textPage.text = String(self.tag) + " load error"
          }
          self.isLoading = false
        }
      })
      
      task.resume() //実行する
    }
    
    // 一覧を空にして、指定したサーバーの最新から読み込み直す
    private func reload(tag: String) {
      loadGeneration += 1
      articles.removeAll()
      table.reloadData()
      self.tag = tag
      savedPage = 1
      maxId = ""
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
      
      guard indexPath.row < articles.count else { return cell }
      let article = articles[indexPath.row]
      // ブーストの場合は元の投稿の本文・ユーザーを表示する
      let isBoosted = article.reblog != nil && article.in_reply_to_account_id == nil
      // セルに表示する本文を設定する
      let textTitle = cell.viewWithTag(2) as? UILabel
      let content = (article.reblog?.content ?? article.content).htmlToPlainText
      if article.in_reply_to_account_id != nil {
        textTitle?.text = "replied | " + content
      }
      else if isBoosted {
        textTitle?.text = "boosted | " + content
      }
      else {
        textTitle?.text = content
      }
      
      let account = isBoosted ? (article.reblog?.account ?? article.account) : article.account
      // セルに表示する画像を設定する
      let profileImage = cell.viewWithTag(1) as? UIImageView
      profileImage?.loadImageAsynchronously(url: URL(string: account.avatar), defaultUIImage: nil)
      // セルに表示するuserName,作成日を設定する
      let textDetailText = cell.viewWithTag(3) as? UILabel
      textDetailText?.text = account.display_name + " " + daysAgo(article.created_at)
      // セルに表示する返信・ブースト・お気に入り数を設定する
      let tagsText = cell.viewWithTag(4) as? UILabel
      if let repliesCount = article.replies_count {
        tagsText?.text = String(repliesCount) + " replies  " + String(article.reblogs_count) + " reblogs  " + String(article.favourites_count) + " favs"
      }
      else {
        tagsText?.text = String(article.reblogs_count) + " reblogs  " + String(article.favourites_count) + " favs"
      }
      return cell
    }
    
    // created_at（例: 2020-11-27T03:04:05.000Z, UTC）を「◯時間前」形式にする。解析できなければ空文字
    func daysAgo(_ data: String) -> String {
      return DateParser.iso8601(data)?.timeAgo() ?? ""
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
      sqliteSavedPage = PageStore.shared.page(for: tag + app)
      
      popUp()
    }
    
    private func popUp() {
      let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

      let drikinMazzoAction = UIAlertAction(title: "drikin/mazzo", style: .default,
        handler:{ [weak self] _ in
          guard let self = self else { return }
          self.reload(tag: self.tag == self.tagDrikin ? self.tagMazzo : self.tagDrikin)
        })
      alertController.addAction(drikinMazzoAction)

      let guruJpAction = UIAlertAction(title: "mstdn.jp/mstdn.guru", style: .default,
        handler:{ [weak self] _ in
          guard let self = self else { return }
          self.reload(tag: self.tag == self.tagJp ? self.tagGuru : self.tagJp)
        })
      alertController.addAction(guruJpAction)

      let pawooAction = UIAlertAction(title: "Pawoo", style: .default,
        handler:{ [weak self] _ in
          guard let self = self else { return }
          self.reload(tag: self.tagPawoo)
        })
      alertController.addAction(pawooAction)

      let pawooAiIlust = UIAlertAction(title: "Pawoo #ai", style: .default,
        handler:{ [weak self] _ in
          guard let self = self else { return }
          self.reload(tag: self.tagPawooAiIlust)
        })
      alertController.addAction(pawooAiIlust)

      let socialCloudAction = UIAlertAction(title: "mstdn.social/mastodon.cloud", style: .default,
        handler:{ [weak self] _ in
          guard let self = self else { return }
          self.reload(tag: self.tag == self.tagSocial ? self.tagCloud : self.tagSocial)
        })
      alertController.addAction(socialCloudAction)

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
    // max_id で古い投稿を順に読み込む方式のため、前のページには戻れない。先頭から読み込み直す
    @IBAction func prev(_ sender: Any) {
      reload(tag: tag)
    }
    
    // セルをタップした時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      guard indexPath.row < articles.count,
            let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as? WebViewController else {
        return
      }
      let article = articles[indexPath.row]
      webView.url = article.url ?? article.uri
      
      if let reblog = article.reblog {
        webView.url = reblog.url ?? reblog.uri
      }
      
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
