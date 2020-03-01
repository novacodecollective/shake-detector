/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A `UIView` subclass that represents a segment of data in a `GraphView`.
 */

import UIKit

@IBDesignable
class GraphSegment: UIView {
    // MARK: Properties

    static let capacity = 32
    let lineColors: [UIColor]
    let gridColor: UIColor

    private(set) var dataPoints = Recording()
    private let startPoint: Record
    private let valueRanges: [ClosedRange<Double>]
    var gridLinePositions = [CGFloat]()

    var isFull: Bool {
        return dataPoints.count >= GraphSegment.capacity
    }

    // MARK: Initialization

    init(startPoint: Record, valueRanges: [ClosedRange<Double>], lineColors: [UIColor], gridColor: UIColor) {
        self.startPoint = startPoint
        self.valueRanges = valueRanges
        self.lineColors = lineColors
        self.gridColor = gridColor

        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func add(_ value: Record) {
        guard dataPoints.count < GraphSegment.capacity else { return }

        dataPoints.append(value)
        setNeedsDisplay()
    }

    // MARK: UIView

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Fill the background.
        if let backgroundColor = backgroundColor?.cgColor {
            context.setFillColor(backgroundColor)
            context.fill(rect)
        }

        // Draw static lines.
        context.drawGraphLines(in: bounds.size, color: gridColor)

        // Plot lines for the 3 sets of values.
        // context.setShouldAntialias(false)
        context.translateBy(x: 0, y: bounds.size.height / 2.0)

        for lineIndex in 0..<3 {
            context.setStrokeColor(lineColors[lineIndex].cgColor)

            // Move to the start point for the current line.
            let value = startPoint[lineIndex]
            let point = CGPoint(x: bounds.size.width, y: scaledValue(for: lineIndex, value: value))
            context.move(to: point)

            // Draw lines between the data points.
            for (pointIndex, dataPoint) in dataPoints.enumerated() {
                let value = dataPoint[lineIndex]
                let point = CGPoint(x: bounds.size.width - CGFloat(pointIndex + 1), y: scaledValue(for: lineIndex, value: value))

                context.addLine(to: point)
            }

            context.strokePath()
        }
    }

    private func scaledValue(for lineIndex: Int, value: Double) -> CGFloat {
        // For simplicity, this assumes the range is centered on zero.
        let valueRange = valueRanges[lineIndex]
        let scale = Double(bounds.size.height) / (valueRange.upperBound - valueRange.lowerBound)
        return CGFloat(floor(value * -scale))
    }
}
