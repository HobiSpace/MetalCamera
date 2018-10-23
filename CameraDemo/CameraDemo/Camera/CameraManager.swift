//
//  CameraManager.swift
//  CameraDemo
//
//  Created by Hobi on 2018/9/20.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import AVFoundation
import MetalKit

enum FilterType: String {
    case Original = "original"
    case Gray = "gray_kernel_function"
    case BlackAndWhite = "black_white_kernel_function"
    case Movie = "movie_kernel_function"
}

struct Vertex {
    var position: float4
    var texturePos: float2
}

class CameraManager: NSObject {
    
    /// Camera
    var cameraSession: AVCaptureSession
    var cameraDevice: AVCaptureDevice!
    var deviceInput: AVCaptureDeviceInput?
    var cameraDataOutput: AVCaptureVideoDataOutput
    var processQueue: DispatchQueue
    
    /// Metal
    var metalDevice: MTLDevice?
    var displayView: MTKView
    var vertex: MTLBuffer?
    var texture: MTLTexture?
    var textureCache: CVMetalTextureCache!
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var computePipeLineState: MTLComputePipelineState?
    
    override init() {
        cameraSession = {
            let session: AVCaptureSession = AVCaptureSession.init()
            return session
        }()
        
        cameraDataOutput = {
            let dataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput.init()
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
            return dataOutput
        }()
        
        processQueue = {
            let queue: DispatchQueue = DispatchQueue.init(label: "com.hobi.data")
            return queue
        }()
        
        displayView = {
            let view: MTKView = MTKView.init(frame: CGRect.zero, device: MTLCreateSystemDefaultDevice()!)
            view.framebufferOnly = false
            return view
        }()
        
        super.init()
        
        createBuffer()
        registerShader()
//        registerComputePipeLineState()
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, displayView.device!, nil, &textureCache)
    }
    
}


// MARK: - Private
extension CameraManager {
    private func cameraDeviceWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devicesSession: AVCaptureDevice.DiscoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        
        for device: AVCaptureDevice in devicesSession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    private func render() {

    }
    
    private func createBuffer() {
        metalDevice = displayView.device
        commandQueue = metalDevice?.makeCommandQueue()
        
        let vertexArray: [Vertex] = [
            Vertex.init(position: float4.init(1, -1, 0.0, 1.0), texturePos: float2.init(1, 1)),
            Vertex.init(position: float4.init(-1, -1, 0.0, 1.0), texturePos: float2.init(1, 0)),
            Vertex.init(position: float4.init(-1,  1, 0.0, 1.0), texturePos: float2.init(0, 0)),
            Vertex.init(position: float4.init(1, -1, 0.0, 1.0), texturePos: float2.init(1, 1)),
            Vertex.init(position: float4.init(-1,  1, 0.0, 1.0), texturePos: float2.init(0, 0)),
            Vertex.init(position: float4.init(1,  1, 0.0, 1.0), texturePos: float2.init(0, 1)),
            ]
        
        let buffer: MTLBuffer? = displayView.device?.makeBuffer(bytes: vertexArray, length: MemoryLayout<Vertex>.stride * 6, options: .storageModeShared)
        vertex = buffer
    }
    
    private func registerShader() {
        let pipeLineDes: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor.init()
        let library: MTLLibrary? = displayView.device?.makeDefaultLibrary()
        let vertexFunc: MTLFunction? = library?.makeFunction(name: "vertexShader")
        let fragmentFunc: MTLFunction? = library?.makeFunction(name: "fragmentShader")
        pipeLineDes.vertexFunction = vertexFunc
        pipeLineDes.fragmentFunction = fragmentFunc
        pipeLineDes.colorAttachments[0].pixelFormat = displayView.colorPixelFormat
        do {
            pipelineState = try displayView.device?.makeRenderPipelineState(descriptor: pipeLineDes)
        } catch {
            
        }
    }
    
    func registerComputePipeLineState() {
        let library: MTLLibrary? = displayView.device?.makeDefaultLibrary()
        let computeFunc: MTLFunction? = library?.makeFunction(name: "kernel_function")
        
        guard let computeFunction = computeFunc else {
            return
        }
        
        computePipeLineState = try! displayView.device?.makeComputePipelineState(function: computeFunction)
    }
}



// MARK: - Public
extension CameraManager {
    func startCapture(withFrontCamera: Bool) {
        switchDevice(withFrontCamera: true)
        if cameraSession.canAddOutput(cameraDataOutput) {
            cameraDataOutput.setSampleBufferDelegate(self, queue: processQueue)
            cameraSession.addOutput(cameraDataOutput)
        }
        cameraSession.startRunning()
    }
    
    func switchDevice(withFrontCamera: Bool) {
        let devicePostion: AVCaptureDevice.Position = withFrontCamera == true ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        
        guard cameraDevice?.position != devicePostion, let device: AVCaptureDevice = cameraDeviceWithPosition(devicePostion) else {
            return
        }
        
        do {
            let tmpDeviceInput: AVCaptureDeviceInput = try AVCaptureDeviceInput.init(device: device)
            cameraSession.beginConfiguration()
            
            if deviceInput != nil {
                cameraSession.removeInput(deviceInput!)
            }
            guard cameraSession.canAddInput(tmpDeviceInput) else {
                return
            }
            cameraSession.addInput(tmpDeviceInput)
            cameraSession.commitConfiguration()
            deviceInput = tmpDeviceInput
        } catch {
            
        }
    }
    
    func configDisplayView(_ view: UIView) {
        displayView.delegate = self
        displayView.frame = view.bounds
        view.insertSubview(displayView, at: 0)
    }
    
    
    func filter(_ type: FilterType) {
        switch type {
        case .Original:
            computePipeLineState = nil
            break
        default:
            let library: MTLLibrary? = displayView.device?.makeDefaultLibrary()
            let computeFunc: MTLFunction? = library?.makeFunction(name: type.rawValue)
            guard let computeFunction = computeFunc else {
                return
            }
            computePipeLineState = try! displayView.device?.makeComputePipelineState(function: computeFunction)
            break
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let width: size_t = CVPixelBufferGetWidth(pixelBuffer)
        let height: size_t = CVPixelBufferGetHeight(pixelBuffer)
  
        var metalTexutreRef: CVMetalTexture?
    
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        let status: CVReturn = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, MTLPixelFormat.bgra8Unorm, width, height, 0, &metalTexutreRef)

        if status == kCVReturnSuccess, let textureRef = metalTexutreRef {
            displayView.drawableSize = CGSize.init(width: width, height: height)
            texture = CVMetalTextureGetTexture(textureRef)
        } else {
            print("error")
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    }
}

// MARK: - MTKViewDelegate
extension CameraManager: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
        guard texture != nil, view.currentDrawable != nil else {
            return
        }
        
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let renderPassDes: MTLRenderPassDescriptor? = view.currentRenderPassDescriptor
        guard renderPassDes != nil else {
            return
        }
        
        let renderEncoder: MTLRenderCommandEncoder? = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDes!)
        renderEncoder?.setViewport(MTLViewport.init(originX: 0, originY: 0, width: Double(view.drawableSize.width), height: Double(view.drawableSize.height), znear: -1, zfar: 1))
        renderEncoder?.setRenderPipelineState(pipelineState!)
        renderEncoder?.setVertexBuffer(vertex, offset: 0, index: 0)
        renderEncoder?.setFragmentTexture(texture, index: 0)
        renderEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder?.endEncoding()
        
        // 加载kernal
        if let computePipeLineState = computePipeLineState {
            let computeEncoder: MTLComputeCommandEncoder? = commandBuffer?.makeComputeCommandEncoder()
            computeEncoder?.setComputePipelineState(computePipeLineState)
            computeEncoder?.setTexture(texture, index: 0)
            computeEncoder?.setTexture(view.currentDrawable?.texture, index: 1)
            
            
            // GPU最大并发处理量
            let w = computePipeLineState.threadExecutionWidth
            
            let h = computePipeLineState.maxTotalThreadsPerThreadgroup / w
            
            let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
            
            let threadgroupsPerGrid = MTLSize(width: (texture!.width + w - 1) / w,
                                              height: (texture!.width + h - 1) / h,
                                              depth: 1)
            
            computeEncoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            
            computeEncoder?.endEncoding()
        }
        
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }

}
