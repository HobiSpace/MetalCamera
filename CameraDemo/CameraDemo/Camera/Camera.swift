//
//  Camera.swift
//  CameraDemo
//
//  Created by hebi on 2018/10/25.
//  Copyright © 2018年 Hobi. All rights reserved.
//

import UIKit
import AVFoundation

class Camera: NSObject {
    private lazy var cameraSession: AVCaptureSession = makeCameraSession()
    private lazy var cameraFrontDevice: AVCaptureDevice? = cameraDeviceWithPosition(.front)
    private lazy var cameraBackDevice: AVCaptureDevice? = cameraDeviceWithPosition(.back)
    private lazy var cameraDataOutput: AVCaptureVideoDataOutput = makeCameraVideoDataOutput()
    
    private lazy var processQueue: DispatchQueue = makeProcessQueue()
    
    var render: MetalRender?
    
    override init() {
        super.init()
    }
}

// MARK: - Public
extension Camera {
    func startCapture() {
        guard let device = cameraFrontDevice, let deviceInput = try? AVCaptureDeviceInput.init(device: device), cameraSession.canAddInput(deviceInput), cameraSession.canAddOutput(cameraDataOutput) else {
            return
        }
        
        cameraSession.addInput(deviceInput)
        cameraDataOutput.setSampleBufferDelegate(self, queue: processQueue)
        cameraSession.addOutput(cameraDataOutput)
        let connection = cameraDataOutput.connection(with: .video)
        connection?.videoOrientation = .portrait
        cameraSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        cameraSession.startRunning()
    }
    
    func addRender(render: MetalRender) {
        self.render = render
    }
    
    func removeRender(render: MetalRender) {
        self.render = nil
    }
}

// MARK: - Make
extension Camera {
    private func makeCameraSession() -> AVCaptureSession {
        let session = AVCaptureSession.init()
        return session
    }
    
    private func makeCameraVideoDataOutput() -> AVCaptureVideoDataOutput {
        let dataOutput = AVCaptureVideoDataOutput.init()
        dataOutput.alwaysDiscardsLateVideoFrames = false
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        return dataOutput
    }
    
    private func cameraDeviceWithPosition(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        let devicesSession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: position)
        
        for device in devicesSession.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    private func makeProcessQueue() -> DispatchQueue {
        let queue: DispatchQueue = DispatchQueue.init(label: "com.hobi.data")
        return queue
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let render = render, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        render.render(pixelBuffer: pixelBuffer)
    }
}
