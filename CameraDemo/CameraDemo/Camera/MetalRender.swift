//
//  MetalRender.swift
//  CameraDemo
//
//  Created by hebi on 2018/10/25.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders

class MetalRender: NSObject {
    
    var textureCache: CVMetalTextureCache!
    var texture: MTLTexture?
    var displayView: MTKView?
    var commandQueue: MTLCommandQueue?
    
    
    func configDisplayView(view: MTKView) {
        view.device = MTLCreateSystemDefaultDevice()
        guard let device = view.device else {
            // 不支持设备
            return
        }
        view.delegate = self
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        commandQueue = device.makeCommandQueue()
        displayView = view
        
    }
    
    func render(pixelBuffer: CVPixelBuffer) {
        guard let displayView = displayView else {
            // 没有渲染目标
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var textureRef: CVMetalTexture?
        
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &textureRef)
        
        if result == kCVReturnSuccess, let textureRef = textureRef {
            displayView.drawableSize = CGSize(width: width, height: height)
            texture = CVMetalTextureGetTexture(textureRef)
        }
        
        // 释放
        textureRef = nil
    }
}

// MARK: - MTKViewDelegate
extension MetalRender: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let texture = texture, let drawable = view.currentDrawable, let device = view.device, let commandBuffer = commandQueue?.makeCommandBuffer() else {
            return
        }
        
        let drawTexture = drawable.texture
        
        let filter = MPSImageGaussianBlur.init(device: device, sigma: 1)
        filter.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: drawTexture)
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
}
