//
//  HatenaBookmarkFavoriteViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/15.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit

class HatenaBookmarkFavoriteViewController: PagedListViewController {
  // お気に入りのRSSはユーザー固有のURLのため未設定（設定されるまで Fav は空表示）
  let feedUrlFavorite: URL? = nil
  let feedUrlHotentry = URL(string: "https://b.hatena.ne.jp/hotentry.rss")
  let feedUrlIT = URL(string: "https://b.hatena.ne.jp/hotentry/it.rss")

  var feedItems = [FeedItem]()

  let tagFav      = "Fav"
  let tagSwift    = "Swift"
  let tagHotentry = "Hotentry"
  let tagIT       = "IT"

  override var initialTag: String { return tagFav }
  // 以前のバージョンで保存したページも読めるよう、従来の name = 1 を使う
  override var pageStoreKey: String? { return "1" }
  // ページ送りできるのはタグ検索（Swift）だけ。他の RSS は1ページのみ
  override var canLoadMore: Bool { return tag == tagSwift }

  override func menuItems() -> [ListMenuItem] {
    return [
      .cycle("Fav/Swift/Hotentry/IT", [tagFav, tagSwift, tagHotentry, tagIT]),
      .fixed("Swift page1/20posts", tag: tagSwift, page: 1),
      .fixed("Swift page50/20posts", tag: tagSwift, page: 50),
      .fixed("Hotentry", tag: tagHotentry, page: 1),
    ]
  }

  override var itemCount: Int { return feedItems.count }

  override func removeAllItems() {
    feedItems.removeAll()
  }

  // tag / page に対応する RSS のURL
  private func feedUrl(tag: String, page: Int) -> URL? {
    switch tag {
    case tagSwift:
      return URL(string: "https://b.hatena.ne.jp/search/tag?q=swift&users=1&mode=rss&page=" + String(page))
    case tagHotentry:
      return feedUrlHotentry
    case tagIT:
      return feedUrlIT
    default:
      return feedUrlFavorite
    }
  }

  override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
    guard let url = feedUrl(tag: tag, page: page) else {
      completion(nil)
      return
    }
    URLSession.shared.dataTask(with: url) { data, response, error in
      guard let data = data else {
        completion(nil)
        return
      }
      let items = RSSParser.parse(data)
      completion { [weak self] in
        self?.feedItems += items
      }
    }.resume()
  }

  override func loadDidFail() {
    if feedUrl(tag: tag, page: savedPage) == nil {
      textPage.text = tag + " (URL未設定)"
    }
  }

  override func configure(_ cell: UITableViewCell, row: Int) {
    let feedItem = feedItems[row]
    // タイトル
    (cell.viewWithTag(2) as? UILabel)?.text = feedItem.title
    // ブックマーク数
    (cell.viewWithTag(3) as? UILabel)?.text = feedItem.bookmarkcount + " users"
    // 画像（Fav はブックマークしたユーザーのアイコン、Hotentry / IT は記事の画像）
    var imageUrl: URL?
    if let creator = feedItem.creator {
      imageUrl = URL(string: "https://cdn.profile-image.st-hatena.com/users/" + creator + "/profile.gif")
    }
    if let imageurl = feedItem.imageurl {
      imageUrl = URL(string: imageurl)
    }
    (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: imageUrl, defaultUIImage: nil)
    // ブックマークしたユーザーと日時（dc:date 例: 2020-10-15T12:34:56+09:00）
    let ago = DateParser.iso8601(feedItem.date ?? "")?.timeAgo() ?? ""
    if let creator = feedItem.creator {
      (cell.viewWithTag(4) as? UILabel)?.text = creator + " " + ago
    }
    else {
      (cell.viewWithTag(4) as? UILabel)?.text = ago
    }
  }

  override func url(forRow row: Int) -> String? {
    let url = feedItems[row].url
    return url.hasPrefix("http") ? url : nil
  }
}
