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
  
  class MastodonViewController: PagedListViewController {
    var articles: [MastodonArticleStruct] = []  // Codable

    // max_id で古い投稿を順に読み込む（次に読み込む投稿の起点）
    var maxId = ""

    let tagDrikin       = "drikin"
    let tagMazzo        = "mazzo"
    let tagJp           = "mstdn.jp"
    let tagGuru         = "mstdn.guru"
    let tagQiita        = "qiitadon"
    let tagPawoo        = "pawoo"
    let tagPawooAiIlust = "pawoo #ai"
    let tagSocial       = "mstdn.social"
    let tagCloud        = "mastodon.cloud"

    override var initialTag: String { return tagJp }
    override var rowHeight: CGFloat { return 110 }
    override var canLoadMore: Bool { return savedPage < 100 }

    override func menuItems() -> [ListMenuItem] {
      return [
        .cycle("drikin/mazzo", [tagDrikin, tagMazzo]),
        .cycle("mstdn.jp/mstdn.guru", [tagJp, tagGuru]),
        .fixed("Pawoo", tag: tagPawoo),
        .fixed("Pawoo #ai", tag: tagPawooAiIlust),
        .cycle("mstdn.social/mastodon.cloud", [tagSocial, tagCloud]),
      ]
    }

    override var itemCount: Int { return articles.count }

    override func removeAllItems() {
      articles.removeAll()
    }

    override func resetPaging() {
      maxId = ""
    }

    // タグ（サーバー・アカウント）ごとのタイムラインのURL
    private func timelineUrlString(tag: String) -> String {
      let limit = "limit=" + String(perPage)
      switch tag {
      case tagJp:
        return "https://mstdn.jp/api/v1/timelines/public?local=true&" + limit
      case tagDrikin:
        return "https://mstdn.guru/api/v1/accounts/1/statuses?" + limit  // drikin
      case tagMazzo:
        return "https://mstdn.guru/api/v1/accounts/2/statuses?" + limit  // mazzo
      case tagGuru:
        return "https://mstdn.guru/api/v1/timelines/public?local=true&" + limit
      case tagQiita:
        return "https://qiitadon.com/api/v1/timelines/public?local=true&" + limit  // qiitadon
      case tagPawoo:
        return "https://pawoo.net/api/v1/timelines/public?local=true&" + limit  // pawoo
      case tagPawooAiIlust:
        return "https://pawoo.net/api/v1/timelines/tag/ai?limit=10"  // pawoo #AIイラスト
      case tagCloud:
        return "https://mastodon.cloud/api/v1/timelines/public?local=true&" + limit
      default:
        return "https://mstdn.social/api/v1/timelines/public?local=true&" + limit
      }
    }

    override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
      var urlString = timelineUrlString(tag: tag)
      if !maxId.isEmpty {
        urlString += "&max_id=" + maxId
      }
      fetchJSON([MastodonArticleStruct].self, from: URL(string: urlString)) { articles in
        guard let articles = articles else {
          completion(nil)
          return
        }
        completion { [weak self] in
          guard let self = self else { return }
          if let lastArticle = articles.last {
            self.maxId = lastArticle.id
          }
          self.articles += articles
        }
      }
    }

    override func loadDidFail() {
      textPage.text = tag + " load error"
    }

    override func configure(_ cell: UITableViewCell, row: Int) {
      let article = articles[row]
      // ブーストの場合は元の投稿の本文・ユーザーを表示する
      let isBoosted = article.reblog != nil && article.in_reply_to_account_id == nil
      // 本文
      let content = (article.reblog?.content ?? article.content).htmlToPlainText
      let textTitle = cell.viewWithTag(2) as? UILabel
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
      // プロフィール画像
      (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: URL(string: account.avatar), defaultUIImage: nil)
      // ユーザー名・作成日（created_at は UTC の ISO8601）
      (cell.viewWithTag(3) as? UILabel)?.text = account.display_name + " " + (DateParser.iso8601(article.created_at)?.timeAgo() ?? "")
      // 返信・ブースト・お気に入り数
      var counts = String(article.reblogs_count) + " reblogs  " + String(article.favourites_count) + " favs"
      if let repliesCount = article.replies_count {
        counts = String(repliesCount) + " replies  " + counts
      }
      (cell.viewWithTag(4) as? UILabel)?.text = counts
    }

    override func url(forRow row: Int) -> String? {
      let article = articles[row]
      if let reblog = article.reblog {
        return reblog.url ?? reblog.uri
      }
      return article.url ?? article.uri
    }

    // max_id で古い投稿を順に読み込む方式のため、前のページには戻れない。先頭から読み込み直す
    override func prev(_ sender: Any) {
      reload(tag: tag, page: 1)
    }
  }
