//
//  ViewController.swift
//  ScanQRCode
//
//  Created by Sreekanth Iragam Reddy on 1/3/18.
//  Copyright © 2018 Sreekanth Iragam Reddy. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    fileprivate let captureMetadataOutput = AVCaptureMetadataOutput()

    /**
     * Used for capturing QR codes with device camera
     */
    fileprivate let captureSession = AVCaptureSession()

    /**
     * DispatchQueue where delegate methods called by captureSession are executed
     */
    fileprivate let captureDispatchQueue = DispatchQueue(label: "device-code-queue")

    /**
     * The CALayer where camera output is displayed while in camera mode
     */
    fileprivate var captureLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Outlets ordered by visual occurence from top to bottom

    @IBOutlet weak var captureView: UIView!

    @IBOutlet weak var ineterestCaptureView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        ineterestCaptureView.layer.borderWidth = 5.0
        ineterestCaptureView.layer.borderColor = UIColor.red.cgColor


        let cameraAuthState = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthState {
        case .authorized: requestCameraAndStartCapturing()
        case .notDetermined: requestCameraAndStartCapturing()
        case .denied: doNothing()
        case .restricted: doNothing()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func startCapturingFrom(_ sender: Any) {


    }

    func doNothing() {

    }

    func requestCameraAndStartCapturing() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
            DispatchQueue.main.sync {
                if granted {
                    self.startCapturing()
                } else {
                    self.doNothing()
                }
            }
        }
    }

    func startCapturing() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }

        var deviceInput: AVCaptureDeviceInput? = nil
        do {
            deviceInput = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(deviceInput!)
        } catch {

        }

        //captureSession.removeInput(AVCaptureDevice.default(for: AVMediaType.audio))
        if captureSession.outputs.count < 1 {
            captureSession.addOutput(captureMetadataOutput)
        }
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: captureDispatchQueue)

        let availableMetadataObjectTypes = captureMetadataOutput.availableMetadataObjectTypes.map { $0.rawValue }
        let filteredObjectTypes = availableMetadataObjectTypes.filter({ return $0 == AVMetadataObject.ObjectType.qr.rawValue })

        guard !filteredObjectTypes.isEmpty else {
            print("No available metadata object types. If this shows up when we aren't running in simulator, this could be a problem")
            return
        }

        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        captureLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill

        captureView.layer.addSublayer(captureLayer!)
        captureSession.startRunning()
        view.setNeedsLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
         captureLayer?.frame = view.bounds
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        captureLayer?.frame = view.bounds
        if let rect = captureLayer?.metadataOutputRectConverted(fromLayerRect: ineterestCaptureView.layer.frame) {
            if rect.width > 0 && rect.height > 0 {
                captureMetadataOutput.rectOfInterest = rect
            }
        }
    }

}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
         let codeObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        print("the code value is \(String(describing: codeObject?.stringValue))")
    }


}

