//
//  GestureVisualiser.swift
//  GestureVisualization
//
//  Created by Shannon Hughes on 4/21/19.
//  Copyright © 2019 The Omni Group. All rights reserved.
//

import UIKit

class GestureVisualizer: UIView {

    public let gesture: UIGestureRecognizer
    let _name: NSAttributedString
    let _delay = 0.5

    var _drawAlternateChanged = false
    var _sentMessage = false

    var transitionsToAnimate: [(UIGestureRecognizer.State, UIGestureRecognizer.State)]?
    var timer: Timer?

    init(gesture: UIGestureRecognizer, name: String, frame: CGRect) {
        self.gesture = gesture
        _name = NSAttributedString (string: name, attributes: [ NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 20)])
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        if isVisualizingDiscreteGesture() {
            return CGSize(width: size(circleCount: 2), height: size(circleCount: 2))
        } else {
            return CGSize(width: size(circleCount: 3), height: size(circleCount: 4))
        }
    }

    public func animate(_ transition: (UIGestureRecognizer.State, UIGestureRecognizer.State)) {
        if (transitionsToAnimate == nil) {
            transitionsToAnimate = [transition]
        } else {
            transitionsToAnimate?.append(transition)
        }
        setNeedsDisplay()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: _delay, repeats: true) { (_) in
                self.transitionsToAnimate?.removeFirst()
                self.setNeedsDisplay()
                guard let remainingTransitions = self.transitionsToAnimate else { return }
                if remainingTransitions.isEmpty {
                    self.timer?.invalidate()
                    self.timer = nil
                }
            }
        }
    }

    public func animateMessageSend() {
        _sentMessage = true
        setNeedsDisplay()
        Timer.scheduledTimer(withTimeInterval: _delay * 2, repeats: true) { (timer) in
            if (self.gesture.state != .changed) {
                self._sentMessage = false
                self.setNeedsDisplay()
                timer.invalidate()
            }
        }
    }

    //MARK: State Machine Basics

    func possibleTransitions() -> [(UIGestureRecognizer.State, UIGestureRecognizer.State)] {
        if isVisualizingDiscreteGesture() {
            return [(.possible, .failed), (.possible, .recognized)]
        } else {
            return [(.possible, .failed), (.possible, .began),
                    (.began, .changed), (.began, .failed), (.began, .cancelled),
                    (.changed, .changed), (.changed, .failed), (.changed, .cancelled),
                    (.changed, .recognized)]
        }
    }

    func states() -> [UIGestureRecognizer.State] {
        if isVisualizingDiscreteGesture() {
            return [.possible, .failed, .recognized]
        } else {
            return [.possible, .began, .changed, .recognized, .failed, .cancelled];
        }
    }

    func isVisualizingDiscreteGesture() -> Bool
    {
        return gesture is UITapGestureRecognizer || gesture is UISwipeGestureRecognizer
    }

    //MARK: Drawing

    override func draw(_ rect: CGRect) {

        self._drawAlternateChanged = !self._drawAlternateChanged

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        // draw background
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(rect)
        if (_sentMessage) {
            context?.setFillColor(UIColor.blue.withAlphaComponent(0.25).cgColor)
            context?.fill(rect)
        }

        // draw titles
        _name.draw(at: CGPoint(x: 10, y: 5))

        // draw lines
        context?.setStrokeColor(UIColor.black.cgColor)
        let currentTransition = transitionsToAnimate?.first
        for (source, destination) in possibleTransitions() {
            if let (curSource, curDestination) = currentTransition, source == curSource && destination == curDestination {
                context?.setLineWidth(4)
            } else {
                context?.setLineWidth(1)
            }
            let sourcePoint = location(for: source)
            let destinationPoint = location(for: destination)
            let controlPoint = niceControlPoint(start: sourcePoint, end: destinationPoint)
            context?.move(to: sourcePoint)
            context?.addQuadCurve(to: destinationPoint, control: controlPoint)
            context?.strokePath()
        }

        // draw states
        context?.setLineWidth(1)
        for state in states()
        {
            let activeState = currentTransition?.1 ?? gesture.state
            let stateCenter = location(for: state)
            func addCirclePath() {
                context?.addArc(center: stateCenter, radius: radius, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
            }
            let drawLight = state != activeState || (!_drawAlternateChanged && state == .changed)
            let alpha: CGFloat = drawLight ? 0.25 : 1.0
            let baseColor = color(for: state)
            addCirclePath()
            if (alpha < 1) {
                context?.setFillColor(UIColor.white.cgColor)
                context?.fillPath()
            }
            addCirclePath()
            context?.setFillColor(baseColor.withAlphaComponent(alpha).cgColor)
            context?.fillPath()
            addCirclePath()
            context?.setStrokeColor(baseColor.cgColor)
            context?.strokePath()

            let stateLabel = label(for: state, active: activeState == state)
            let labelSize = stateLabel.size()
            let drawingPoint = CGPoint(x: stateCenter.x - labelSize.width/2.0, y: stateCenter.y - labelSize.height/2.0)
            stateLabel.draw(at: drawingPoint)
        }

        context?.restoreGState()

        if (gesture.state == .failed || gesture.state == .cancelled) {
            Timer.scheduledTimer(withTimeInterval: _delay, repeats: false) { (_) in
                self.setNeedsDisplay()
            }
        }
    }

    //MARK: Helpers

    func niceControlPoint(start: CGPoint, end: CGPoint) -> CGPoint {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let slope: CGFloat = deltaX/deltaY > 0 ? 1 : -1
        let midPoint = CGPoint(x: start.x + deltaX/2, y: start.y + deltaY/2)
        var transform = CGAffineTransform.identity.translatedBy(x: midPoint.x, y: midPoint.y)
        transform = transform.rotated(by: slope * CGFloat.pi/2.0)
        transform = transform.translatedBy(x: -midPoint.x, y: -midPoint.y)
        return start.applying(transform)
    }

    func color(for state: UIGestureRecognizer.State) -> UIColor {
        var baseColor: UIColor
        switch state {
        case .possible, .began, .changed:
            baseColor = .blue
        case .failed, .cancelled:
            baseColor = .red
        case .ended:
            baseColor = .green

        @unknown default:
            baseColor = .black
        }
        return baseColor
    }

    let radius = CGFloat(40)
    let padding = CGFloat(30)

    func size(circleCount: CGFloat) -> CGFloat {
        return (2*padding/*edgepadding*/ + circleCount*2*radius/*circles*/ + (circleCount - 1)*radius/*space between circles*/)
    }

    func location(for state: UIGestureRecognizer.State) -> CGPoint {
        let oneCircleOffsetFromEdge = padding + radius
        let oneCircleOffsetFromAnother = 3 * radius
        if isVisualizingDiscreteGesture() {
            switch state {
            case .possible:
                return CGPoint(x: size(circleCount: 2)/2.0, y: oneCircleOffsetFromEdge)

            case .failed:
                return CGPoint(x: padding + radius, y: size(circleCount: 2) - oneCircleOffsetFromEdge)
            case .ended:
                return CGPoint(x: size(circleCount: 2) - oneCircleOffsetFromEdge, y: size(circleCount: 2) - oneCircleOffsetFromEdge)

            default:
                return .zero
            }
        } else {
            switch state {
            case .possible:
                return CGPoint(x: oneCircleOffsetFromEdge + radius, y: oneCircleOffsetFromEdge)

            case .failed:
                return CGPoint(x: oneCircleOffsetFromEdge, y: oneCircleOffsetFromEdge + oneCircleOffsetFromAnother)
            case .began:
                return CGPoint(x: oneCircleOffsetFromEdge + oneCircleOffsetFromAnother, y: oneCircleOffsetFromEdge + oneCircleOffsetFromAnother)
            case .cancelled:
                return CGPoint(x: oneCircleOffsetFromEdge + 2*oneCircleOffsetFromAnother, y: oneCircleOffsetFromEdge + oneCircleOffsetFromAnother)

            case .changed:
                return CGPoint(x: oneCircleOffsetFromEdge + 1.25*oneCircleOffsetFromAnother, y: oneCircleOffsetFromEdge + 2*oneCircleOffsetFromAnother)

            case .ended:
                return CGPoint(x: oneCircleOffsetFromEdge + 1.5*oneCircleOffsetFromAnother, y: oneCircleOffsetFromEdge + 3*oneCircleOffsetFromAnother)

            default:
                return .zero
            }
        }
    }

    func label(for state: UIGestureRecognizer.State, active: Bool) -> NSAttributedString {
        let title: String
        switch state {
        case .possible:
            title = "possible"
        case .began:
            title = "began"
        case .changed:
            title = "changed"
        case .ended:
            title = "ended"
        case .failed:
            title = "failed"
        case .cancelled:
            title = "cancelled"
        default:
            title = "unknown"
        }
        let color = active ? UIColor.white : UIColor.black
        return NSAttributedString.init(string: title, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 12), NSAttributedString.Key.foregroundColor : color])
    }
}
