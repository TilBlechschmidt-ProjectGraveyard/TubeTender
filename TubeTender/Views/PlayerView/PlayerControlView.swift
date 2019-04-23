//
//  PlayerViewControls.swift
//  Pivo
//
//  Created by Til Blechschmidt on 13.11.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import AVKit
import SnapKit

class PlayerControlView: UIView {
    let controlView = UIView()
    let loadingIndicator = UIActivityIndicatorView()
    let playButton = PlayButton(frame: CGRect(x: 0, y: 0, width: 35, height: 35))

    // MARK: Labels
    let elapsedTimeLabel = UILabel()
    let durationLabel = UILabel()

    // MARK: Video progress
    let progressBar = UIProgressView()
    let seekingSlider = UISlider()

    // MARK: Context controls (PiP, Fullscreen, Quality, Queue)
    private(set) var topLeftControlView: ButtonStackView!
    private(set) var pictureInPictureButton: UIButton!
    private(set) var fullscreenButton: UIButton!
    private(set) var qualityButton: UIButton!
    private(set) var topRightControlView: ButtonStackView!

    var isFullscreenActive: Bool = false {
        didSet {
            if isFullscreenActive {
                enterFullscreen()
            } else {
                exitFullscreen()
            }

            // Hide/show the progress bar
            UIView.animate(withDuration: 0.4) {
                self.layoutIfNeeded()
                self.progressBar.alpha = self.isFullscreenActive ? 0.0 : 1.0
            }
        }
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Add activity indicator
        loadingIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(loadingIndicator)
        loadingIndicator.isUserInteractionEnabled = false
        loadingIndicator.hidesWhenStopped = true

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        // Create a view to recognize any taps on the view
        let interactionView = UIView()
        addSubview(interactionView)
        interactionView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }

        // Add video progress bar
        progressBar.progressTintColor = UIColor.red
        interactionView.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }

        // Create view for video controls
        interactionView.addSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalToSuperview()
        }

        // Add play/pause button
        controlView.addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(35)
        }

        // Add the elapsed and remaining time
        timeLabelSetup(label: elapsedTimeLabel)
        controlView.addSubview(elapsedTimeLabel)

        timeLabelSetup(label: durationLabel)
        controlView.addSubview(durationLabel)

        // Add a slider for seeking
        let thumbImage = image(with: UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 10, height: 10), cornerRadius: 100), size: CGSize(width: 10, height: 10))
        seekingSlider.thumbTintColor = UIColor.red
        seekingSlider.minimumTrackTintColor = UIColor.red
        seekingSlider.setThumbImage(thumbImage!, for: .normal)
        seekingSlider.setThumbImage(thumbImage!, for: .highlighted)
        controlView.addSubview(seekingSlider)

        // Create TLCV buttons
        var tlcvButtons: [UIView] = []
        pictureInPictureButton = UIButton(type: .roundedRect)
        pictureInPictureButton.tintColor = UIColor.white
        pictureInPictureButton.setImage(
            AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: nil),
            for: .normal
        )
        if AVPictureInPictureController.isPictureInPictureSupported() {
            tlcvButtons.append(pictureInPictureButton)
        }

        fullscreenButton = UIButton(type: .roundedRect)
        fullscreenButton.tintColor = UIColor.white
        fullscreenButton.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.width.equalTo(22)
        }
        tlcvButtons.append(fullscreenButton)

        // Create TLCV
        topLeftControlView = ButtonStackView(arrangedSubviews: tlcvButtons)
        controlView.addSubview(topLeftControlView)
        topLeftControlView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.uiPadding)
            make.left.equalToSuperview().inset(Constants.uiPadding)
        }

        // Create the TRCV buttons
        qualityButton = UIButton(type: .roundedRect)
        qualityButton.setImage(UIImage(named: "automation"), for: .normal)
        qualityButton.tintColor = UIColor.white
        qualityButton.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.width.equalTo(22)
        }

        // Create TRCV
        topRightControlView = ButtonStackView(arrangedSubviews: [qualityButton])
        controlView.addSubview(topRightControlView)
        topRightControlView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Constants.uiPadding)
            make.right.equalToSuperview().inset(Constants.uiPadding)
        }

        // Activate the regular constraints
        exitFullscreen()

        // Add the blur layer to make the UI more visible
        blurView = controlView.blur(style: .dark)

        let playButtonBlack = UIColor.black.withAlphaComponent(0.25)
        playButtonGradient.colors = [playButtonBlack, playButtonBlack, UIColor.clear, UIColor.clear]

        bottomGradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        bottomGradient.locations = [0, 0.925, 1]
        bottomGradient.frame = blurView.frame

        gradientLayer.addSublayer(playButtonGradient)
        gradientLayer.addSublayer(bottomGradient)

        blurView.layer.mask = gradientLayer
    }

    private func enterFullscreen() {
        fullscreenButton.setImage(UIImage(named: "compact"), for: .normal)

        elapsedTimeLabel.snp.remakeConstraints { make in
            make.left.equalTo(controlView.safeAreaLayoutGuide).offset(25)
            make.bottom.equalTo(controlView.safeAreaLayoutGuide).offset(-25)
        }

        durationLabel.snp.remakeConstraints { make in
            make.right.equalTo(controlView.safeAreaLayoutGuide).offset(-25)
            make.bottom.equalTo(controlView.safeAreaLayoutGuide).offset(-25)
        }

        seekingSlider.snp.remakeConstraints { make in
            make.left.equalTo(elapsedTimeLabel.snp.right).offset(10)
            make.right.equalTo(durationLabel.snp.left).offset(-10)
            make.centerY.equalTo(elapsedTimeLabel)
        }

    }

    private func exitFullscreen() {
        fullscreenButton.setImage(UIImage(named: "enlarge"), for: .normal)

        elapsedTimeLabel.snp.remakeConstraints { make in
            make.left.equalTo(controlView).offset(10)
            make.bottom.equalTo(controlView).offset(-10)
        }

        durationLabel.snp.remakeConstraints { make in
            make.right.equalTo(controlView).offset(-10)
            make.bottom.equalTo(controlView).offset(-10)
        }

        seekingSlider.snp.remakeConstraints { make in
            make.centerY.equalTo(progressBar).offset(-0.5)
            make.width.equalTo(progressBar)
        }
    }

    private let gradientLayer = CALayer()
    private let playButtonGradient = RadialGradientLayer()
    private let bottomGradient = CAGradientLayer()
    private var blurView: UIVisualEffectView!

    override func layoutSubviews() {
        playButtonGradient.frame = blurView.frame
        bottomGradient.frame = blurView.frame
        gradientLayer.frame = blurView.frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func timeLabelSetup(label: UILabel) {
        label.numberOfLines = 1
        label.font = label.font.withSize(10)
        label.textAlignment = .center
        label.textColor = UIColor.white
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
