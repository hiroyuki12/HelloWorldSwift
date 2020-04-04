//
//  ViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var labelHello: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func tapButton(_ sender: Any) {
        labelHello.text = "Tap!"
        print("Tap!")
    }
    
    @IBAction func tapButton2(_ sender: Any) {
        view.backgroundColor = UIColor.green
    }
}

