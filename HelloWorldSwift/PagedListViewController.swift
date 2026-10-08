//
//  PagedListViewController.swift
//  HelloWorldSwift
//
//  記事一覧画面（Qiita / teratail / Stack Overflow / Mastodon / note / はてなブックマーク）の共通処理。
//  ページ送り・無限スクロール・メニュー・保存ページ・キー操作・記事を開く処理をまとめ、
//  各画面は「何を読み込み、セルに何を表示し、どのURLを開くか」だけを実装する。
//

import UIKit

// メニューの1項目。tag は現在のタグを受け取り、切り替え先のタグを返す
struct ListMenuItem {
  let title: String
  let tag: (String) -> String
  let page: Int

  // 指定したタグ・ページを表示する
  static func fixed(_ title: String, tag: String, page: Int = 1) -> ListMenuItem {
    return ListMenuItem(title: title, tag: { _ in tag }, page: page)
  }

  // tags を順番に切り替える（現在のタグが tags に無ければ先頭に戻る）
  static func cycle(_ title: String, _ tags: [String]) -> ListMenuItem {
    return ListMenuItem(title: title, tag: { current in
      guard let index = tags.firstIndex(of: current) else { return tags[0] }
      return tags[(index + 1) % tags.count]
    }, page: 1)
  }
}

class PagedListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!

  var isLoading = false
  // 読み込み中にタグやページを切り替えた場合に、古いリクエストの結果を捨てるための番号
  private var loadGeneration = 0

  var tag = ""
  var savedPage = 1
  var perPage = 20
  var sqliteSavedPage = 0

  // MARK: - 各画面で上書きする

  // 最初に表示するタグ
  var initialTag: String { return "" }

  // セルの高さ
  var rowHeight: CGFloat { return 70 }

  // 保存ページのキー。nil ならメニューに Save / Load を出さない
  var pageStoreKey: String? { return nil }

  // スクロールで次のページを読み込めるか
  var canLoadMore: Bool { return true }

  // メニューに並べる項目（Save / Load / Cancel は共通で追加される）
  func menuItems() -> [ListMenuItem] { return [] }

  // 表示中の件数
  var itemCount: Int { return 0 }

  // 表示中の項目をすべて消す
  func removeAllItems() {}

  // タグやページを切り替えて読み込み直すときに、ページ送り用の状態を初期化する
  func resetPaging() {}

  // 指定ページを取得する。completion はどのスレッドから呼んでもよい。
  // 成功時は一覧に結果を追加する処理を、失敗時は nil を渡す（追加処理はメインスレッドで実行される）
  func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
    completion(nil)
  }

  // 読み込みに失敗したとき（メインスレッド）
  func loadDidFail() {}

  // セルに row 行目の内容を表示する
  func configure(_ cell: UITableViewCell, row: Int) {}

  // row 行目をタップしたときに開くURL
  func url(forRow row: Int) -> String? { return nil }

  // MARK: - 共通処理

  override func viewDidLoad() {
    super.viewDidLoad()

    // セルの高さを設定
    table.rowHeight = rowHeight

    tag = initialTag
    loadPage()
    updatePageLabel()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    isModalInPresentation = true  // 下にスワイプで閉じなくする
  }

  // 現在の tag / savedPage を読み込み、一覧の末尾に追加する
  func loadPage() {
    isLoading = true
    let generation = loadGeneration
    fetchPage(savedPage, tag: tag) { [weak self] append in
      DispatchQueue.main.async {
        guard let self = self, generation == self.loadGeneration else { return }
        if let append = append {
          append()
          self.table.reloadData()
        } else {
          self.loadDidFail()
        }
        // 失敗時も解除しないと、以降スクロールで次のページを読み込めなくなる
        self.isLoading = false
      }
    }
  }

  // 一覧を空にして、指定したタグ・ページを読み込み直す
  func reload(tag: String, page: Int) {
    loadGeneration += 1
    removeAllItems()
    table.reloadData()
    self.tag = tag
    savedPage = page
    resetPaging()
    loadPage()
    updatePageLabel()
  }

  func updatePageLabel() {
    textPage.text = "\(tag) Page \(savedPage)/20posts/\((savedPage - 1) * 20 + 1)〜"
  }

  // JSON を取得して T にデコードする。失敗時は nil
  func fetchJSON<T: Decodable>(_ type: T.Type, from url: URL?, completion: @escaping (T?) -> Void) {
    guard let url = url else {
      completion(nil)
      return
    }
    URLSession.shared.dataTask(with: url) { data, response, error in
      var decoded: T?
      if let data = data {
        do {
          decoded = try JSONDecoder().decode(T.self, from: data)
        } catch {
          print("JSON Decode Error: \(error)")
        }
      }
      completion(decoded)
    }.resume()
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return itemCount
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    if indexPath.row < itemCount {
      configure(cell, row: indexPath.row)
    }
    return cell
  }

  // MARK: - UITableViewDelegate

  // セルをタップしたら記事を開く
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard indexPath.row < itemCount,
          let urlString = url(forRow: indexPath.row),
          let webView = storyboard?.instantiateViewController(withIdentifier: "MyWebView") as? WebViewController else {
      return
    }
    webView.url = urlString
    present(webView, animated: true, completion: nil)
  }

  // 一番下までスクロールしたら次のページを読み込む
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if table.contentSize.height > 0
        && table.contentOffset.y + table.frame.size.height > table.contentSize.height
        && table.isDragging && !isLoading && canLoadMore {
      savedPage += 1
      loadPage()
      updatePageLabel()
    }
  }

  // MARK: - Actions

  // Menuボタンタップ時 / mキー押下時
  @IBAction func next(_ sender: Any) {
    if let key = pageStoreKey {
      sqliteSavedPage = PageStore.shared.page(for: key)
    }
    popUp()
  }

  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    table.reloadData()
  }

  // Loadボタンタップ時
  @IBAction func tapLoad(_ sender: Any) {
  }

  // Prevボタン押下
  @IBAction func prev(_ sender: Any) {
    guard savedPage > 1 else { return }
    reload(tag: tag, page: savedPage - 1)
  }

  // Closeボタンタップ時 / qキー押下時
  @IBAction func tapClose(_ sender: Any) {
    dismiss(animated: true, completion: nil)
  }

  // Storyboard互換用（Closeボタンは tapSave: に接続されている）
  @IBAction func tapSave(_ sender: Any) {
    tapClose(sender)
  }

  private func popUp() {
    let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)

    for item in menuItems() {
      alertController.addAction(UIAlertAction(title: item.title, style: .default) { [weak self] _ in
        guard let self = self else { return }
        self.reload(tag: item.tag(self.tag), page: item.page)
      })
    }

    if pageStoreKey != nil {
      alertController.addAction(UIAlertAction(title: "Save \(tag) Page ! \(savedPage)", style: .default) { [weak self] _ in
        guard let self = self, let key = self.pageStoreKey else { return }
        PageStore.shared.save(page: self.savedPage, for: key)
        self.sqliteSavedPage = self.savedPage
      })
      alertController.addAction(UIAlertAction(title: "Load \(tag) Page ! \(sqliteSavedPage)", style: .default) { [weak self] _ in
        guard let self = self, self.sqliteSavedPage > 0 else { return }
        self.reload(tag: self.tag, page: self.sqliteSavedPage)
      })
    }

    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

    // iPad/Macで表示した場合に備えて、ポップオーバーの表示位置を指定する
    if let popover = alertController.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }

    present(alertController, animated: true, completion: nil)
  }

  // MARK: - キー操作

  // qキーで画面を閉じる、mキーでメニューを表示する
  override var keyCommands: [UIKeyCommand]? {
    let closeCommand = UIKeyCommand(input: "q", modifierFlags: [], action: #selector(tapClose(_:)))
    closeCommand.wantsPriorityOverSystemBehavior = true
    let menuCommand = UIKeyCommand(input: "m", modifierFlags: [], action: #selector(next(_:)))
    menuCommand.wantsPriorityOverSystemBehavior = true
    return [closeCommand, menuCommand]
  }

  // キー入力を受け取るためにファーストレスポンダーになる
  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    becomeFirstResponder()
  }
}
