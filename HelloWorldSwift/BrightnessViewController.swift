//
//  BrightnessViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class BrightnessViewController: UIViewController {
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let screen = UIScreen.main
        
        self.label.text = String(describing: screen.brightness)
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
