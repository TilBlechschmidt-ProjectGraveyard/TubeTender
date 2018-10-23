//
//  PlayerView.swift
//  Pivo
//
//  Created by Til Blechschmidt on 10.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import AVKit
import AVFoundation

class PlayerView: UIView, VLCMediaPlayerDelegate {

    var _streamManager: StreamManager!
    var streamManager: StreamManager! {
        get {
            return _streamManager
        }
        set {
            mediaPlayer.stop()

            DispatchQueue.main.async {
                // We replace the media so make sure the button disappears and the loader starts.
                self.playButton.select(animate: false)
                self.playButton.isHidden = true
                self.loadingIndicator.startAnimating()
            }

            _streamManager = newValue

            let bestSource = streamManager.bestAvailableSource()

            if let videoSource = bestSource.video {
                // TODO Handle this URL being invalid
                let videoURL = URL(string: videoSource.url)!
                mediaPlayer.media = VLCMedia(url: videoURL)
            }

            if let audioSource = bestSource.audio {
                // TODO Handle this URL being invalid
                let audioURL = URL(string: audioSource.url)!
                mediaPlayer.addPlaybackSlave(audioURL, type: .audio, enforce: true)
            }

            mediaPlayer.play()
        }
    }

    var idleTimer: Timer?
    var mediaPlayer: VLCMediaPlayer = VLCMediaPlayer()

    var previousState: VLCMediaPlayerState = .stopped
    var videoIsPlaying = false

    var loadingIndicator: UIActivityIndicatorView!
    var controlView: UIView!
    var playButton: PlayButton!
    var elapsedTime: UILabel!
    var durationLabel: UILabel!
    var progressBar: UIProgressView!
    var seekingSlider: UISlider!

    var fullscreenConstraints: [NSLayoutConstraint] = []
    var regularConstraints: [NSLayoutConstraint] = []

    var zoomToFillConstraint: NSLayoutConstraint!
    var zoomToFitConstraint: NSLayoutConstraint!

    var controlsVisible: Bool {
        get {
            return self.controlView.alpha == 1
        }
        set {
            UIView.animate(withDuration: 0.4, animations: {
                self.controlView.alpha = newValue ? 1.0 : 0.0
                return
            })
        }
    }

    fileprivate var _isFullscreen = false
    var isFullscreen: Bool {
        get {
            return _isFullscreen
        }
        set {
            // Update the constraints (in the right order)
            if newValue {
                regularConstraints.forEach { $0.isActive = false }
                fullscreenConstraints.forEach { $0.isActive = true }
            } else {
                fullscreenConstraints.forEach { $0.isActive = false }
                regularConstraints.forEach { $0.isActive = true }
            }
            // Set the new value
            _isFullscreen = newValue
            // Hide/show the progress bar
            UIView.animate(withDuration: 0.4, animations: {
                self.progressBar.alpha = newValue ? 0.0 : 1.0
            })
        }
    }

    @objc func applicationWillResignActive(notification: NSNotification) {
        mediaPlayer.pause()
        controlsVisible = true
        videoIsPlaying = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Pause the video if the app goes to background
        let app = UIApplication.shared
        NotificationCenter.default.addObserver(self, selector: #selector(PlayerView.applicationWillResignActive(notification:)), name: UIApplication.willEnterForegroundNotification, object: app)

        self.backgroundColor = UIColor.black

        // Add a view for the video
        let movieView = UIView()
        addSubview(movieView)
        movieView.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            movieView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            movieView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            movieView.widthAnchor.constraint(equalTo: self.widthAnchor)
        ])
        zoomToFitConstraint = movieView.heightAnchor.constraint(equalTo: self.heightAnchor)
        zoomToFillConstraint = movieView.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5625)

        // TODO Pass this as a parameter
        zoomToFitConstraint.isActive = true


        // Setup progress indicator
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
        playButton.addTarget(self, action: #selector(PlayerView.playButtonTapped(sender:)), for: .touchUpInside)
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
            elapsedTime.leftAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.leftAnchor),
            elapsedTime.bottomAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.bottomAnchor)
        ])
        regularConstraints.append(contentsOf: [
            elapsedTime.leftAnchor.constraint(equalTo: controlView.leftAnchor, constant: 10),
            elapsedTime.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),
        ])

        durationLabel = UILabel()
        timeLabelSetup(label: durationLabel)
        controlView.addSubview(durationLabel)
        fullscreenConstraints.append(contentsOf: [
            durationLabel.rightAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.rightAnchor),
            durationLabel.bottomAnchor.constraint(equalTo: controlView.safeAreaLayoutGuide.bottomAnchor)
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
        seekingSlider.addTarget(self, action: #selector(PlayerView.seeked(sender:)), for: .touchDragInside)
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

        // Add tap gesture to prevent hiding the view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(PlayerView.viewTapped))
        interactionView.addGestureRecognizer(tapGesture)
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(PlayerView.viewDoubleTapped(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        interactionView.addGestureRecognizer(doubleTapGesture)

        // Add pinch gesture recognizer to zoom in the video
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(PlayerView.pinched(sender:)))
        interactionView.addGestureRecognizer(pinchGesture)

        // Activate the regular constraints
        regularConstraints.forEach { $0.isActive = true }

        // Setup the media player
        self.mediaPlayer.delegate = self
        self.mediaPlayer.drawable = movieView
    }

    private func image(with path: UIBezierPath, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.red.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    private func timeLabelSetup(label: UILabel) {
        label.numberOfLines = 1
        label.font = label.font.withSize(10)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    @objc func pinched(sender: UIPinchGestureRecognizer) {
        if sender.scale > 1.25 {
            zoomToFitConstraint.isActive = false
            zoomToFillConstraint.isActive = true
        } else if sender.scale < 0.75 {
            zoomToFillConstraint.isActive = false
            zoomToFitConstraint.isActive = true
        }

        //        UIView.animate(withDuration: 0.5) {
        //            self.layoutIfNeeded()
        //        }
    }

    @objc func playButtonTapped(sender: PlayButton) {
        self.viewTapped()
        if sender.isSelected {
            mediaPlayer.play()
        } else {
            mediaPlayer.pause()

        }
    }

    @objc func seeked(sender: UISlider) {
        if let media = mediaPlayer.media {
            let targetTime = media.length * sender.value
            elapsedTime.text = targetTime.stringValue
            mediaPlayer.time = targetTime
        }

        refreshControlHideTimer()
    }

    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let currentState: VLCMediaPlayerState  = mediaPlayer.state;

        // Handle state transitions for states that only make sense when combined
        if previousState == .buffering && currentState == .esAdded {
            // File was added thus we are currently loading
            playButton.select(animate: false)
            playButton.isHidden = true
            setNeedsDisplay(playButton.frame)
            loadingIndicator.startAnimating()

            videoIsPlaying = true
            refreshControlHideTimer()
        } else if previousState == .esAdded && currentState == .buffering {
            // File was loaded and we are buffering -> playing right now
            loadingIndicator.stopAnimating()
            playButton.deselect(animate: false)
            setNeedsDisplay(playButton.frame)
            playButton.isHidden = false

            videoIsPlaying = true
        }

        // Handle specific states that can appear by themselves
        switch(currentState) {
        case .ended:
            playButton.select()
            videoIsPlaying = false
        case .stopped:
            playButton.select()
            videoIsPlaying = false
        case .paused:
            playButton.select()
            videoIsPlaying = false
        case .playing:
            playButton.deselect()
            videoIsPlaying = true
        default:
            break;
        }

        previousState = currentState
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        progressBar.setProgress(mediaPlayer.position, animated: true)
        elapsedTime.text = mediaPlayer.time?.stringValue
        durationLabel.text = mediaPlayer.media?.length.stringValue

        if !seekingSlider.isTracking {
            seekingSlider.setValue(mediaPlayer.position, animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshControlHideTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(PlayerView.idleTimerExceeded), userInfo: nil, repeats: false)
    }

    @objc func viewTapped() {
        refreshControlHideTimer()
        if !controlsVisible {
            controlsVisible = true
        }
    }

    @objc func idleTimerExceeded(_ sender: Timer) {
        if seekingSlider.isTracking {
            refreshControlHideTimer()
        } else if videoIsPlaying {
            controlsVisible = false
        }
    }

    @objc func viewDoubleTapped(_ sender: UITapGestureRecognizer) {
        // TODO Implement exponential growth after a few steps
        let tapPoint = sender.location(in: self)
        if tapPoint.x > self.bounds.width / 2 {
            mediaPlayer.jumpForward(10)
        } else {
            mediaPlayer.jumpBackward(10)
        }
    }
}

