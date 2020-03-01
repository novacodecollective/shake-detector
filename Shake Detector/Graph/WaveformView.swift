//
//  WaveformView.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/23/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import UIKit

@IBDesignable
class WaveformView: UIView {
    private var phase: CGFloat = 0.0

    @IBInspectable var waveColor: UIColor = .black
    @IBInspectable var numberOfWaves: Int = 5
    @IBInspectable var primaryWaveLineWidth: CGFloat = 3.0
    @IBInspectable var secondaryWaveLineWidth: CGFloat = 1.0
    @IBInspectable var idleAmplitude: CGFloat = 0.01
    @IBInspectable var frequency: CGFloat = 1.25
    @IBInspectable var density: CGFloat = 5
    @IBInspectable var phaseShift: CGFloat = -0.15
    @IBInspectable var amplitude: CGFloat = 0.3

    func updateWithLevel(_ level: CGFloat) {
        phase += phaseShift
        amplitude = max(level, idleAmplitude)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(bounds)

        backgroundColor?.set()
        context.fill(rect)

        // Draw multiple sinus waves, with equal phases but altered
        // amplitudes, multiplied by a parable function.
        for waveNumber in 0...numberOfWaves {
            context.setLineWidth((waveNumber == 0 ? primaryWaveLineWidth : secondaryWaveLineWidth))

            let halfHeight = bounds.height / 2.0
            let width = bounds.width
            let mid = width / 2.0

            let maxAmplitude = halfHeight - 4.0 // 4 corresponds to twice the stroke width
            // Progress is a value between 1.0 and -0.5, determined by the current wave idx,
            // which is used to alter the wave's amplitude.
            let progress: CGFloat = 1.0 - CGFloat(waveNumber) / CGFloat(numberOfWaves)
            let normedAmplitude = (1.5 * progress - 0.5) * amplitude

            let multiplier: CGFloat = 1.0
            waveColor.withAlphaComponent(multiplier * waveColor.cgColor.alpha).set()

            var x: CGFloat = 0.0
            while x < width + density {
                // Use a parable to scale the sinus wave, that has its peak in the middle of the view.
                let scaling = -pow(1 / mid * (x - mid), 2) + 1
                let tempCasting = 2 * CGFloat.pi * x / width * frequency + phase
                let y = scaling * maxAmplitude * normedAmplitude * sin(tempCasting) + halfHeight

                if x == 0 {
                    context.move(to: CGPoint(x: x, y: y))
                } else {
                    context.addLine(to: CGPoint(x: x, y: y))
                }

                x += density
            }

            context.strokePath()
        }
    }
}
