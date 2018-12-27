//
//  MainViewController.swift
//  Pivo
//
//  Created by Til Blechschmidt on 17.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation
import AVKit

class MainViewController: UIViewController {
    let interactor = Interactor()
    let viewTransition = DraggableViewTransition()

    override func viewDidLoad() {
        let openVideoButton = UIButton()
        openVideoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openVideoButton)
        view.addConstraints([
            openVideoButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            openVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openVideoButton.widthAnchor.constraint(equalToConstant: 200),
            openVideoButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        openVideoButton.setTitle("Open video", for: .normal)
        openVideoButton.setTitleColor(UIColor.black, for: .normal)
        openVideoButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainViewController.openVideoTapped)))

        let subscriptionsButton = UIButton()
        subscriptionsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subscriptionsButton)
        view.addConstraints([
            subscriptionsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            subscriptionsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subscriptionsButton.widthAnchor.constraint(equalToConstant: 200),
            subscriptionsButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        subscriptionsButton.setTitle("Subscriptions", for: .normal)
        subscriptionsButton.setTitleColor(UIColor.black, for: .normal)
        subscriptionsButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainViewController.subscriptionsTapped)))

        let signInButton = UIButton()
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(signInButton)
        view.addConstraints([
            signInButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 50),
            signInButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signInButton.widthAnchor.constraint(equalToConstant: 200),
            signInButton.heightAnchor.constraint(equalToConstant: 30),
            ])
        signInButton.setTitle("Sign in", for: .normal)
        signInButton.setTitleColor(UIColor.black, for: .normal)
        signInButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MainViewController.signInTapped)))
    }

    @objc func openVideoTapped() {
        let viewController = PlayerViewController()
        let playbackManager = PlaybackManager.shared

        viewController.playbackManager = playbackManager

        playbackManager.enqueue(videoID: "1La4QzGeaaQ")
        playbackManager.enqueue(videoID: "_zeFohwlYtI")
        playbackManager.preferQuality = .hd1080

        present(viewController, animated: true) {
            playbackManager.next().startWithFailed { error in
                print("Failed: \(error)")
            }
        }
    }

    @objc func subscriptionsTapped() {
//        present(SubscriptionFeedViewController(), animated: true, completion: nil)
    }

    @objc func signInTapped() {
        present(SignInViewController(), animated: true, completion: nil)
    }

    func presentVideoDetailView(withID videoID: String) {
        present(viewTransition.createVideoDetailViewController(withID: videoID), animated: true, completion: nil)
    }
}

//extension MainViewController: UIViewControllerTransitioningDelegate {
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return DismissAnimator()
//    }
//
//    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        return interactor.hasStarted ? interactor : nil
//    }
//}
