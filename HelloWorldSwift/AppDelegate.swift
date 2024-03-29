//
//  AppDelegate.swift
//  HelloWorldSwift
//
//  Created by hiroyuki on 2020/04/03.
//  Copyright © 2020 hiroyuki. All rights reserved.
//

import UIKit
import SwiftyDropbox
//import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    //先にiPhoneにDropboxアプリをインストール
    //Info.plistにdb-DROPBOX_APP_KEYを設定、下記にも設定して実行すると
    //Sign inして画像を表示できた。
    //DROPBOX_APP_KEYは実際のApp keyに置き換え
    //一度Sign inした後はダミーのkeyに変更してもSign inせずにDownloadできる。
      DropboxClientsManager.setupWithAppKey("DROPBOX_APP_KEY")
//    FirebaseApp.configure()
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
      // Called when a new scene session is being created.
      // Use this method to select a configuration to create the new scene with.
      return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
      // Called when the user discards a scene session.
      // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
      // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return true
  }
}



