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
  // 地名
  var locationNameNow: String = ""
  // 取得中
  var isLoading: Bool = false
  
  // ロケーションマネージャ
  var locationManager: CLLocationManager!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
    // 位置情報を取得
    // ロケーションマネージャのセットアップ
    setupLocationManager()
  }
  
  let FMT_url_rev_geo = "https://www.finds.jp/ws/rgeocode.php?lat=%s&lon=%s&json"
  
  // 位置情報を取得ボタンタップ時
  @IBAction func tapGetLocation(_ sender: Any) {
    isLoading = true
    
    // マネージャの設定
    let status = CLLocationManager.authorizationStatus()
    
    if status == .denied {
      showAlert()
    } else if status == .authorizedWhenInUse {
      labelLocation.text = latitudeNow
      labelLocation2.text = longitudeNow
      
      let dt = Date()
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
      
      let data = dateFormatter.string(from: dt) + "," + latitudeNow + "," + longitudeNow + "\n"
      Log.writeToFile(file:"location.csv", text:data)
      
      getLocationName()
      // getLocationName の完了を待つ
      while(isLoading) {}
      locationName.text = locationNameNow
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
  
  func getLocationName()
  {
//    let url = URL(string: String(format: FMT_url_rev_geo, self.latitudeNow, self.longitudeNow))!
    let url = URL(string: String("https://www.finds.jp/ws/rgeocode.php?lat=" + latitudeNow + "&lon=" + longitudeNow + "&json"))!
    let request = URLRequest(url: url)
    let session = URLSession.shared
    session.dataTask(with: request) {
      (data, response, error) in
      if error == nil, let data = data, let response = response as? HTTPURLResponse {
        print("statusCode: \(response.statusCode)")
        let jsonString: String = String(data: data, encoding: String.Encoding.utf8) ?? ""
        let locationData =  jsonString.data(using: String.Encoding.utf8)!
        do {
          let items = try JSONSerialization.jsonObject(with: locationData) as! Dictionary<String, Any>
          let result = items["result"] as! Dictionary<String, Any>
          let prefecture = result["prefecture"] as! Dictionary<String, Any>
          let municipality = result["municipality"] as! Dictionary<String, Any>
          let local = result["local"] as! Array<Any>
          let local0 = local[0] as! Dictionary<String, Any>
          
          let a = prefecture["pname"] as! String
          let b = municipality["mname"] as! String
          let c = local0["section"] as! String
          self.locationNameNow = a + " " + b + " " + c
          self.isLoading = false
          
          //self.locationName.text  = locationName  //NG
//                self.locationName.text = prefecture["pname"] as! String
//                self.locationName.text! += municipality["mname"] as! String
//                self.locationName.text! += local0["section"] as! String
        }
        catch {
            print(error)
        }
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
    let status = CLLocationManager.authorizationStatus()
    // ステータスごとの処理
    if status == .authorizedWhenInUse {
      locationManager.delegate = self
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
    
    let dt = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMdHms", options: 0, locale: Locale(identifier: "ja_JP"))
    
    print("didUpdateLocations")
    let data = dateFormatter.string(from: dt) + "," + String(latitude!) + "," + String(longitude!) + "\n"
    print(data)
    Log.writeToFile(file:"location.csv", text:data)
  }
}
