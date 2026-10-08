//
//  TeratailViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import Foundation
import WebKit

struct TeratailArticlesStruct: Codable {
  var questions: [QuestionsStruct]
  
  struct QuestionsStruct: Codable {
    var id: Int
    var title: String
    var created: String
    var count_reply: Int
    var count_pv: Int
    var tags: [String]
    var user: UserStruct?

    struct UserStruct: Codable {
      var photo: String
//      var score: Int
    }
  }
}

class TeratrailViewController: PagedListViewController {
  var questions: [TeratailArticlesStruct.QuestionsStruct] = []

  let app = "Teratail"

  let tagSwift    = "Swift"
  let tagFirebase = "Firebase"
  let tagFlutter  = "Flutter"
  let tagReact    = "React.js"

  override var initialTag: String { return tagSwift }
  override var pageStoreKey: String? { return tag + app }

  override func menuItems() -> [ListMenuItem] {
    return [
      .cycle("Swift/React.js/Firebase/Flutter", [tagSwift, tagReact, tagFirebase, tagFlutter]),
      .fixed("Swift page1/20posts", tag: tagSwift, page: 1),
      .fixed("Swift page50/20posts", tag: tagSwift, page: 50),
      .fixed("Flutter page1/20posts", tag: tagFlutter, page: 1),
    ]
  }

  override var itemCount: Int { return questions.count }

  override func removeAllItems() {
    questions.removeAll()
  }

  override func fetchPage(_ page: Int, tag: String, completion: @escaping ((() -> Void)?) -> Void) {
    var components = URLComponents(string: "https://teratail.com/api/v1/tags/")
    components?.path += tag + "/questions"
    components?.queryItems = [URLQueryItem(name: "page", value: String(page)),
                              URLQueryItem(name: "limit", value: String(perPage))]
    fetchJSON(TeratailArticlesStruct.self, from: components?.url) { result in
      guard let questions = result?.questions else {
        completion(nil)
        return
      }
      completion { [weak self] in
        self?.questions += questions
      }
    }
  }

  override func configure(_ cell: UITableViewCell, row: Int) {
    let question = questions[row]
    // タイトル
    (cell.viewWithTag(2) as? UILabel)?.text = question.title
    // 作成日
    (cell.viewWithTag(3) as? UILabel)?.text = DateParser.localDateTime(question.created)?.timeAgo() ?? ""
    // プロフィール画像（画像がなければ再利用セルの古い画像を消す）
    (cell.viewWithTag(1) as? UIImageView)?.loadImageAsynchronously(url: question.user.flatMap { URL(string: $0.photo) }, defaultUIImage: nil)
    // 回答数・PV数とタグ（最大5つ）
    var text = "回答数 " + String(question.count_reply) + " / PV数 " + String(question.count_pv)
    if !question.tags.isEmpty {
      text += " / " + question.tags.prefix(5).joined(separator: ",")
    }
    (cell.viewWithTag(4) as? UILabel)?.text = text
  }

  override func url(forRow row: Int) -> String? {
    return "https://teratail.com/questions/" + String(questions[row].id)
  }
}
