//
//  ListViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/20.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class ListViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return TodoKobetsunonakami.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let TodoCell : UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath)

//    let fileName = "log.csv"
//    guard let documentPath =
//    FileManager.default.urls(for: .documentDirectory,
//                             in: .userDomainMask).first else { return TodoCell }
//
//    let fileURL = documentPath.appendingPathComponent(fileName)
//    let data = getFileData(fileURL)
//    print("data")
//    print(data)
//
//    guard data != nil else { return }
//
//
    TodoCell.textLabel!.text = TodoKobetsunonakami[indexPath.row]
    return TodoCell
  }
  

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
//    if UserDefaults.standard.object(forKey: "TodoList") != nil {
//      TodoKobetsunonakami = UserDefaults.standard.object(forKey: "TodoList") as! [String]
//    }
//
//    let fileName = "log.csv"
//    guard let documentPath =
//    FileManager.default.urls(for: .documentDirectory,
//                             in: .userDomainMask).first else { return }
//
//    let fileURL = documentPath.appendingPathComponent(fileName)
//    let data = getFileData(fileURL)
//    print("data")
//    print(data)
    
//    guard let file = FileHandle(forReadingAtPath: pathString) else
//    {
//        print("csvファイルがないよ")
//        return
//    }
//    guard let stream = InputStream(url: fileURL) else { return }
//    stream.open()
//
//    defer { stream.close() }
    
//    let contentData = file.readDataToEndOfFile()
//
//    let contentString = String(data: contentData, encoding: .utf8)!
//
//    file.closeFile()
    
//    print(contentString)
  }

  func getFileData(_ filePath: URL) -> Data? {
      let fileData: Data?
      do {
//          let fileUrl = URL(fileURLWithPath: filePath)
          fileData = try Data(contentsOf: filePath)
      } catch {
          // ファイルデータの取得でエラーの場合
          fileData = nil
      }
      return fileData
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
