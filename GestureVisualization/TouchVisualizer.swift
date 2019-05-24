//
//  TouchVisualizer.swift
//  GestureVisualization
//
//  Created by Shannon Hughes on 5/15/19.
//  Copyright © 2019 The Omni Group. All rights reserved.
//

import UIKit

class TouchVisualizer: UIView {

    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()

        // draw background
        context?.setFillColor(UIColor.white.cgColor)
        context?.fill(rect)

        // draw touch
        context?.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
        context?.fillEllipse(in: self.bounds)

        context?.restoreGState()
    }

}
