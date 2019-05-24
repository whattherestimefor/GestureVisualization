//
//  ViewController.swift
//  GestureVisualization
//
//  Created by Shannon Hughes on 4/21/19.
//  Copyright © 2019 The Omni Group. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var stackView: UIStackView?

    var showTouchOnScreen = true
    var noWaitLongpress: UIGestureRecognizer?
    var touchVisualizer: TouchVisualizer?
    
    var gestureVisualizers = [GestureVisualizer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (showTouchOnScreen) {
            let touchGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(touchUpdate(gesture:)))
            touchGesture.minimumPressDuration = 0.0
            view.addGestureRecognizer(touchGesture)
            noWaitLongpress = touchGesture
        }
        
//        let gestures = doubleTapSingleTap(requireToFail: false)
//        let gestures = doubleTapSingleTap(requireToFail: true)
        let gestures = panLongPressTap()

        for (gestureName, gesture) in gestures {
            gesture.delegate = self
            view.addGestureRecognizer(gesture)
            gesture.addTarget(self, action: #selector(gestureChanged(gesture:)))
            let visualizer = GestureVisualizer.init(gesture: gesture, name: gestureName, frame: .zero)
            gestureVisualizers.append(visualizer)
            gesture.addObserver(self, forKeyPath: "state", options: [.new, .old], context: nil)  // DO NOT observe the state of a UIGestureRecognizer in a real app. See README.md
            stackView?.addArrangedSubview(visualizer)
        }
    }

    //MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        if gestureRecognizer == noWaitLongpress || otherGestureRecognizer == noWaitLongpress {
            return true   // showing touches depends on an extra gesture recognizer that isn't visualized, so gestures have to be allowed to recognize with it
        }

        // default is false
        return false
     //   return true
    }

    //MARK: Gesture Set Ups

    func doubleTapSingleTap(requireToFail: Bool) -> ([(String, UIGestureRecognizer)]) {
        let doubleTap = UITapGestureRecognizer();
        doubleTap.numberOfTapsRequired = 2;
        let singleTap = UITapGestureRecognizer();
        if requireToFail {
            singleTap.require(toFail: doubleTap)
        }

        return  [("Tap", singleTap),
                 ("Double Tap", doubleTap)]
    }

    func panLongPressTap() -> ([(String, UIGestureRecognizer)]) {
        return [("Longpress", UILongPressGestureRecognizer()),
                ("Pan", UIPanGestureRecognizer()),
              //  ("Tap", UITapGestureRecognizer())
        ]
    }

    //MARK: Update Gesture Diagrams

    @objc func gestureChanged(gesture: UIGestureRecognizer) {
        for visualizer in gestureVisualizers {
            if (gesture == visualizer.gesture) {
                visualizer.animateMessageSend()
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (_) in
            for visualizer in self.gestureVisualizers {
                visualizer.setNeedsDisplay()  // clears out state of gestures that were waiting for this one to fail
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // DO NOT observe the state of a UIGestureRecognizer in a real app. See README.md
        guard let gesture = object as? UIGestureRecognizer else { return }
        guard self.view.gestureRecognizers?.contains(gesture) ?? false else { return }
        guard keyPath == "state" else { return }

        for visualizer in gestureVisualizers {
            if visualizer.gesture == gesture {
                guard let oldStateRaw = change?[NSKeyValueChangeKey.oldKey] as? Int, let newStateRaw = change?[NSKeyValueChangeKey.newKey] as? Int else { return }
                guard let oldState = UIGestureRecognizer.State(rawValue: oldStateRaw), let newState = UIGestureRecognizer.State(rawValue: newStateRaw) else { return }
                visualizer.animate((oldState, newState))
                return
            }
        }
    }

    //MARK: Visualize Initial Touch

    let minRadius: CGFloat = 3
    let radiusGrowthDelta: CGFloat = 25
    let animationTime = 0.2

    @objc func touchUpdate(gesture: UIGestureRecognizer) {
        if gesture.state == .ended || gesture.state == .failed || gesture.state == .cancelled {
            guard let touchView = touchVisualizer else { return }
            removeTouchView(touchView: touchView)
        } else {
            // update the location
            let location = gesture.location(in: self.view)
            if let touchView = touchVisualizer {
                // we have a touch view.  update its location.
                var newFrame = touchView.frame
                newFrame.origin.x = location.x - touchView.frame.size.width/2.0
                newFrame.origin.y = location.y - touchView.frame.size.height/2.0
                touchView.frame = newFrame
            } else {
                // we have no touch view.  create one.
                let frame = CGRect(x: location.x - minRadius, y: location.y - minRadius, width: minRadius * 2, height: minRadius * 2)
                let touchVis = TouchVisualizer.init(frame: frame)
                self.view.addSubview(touchVis)
                UIView.animate(withDuration: animationTime) {
                    touchVis.frame = touchVis.frame.inset(by: UIEdgeInsets.init(top: -self.radiusGrowthDelta, left: -self.radiusGrowthDelta, bottom: -self.radiusGrowthDelta, right: -self.radiusGrowthDelta))
                }
                touchVisualizer = touchVis
            }
        }
    }

    func removeTouchView(touchView: UIView) {
        if (touchView == self.touchVisualizer) {
            self.touchVisualizer = nil
        }
        let delay = touchView.frame.size.width > radiusGrowthDelta ? 0 : animationTime
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIView.animate(withDuration: self.animationTime, animations: {
                touchView.frame = touchView.frame.inset(by: UIEdgeInsets.init(top: self.radiusGrowthDelta, left: self.radiusGrowthDelta, bottom: self.radiusGrowthDelta, right: self.radiusGrowthDelta))
            }) { (_) in
                touchView.removeFromSuperview()
            }
        }
    }

}

