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
    
    var gestureVisualizers = [GestureVisualizer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

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
                ("Tap", UITapGestureRecognizer())
        ]
    }

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

}

