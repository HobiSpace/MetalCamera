//
//  ViewController.swift
//  CameraDemo
//
//  Created by Hobi on 2018/9/20.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    
//    let manager: CameraManager = CameraManager.init()
//    var isfront: Bool = true
    
    
    var mtkView: MTKView!
    var render: MetalRender!
    var camera: Camera!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView = MTKView.init(frame: self.view.bounds)
        self.view.addSubview(mtkView)
        
        render = MetalRender()
        render.configDisplayView(view: mtkView)
        
        camera = Camera.init()
        camera.addRender(render: render)
        
        camera.startCapture()
//        manager.configDisplayView(self.view)
//        manager.startCapture(withFrontCamera: true)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//    @IBAction func originalAction(_ sender: Any) {
//        manager.filter(.Original)
//    }
//    
//    @IBAction func blackAndWhiteAction(_ sender: Any) {
//        manager.filter(.BlackAndWhite)
//    }
//    
//    @IBAction func grayFilterAction(_ sender: Any) {
//        manager.filter(.Gray)
//    }
//    
//    @IBAction func movieAction(_ sender: Any) {
//        manager.filter(.Movie)
//    }
}

