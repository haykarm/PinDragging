//
//  DraggableAnnotationView.swift
//  MapBoxLine
//
//  Created by Hayk Harutyunyan on 11/2/20.
//  Copyright © 2020 Hayk Harutyunyan. All rights reserved.
//

import UIKit
import Mapbox

enum State {
    case start
    case changing
    case ended
}

protocol DraggableAnnotationViewDelegate: class {
    func draggableAnnotation(view: DraggableAnnotationView, didBecome state:State)
}

class DraggableAnnotationView: MGLAnnotationView {
    weak var delegate:DraggableAnnotationViewDelegate?
    
    init(reuseIdentifier: String, size: CGFloat) {
        super.init(reuseIdentifier: reuseIdentifier)

        // `isDraggable` is a property of MGLAnnotationView, disabled by default.
        isDraggable = true

        // This property prevents the annotation from changing size when the map is tilted.
        scalesWithViewingDistance = false

        // Begin setting up the view.
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        centerOffset = CGVector(dx: 0, dy: -size / 2)
        let imageView = UIImageView(frame: bounds)
        self.addSubview(imageView)
        imageView.image = UIImage(systemName: "mappin")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .red
    }

    // These two initializers are forced upon us by Swift.
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Custom handler for changes in the annotation’s drag state.
    override func setDragState(_ dragState: MGLAnnotationViewDragState, animated: Bool) {
        super.setDragState(dragState, animated: animated)

        switch dragState {
        case .starting:
            print("Starting", terminator: "")
            delegate?.draggableAnnotation(view: self, didBecome: .start)
            startDragging()
        case .dragging:
            print(".", terminator: "")
            delegate?.draggableAnnotation(view: self, didBecome: .changing)
        case .ending, .canceling:
            print("Ending")
            endDragging()
            delegate?.draggableAnnotation(view: self, didBecome: .ended)
        case .none:
            break
        @unknown default:
            fatalError("Unknown drag state")
        }
    }

    // When the user interacts with an annotation, animate opacity and scale changes.
    func startDragging() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 0.8
            self.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        }, completion: nil)

        // Initialize haptic feedback generator and give the user a light thud.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }
    }

    func endDragging() {
        transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: [], animations: {
            self.layer.opacity = 1
            self.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
        }, completion: nil)

        // Give the user more haptic feedback when they drop the annotation.
        if #available(iOS 10.0, *) {
            let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
            hapticFeedback.impactOccurred()
        }
    }
}
