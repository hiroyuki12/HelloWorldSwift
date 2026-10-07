//
//  LocationViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/10.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController {
  @IBOutlet weak var labelLocation: UILabel!
  @IBOutlet weak var labelLocation2: UILabel!
  @IBOutlet weak var locationName: UILabel!

  // 緯度
  var latitudeNow: String = ""
  // 経度
  var longitudeNow: String = ""
  
  // ロケーションマネージャ
  var locationManager: CLLocationManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
    // 位置情報を取得
    // ロケーションマネージャのセットアップ
    setupLocationManager()
  }
  
  // 位置情報を取得ボタンタップ時
  @IBAction func tapGetLocation(_ sender: Any) {
    let status = locationManager.authorizationStatus
    
    if status == .denied {
      showAlert()
    } else if status == .authorizedWhenInUse || status == .authorizedAlways {
      labelLocation.text = latitudeNow
      labelLocation2.text = longitudeNow
      // まだ位置情報を受信していない
      guard !latitudeNow.isEmpty, !longitudeNow.isEmpty else { return }
      
      let dt = Date()
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
      
      let data = dateFormatter.string(from: dt) + "," + latitudeNow + "," + longitudeNow + "\n"
      Log.writeToFile(file:"location.csv", text:data)
      
      // 通信の完了をメインスレッドで待つと画面が固まる（失敗時は永久に固まる）ため、完了時にラベルを更新する
      locationName.text = "取得中..."
      getLocationName { [weak self] name in
        self?.locationName.text = name ?? "地名を取得できませんでした"
      }
    }
  }
  
  // Startボタンタップ時
  @IBAction func tapStart(_ sender: Any) {
    locationManager.startUpdatingLocation()
    print("Start tap!")
  }
  
  // Stopボタンタップ時
  @IBAction func tapStop(_ sender: Any) {
    locationManager.stopUpdatingLocation()
    print("Stop tap!")
  }
  
  // 緯度・経度から地名を取得する。completion はメインスレッドで呼ばれ、失敗時は nil
  func getLocationName(completion: @escaping (String?) -> Void) {
    var components = URLComponents(string: "https://www.finds.jp/ws/rgeocode.php")
    components?.queryItems = [URLQueryItem(name: "lat", value: latitudeNow),
                              URLQueryItem(name: "lon", value: longitudeNow),
                              URLQueryItem(name: "json", value: nil)]
    guard let url = components?.url else {
      completion(nil)
      return
    }
    URLSession.shared.dataTask(with: url) { data, response, error in
      var name: String?
      if let data = data,
         let items = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
         let result = items["result"] as? [String: Any],
         let prefecture = (result["prefecture"] as? [String: Any])?["pname"] as? String,
         let municipality = (result["municipality"] as? [String: Any])?["mname"] as? String {
        let section = ((result["local"] as? [Any])?.first as? [String: Any])?["section"] as? String
        name = [prefecture, municipality, section].compactMap { $0 }.joined(separator: " ")
      }
      DispatchQueue.main.async {
        completion(name)
      }
    }.resume()
  }

  // ロケーションマネージャのセットアップ
  func setupLocationManager() {
    locationManager = CLLocationManager()
    
    // 権限をリクエスト
    // 位置情報取得許可ダイアログの表示
    guard let locationManager = locationManager else { return }
    //locationManager.requestWhenInUseAuthorization()
    locationManager.requestAlwaysAuthorization()
    
    // マネージャの設定
    let status = locationManager.authorizationStatus
    // ステータスごとの処理
    // 初回は許可ダイアログの結果が後から届くため、許可状態にかかわらず delegate を設定する
    // （許可された時点で locationManagerDidChangeAuthorization から取得を開始する）
    locationManager.delegate = self
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      // 位置情報取得を開始
      locationManager.startUpdatingLocation()
    }
    if status == CLAuthorizationStatus.notDetermined {
        locationManager.requestAlwaysAuthorization()
    }
    
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    locationManager.distanceFilter = 100  //100m移動したら位置情報を更新する
//    locationManager.distanceFilter = 1  //1m移動したら位置情報を更新する(動作確認用)
    // バックグランドでも位置情報を取得
    locationManager.allowsBackgroundLocationUpdates = true
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
  
  
  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // Get the new view controller using segue.destination.
      // Pass the selected object to the new view controller.
  }
  */

}

// 位置情報を取得
extension LocationViewController: CLLocationManagerDelegate {
  // 許可状態が変わった（初回の許可ダイアログで許可された等）ら取得を開始する
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    if status == .authorizedWhenInUse || status == .authorizedAlways {
      manager.startUpdatingLocation()
    }
  }

  // 位置情報が更新された際、位置情報を格納する
  // - Parameters:
  //   - manager: ロケーションマネージャ
  //   - locations: 位置情報
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      // 配列の最後が最新の位置情報
      guard let location = locations.last else { return }
      let latitude = location.coordinate.latitude
      let longitude = location.coordinate.longitude
      // 位置情報を格納する
      self.latitudeNow = String(latitude)
      self.longitudeNow = String(longitude)
    
    let dt = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
    
    print("didUpdateLocations")
    let data = dateFormatter.string(from: dt) + "," + String(latitude) + "," + String(longitude) + "\n"
    print(data)
    Log.writeToFile(file:"location.csv", text:data)
  }
}
