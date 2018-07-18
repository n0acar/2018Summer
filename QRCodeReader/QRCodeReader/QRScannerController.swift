//
//  QRScannerController.swift
//  QRCodeReader
//
//  Created by Simon Ng on 13/10/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion


class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var messageLabel:UILabel!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var faceCodeFrameView:UIView?
    var motionManager = CMMotionManager()
    var isPhotoTaken = false
    var isDeviceUp = false
    var isFaceInTheCenter = false
    var screenWidth = UIScreen.main.bounds.width
    var screenHeight = UIScreen.main.bounds.height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue(), withHandler: handleMoves)

        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [ .face]

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession.startRunning()
            
            view.bringSubview(toFront: messageLabel)
            
            faceCodeFrameView = UIView()
            
            if let faceCodeFrameView = faceCodeFrameView {
                faceCodeFrameView.layer.borderColor = UIColor.green.cgColor
                faceCodeFrameView.layer.borderWidth = 2
                view.addSubview(faceCodeFrameView)
                view.bringSubview(toFront: faceCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        // Do any additional setup after loading the view.
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            faceCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No Face is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0]

        if metadataObj.type == AVMetadataObject.ObjectType.face {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds

            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            faceCodeFrameView?.frame = barCodeObject!.bounds
            
            print(screenWidth)
            print(screenHeight)
            print(barCodeObject!.bounds.origin.x + barCodeObject!.bounds.width)
            print(barCodeObject!.bounds.origin.y + barCodeObject!.bounds.height)
            
            isFaceInTheCenter = ((screenWidth < barCodeObject!.bounds.origin.x + barCodeObject!.bounds.width + screenWidth/4  && screenWidth > barCodeObject!.bounds.origin.x + barCodeObject!.bounds.width - screenWidth/4) && (screenHeight < barCodeObject!.bounds.origin.y + barCodeObject!.bounds.height + screenHeight/4  && screenHeight > barCodeObject!.bounds.origin.y + barCodeObject!.bounds.height - screenHeight/4))
            
            if metadataObj.type == .face && isDeviceUp && !isPhotoTaken && isFaceInTheCenter{
                messageLabel.text = "found"
                self.motionManager.stopDeviceMotionUpdates()
                isPhotoTaken = true
                
            }
        }
    }
    
    func handleMoves(motion: CMDeviceMotion?, error: Error?) {
        
        if error != nil {
            print(error)
        } else {
            
            if let devicePitch = motion?.attitude.pitch {
                if(devicePitch > 1.3 && devicePitch < 1.6) {
                    isDeviceUp = true
                } else {
                    isDeviceUp = false
                }
            } else {
                isDeviceUp = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
