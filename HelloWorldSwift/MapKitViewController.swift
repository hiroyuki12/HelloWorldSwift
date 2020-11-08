//
//  MapKitViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/11.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import MapKit

class MapKitViewController: UIViewController {
    @IBOutlet weak var mkMapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

  @IBAction func tapClose(_ sender: Any) {
    //戻る
    dismiss(animated: true, completion: nil)
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
