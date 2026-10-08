//
//  NoteViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit

struct NoteArticlesStruct: Codable {
    var data: DataStruct
    
    struct DataStruct: Codable {
        var notes: [NotesStruct]
        
        struct NotesStruct: Codable {
            var id: Int?
            var name: String?       // ★ これが本来のタイトル（今回のJSONの "name" に対応）
            var tweet_text: String? // 今回 null が返ってきている項目
            var publish_at: String?
            var user: UserStruct
            var hashtag_notes: [HashTagNotesStruct]
            var twitter_share_url: String?
            var like_count: Int?
            
            struct UserStruct: Codable {
                var user_profile_image_path: String?
            }
            
            struct HashTagNotesStruct: Codable {
                var hashtag: HashTagStruct
                
                struct HashTagStruct: Codable {
                    var name: String?
                }
            }
        }
    }
}

class NoteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var textPage: UILabel!
    @IBOutlet weak var myImage: UIImageView!
    
    var isLoading = false
    // 読み込み中にタグやページを切り替えた場合に、古いリクエストの結果を捨てるための番号
    private var loadGeneration = 0
    var notes: [NoteArticlesStruct.DataStruct.NotesStruct] = []
    
    var sqliteSavedPage = 0
    
    var tag = "tech"
    let tagSwift    = "swift"
    let tagFlutter  = "flutter"
    
    var savedPage = 1
    var perPage = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.rowHeight = 70
        
        myload(page: 1, perPage: perPage, tag: tag)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        isModalInPresentation = true
    }
    
    func myload(page: Int, perPage: Int, tag: String) {
        let urlString = "https://note.com/api/v1/categories/tech?note_intro_only=true&sort=new&page=\(page)"
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        let generation = loadGeneration
        // [weak self] で循環参照を防ぐ
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            // デコードはバックグラウンドで行い、配列の更新はメインスレッドで行う（データ競合防止）
            var newNotes: [NoteArticlesStruct.DataStruct.NotesStruct]?
            if let data = data {
                do {
                    newNotes = try JSONDecoder().decode(NoteArticlesStruct.self, from: data).data.notes
                } catch {
                    print("JSON Decode Error: \(error)")
                }
            }
            DispatchQueue.main.async {
                guard let self = self, generation == self.loadGeneration else { return }
                if let newNotes = newNotes {
                    self.notes += newNotes
                    self.table.reloadData()
                }
                self.isLoading = false
            }
        }
        task.resume()
    }
    
    // 一覧を空にして、指定したタグ・ページを読み込み直す
    private func reload(tag: String, page: Int) {
        loadGeneration += 1
        notes.removeAll()
        table.reloadData()
        self.tag = tag
        savedPage = page
        myload(page: savedPage, perPage: 20, tag: self.tag)
        updatePageLabel()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard indexPath.row < notes.count else { return cell }
        let note = notes[indexPath.row]
        
        // タイトルの表示（最優先を note.name に変更）
        if let textTitle = cell.viewWithTag(2) as? UILabel {
            // 1. name（記事タイトル）があれば使う
            // 2. なければ tweet_text を使う
            // 3. どちらもなければ "タイトルなし"
            textTitle.text = note.name ?? note.tweet_text ?? "タイトルなし"
        }
        
        // 作成日
        if let textDetailText = cell.viewWithTag(3) as? UILabel {
            textDetailText.text = daysAgo(note.publish_at ?? "")
        }
        
        // プロフィール画像（画像がなければ再利用セルの古い画像を消す）
        if let profileImage = cell.viewWithTag(1) as? UIImageView {
            let profileImageUrl = note.user.user_profile_image_path.flatMap { URL(string: $0) }
            profileImage.loadImageAsynchronously(url: profileImageUrl, defaultUIImage: nil)
        }
        
        // タグ
        if let hasTagText = cell.viewWithTag(4) as? UILabel {
            let tagNames = note.hashtag_notes.prefix(5).map { $0.hashtag.name ?? "" }.filter { !$0.isEmpty }
            hasTagText.text = tagNames.joined(separator: " ")
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < notes.count else { return }
        
        let note = notes[indexPath.row]
        
        // twitter_share_url が nil だった場合は処理をスキップする
        guard let urlString = note.twitter_share_url else { return }
        
        let newStr = urlString.replacingOccurrences(of: "https://twitter.com/intent/tweet?url=", with: "")
        let array1 = newStr.components(separatedBy: "&")
        
        guard let firstUrl = array1.first else { return }
        
        if let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as? WebViewController {
            webView.url = firstUrl
            self.present(webView, animated: true, completion: nil)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        if maximumOffset - currentOffset <= 0 && scrollView.isDragging && !isLoading {
            savedPage += 1
            myload(page: savedPage, perPage: 20, tag: tag)
            
            updatePageLabel()
        }
    }
    
    // MARK: - 日付変換ユーティリティ
    
    // publish_at（例: 2020-04-12T15:00:00+09:00）を「◯時間前」形式にする。解析できなければ空文字
    func daysAgo(_ data: String) -> String {
        return DateParser.iso8601(data)?.timeAgo() ?? ""
    }
    
    // MARK: - Actions
    
    @IBAction func load(_ sender: Any) {
        self.table.reloadData()
    }
    
    @IBAction func next(_ sender: Any) {
        sqliteSavedPage = PageStore.shared.page(for: tag)
        popUp()
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

    @IBAction func tapSave(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapLoad(_ sender: Any) {
    }
    
    @IBAction func prev(_ sender: Any) {
        guard savedPage > 1 else { return }
        reload(tag: tag, page: savedPage - 1)
    }
    
    // 共通のラベル更新処理
    private func updatePageLabel() {
        textPage.text = "\(tag) Page \(savedPage)/20posts/\((savedPage - 1) * 20 + 1)〜"
    }
    
    // MARK: - PopUp AlertSheet
    
    private func popUp() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        let flutterSwiftAction = UIAlertAction(title: "Flutter/Swift", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.reload(tag: (self.tag == self.tagSwift) ? self.tagFlutter : self.tagSwift, page: 1)
        }
        alertController.addAction(flutterSwiftAction)
        
        let swiftPage1Action = UIAlertAction(title: "Swift page1/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.reload(tag: self.tagSwift, page: 1)
        }
        alertController.addAction(swiftPage1Action)
        
        let swiftPage50Action = UIAlertAction(title: "Swift page50/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.reload(tag: self.tagSwift, page: 50)
        }
        alertController.addAction(swiftPage50Action)
        
        let flutterPage1Action = UIAlertAction(title: "Flutter page1/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.reload(tag: self.tagFlutter, page: 1)
        }
        alertController.addAction(flutterPage1Action)
        
        let saveSwiftPageAction = UIAlertAction(title: "Save \(self.tag) Page ! \(self.savedPage)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            PageStore.shared.save(page: self.savedPage, for: self.tag)
            self.sqliteSavedPage = self.savedPage
        }
        alertController.addAction(saveSwiftPageAction)
        
        let loadSwiftPageAction = UIAlertAction(title: "Load \(self.tag) Page ! \(self.sqliteSavedPage)", style: .default) { [weak self] _ in
            guard let self = self, self.sqliteSavedPage > 0 else { return }
            self.reload(tag: self.tag, page: self.sqliteSavedPage)
        }
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
}
