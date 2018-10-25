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
    
    var mtkView: MTKView!
    var render: MetalRender!
    var camera: Camera!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mtkView = MTKView.init(frame: self.view.bounds)
        self.view.insertSubview(mtkView, at: 0)
        
        render = MetalRender()
        render.configDisplayView(view: mtkView)
        render.filter(.Original)
        
        camera = Camera.init()
        camera.addRender(render: render)
        
        camera.startCapture()
    }
    
    @IBAction func originalAction(_ sender: Any) {
        render.filter(.Original)
    }
    
    @IBAction func blackAndWhiteAction(_ sender: Any) {
        render.filter(.BlackAndWhite)
    }
    
    @IBAction func grayFilterAction(_ sender: Any) {
        render.filter(.Gray)
    }
    
    @IBAction func movieAction(_ sender: Any) {
        render.filter(.Movie)
    }
}

