//
//  BatteryViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class BatteryViewController: UIViewController {
    @IBOutlet weak var labelBatteryLevel: UILabel!
    @IBOutlet weak var labelBatteryStatus: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
