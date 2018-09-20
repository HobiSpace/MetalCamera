//
//  ViewController.swift
//  CameraDemo
//
//  Created by Hobi on 2018/9/20.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let manager: CameraManager = CameraManager.init()
    var isfront: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager.configDisplayView(self.view)
        manager.startCapture(withFrontCamera: true)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
}

