//
//  SubViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/21.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import LocalAuthentication  // Face ID

class SubViewController: UIViewController {
  @IBOutlet weak var labelBatteryLevel: UILabel!
  @IBOutlet weak var labelBatteryStatus: UILabel!
  @IBOutlet weak var labelBrightness: UILabel!
  @IBOutlet weak var labelNow: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    
// Battery
   // バッテリーのモニタリングをenableにする
   UIDevice.current.isBatteryMonitoringEnabled = true
    
    let bLevel:Float = UIDevice.current.batteryLevel
    
    if(bLevel == -1){
        // バッテリーレベルがモニターできないケース
        labelBatteryLevel.text = "Battery Level: ?"
    }
    else{
        labelBatteryLevel.text = "Battery Level:  \(bLevel * 100) %"
    }
       
    // Battery Status
    var state:String = "Battery Status: "

    if UIDevice.current.batteryState == UIDevice.BatteryState.unplugged {
           state += "Unplugged"
    }

    if UIDevice.current.batteryState == UIDevice.BatteryState.charging {
           state += "Charging"
    }

    if UIDevice.current.batteryState == UIDevice.BatteryState.full {
           state += "Full"
    }

    if UIDevice.current.batteryState == UIDevice.BatteryState.unknown {
           state += "Unknown"
    }
           
    labelBatteryStatus.text = state
    
// Brightness
    let screen = UIScreen.main
    
    self.labelBrightness.text = String(describing: screen.brightness)
    
// Now
    let now = Date() // 現在日時の取得
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US") // ロケールの設定
    dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss" // 日付フォーマットの設定

    //print(dateFormatter.string(from: now)) // -> 2014/06/25 02:13:18
    
    labelNow.text = dateFormatter.string(from: now)
    
  }
    
  @IBAction func tapButtonAlert(_ sender: Any) {
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
  
  @IBAction func tapFaceID(_ sender: Any) {
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
