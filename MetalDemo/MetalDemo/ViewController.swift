//
//  ViewController.swift
//  MetalDemo
//
//  Created by Hobi on 2018/9/18.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import Metal
import MetalKit

struct Vertex {
    var position: float4
    var texturePos: float2
}

class ViewController: UIViewController {
    
    lazy var displayView: MTKView = makeDisplayView()
    lazy var pipelineState: MTLRenderPipelineState? = makePipeLineState()
    lazy var commandQueue: MTLCommandQueue? = makeCommandQueue()
    lazy var vertex: MTLBuffer? = makeVertex()
    lazy var texture: MTLTexture? = makeTexture()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(displayView)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}

// MARK: - Make
extension ViewController {
    
    func makeDisplayView() -> MTKView {
        let device: MTLDevice? = MTLCreateSystemDefaultDevice()
        let view: MTKView = MTKView.init(frame: self.view.bounds, device: device)
        view.delegate = self
        return view
    }
    
    func makePipeLineState() -> MTLRenderPipelineState? {
        let pipeLineDes: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor.init()
        let library = displayView.device?.makeDefaultLibrary()
        let vertexFunc = library?.makeFunction(name: "myVertexShader")
        let fragmentFunc = library?.makeFunction(name: "myFragmentShader")
        pipeLineDes.vertexFunction = vertexFunc
        pipeLineDes.fragmentFunction = fragmentFunc
        pipeLineDes.colorAttachments[0].pixelFormat = displayView.colorPixelFormat
        do {
            let renderPipeStatue = try displayView.device?.makeRenderPipelineState(descriptor: pipeLineDes)
            return renderPipeStatue
        } catch {
            return nil
        }
    }
    
    func makeCommandQueue() -> MTLCommandQueue? {
        return displayView.device?.makeCommandQueue()
    }
    
    func makeVertex() -> MTLBuffer? {
        let vertexArray: [Vertex] = [
            Vertex.init(position: float4.init(0.5, -0.5, 0.0, 1.0), texturePos: float2.init(1, 0)),
            Vertex.init(position: float4.init(-0.5, -0.5, 0.0, 1.0), texturePos: float2.init(0, 0)),
            Vertex.init(position: float4.init(-0.5,  0.5, 0.0, 1.0), texturePos: float2.init(0, 1)),
            Vertex.init(position: float4.init(0.5, -0.5, 0.0, 1.0), texturePos: float2.init(1, 0)),
            Vertex.init(position: float4.init(-0.5,  0.5, 0.0, 1.0), texturePos: float2.init(0, 1)),
            Vertex.init(position: float4.init(0.5,  0.5, 0.0, 1.0), texturePos: float2.init(1, 1)),
        ]

        let buffer: MTLBuffer? = displayView.device?.makeBuffer(bytes: vertexArray, length: MemoryLayout<Vertex>.stride * 6, options: .storageModeShared)
        return buffer
    }
    
    func makeTexture() -> MTLTexture? {
        let device: MTLDevice? = MTLCreateSystemDefaultDevice()
        let textureLoader: MTKTextureLoader = MTKTextureLoader.init(device: device!)
        let image: UIImage = UIImage.init(named: "test")!
        let texture: MTLTexture? = try? textureLoader.newTexture(cgImage: image.cgImage!, options: nil)
        return texture
        
    }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderPassDes = displayView.currentRenderPassDescriptor
        renderPassDes?.colorAttachments[0].clearColor = MTLClearColorMake(1, 0.2, 0.5, 1)
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDes!)
        renderEncoder?.setViewport(MTLViewport.init(originX: 0, originY: 0, width: Double(displayView.drawableSize.width), height: Double(displayView.drawableSize.height), znear: -1, zfar: 1))
        renderEncoder?.setRenderPipelineState(pipelineState!)
        renderEncoder?.setVertexBuffer(vertex, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(texture, index: 0)
        renderEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }
    
    
    
}
