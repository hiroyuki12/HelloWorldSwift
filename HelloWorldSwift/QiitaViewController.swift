//
//  QiitaViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation

struct QiitaArticleStruct: Codable {
//  var coediting: Bool
//  var comments_count: Int
  var created_at: String
  var id: String
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
  // 表示中の記事の id（ページをまたいだ重複を除くため）
  private var articleIDs = Set<String>()

  override func viewDidLoad() {
    super.viewDidLoad()
    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refreshArticles), for: .valueChanged)
    table.refreshControl = refreshControl
    table.alwaysBounceVertical = true
  }

  @objc private func refreshArticles() {
    reload(tag: tag, page: 1)
  }

  let app = "qiita"

  let tagSwift         = "Swift"
  let tagReact         = "React"
  let tagCodex         = "Codex"
  let tagChatGPT       = "ChatGPT"
  let tagGrokBot       = "GrokBot"
  let tagClaudeCode    = "ClaudeCode"
  let tagGemini        = "Gemini"
  let tagGitHubCopilot = "GitHubCopilot"

  override var initialTag: String { return tagGrokBot }
  override var pageStoreKey: String? { return tag + app }
  // Qiita API は100ページまで
  override var maxPage: Int? { return 100 }

  override func menuItems() -> [ListMenuItem] {
    return [
      .fixed("GrokBot", tag: tagGrokBot),
      .fixed("ClaudeCode", tag: tagClaudeCode),
      .fixed("ChatGPT", tag: tagChatGPT),
      .fixed("Gemini", tag: tagGemini),
      .fixed("GitHubCopilot", tag: tagGitHubCopilot),
      .fixed("Codex", tag: tagCodex),
      .fixed("Swift", tag: tagSwift),
      .fixed("React", tag: tagReact),
    ]
  }

  override var itemCount: Int { return articles.count }

  override func removeAllItems() {
    articles.removeAll()
    articleIDs.removeAll()
  }

  // 取得した1ページ分の記事から、表示済みの記事を除いたものと、それが最後のページだったかを返す。
  // 新着記事が投稿されるとページの境目がずれ、前のページと同じ記事が返ることがあるため重複を除く
  static func merge(page: [QiitaArticleStruct], seenIDs: inout Set<String>,
                    perPage: Int) -> (articles: [QiitaArticleStruct], isLastPage: Bool) {
    let newArticles = page.filter { seenIDs.insert($0.id).inserted }
    // 1ページ分に満たなければ、それ以降のページは無い
    return (newArticles, page.count < perPage)
  }

  override func fetchPageResult(_ page: Int, tag: String, completion: @escaping (Result<() -> Void, ListLoadError>) -> Void) {
    let perPage = self.perPage
    var components = URLComponents(string: "https://qiita.com/api/v2/tags/")
    components?.path += "\(tag)/items"
    components?.queryItems = [
      URLQueryItem(name: "page", value: String(page)),
      URLQueryItem(name: "per_page", value: String(perPage)),
    ]
    fetchJSONResult([QiitaArticleStruct].self, from: components?.url) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let articles):
        completion(.success { [weak self] in
          guard let self = self else { return }
          let result = QiitaViewController.merge(page: articles, seenIDs: &self.articleIDs, perPage: perPage)
          self.articles += result.articles
          if result.isLastPage {
            self.reachedEnd = true
          }
        })
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
    (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: URL(string: article.user.profile_image_url), defaultUIImage: UIImage(systemName: "person.crop.square"))
    // タグ（最大5つ）
    (cell.viewWithTag(4) as? UILabel)?.text = article.tags.prefix(5).map { $0.name }.joined(separator: ", ")
  }

  override func url(forRow row: Int) -> String? {
    return articles[row].url
  }

  override func loadDidFail(_ error: ListLoadError) {
    let message: String
    switch error {
    case .network:
      message = "通信できません。接続を確認してください"
    case .httpStatus(429):
      message = "APIの利用制限に達しました。時間をおいて再試行してください"
    case .httpStatus(let status):
      message = "読み込み失敗（HTTP \(status)）"
    case .decoding:
      message = "記事データを読み取れませんでした"
    case .invalidURL, .invalidResponse, .unknown:
      message = "記事を読み込めませんでした"
    }
    textPage.text = "\(tag) \(message)"
  }

  private func daysAgo(_ data: String) -> String {
    guard let date = DateParser.iso8601(data) ?? DateParser.localDateTime(data) else {
      return ""
    }
    return date.timeAgo()
  }
}
