//
//  StackOverflowViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit

struct StackOverflowArticlesStruct: Codable {
  var items: [ItemsStruct]
  
  struct ItemsStruct: Codable {
    var answer_count: Int
    var title: String
    var creation_date: Int
    var owner: OwnerStruct?
    var view_count: Int
    var tags: [String]
    var link: String

    struct OwnerStruct: Codable {
      var  profile_image: String?
      var user_type: String?
    }
  }
}

class StackOverflowViewController: PagedListViewController {
  var items: [StackOverflowArticlesStruct.ItemsStruct] = []

  let app = "StackOverflow"

  let tagSwift    = "swift"
  let tagFirebase = "firebase"
  let tagFlutter  = "flutter"

  override var initialTag: String { return tagSwift }
  override var pageStoreKey: String? { return tag + app }

  override func menuItems() -> [ListMenuItem] {
    return [
      .cycle("Swift/Firebase/Flutter", [tagSwift, tagFirebase, tagFlutter]),
      .fixed("Swift page1/20posts", tag: tagSwift, page: 1),
      .fixed("Swift page50/20posts", tag: tagSwift, page: 50),
      .fixed("Flutter page1/20posts", tag: tagFlutter, page: 1),
    ]
  }

  override var itemCount: Int { return items.count }

  override func removeAllItems() {
    items.removeAll()
  }

  override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
    var components = URLComponents(string: "https://api.stackexchange.com/2.2/questions")
    components?.queryItems = [URLQueryItem(name: "page", value: String(page)),
                              URLQueryItem(name: "order", value: "desc"),
                              URLQueryItem(name: "sort", value: "activity"),
                              URLQueryItem(name: "tagged", value: tag),
                              URLQueryItem(name: "site", value: "ja.stackoverflow")]
    fetchJSON(StackOverflowArticlesStruct.self, from: components?.url) { result in
      guard let items = result?.items else {
        completion(nil)
        return
      }
      completion { [weak self] in
        self?.items += items
      }
    }
  }

  override func configure(_ cell: UITableViewCell, row: Int) {
    let item = items[row]
    // タイトル（HTMLエスケープを戻す）
    (cell.viewWithTag(2) as? UILabel)?.text = item.title.htmlToPlainText
    // 作成日
    (cell.viewWithTag(3) as? UILabel)?.text = Date(timeIntervalSince1970: Double(item.creation_date)).timeAgo()
    // プロフィール画像（退会済みユーザーや画像なしの場合は再利用セルの古い画像を消す）
    var profileImageUrl: URL?
    if let owner = item.owner, owner.user_type != "does_not_exist", let urlString = owner.profile_image {
      profileImageUrl = URL(string: urlString)
    }
    (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: profileImageUrl, defaultUIImage: nil)
    // 回答数・PV数とタグ（最大5つ）
    var text = "回答数 " + String(item.answer_count) + " / PV数 " + String(item.view_count)
    if !item.tags.isEmpty {
      text += " / " + item.tags.prefix(5).joined(separator: ",")
    }
    (cell.viewWithTag(4) as? UILabel)?.text = text
  }

  override func url(forRow row: Int) -> String? {
    return items[row].link
  }
}

class DateUtils {
  class func dateFromString(string: String, format: String) -> Date {
    let formatter: DateFormatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = format
    return formatter.date(from: string)!
  }
  
  class func stringFromDate(date: Date, format: String) -> String {
    let formatter: DateFormatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.dateFormat = format
    return formatter.string(from: date)
  }
}
