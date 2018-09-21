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
    var displayView: MTKView
    var texture: MTLTexture!
    var textureCache: CVMetalTextureCache!
    
    
    lazy var commandQueue: MTLCommandQueue? = {
        return displayView.device?.makeCommandQueue()
    }()
    
    lazy var vertex: MTLBuffer? = {
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
    }()
    
    lazy var pipelineState: MTLRenderPipelineState? = {
        let pipeLineDes: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor.init()
        let library: MTLLibrary? = displayView.device?.makeDefaultLibrary()
        let vertexFunc: MTLFunction? = library?.makeFunction(name: "vertexShader")
        let fragmentFunc: MTLFunction? = library?.makeFunction(name: "fragmentShader")
        pipeLineDes.vertexFunction = vertexFunc
        pipeLineDes.fragmentFunction = fragmentFunc
        pipeLineDes.colorAttachments[0].pixelFormat = displayView.colorPixelFormat
        do {
            let renderPipeStatue = try displayView.device?.makeRenderPipelineState(descriptor: pipeLineDes)
            return renderPipeStatue
        } catch {
            return nil
        }
    }()
    
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
            return view
        }()
        
        super.init()
        
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
        
        guard cameraDevice?.position != devicePostion, let device:AVCaptureDevice = cameraDeviceWithPosition(devicePostion) else {
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
//        let displayLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: cameraSession)
//        displayLayer.frame = view.bounds
//        view.layer.addSublayer(displayLayer)
//
        
        displayView.delegate = self
        displayView.frame = view.bounds
        view.addSubview(displayView)
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
        
        let s: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, 1920, 1080, kCVPixelFormatType_32BGRA, nil, &metalTexutreRef)
        
        guard s == kCVReturnSuccess else {
            return
        }
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
        
        guard texture != nil else {
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
        commandBuffer?.present(view.currentDrawable!)
        commandBuffer?.commit()
    }

}
