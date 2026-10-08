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

class NoteViewController: PagedListViewController {
    var notes: [NoteArticlesStruct.DataStruct.NotesStruct] = []
    
    let tagSwift    = "swift"
    let tagFlutter  = "flutter"
    
    override var initialTag: String { return "tech" }
    override var pageStoreKey: String? { return tag }
    
    override func menuItems() -> [ListMenuItem] {
        return [
            .cycle("Flutter/Swift", [tagSwift, tagFlutter]),
            .fixed("Swift page1/20posts", tag: tagSwift, page: 1),
            .fixed("Swift page50/20posts", tag: tagSwift, page: 50),
            .fixed("Flutter page1/20posts", tag: tagFlutter, page: 1),
        ]
    }
    
    override var itemCount: Int { return notes.count }
    
    override func removeAllItems() {
        notes.removeAll()
    }
    
    // TODO: タグを切り替えても常に tech カテゴリを読み込んでいる（タグ別の API が未調査）
    override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
        let url = URL(string: "https://note.com/api/v1/categories/tech?note_intro_only=true&sort=new&page=\(page)")
        fetchJSON(NoteArticlesStruct.self, from: url) { result in
            guard let notes = result?.data.notes else {
                completion(nil)
                return
            }
            completion { [weak self] in
                self?.notes += notes
            }
        }
    }
    
    override func configure(_ cell: UITableViewCell, row: Int) {
        let note = notes[row]
        // タイトル（name → tweet_text → "タイトルなし" の順に使う）
        (cell.viewWithTag(2) as? UILabel)?.text = note.name ?? note.tweet_text ?? "タイトルなし"
        // 作成日（publish_at 例: 2020-04-12T15:00:00+09:00）
        (cell.viewWithTag(3) as? UILabel)?.text = DateParser.iso8601(note.publish_at ?? "")?.timeAgo() ?? ""
        // プロフィール画像（画像がなければ再利用セルの古い画像を消す）
        let profileImageUrl = note.user.user_profile_image_path.flatMap { URL(string: $0) }
        (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: profileImageUrl, defaultUIImage: nil)
        // ハッシュタグ（最大5つ）
        let tagNames = note.hashtag_notes.prefix(5).map { $0.hashtag.name ?? "" }.filter { !$0.isEmpty }
        (cell.viewWithTag(4) as? UILabel)?.text = tagNames.joined(separator: " ")
    }
    
    // twitter_share_url（https://twitter.com/intent/tweet?url=記事URL&...）から記事のURLを取り出す
    override func url(forRow row: Int) -> String? {
        guard let urlString = notes[row].twitter_share_url else { return nil }
        let newStr = urlString.replacingOccurrences(of: "https://twitter.com/intent/tweet?url=", with: "")
        return newStr.components(separatedBy: "&").first
    }
}
