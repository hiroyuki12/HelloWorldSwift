//
//  CameraRollViewController.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/30.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit

class CameraRollViewController: UIViewController {
  @IBOutlet weak var imageView: UIImageView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
  }
    
  @IBAction func tapSelectPhoto(_ sender: Any) {
    // カメラロールが利用可能か？
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      // 写真を選ぶビュー
      let pickerView = UIImagePickerController()
      // 写真の選択元をカメラロールにする
      // 「.camera」にすればカメラを起動できる
      pickerView.sourceType = .photoLibrary
      // デリゲート
      pickerView.delegate = self
      // ビューに表示
      self.present(pickerView, animated: true)
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

extension CameraRollViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // 写真を選んだ後に呼ばれる処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 選択した写真を取得する
        let image = info[.originalImage] as! UIImage
        // ビューに表示する
        imageView.image = image
        // 写真を選ぶビューを引っ込める
        self.dismiss(animated: true)
    }
}
