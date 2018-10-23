//
//  MetalRenderManager.swift
//  VRVideoDemo
//
//  Created by hebi on 2018/10/9.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import MetalKit
import Metal


struct Vertex {
    var position: float4
    var textureCoord: float2
}

class MetalRenderManager: NSObject {
    var mtkView: MTKView
    var commandQueue: MTLCommandQueue?
    var vertexBuffer: MTLBuffer?
    var indexBuffer: MTLBuffer?
    var pipelineState: MTLRenderPipelineState?

    
    init(mtkView: MTKView) {
        self.mtkView = mtkView
        super.init()
        createBuffer()
        registerShader()
        
        self.mtkView.delegate = self
    }
}


// MARK: - Pipeline
extension MetalRenderManager {
    func createBuffer() {
        
        let vertexArray: [Vertex] = [
            Vertex.init(position: float4.init(-0.5, -0.5, 0.0, 1.0), textureCoord: float2.init(1, 0)), // 左下角
            Vertex.init(position: float4.init(-0.5,  0.5, 0.0, 1.0), textureCoord: float2.init(0, 0)), // 左上角
            Vertex.init(position: float4.init(0.5, -0.5, 0.0, 1.0), textureCoord: float2.init(1, 1)), // 右下角
//            Vertex.init(position: float4.init(0.5,  0.5, 0.0, 1.0), textureCoord: float2.init(0, 1)), // 右上角
            ]
        let indexArray: [UInt16] = [
            0, 1, 2
//            1, 2, 3
        ]
        mtkView.device = MTLCreateSystemDefaultDevice()
        commandQueue = mtkView.device?.makeCommandQueue()
        let buffer: MTLBuffer? = mtkView.device?.makeBuffer(bytes: vertexArray, length: MemoryLayout<Vertex>.stride * 6, options: .storageModeShared)
        let indexBu = mtkView.device?.makeBuffer(bytes: indexArray, length: indexArray.count * MemoryLayout<UInt16>.stride, options: .storageModeShared)
        vertexBuffer = buffer
        indexBuffer = indexBu

    }
    
    func registerShader() {
        let pipeLineDes: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor.init()
        let library: MTLLibrary? = mtkView.device?.makeDefaultLibrary()
        let vertexFunc: MTLFunction? = library?.makeFunction(name: "vertexShader")
        let fragmentFunc: MTLFunction? = library?.makeFunction(name: "fragmentShader")
        pipeLineDes.vertexFunction = vertexFunc
        pipeLineDes.fragmentFunction = fragmentFunc
        pipeLineDes.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        do {
            pipelineState = try mtkView.device?.makeRenderPipelineState(descriptor: pipeLineDes)
        } catch {
            
        }
    }
}

extension MetalRenderManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDes = view.currentRenderPassDescriptor, view.currentDrawable != nil else {
            return
        }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
        let renderEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDes)
        renderEncoder?.setViewport(MTLViewport.init(originX: 0, originY: 0, width: Double(view.drawableSize.width), height: Double(view.drawableSize.height), znear: -1, zfar: 1))
        renderEncoder?.setRenderPipelineState(pipelineState!)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        let size = (indexBuffer?.length)! / MemoryLayout<UInt16>.stride
    
        renderEncoder?.drawIndexedPrimitives(type: .triangle, indexCount: size, indexType: MTLIndexType.uint16, indexBuffer: indexBuffer!, indexBufferOffset: 0)
       
//        renderEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
}
