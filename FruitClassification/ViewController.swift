//
//  ViewController.swift
//  FruitClassification
//
//  Created by Hamza on 2/14/22.
//  Copyright © 2022 Hamza. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var classification: UILabel!
    
    lazy var requestClassification: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: FruitClassifier().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                self.classificationProcess(for: request , error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed To Load a Model : \(error)")
        }
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    
    func classificationProcess(for request: VNRequest, error : Error?) {
        guard let classifications = request.results as? [VNClassificationObservation] else {
            self.classification.text = "Enable to calissify.\n \(error?.localizedDescription ?? "Error")"
            return
        }
        
        if classifications.isEmpty {
            self.classification.text = "Nothing recognized. \n Please Try Other image."
        } else {
            let topClassification = classifications.prefix(2)
            let description = topClassification.map { classif in
                return String(format: "%.2f", classif.confidence * 100) + "% - " + classif.identifier
            }
            
            self.classification.text = "Classifications:\n" + description.joined(separator: "\n")
        }
    }
    
    func updateClassification(for image: UIImage) {
        classification.text = "En cours..."
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)), let ciImage = CIImage(image: image) else {
            print("Something Wrong.")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        do {
            try handler.perform([requestClassification])
        } catch {
            print("Failed \(error.localizedDescription)")
        }
        
    }
    
    
    @IBAction func addImgClicked(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            photoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSource = UIAlertController()
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { _ in
            self.photoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { _ in
            self.photoPicker(sourceType: .photoLibrary)
        }
        photoSource.addAction(takePhoto)
        photoSource.addAction(choosePhoto)
        photoSource.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSource, animated: true, completion: nil)
    }
    
    
    func photoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        img.image = image
        updateClassification(for: image)
        
    }
    
}

