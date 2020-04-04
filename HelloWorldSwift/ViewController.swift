//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var labelHello: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var articles: [[String: Any]] = [] //追加
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

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


    @IBAction func tapButton(_ sender: Any) {
        labelHello.text = "Tap!"
        print("Tap!")
    }
    
    @IBAction func tapButton2(_ sender: Any) {
        view.backgroundColor = UIColor.green
    }
}


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

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("section: \(indexPath.section) index: \(indexPath.row)")
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        return
    }
}
