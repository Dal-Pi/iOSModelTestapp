//
//  ViewController.swift
//  iOSModelTestapp
//
//  Created by Seonghan Kim on 1/19/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        checkCameraPermission()
    }

    func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if granted {
                print("granted")
            } else {
                print("not granted")
            }
        })
    }
}

