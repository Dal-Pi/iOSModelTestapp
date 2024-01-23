//
//  ViewController.swift
//  iOSModelTestapp
//
//  Created by Seonghan Kim on 1/19/24.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var previewView: UIView!

    let drawLayer = CALayer()

    var cameraDevice: CameraDevice?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        checkCameraPermission()
    }

    func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if granted {
                print("granted")
                self.openCamera()
            } else {
                print("not granted")
            }
        })
    }

    func openCamera() {
        let previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        DispatchQueue.main.async {
            self.previewView.layer.addSublayer(previewLayer)
            previewLayer.frame = self.previewView.bounds
            self.previewView.layer.addSublayer(self.drawLayer)
            self.drawLayer.frame = self.previewView.bounds
        }

        cameraDevice = CameraDevice(preview: previewLayer, cameraBufferDataDelegate: self)

        DispatchQueue.global().async {
            do {
                try self.cameraDevice?.openCamera(cameraType: .builtInWideAngleCamera, position: .front)
            } catch {
                print("error while opening camera")
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("error while CMSampleBufferGetImageBuffer")
            return
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer).oriented(.right)

        analyzeImage(image: ciImage)
    }

    func analyzeImage(image: CIImage) {
        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)
        let request = VNDetectFaceRectanglesRequest { requested, error in
            guard let observations = requested.results as? [VNFaceObservation] else {
                print("there is no observations")
                return
            }
            let _bestObservation = observations.max { lhs, rhs in
                lhs.confidence < rhs.confidence
            }
            guard let bestObservation = _bestObservation else {
                print("there is no bestObservation")
                return
            }

            print("bestObservation box : \(String(describing: bestObservation.boundingBox))")
            DispatchQueue.main.async {
                self.drawBoundingBox(bestObservation.boundingBox)
            }
        }
        do {
            try handler.perform([request])
        } catch {
            print("error while perform request")
        }
    }

    func drawBoundingBox(_ box: CGRect) {
        let layerWidth = drawLayer.bounds.width
        let layerHeight = drawLayer.bounds.height
        let boundingBox = CGRect(
            x: (1.0 - box.origin.x - box.width) * layerWidth,
            y: (1.0 - box.origin.y - box.height) * layerHeight,
            width: box.width * layerWidth,
            height: box.height * layerHeight
        )
        let boundingBoxLayer = getBoundingBoxLayer(boundingBox)
        drawLayer.sublayers = nil
        drawLayer.addSublayer(boundingBoxLayer)
    }

    func getBoundingBoxLayer(_ rect: CGRect) -> CALayer {
        let boxLayer = CALayer()
        boxLayer.frame = rect
        boxLayer.borderWidth = 3.0
        boxLayer.borderColor = UIColor.red.cgColor
        return boxLayer
    }
}

