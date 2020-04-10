//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation
import LocalAuthentication
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var labelHello: UILabel!
    @IBOutlet weak var tableView: UITableView!
//    @IBOutlet weak var wkWebView: WKWebView!
    
    var articles: [[String: Any]] = [] //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Face ID
        let context = LAContext()
        var error: NSError?
        let description: String = "認証"
        
        // Touch ID・Face IDが利用できるデバイスか確認する
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // 利用できる場合は指紋・顔認証を要求する
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: description, reply: {success, evaluateError in
                if (success) {
                    // 認証成功時の処理を書く
                    print("認証成功")
                } else {
                    // 認証失敗時の処理を書く
                    print("認証失敗")
                }
            })
        } else {
            // Touch ID・Face IDが利用できない場合の処理
            let errorDescription = error?.userInfo["NSLocalizedDescription"] ?? ""
            print(errorDescription) // Biometry is not available on this device.
        }
        
        // WebView
//        if let url = NSURL(string: "https://www.google.com") {
//            let request = NSURLRequest(url: url as URL)
//            wkWebView.load(request as URLRequest)
//        }
        
        // WIP Tabel View
        let url: URL = URL(string: "http://qiita.com/api/v2/items")!

        let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
                let articles = json.map { (article) -> [String: Any] in
                    return article as! [String: Any]
                }
//                print(json)
                print(articles[0]["title"]!)
                print("count: \(json.count)") //追加
                self.articles = articles //追加
            }
            catch {
                print(error)
            }
        })
        
        task.resume() //実行する
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
    }
    
    // Button backgroud Color
    @IBAction func tapButton2(_ sender: Any) {
        view.backgroundColor = UIColor.green
    }
    

    
    // Button 画面遷移
    @IBAction func tapNextPage(_ sender: Any) {
//        // Storyboardのインスタンスを名前指定で取得する
//        let storyboard = UIStoryboard(name: "Sub", bundle: nil)
//        // Storyboard内で'is initial'に指定されているViewControllerを取得する
//        let nextVC = storyboard.instantiateInitialViewController() as! SubViewController
//        // FullScreenにする
//        nextVC.modalPresentationStyle = .fullScreen
//        // presentする
//        self.present(nextVC, animated: true, completion: nil)
    }
}

// WIP Table View
extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count //変更
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell
        let article = articles[indexPath.row] //追加
        let title = article["title"] as! String //追加
//        cell.bindData(text: "title: \(title)") //変更
        return cell
    }
  
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// WIP Table View
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("section: \(indexPath.section) index: \(indexPath.row)")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        return
    }
}
