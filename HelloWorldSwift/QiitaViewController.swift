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

class QiitaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  @IBOutlet weak var table: UITableView!
  @IBOutlet weak var textPage: UILabel!
  @IBOutlet weak var myImage: UIImageView!
  
  var isLoading = false;
  
  var articles: [[String: Any]] = []
  
  let tag = "swift"
//    let _tag = "flutter"

  let tagFlutter  = "flutter"
  let tagSwift    = "swift"
  
  var savedPage = 1
  
  // Cellの中身を設定
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    // セルを取得する
    let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    
    let article = articles[indexPath.row]
    // セルに表示するテキストを設定する
    cell.textLabel!.text = articles[indexPath.row]["title"]! as? String
    cell.detailTextLabel!.text = articles[indexPath.row]["created_at"]! as? String
    
    let couponImageView = cell.viewWithTag(5) as! UIImageView
    let image:UIImage = getImageByUrl(url:"https://rr.img.naver.jp/mig?src=http%3A%2F%2Fimgcc.naver.jp%2Fkaze%2Fmission%2FUSER%2F20140315%2F40%2F4254050%2F12%2F384x215xbeefc5a0630dd93608c286cb.jpg%2F300%2F600&twidth=300&theight=600&qlt=80&res_format=jpg&op=r")
     couponImageView.image = image
//    myImage.image = image
    
    // セルに表示する画像を設定する
//    let img = UIImage(named: imgArray[indexPath.row] as! String)
//    cell.imageView?.image = img
    
    return cell
  }
  
  func getImageByUrl(url: String) -> UIImage{
      let url = URL(string: url)
      do {
          let data = try Data(contentsOf: url!)
          return UIImage(data: data)!
      } catch let err {
          print("Error : \(err.localizedDescription)")
      }
      return UIImage()
  }
    
  // Cellの個数を設定
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return articles.count
  }

  // 起動時処理
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    myload(page: 1, perPage: 20)
    print("myload (viewDidLoad)")
    
    print("viewDidLoad End!")
  }
  
  func myload(page: Int , perPage: Int) {
    let str1:String = "http://qiita.com/api/v2/tags/Swift/items?page="
    let str2:String = String(page)
    let str3:String = "&per_page="
    let str4:String = String(perPage)

    let str5:String = str1 + str2 + str3 + str4
    
    let url: URL = URL(string: str5)!
    
    let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
      do {
        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
        
        // 一時退避
        let articles_tmp = self.articles
        // 末尾に追加
        let articles = articles_tmp + json.map { (article) -> [String: Any] in
            return article as! [String: Any]
        }
//        print(json)
//        print(articles[0]["user"]!)
        print("BBB")
        print(articles[0]["title"]!)
//        print(articles[0]["url"]!)
//        print(articles[1]["title"]!)

//        extract articles
//        for entry in articles {
//            print(entry["title"]!)
//        }
//
//        print("count: \(json.count)") //追加
        
        self.articles = articles //追加
        print("savePage : \(self.savedPage)")
        print("self.articles Set End!")
        
        DispatchQueue.main.async {
          self.table.reloadData()
          print("reloadData End!")
          self.isLoading = false
          print("self.isLoading = false End!")
        }
      }
      catch {
          print(error)
      }
    })
    
    task.resume() //実行する
    
    print("myload End!")
  }
  
  // Loadボタン押下
  @IBAction func load(_ sender: Any) {
    self.table.reloadData()
    print("reloadData(tap load button")
  }
  
  // Nextボタン押下
  @IBAction func next(_ sender: Any) {
    savedPage += 1
    myload(page: savedPage, perPage: 20)
    print("myload(tap next button)")
    
    textPage.text =  "swift Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // Prevボタン押下
  @IBAction func prev(_ sender: Any) {
    savedPage -= 1
    myload(page: savedPage, perPage: 20)
    print("myload(tap prev button)")
    
    textPage.text =  "swift Page " + String(savedPage) +
      "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
  }
  
  // セルをタップした時の処理
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    print (indexPath)  // 1つ目が[0,0]、２つ目が[0,1]
//    popUp()
    
    let webView = self.storyboard?.instantiateViewController(withIdentifier: "MyWebView") as! WebViewController
    webView.url = articles[indexPath.row]["url"]! as? String ?? "http://www.yahoo.co.jp"
    
    self.present(webView, animated: true, completion: nil)
  }
  
  
  private func popUp() {
      let alertController = UIAlertController(title: "確認", message: "本当に実行しますか", preferredStyle: .actionSheet)

      let yesAction = UIAlertAction(title: "はい", style: .default, handler: nil)
      alertController.addAction(yesAction)

      let noAction = UIAlertAction(title: "いいえ", style: .default, handler: nil)
      alertController.addAction(noAction)

      let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
      alertController.addAction(cancelAction)

      present(alertController, animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if (self.table.contentOffset.y + self.table.frame.size.height > self.table.contentSize.height && self.table.isDragging && !isLoading){
      isLoading = true
      savedPage += 1
      myload(page: savedPage, perPage: 20)
      print("myload(List End)")
      
      textPage.text =  "swift Page " + String(savedPage) +
        "/20posts/" + String((savedPage-1) * 20 + 1) + "〜"
    }
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

struct QiitaUser: Codable {
    let id: String
    let imageUrl: String // ①
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "profile_image_url" // ②
    }
}

struct QiitaArticle: Codable {
    let title: String
    let url: String
    let user: QiitaUser // ⓵
}

//extension ViewController: UITableViewDelegate {
//  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let storyboard = UIStoryboard(name: "WebViewController", bundle: nil)
//    let webViewController = storyboard.instantiateInitialViewController() as! WebViewController
//    // ③indexPathを使用してarticlesから選択されたarticleを取得
//    //let article = articles[indexPath.row]
//    // ④urlとtitleを代入
//    webViewController.url = "http://www.google.com/"
//    //webViewController.url = article.url
//    //webViewController.title = article.title
//    navigationController?.pushViewController(webViewController, animated: true)
//  }
//}

