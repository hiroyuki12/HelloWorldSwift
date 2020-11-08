//
//  GithubViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/10/31.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

struct Covid19Struct: Codable {
  var date: Int
  var pcr: Int
  var hospitalize: Int
  var positive: Int
  var severe: Int
  var discharge: Int
  var death: Int
  var symptom_confirming: Int
}

struct HatenaBookmarkStruct: Codable {
  var url: String
  var bookmarks: [BookMarkStruct]
  var count: Int
  var related: [RelatedStruct]
  var requested_url: String
  var eid: String
  var screenshot: String
  var entry_url: String
  var title: String
  
  struct BookMarkStruct: Codable {
    var tags: [String]
    var comment: String
    var user: String
    var timestamp: String
  }
  struct RelatedStruct: Codable {
    var count: Int
    var title: String
    var entry_url: String
    var eid: String
  }
}

struct GithubUserStruct: Codable {
  var login: String
  var id: Int
  var node_id: String
  var avatar_url: String
  var gravatar_id: String
  var url: String
  var html_url: String
  var followers_url: String
  var following_url: String
  var gists_url: String
  var starred_url: String
  var subscriptions_url: String
  var organizations_url: String
  var repos_url: String
  var events_url: String
  var received_events_url: String
  var type: String
  var site_admin: Bool
  var name: String
  var company: String
  var blog: String
  var location: String
  var email: String?
  var hireable: String?
  var bio: String?
  var twitter_username: String?
  var public_repos: Int
  var public_gists: Int
  var followers: Int
  var following: Int
  var created_at: String
  var updated_at: String
}

struct QiitaUserStruct: Codable {
  var description: String
  var facebook_id: String
  var followees_count: Int
  var followers_count: Int
  var github_login_name: String
  var id: String
  var items_count: Int
  var linkedin_id: String
  var location: String
  var name: String
  var organization: String
  var permanent_id: Int
  var profile_image_url: String
  var team_only: Bool
  var twitter_screen_name: String
  var website_url: String
}


class GithubViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
    
//    let url: URL = URL(string: "https://qiita.com/api/v2/users/TakahiRoyte")!
//    let url: URL = URL(string: "https://api.github.com/users/octocat")!
//    let url: URL = URL(string: "https://bookmark.hatenaapis.com/count/entry?url=http%3A%2F%2Fwww.hatena.ne.jp%2F")!
    let url: URL = URL(string: "https://b.hatena.ne.jp/entry/json/https://tech.hey.jp/entry/2020/10/23/111200")!
//    let url: URL = URL(string: "https://covid19-japan-web-api.now.sh/api/v1/total")!
//    let url: URL = URL(string: "https://qiita.com/api/v2/items")!
    
    let task: URLSessionTask = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
      guard let data = data else {
        return
      }
      do {
//        let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
//        print(json)
        
        //Codable
//        let qiitaUser = try JSONDecoder().decode(QiitaUserStruct.self, from: data)
//        print(qiitaUser.description)
        
//        let github = try JSONDecoder().decode(GithubUserStruct.self, from: data)
//        print(github.login)
                
        
        let hatenaBookmark = try JSONDecoder().decode(HatenaBookmarkStruct.self, from: data)
        print(hatenaBookmark.url)
        if(hatenaBookmark.bookmarks[0].tags.count > 0)  {
          print(hatenaBookmark.bookmarks[0].tags[0])
        }
        print(hatenaBookmark.related[0].count)
        print(hatenaBookmark.title)
//
//        let covid19 = try JSONDecoder().decode(Covid19Struct.self, from: data)
//        print(covid19.date)
        
//        let qiitaArticles = try JSONDecoder().decode([QiitaArticleStruct].self, from: data)
//        print(qiitaArticles[0].title)
//        print(qiitaArticles[0].tags[0].name)
//        print(qiitaArticles[0].user.id)
        
      // コンソールに出力
//      print("data: \(String(describing: data))")
//      print("response: \(String(describing: response))")
//      print("error: \(String(describing: error))")
      }
      catch {
          //print(error)
      }
    })
    task.resume()
    
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destination.
   // Pass the selected object to the new view controller.
   }
   */
  
}
