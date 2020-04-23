//
//  SQLiteViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/23.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import SQLite3

class SQLiteViewController: UIViewController {
  var db: OpaquePointer?
  
  // Insertボタンタップ時
  @IBAction func tapSave(_ sender: Any) {
    //creating a statement
    var stmt: OpaquePointer?

    //the insert query
    let queryString = "INSERT INTO Heroes (name, powerrank) VALUES (1,?)"

    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing insert: \(errmsg)")
      return
    }
    //binding the parameters
    //1つ目の?に2をセット
    if sqlite3_bind_text(stmt, 1, "2", -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding: \(errmsg)")
        return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure inserting hero: \(errmsg)")
        return
    }
    
    print ("finish tapSave!")
  }
  
  // Selectボタンタップ時
  @IBAction func tapRead(_ sender: Any) {

    //this is our select query
    let queryString = "SELECT * FROM Heroes"
    
    //statement pointer
    var stmt:OpaquePointer?
    
    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("error preparing insert: \(errmsg)")
        return
    }
    
    //traversing through all the records
    while(sqlite3_step(stmt) == SQLITE_ROW){
      let id = sqlite3_column_int(stmt, 0)
      let name = String(cString: sqlite3_column_text(stmt, 1))
      print("name")
      print(name)
      let powerrank = sqlite3_column_int(stmt, 2)
      print("powerrank")
      print(powerrank)
        //adding values to list
//        heroList.append(Hero(id: Int(id), name: String(describing: name), powerRanking: Int(powerrank)))
     }
    
    print ("finish tapRead!")
  }
  
  // Updateボタンタップ時
  @IBAction func tapUpdate(_ sender: Any) {
    //creating a statement
    var stmt: OpaquePointer?

    //the insert query
    let queryString = "UPDATE Heroes SET powerrank = ?"

    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing update: \(errmsg)")
      return
    }
    //binding the parameters
    //1つ目の?に3をセット
    if sqlite3_bind_text(stmt, 1, "3", -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding: \(errmsg)")
        return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure updating hero: \(errmsg)")
        return
    }
    
    print ("finish tapUpdate!")
  }
  
  @IBAction func tapDelete(_ sender: Any) {
    //creating a statement
    var stmt: OpaquePointer?

    //the insert query
    let queryString = "DELETE FROM  Heroes WHERE name = ?"

    //preparing the query
    if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
      let errmsg = String(cString: sqlite3_errmsg(db)!)
      print("error preparing delte: \(errmsg)")
      return
    }
    //binding the parameters
    //1つ目の?に1をセット
    if sqlite3_bind_text(stmt, 1, "1", -1, nil) != SQLITE_OK{
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure binding: \(errmsg)")
        return
    }
    //executing the query to insert values
    if sqlite3_step(stmt) != SQLITE_DONE {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("failure deleting hero: \(errmsg)")
        return
    }
    
    print ("finish tapDelete!")
  }
  
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    let fileUrl = try!
      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("HeroDatabase.sqlite")
    
    if sqlite3_open(fileUrl.path, &db) != SQLITE_OK{
      print("Error opening database. HeroDatabase.sqlite")
      return
    }
    
    let createTableQuery = "create table if not exists Heroes (id integer primary key autoincrement, name text, powerrank integer)"
    
    if sqlite3_exec(db, createTableQuery, nil, nil, nil) !=
      SQLITE_OK{
      print("Error createing table Heros")
      return
    }
    
    print("Everything is fine!")
    
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
