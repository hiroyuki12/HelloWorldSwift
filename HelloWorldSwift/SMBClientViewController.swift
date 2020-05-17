//
//  SMBClientViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/05/05.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import SMBClient

class SMBClientViewController: UIViewController, NetBIOSNameServiceDelegate {
  @IBOutlet weak var label: UILabel!
  
  let biosNameService = NetBIOSNameService()
  // 共有ボリューム
  var volumes: [SMBVolume] = []
  
  // 接続先
  var servers: [NetBIOSNameServiceEntry] = []{
      // デリゲートメソッドがメインスレッド内じゃないので
      // 接続先追加/削除時の処理はプロパティ変更検知で対応
      didSet {
          DispatchQueue.main.async {
              // とりあえずラベルに表示
              var txt = ""
              for server in self.servers {
                  txt += "\(server.name) : \(server.ipAddressString)\r\n"
              }
              self.label.text = txt
          }
      }
  }
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      biosNameService.delegate = self
    }
    
  @IBAction func TapSearch(_ sender: Any) {
    // LAN内検索開始
    biosNameService.startDiscovery(withTimeout: 3000)
  }
  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
  
  /// 接続先が追加された場合の処理
  ///
  /// - Parameter entry: 接続先
  func added(entry: NetBIOSNameServiceEntry) {
      self.servers.append(entry)
  }

  /// 接続先が消えた場合の処理？確認できず
  ///
  /// - Parameter entry: 接続先
  func removed(entry: NetBIOSNameServiceEntry) {
      self.servers = self.servers.filter { $0 != entry }
  }
  /// 接続処理
  func connect(){
      let svr = self.servers.first!   // とりあえずテストとして最初のやつ
      // サーバ情報
      let smbServer = SMBServer(hostname: svr.name, ipAddress: svr.ipAddress)
      // 認証情報
      let creds = SMBSession.Credentials.user(name: "hiroyuki", password: "muromuro")
      // セッション情報
      let session = SMBSession(server: smbServer, credentials: creds)

      // 接続先の共有フォルダ一覧取得
      session.requestVolumes(completion: { (result) in
          switch result {
          case .success(let volumes):
              // とりあえずラベルに表示
              var txt = ""
              for volume in volumes {
                  txt += "\(volume.name)\r\n"
              }
              self.label.text = txt
          case .failure(let error):
              let alert = UIAlertController(title: "error", message: error.debugDescription, preferredStyle: .alert)
              let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                  self.navigationController?.popViewController(animated: true)
              })
              alert.addAction(ok)
              self.present(alert, animated: true, completion: nil)
          }
      })
  }
  
  @IBAction func TapConnect(_ sender: Any) {
    connect()
  }
  
}
