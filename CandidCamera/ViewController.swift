//
//  ViewController.swift
//  CandidCamera
//
//  Created by June Kim on 10/19/22.
//

import UIKit
import NextLevel
import AVFoundation
import PhotosUI

enum SessionState {
  case unknown
  case standby
  case recording
}

class ViewController: UIViewController {
  let sessionController = NextLevelSessionController()
  var state: SessionState = .unknown {
    didSet {
    }
  }
  
  let stateButton = UIButton()
  let zoomLabel = UILabel()
  let flipLabel = UILabel()


  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    addStateButton()
    addControlButtons()
    
    NextLevel.shared.delegate = self
    NextLevel.shared.videoDelegate = self
    NextLevel.shared.deviceDelegate = self
    sessionController.configureCaptureSession()

    // Do any additional setup after loading the view.
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sessionController.tryStartingRecordingSession(presenter: self) {
      self.state = .standby
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    showPrompt()
  }
  
  func showPrompt() {
    let promptVC = PromptViewController()
    present(promptVC, animated: true)
  }
  
  func addStateButton() {
    view.addSubview(stateButton)
    stateButton.centerXInParent()
    stateButton.pinBottomToParent(margin: 12, insideSafeArea: true)
    stateButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
    stateButton.setTitleColor(.lightGray, for: .normal)
    stateButton.setTitle("", for: .normal)
    stateButton.addTarget(self, action: #selector(stateButtonTapped), for: .touchUpInside)
  }
  
  func addControlButtons() {
    let buttonStack = UIStackView()
    buttonStack.axis = .vertical
    buttonStack.alignment = .center
    buttonStack.distribution = .equalSpacing
    buttonStack.spacing = 32
    view.addSubview(buttonStack)

    buttonStack.backgroundColor = .lightGray.withAlphaComponent(0.1)
    buttonStack.pinLeadingToParent()
    buttonStack.pinTrailingToParent()
    buttonStack.centerYInParent()

    let zoomRow = UIStackView()
    zoomRow.axis = .horizontal
    zoomRow.distribution = .fillProportionally
    zoomRow.alignment = .fill
    buttonStack.addArrangedSubview(zoomRow)
    zoomRow.fillWidthOfParent()

    let zoomOutButton = UIButton(type: .system, primaryAction: UIAction(handler: { action in
      print("zoom out: " + String(NextLevel.shared.videoZoomFactor))
      NextLevel.shared.videoZoomFactor = NextLevel.shared.videoZoomFactor - 0.1
    }))
    zoomOutButton.setTitle("Zoom Out", for: .normal)
    zoomOutButton.setTitleColor(.lightGray, for: .normal)
    zoomRow.addArrangedSubview(zoomOutButton)
 
    let zoomInButton = UIButton(type: .system, primaryAction: UIAction(handler: { action in
      print("zoom in")
      NextLevel.shared.videoZoomFactor += 0.1
    }))
    zoomInButton.setTitle("Zoom In", for: .normal)
    zoomInButton.setTitleColor(.lightGray, for: .normal)
    zoomRow.addArrangedSubview(zoomInButton)
    
    zoomLabel.textColor = .darkGray
    zoomLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
    zoomRow.addArrangedSubview(zoomLabel)
    zoomLabel.text = "1x"

    let flipRow = UIStackView()
    flipRow.axis = .horizontal
    flipRow.distribution = .fillProportionally
    buttonStack.addArrangedSubview(flipRow)
    flipRow.fillWidthOfParent()
    
    let flipButton = UIButton(type: .system, primaryAction: UIAction(handler: { action in
      print("flip camera")
      NextLevel.shared.flipCaptureDevicePosition()
    }))
    flipButton.setTitle("Flip camera", for: .normal)
    flipButton.setTitleColor(.lightGray, for: .normal)
    flipRow.addArrangedSubview(flipButton)

    flipLabel.textColor = .darkGray
    flipLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
    flipRow.addArrangedSubview(flipLabel)
    flipLabel.text = "Back"


  }
  
  @objc func stateButtonTapped() {
    switch state {
    case .unknown:
      print("noop")
    case .standby:
      NextLevel.shared.record()
      NextLevel.shared.automaticallyUpdatesDeviceOrientation = true
    case .recording:
      NextLevel.shared.pause()
      NextLevel.shared.automaticallyUpdatesDeviceOrientation = false
    }
  }
  
  func showExportAlert() {
    let alertController = UIAlertController(title: "Export failed", message: "I'm not quite sure why but it didn't work for some reason. Maybe you can tell me in the chat?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
      self.reset()
    }))
    present(alertController, animated: true)
  }
  
  func showPreSaveAlert() {
    let alertController = UIAlertController(title: "Save video?", message: "You can either save the video now or record more.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Not yet", style: .cancel))
    alertController.addAction(UIAlertAction(title: "Save", style: .default) { action in
      self.export()
    })
    present(alertController, animated: true)
  }
  
  func showPostSaveAlert() {
    let alertController = UIAlertController(title: "Video saved", message: "Go to your photos app to watch the video", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
    present(alertController, animated: true)
  }
  
  func export() {
    guard let session = NextLevel.shared.session else { return }
    session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
      if let url = url {
        self.sessionController.saveVideoToAlbum(url) { [weak self] err in
          guard let self = self else { return }
          guard err == nil else {
            self.showExportAlert()
            return
          }
          self.showPostSaveAlert()
        }
        self.reset()
      } else if let _ = error {
        self.showExportAlert()
      }
    })
  }
  
  func reset() {
    if let session = NextLevel.shared.session {
      session.removeAllClips()
    }
  }

}

extension ViewController: NextLevelDelegate, NextLevelVideoDelegate, NextLevelDeviceDelegate {
  func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
    switch nextLevel.devicePosition {
    case .back:
      flipLabel.text = "Back"
      zoomLabel.text = "1.0x"
    case .front:
      flipLabel.text = "Front"
      zoomLabel.text = "1.0x"
    case .unspecified:
      flipLabel.text = "Unspecified"
    default:
      flipLabel.text = "Unknown"
    }
  }
  
  func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didChangeDeviceFormat deviceFormat: AVCaptureDevice.Format) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
    
  }
  
  func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelDidStopFocus(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didChangeLensPosition videoZoomFactor: Float) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    zoomLabel.text = String(format: "%.1f", videoZoomFactor) + "x"
  }
  
  func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
    stateButton.setTitle("Recording", for: .normal)
    stateButton.setTitleColor(.systemRed.withAlphaComponent(0.5), for: .normal)
    state = .recording
  }
  
  func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    stateButton.setTitle("Standby", for: .normal)
    stateButton.setTitleColor(.lightGray, for: .normal)
    self.export()
    state = .standby

  }
  
  func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
    
  }
  
  func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
      
  }
  
  func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
      
  }
  
  func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
    stateButton.setTitle("Standby", for: .normal)
  }
  
  func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    
  }
  
  func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    
  }
  
  
}
