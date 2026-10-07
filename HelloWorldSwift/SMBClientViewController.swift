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
  /// 認証情報はソースコードに書かず、接続のたびに入力してもらう
  func connect(){
      guard !self.servers.isEmpty else {
          self.label.text = "先に Search でサーバーを検索してください"
          return
      }
      let alert = UIAlertController(title: "SMB 認証", message: nil, preferredStyle: .alert)
      alert.addTextField { $0.placeholder = "ユーザー名" }
      alert.addTextField {
          $0.placeholder = "パスワード"
          $0.isSecureTextEntry = true
      }
      alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "接続", style: .default, handler: { [weak self, weak alert] _ in
          let name = alert?.textFields?[0].text ?? ""
          let password = alert?.textFields?[1].text ?? ""
          self?.connect(name: name, password: password)
      }))
      present(alert, animated: true, completion: nil)
  }

  private func connect(name: String, password: String) {
      guard let svr = self.servers.first else { return }  // とりあえずテストとして最初のやつ
      // サーバ情報
      let smbServer = SMBServer(hostname: svr.name, ipAddress: svr.ipAddress)
      // 認証情報
      let creds = SMBSession.Credentials.user(name: name, password: password)
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
