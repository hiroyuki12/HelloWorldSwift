//
//  Storyboard+Extension.swift
//  Example
//
//  Created by Seth Faxon on 9/7/17.
//  Copyright © 2017 Filmic. All rights reserved.
//

import UIKit
import SMBClient

extension UIStoryboard {
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }

//    class func fileTableViewController(session: SMBSession, volume: SMBVolume, title: String, path: String = "/") -> FilesTableViewController {
//        let vc = mainStoryboard().instantiateViewController(withIdentifier: "FilesTableViewController") as! FilesTableViewController
//        vc.session = session
//        vc.volume = volume
//        vc.path = path
//        vc.title = title
//        return vc
//    }

    class func fileTableViewController(session: SMBSession, path: SMBPath, title: String) -> FilesTableViewController {
        let vc = mainStoryboard().instantiateViewController(withIdentifier: "FilesTableViewController") as! FilesTableViewController
        vc.session = session
        vc.path = path
        vc.title = title
        return vc
    }

    class func downloadProgressViewController(session: SMBSession, file: SMBFile) -> DownloadProgressViewController {
        let vc = mainStoryboard().instantiateViewController(withIdentifier: "DownloadProgressViewController") as! DownloadProgressViewController
        vc.session = session
        vc.file = file
        return vc
    }

    class func volumeListViewController(session: SMBSession) -> VolumeListViewController {
        let vc = mainStoryboard().instantiateViewController(withIdentifier: "VolumeListViewController") as! VolumeListViewController
        vc.session = session
        return vc
    }

    class func authViewController(server: SMBServer) -> AuthViewController {
        let vc = mainStoryboard().instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        vc.server = server
        return vc
    }
}
