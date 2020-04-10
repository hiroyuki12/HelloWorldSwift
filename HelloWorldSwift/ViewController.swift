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
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelLocation2: UILabel!
    
    var articles: [[String: Any]] = [] //
    
    // 緯度
    var latitudeNow: String = ""
    // 経度
    var longitudeNow: String = ""
    // ロケーションマネージャ
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //
        
        
        // 位置情報を取得
        // ロケーションマネージャのセットアップ
        setupLocationManager()
        
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


    @IBAction func tapButton(_ sender: Any) {
        labelHello.text = "Tap!"
        print("Tap!")
    }
    
    // Button backgroud Color
    @IBAction func tapButton2(_ sender: Any) {
        view.backgroundColor = UIColor.green
    }
    
    // ButtonAlert
    @IBAction func tapAlert(_ sender: Any) {
        popUp()
    }
    
    // Alert
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
    
    // Button 位置情報を取得
    @IBAction func tapGetLocationInfo(_ sender: Any) {
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        if status == .denied {
            showAlert()
        } else if status == .authorizedWhenInUse {
            labelLocation.text = latitudeNow
            labelLocation2.text = longitudeNow
        }
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
    
    
    // ロケーションマネージャのセットアップ
    func setupLocationManager() {
        locationManager = CLLocationManager()
        
        // 権限をリクエスト
        // 位置情報取得許可ダイアログの表示
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
        
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        // ステータスごとの処理
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            // 位置情報取得を開始
            locationManager.startUpdatingLocation()
        }
    }
    
    // アラートを表示する
    func showAlert() {
        let alertTitle = "位置情報取得が許可されていません。"
        let alertMessage = "設定アプリの「プライバシー > 位置情報サービス」から変更してください。"
        let alert: UIAlertController = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle:  UIAlertController.Style.alert
        )
        // OKボタン
        let defaultAction: UIAlertAction = UIAlertAction(
            title: "OK",
            style: UIAlertAction.Style.default,
            handler: nil
        )
        // UIAlertController に Action を追加
        alert.addAction(defaultAction)
        // Alertを表示
        present(alert, animated: true, completion: nil)
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

// 位置情報を取得
extension ViewController: CLLocationManagerDelegate {

    // 位置情報が更新された際、位置情報を格納する
    // - Parameters:
    //   - manager: ロケーションマネージャ
    //   - locations: 位置情報
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        // 位置情報を格納する
        self.latitudeNow = String(latitude!)
        self.longitudeNow = String(longitude!)
    }
}
