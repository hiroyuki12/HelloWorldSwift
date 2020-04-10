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
    
    // Button 位置情報を取得
    @IBAction func tapGetLocation(_ sender: Any) {
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        
        if status == .denied {
            showAlert()
        } else if status == .authorizedWhenInUse {
            labelLocation.text = latitudeNow
            labelLocation2.text = longitudeNow
        }
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
    }
}
