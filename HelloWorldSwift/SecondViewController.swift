//
//  SecondViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/10.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController {
    @IBOutlet weak var labelHello: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func tapButton(_ sender: Any) {
        labelHello.text = "Tap!"
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
