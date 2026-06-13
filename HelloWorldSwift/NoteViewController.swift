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
import SQLite3

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
    
    var db: OpaquePointer?
    var isLoading = false
    var notes: [NoteArticlesStruct.DataStruct.NotesStruct] = []
    
    var sqliteSavedPage = 0
    var sqlliteSavedPerPage = 0
    
    var tag = "tech"
    let tagSwift    = "swift"
    let tagFlutter  = "flutter"
    
    var savedPage = 1
    var perPage = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.rowHeight = 70
        
        myload(page: 1, perPage: perPage, tag: tag)
        
        // SQLite 初期化
        let fileUrl = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("HeroDatabase.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            return
        }
        
        let createTableQuery = "CREATE TABLE IF NOT EXISTS Heroes (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, powerrank INTEGER)"
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            return
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        isModalInPresentation = true
    }
    
    func myload(page: Int, perPage: Int, tag: String) {
        let urlString = "https://note.com/api/v1/categories/tech?note_intro_only=true&sort=new&page=\(page)"
        guard let url = URL(string: urlString) else { return }
        
        // [weak self] で循環参照を防ぐ
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data else { return }
            
            do {
                let noteArticles = try JSONDecoder().decode(NoteArticlesStruct.self, from: data)
                
                let currentNotes = self.notes
                self.notes = currentNotes + noteArticles.data.notes
                
                DispatchQueue.main.async {
                    self.table.reloadData()
                    self.isLoading = false
                }
            } catch {
                print("JSON Decode Error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
        task.resume()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
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
        
        // プロフィール画像
        if let profileImage = cell.viewWithTag(1) as? UIImageView {
            if let profileImageUrl = note.user.user_profile_image_path,
               let myUrl = URL(string: profileImageUrl) {
                profileImage.loadImageAsynchronously(url: myUrl, defaultUIImage: nil)
            } else {
                profileImage.image = nil
            }
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
            isLoading = true
            savedPage += 1
            myload(page: savedPage, perPage: 20, tag: tag)
            
            updatePageLabel()
        }
    }
    
    // MARK: - 日付変換ユーティリティ
    
    func daysAgo(_ data: String) -> String {
        // ISO8601などのフォーマットに合わせてDateFormatterで解析
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // APIの返却形式が "2020-04-12 15:00:00" の場合は "yyyy-MM-dd HH:mm:ss" に変更してください
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: data) else {
            // フォーマット解析に失敗した場合は、古いロジックのフォールバックか空文字を返す
            return ""
        }
        
        // Dateの拡張メソッド（timeAgo）を呼び出し
        return date.timeAgo()
    }
    
    // MARK: - Actions
    
    @IBAction func load(_ sender: Any) {
        self.table.reloadData()
    }
    
    @IBAction func next(_ sender: Any) {
        tapRead(self.savedPage, self.tag)
        popUp()
    }
    
    @IBAction func tapSave(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapLoad(_ sender: Any) {
    }
    
    @IBAction func prev(_ sender: Any) {
        if savedPage > 1 {
            savedPage -= 1
            myload(page: savedPage, perPage: 20, tag: tag)
            textPage.text = "swift Page \(savedPage)/20posts/\((savedPage - 1) * 20 + 1)〜"
        }
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
            self.notes.removeAll()
            self.tag = (self.tag == self.tagSwift) ? self.tagFlutter : self.tagSwift
            self.savedPage = 1
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.updatePageLabel()
        }
        alertController.addAction(flutterSwiftAction)
        
        let swiftPage1Action = UIAlertAction(title: "Swift page1/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.notes.removeAll()
            self.tag = self.tagSwift
            self.savedPage = 1
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.updatePageLabel()
        }
        alertController.addAction(swiftPage1Action)
        
        let swiftPage50Action = UIAlertAction(title: "Swift page50/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.notes.removeAll()
            self.tag = self.tagSwift
            self.savedPage = 50
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.updatePageLabel()
        }
        alertController.addAction(swiftPage50Action)
        
        let flutterPage1Action = UIAlertAction(title: "Flutter page1/20posts", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.notes.removeAll()
            self.tag = self.tagFlutter
            self.savedPage = 1
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.updatePageLabel()
        }
        alertController.addAction(flutterPage1Action)
        
        let saveSwiftPageAction = UIAlertAction(title: "Save \(self.tag) Page ! \(self.savedPage)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.tapDelete(self.savedPage, self.tag)
            self.tapSave(self.savedPage, self.tag)
            self.sqliteSavedPage = self.savedPage
        }
        alertController.addAction(saveSwiftPageAction)
        
        let loadSwiftPageAction = UIAlertAction(title: "Load \(self.tag) Page ! \(self.sqliteSavedPage)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.notes.removeAll()
            self.savedPage = self.sqliteSavedPage
            self.myload(page: self.savedPage, perPage: 20, tag: self.tag)
            self.updatePageLabel()
        }
        alertController.addAction(loadSwiftPageAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - SQLite Operations (安全なバインド処理への修正)
    
    func tapDelete(_ page: Int, _ tag: String) {
        var stmt: OpaquePointer?
        let queryString = "DELETE FROM Heroes WHERE name = ?"
        
        if sqlite3_prepare_v2(db, queryString, -1, &stmt, nil) == SQLITE_OK {
            // SQLインジェクションを防ぐため、値を安全にバインド
            sqlite3_bind_text(stmt, 1, (tag as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error deleting row")
            }
        }
        sqlite3_finalize(stmt)
    }
    
    func tapSave(_ page: Int, _ tag: String) {
        var stmt: OpaquePointer?
        let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (?, ?)"
        
        if sqlite3_prepare_v2(db, queryString, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (tag as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(page))
            
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Error inserting row")
            }
        }
        sqlite3_finalize(stmt)
    }
    
    func tapRead(_ page: Int, _ tag: String) {
        sqliteSavedPage = 0
        var stmt: OpaquePointer?
        let queryString = "SELECT powerrank FROM Heroes WHERE name = ?"
        
        if sqlite3_prepare_v2(db, queryString, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (tag as NSString).utf8String, -1, nil)
            
            if sqlite3_step(stmt) == SQLITE_ROW {
                let powerrank = sqlite3_column_int(stmt, 0)
                sqliteSavedPage = Int(powerrank)
            }
        }
        sqlite3_finalize(stmt)
    }
}
