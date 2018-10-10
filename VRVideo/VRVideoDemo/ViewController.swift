//
//  ViewController.swift
//  VRVideoDemo
//
//  Created by hebi on 2018/10/8.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var manager: MetalRenderManager!
    override func viewDidLoad() {
        super.viewDidLoad()
        let displayView: MTKView = MTKView.init(frame: self.view.bounds)
        manager = MetalRenderManager.init(mtkView: displayView)
        view.addSubview(displayView)
    }


}

