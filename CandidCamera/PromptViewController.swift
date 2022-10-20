//
//  PromptViewController.swift
//  CandidCamera
//
//  Created by June Kim on 10/20/22.
//

import UIKit

class PromptViewController: UIViewController {

  let descriptionLabel = UILabel()

  override func viewDidLoad() {
    view.backgroundColor = .black
    addDescription()
    addTitle()
    addDismissButton()
  }
  
  func addTitle() {
    let titleLabel = UILabel()
    titleLabel.text = "Candid Camera"
    titleLabel.font = .systemFont(ofSize: 28, weight: .medium)
    
    view.addSubview(titleLabel)
    
    titleLabel.centerXInParent()
    titleLabel.pinBottom(toTopOf: descriptionLabel, margin: 18)
  }
  
  func addDescription() {
    descriptionLabel.text = "This app records video without showing the preview. Responsible adults can record others without them being aware that they are being recorded. To start recording, tap on the big text at the bottom of the screen."
    view.addSubview(descriptionLabel)
    descriptionLabel.textColor = .lightGray
    descriptionLabel.font = .systemFont(ofSize: 20)
    descriptionLabel.numberOfLines = 0
    descriptionLabel.set(width: 300)
    
    descriptionLabel.centerXInParent()
    descriptionLabel.centerYInParent(offset: -40)
    
  }
  
  func addDismissButton() {
    let dismissButton = UIButton(type: .system, primaryAction: UIAction(handler: { action in
      self.dismiss(animated: true)
    }))
    dismissButton.setTitle("OK", for: .normal)
    dismissButton.setTitleColor(.white, for: .normal)
    dismissButton.titleLabel?.font = .systemFont(ofSize: 32)
    view.addSubview(dismissButton)
    
    dismissButton.centerXInParent()
    dismissButton.pinTop(toBottomOf: descriptionLabel, margin: 24)
  }
}
