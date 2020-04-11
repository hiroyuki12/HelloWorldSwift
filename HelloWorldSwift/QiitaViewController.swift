//
//  QiitaViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class QiitaViewController: UIViewController {
    @IBOutlet weak var tableview: UITableView!
    
    var articles: [[String: Any]] = [] //

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // WIP Tabel View
        let url: URL = URL(string: "http://qiita.com/api/v2/tags/Swift/items")!

        let task: URLSessionTask  = URLSession.shared.dataTask(with: url, completionHandler: {data, response, error in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [Any]
                let articles = json.map { (article) -> [String: Any] in
                    return article as! [String: Any]
                }
//                print(json)
                //print(articles[0]["title"]!)
                //print(articles[1]["title"]!)
                
                //extract articles
                for entry in articles {
                    print(entry["title"]!)
                }
                
                print("count: \(json.count)") //追加
                self.articles = articles //追加
            }
            catch {
                print(error)
            }
        })
        
        //task.resume() //実行する
        
        tableview.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
        
        // register関数でUITableViewCellを登録
//        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
//        // dataSourceの設定
//        tableview.dataSource = self
        
        print("Hello!")
        
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeueReusableCell関数でCellの取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        // UITableViewCellにあるtextLabelの設定
        cell.textLabel?.text = "\(indexPath.row)番目のセル"
        return cell
    }
    
    @IBAction func load(_ sender: Any) {
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

// WIP Table View
extension QiitaViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count //変更
    }

    func tableview(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") as! TableViewCell
        //let article = articles[indexPath.row] //追加
        //let title = article["title"] as! String //追加
//        cell.bindData(text: "title: \(title)") //変更
        cell.textLabel?.text = "\(indexPath.row)番目のセル"
        return cell
    }
  
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 10
    }
}

// WIP Table View
extension QiitaViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("section: \(indexPath.section) index: \(indexPath.row)")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        return
    }
}
