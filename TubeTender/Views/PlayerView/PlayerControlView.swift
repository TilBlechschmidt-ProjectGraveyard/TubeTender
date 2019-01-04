//
//  PlayerViewControls.swift
//  Pivo
//
//  Created by Til Blechschmidt on 13.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import AVKit

class PlayerControlView: UIView {
    private(set) var controlView: UIView!
    private(set) var loadingIndicator: UIActivityIndicatorView!
    private(set) var playButton: PlayButton!

    // MARK: Labels
    private(set) var elapsedTime: UILabel!
    private(set) var durationLabel: UILabel!

    // MARK: Video progress
    private(set) var progressBar: UIProgressView!
    private(set) var seekingSlider: UISlider!

    // MARK: Context controls (PiP, Fullscreen, Quality, Queue)
    private(set) var topLeftControlView: UIView!
    private(set) var topRightControlView: UIView!
    private(set) var pictureInPictureButton: UIButton!
    private(set) var fullscreenButton: UIButton!

    // MARK: Constraint sets
    private(set) var fullscreenConstraints: [NSLayoutConstraint] = []
    private(set) var regularConstraints: [NSLayoutConstraint] = []

    var isFullscreenActive: Bool = false {
        didSet {
            if isFullscreenActive {
                regularConstraints.forEach { $0.isActive = false }
                fullscreenConstraints.forEach { $0.isActive = true }
                fullscreenButton.setImage(UIImage(named: "compact"), for: .normal)
            } else {
                fullscreenConstraints.forEach { $0.isActive = false }
                regularConstraints.forEach { $0.isActive = true }
                fullscreenButton.setImage(UIImage(named: "enlarge"), for: .normal)
            }

            // Hide/show the progress bar
            UIView.animate(withDuration: 0.4, animations: {
                self.layoutIfNeeded()
                self.progressBar.alpha = self.isFullscreenActive ? 0.0 : 1.0
            })
        }
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add activity indicator
        loadingIndicator = UIActivityIndicatorView(frame: self.bounds)
        loadingIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(loadingIndicator)
        loadingIndicator.isUserInteractionEnabled = false
        loadingIndicator.hidesWhenStopped = true

        // Create a view to recognize any taps on the view
        let interactionView = UIView()
        addSubview(interactionView)
        interactionView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            interactionView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            interactionView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            interactionView.widthAnchor.constraint(equalTo: self.widthAnchor),
            interactionView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])

        // Add video progress bar
        progressBar = UIProgressView()
        progressBar.progressTintColor = UIColor.red
        interactionView.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            progressBar.bottomAnchor.constraint(equalTo: interactionView.bottomAnchor),
            progressBar.leftAnchor.constraint(equalTo: interactionView.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: interactionView.rightAnchor)
        ])

        // Create view for video controls
        controlView = UIView()
        interactionView.addSubview(controlView)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            controlView.centerXAnchor.constraint(equalTo: interactionView.centerXAnchor),
            controlView.centerYAnchor.constraint(equalTo: interactionView.centerYAnchor),
            controlView.widthAnchor.constraint(equalTo: interactionView.widthAnchor),
            controlView.heightAnchor.constraint(equalTo: interactionView.heightAnchor)
        ])

        // Add play/pause button
        playButton = PlayButton(frame: CGRect(x: 0, y: 0, width: 33, height: 33))
        controlView.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            playButton.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: controlView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 35),
            playButton.heightAnchor.constraint(equalToConstant: 35)
        ])

        // Add the elapsed and remaining time
        elapsedTime = UILabel()
        timeLabelSetup(label: elapsedTime)
        controlView.addSubview(elapsedTime)
        fullscreenConstraints.append(contentsOf: [
            elapsedTime.leftAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.leftAnchor, constant: 25),
            elapsedTime.bottomAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.bottomAnchor, constant: -25)
        ])
        regularConstraints.append(contentsOf: [
            elapsedTime.leftAnchor.constraint(equalTo: controlView.leftAnchor, constant: 10),
            elapsedTime.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),
        ])

        durationLabel = UILabel()
        timeLabelSetup(label: durationLabel)
        controlView.addSubview(durationLabel)
        fullscreenConstraints.append(contentsOf: [
            durationLabel.rightAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.rightAnchor, constant: -25),
            durationLabel.bottomAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.bottomAnchor, constant: -25)
        ])
        regularConstraints.append(contentsOf: [
            durationLabel.rightAnchor.constraint(equalTo: controlView.rightAnchor, constant: -10),
            durationLabel.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),
        ])

        // Add a slider for seeking
        let thumbImage = image(with: UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 10, height: 10), cornerRadius: 100), size: CGSize(width: 10, height: 10))
        seekingSlider = UISlider()
        seekingSlider.thumbTintColor = UIColor.red
        seekingSlider.minimumTrackTintColor = UIColor.red
        seekingSlider.setThumbImage(thumbImage!, for: .normal)
        seekingSlider.setThumbImage(thumbImage!, for: .highlighted)
        seekingSlider.translatesAutoresizingMaskIntoConstraints = false
        controlView.addSubview(seekingSlider)
        fullscreenConstraints.append(contentsOf: [
            seekingSlider.leftAnchor.constraint(equalTo: elapsedTime.rightAnchor, constant: 10),
            seekingSlider.rightAnchor.constraint(equalTo: durationLabel.leftAnchor, constant: -10),
            seekingSlider.centerYAnchor.constraint(equalTo: elapsedTime.centerYAnchor)
        ])
        regularConstraints.append(contentsOf: [
            seekingSlider.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor, constant: -0.5),
            seekingSlider.widthAnchor.constraint(equalTo: progressBar.widthAnchor)
        ])

        // Add top left/right control views
        topLeftControlView = UIView()
        topLeftControlView.translatesAutoresizingMaskIntoConstraints = false
        controlView.addSubview(topLeftControlView)
        addConstraints([
            topLeftControlView.topAnchor.constraint(equalTo: controlView.topAnchor, constant: 10),
            topLeftControlView.leftAnchor.constraint(equalTo: controlView.leftAnchor, constant: 10)
        ])

        // Add blur to TLCV
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = topLeftControlView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.clipsToBounds = true
        blurEffectView.layer.cornerRadius = 10
        topLeftControlView.layer.cornerRadius = 10
        topLeftControlView.addSubview(blurEffectView)
        topLeftControlView.sendSubviewToBack(blurEffectView)

        // Fill in TLCV
        pictureInPictureButton = UIButton(type: .roundedRect)
        pictureInPictureButton.setImage(
            AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil),
            for: .normal
        )
        pictureInPictureButton.tintColor = UIColor.white
        pictureInPictureButton.translatesAutoresizingMaskIntoConstraints = false

        let pipSupported = AVPictureInPictureController.isPictureInPictureSupported()
        if pipSupported {
            topLeftControlView.addSubview(pictureInPictureButton)
            addConstraints([
                pictureInPictureButton.topAnchor.constraint(equalTo: topLeftControlView.topAnchor, constant: 10),
                pictureInPictureButton.bottomAnchor.constraint(equalTo: topLeftControlView.bottomAnchor, constant: -10),
                pictureInPictureButton.leftAnchor.constraint(equalTo: topLeftControlView.leftAnchor, constant: 10)
            ])
        }

        let fullscreenButtonLeftAnchor = pipSupported ? pictureInPictureButton.rightAnchor : topLeftControlView.leftAnchor
        fullscreenButton = UIButton(type: .roundedRect)
        fullscreenButton.setImage(UIImage(named: "enlarge"), for: .normal)
        fullscreenButton.tintColor = UIColor.white
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        topLeftControlView.addSubview(fullscreenButton)
        addConstraints([
            fullscreenButton.topAnchor.constraint(equalTo: topLeftControlView.topAnchor, constant: 10),
            fullscreenButton.bottomAnchor.constraint(equalTo: topLeftControlView.bottomAnchor, constant: -10),
            fullscreenButton.leftAnchor.constraint(equalTo: fullscreenButtonLeftAnchor, constant: 10),
            fullscreenButton.rightAnchor.constraint(equalTo: topLeftControlView.rightAnchor, constant: -10),
            fullscreenButton.heightAnchor.constraint(lessThanOrEqualToConstant: 22),
            fullscreenButton.widthAnchor.constraint(equalTo: fullscreenButton.heightAnchor)
        ])

        // Activate the regular constraints
        regularConstraints.forEach { $0.isActive = true }

        // Random experiments with blurs
//        let testBlurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
//        let testBlurEffectView = UIVisualEffectView(effect: testBlurEffect)
//        testBlurEffectView.frame = controlView.bounds
//        testBlurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        testBlurEffectView.isUserInteractionEnabled = false
//        testBlurEffectView.clipsToBounds = true
//        controlView.addSubview(testBlurEffectView)
//        controlView.sendSubviewToBack(testBlurEffectView)
//
//        let gradient = CAGradientLayer()
//        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor]
//        gradient.locations = [0, 0.1, 0.9, 1]
//        gradient.frame = blurEffectView.bounds
//        blurEffectView.layer.mask = gradient
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func timeLabelSetup(label: UILabel) {
        label.numberOfLines = 1
        label.font = label.font.withSize(10)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "--:--"
    }

    private func image(with path: UIBezierPath, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.red.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
