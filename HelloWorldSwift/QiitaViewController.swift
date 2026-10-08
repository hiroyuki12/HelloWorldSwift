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

class QiitaViewController: PagedListViewController {
  var articles: [QiitaArticleStruct] = []  // Codable

  let app = "qiita"

  let tagSwift         = "Swift"
  let tagReact         = "React"
  let tagCodex         = "Codex"
  let tagClaudeCode    = "ClaudeCode"
  let tagGemini        = "Gemini"
  let tagGitHubCopilot = "GitHubCopilot"

  override var initialTag: String { return tagClaudeCode }
  override var pageStoreKey: String? { return tag + app }
  // Qiita API は100ページまで
  override var canLoadMore: Bool { return savedPage < 100 }

  override func menuItems() -> [ListMenuItem] {
    return [
      .fixed("ClaudeCode", tag: tagClaudeCode),
      .fixed("Codex", tag: tagCodex),
      .fixed("Gemini", tag: tagGemini),
      .fixed("GitHubCopilot", tag: tagGitHubCopilot),
      .fixed("Swift", tag: tagSwift),
      .fixed("React", tag: tagReact),
    ]
  }

  override var itemCount: Int { return articles.count }

  override func removeAllItems() {
    articles.removeAll()
  }

  override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
    let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
    let url = URL(string: "https://qiita.com/api/v2/tags/\(encodedTag)/items?page=\(page)&per_page=\(perPage)")
    fetchJSON([QiitaArticleStruct].self, from: url) { articles in
      guard let articles = articles else {
        completion(nil)
        return
      }
      completion { [weak self] in
        self?.articles += articles
      }
    }
  }

  override func configure(_ cell: UITableViewCell, row: Int) {
    let article = articles[row]
    // タイトル
    (cell.viewWithTag(2) as? UILabel)?.text = article.title
    // 作成日
    (cell.viewWithTag(3) as? UILabel)?.text = daysAgo(article.created_at)
    // プロフィール画像
    (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: URL(string: article.user.profile_image_url), defaultUIImage: nil)
    // タグ（最大5つ）
    (cell.viewWithTag(4) as? UILabel)?.text = article.tags.prefix(5).map { $0.name }.joined(separator: ", ")
  }

  override func url(forRow row: Int) -> String? {
    return articles[row].url
  }

  func daysAgo(_ data: String) -> String {
    guard let date = DateParser.iso8601(data) ?? DateParser.localDateTime(data) else {
      return ""
    }
    return date.timeAgo()
  }
}
