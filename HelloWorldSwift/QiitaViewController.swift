//
//  QiitaViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/12.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class QiitaViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var articles: [[String: Any]] = [] //
    let TODO = ["牛乳を買う", "掃除をする", "アプリ開発の勉強をする"]
    
    // Cellの中身を設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // セルを取得する
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // セルに表示する値を設定する
        cell.textLabel!.text = articles[indexPath.row]["title"]! as? String
        //cell.textLabel!.text = TODO[indexPath.row]
        
        //print(articles[0]["title"]!)
        //print(articles[1]["title"]!)
        print ("AAA")
        return cell
    }
    
    
    // Cellの個数を設定
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
        //return TODO.count
        
    }
    
//    @IBOutlet weak var tableview: UITableView!

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
                //self.tableView.reloadData()
            }
            catch {
                print(error)
            }
        })
        
        task.resume() //実行する
        
//        tableview.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
        
        // register関数でUITableViewCellを登録
//        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
//        // dataSourceの設定
//        tableview.dataSource = self
        
        print("Hello!")
        
    }
    
    
    
    @IBAction func load(_ sender: Any) {
        self.tableView.reloadData()

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
