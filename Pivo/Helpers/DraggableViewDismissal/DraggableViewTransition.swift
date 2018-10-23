//
//  DraggableViewTransition.swift
//  Pivo
//
//  Created by Til Blechschmidt on 18.10.18.
//  Copyright © 2018 Til Blechschmidt. All rights reserved.
//

import Foundation

class DraggableViewTransition: NSObject, UIViewControllerTransitioningDelegate {
    let interactor = Interactor()

    func createVideoDetailViewController(withID videoID: String) -> VideoDetailViewController {
        let videoDetailController = VideoDetailViewController()
        videoDetailController.videoID = videoID
        videoDetailController.interactor = interactor
        videoDetailController.transitioningDelegate = self
        return videoDetailController
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
