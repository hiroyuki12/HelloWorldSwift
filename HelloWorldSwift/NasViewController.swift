//
//  NasViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/05/05.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class NasViewController: UIViewController {
  @IBOutlet weak var myImageView: UIImageView!
  
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
      // メインスレッドで同期的にダウンロードすると画面が固まり、通信失敗時はクラッシュするため非同期で読み込む
      let imgUrl = URL(string: "https://cdn-ak.f.st-hatena.com/images/fotolife/f/fedora9/20200501/20200501150536.png")
      myImageView.loadImageAsynchronously(url: imgUrl, defaultUIImage: nil)
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
