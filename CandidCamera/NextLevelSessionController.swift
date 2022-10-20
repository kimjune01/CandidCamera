//
//  NextLevelSessionController.swift
//  CandidCamera
//
//  Created by June Kim on 10/19/22.
//

import Foundation
import NextLevel
import AVFoundation
import PhotosUI

class NextLevelSessionController {
  
  func configureCaptureSession() {
    // modify .videoConfiguration, .audioConfiguration, .photoConfiguration properties
    // Compression, resolution, and maximum recording time options are available
    NextLevel.shared.audioConfiguration.bitRate = 44000
    NextLevel.shared.videoStabilizationMode = .standard
    NextLevel.shared.automaticallyUpdatesDeviceOrientation = true

  }
  
  func requestPermissions(_ completion: @escaping (Bool) -> ()) {
    var audioGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    var videoGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    if audioGranted && videoGranted {
      completion(true)
      return
    }
    let group = DispatchGroup()
    if !audioGranted {
      group.enter()
      AVCaptureDevice.requestAccess(for: .audio){ granted in
        audioGranted = granted
        group.leave()
      }
    }
    if !videoGranted {
      group.enter()
      AVCaptureDevice.requestAccess(for: .video) { granted in
        videoGranted = granted
        group.leave()
      }
    }
    group.notify(queue: .main) {
      completion(audioGranted && videoGranted)
    }
  }
  
  func tryStartingRecordingSession(presenter: UIViewController, completion: @escaping () -> ()) {
    requestPermissions() { [weak self] granted in
      guard let self = self else { return }
      guard granted else {
        self.showPermissionRequiredAlert(presenter: presenter)
        return
      }
      DispatchQueue.global().async {
        do {
          try NextLevel.shared.changeCaptureDeviceIfAvailable(captureDevice: .tripleCamera)
        } catch {
          do {
            try NextLevel.shared.changeCaptureDeviceIfAvailable(captureDevice: .duoCamera)
          } catch {
            do {
              try NextLevel.shared.changeCaptureDeviceIfAvailable(captureDevice: .dualWideCamera)
            } catch {
              print("did not change capture device")
            }
          }
        }
        do {
          NextLevel.shared.automaticallyUpdatesDeviceOrientation = true
          try NextLevel.shared.start()
          DispatchQueue.main.async {
            completion()
          }
        } catch {
          print(error)
        }
      }
    }
  }
  
  func showPermissionRequiredAlert(presenter: UIViewController) {
    let alert = UIAlertController(title: "Need camera & microphone permission", message: "Go to the settings app to enable camera permissions for this app", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
    presenter.present(alert, animated: false)
  }
  
  func saveVideoToAlbum(_ outputURL: URL, _ completion: @escaping (Error?) -> ()) {
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetCreationRequest.forAsset()
      request.addResource(with: .video, fileURL: outputURL, options: nil)
    }) { (result, error) in
      DispatchQueue.main.async {
        if let error = error {
          print(error.localizedDescription)
        }
        completion(error)
      }
    }
  }
  
}
