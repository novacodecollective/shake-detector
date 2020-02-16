/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A `UIView` subclass used to graph the values retreived from sensors. The graph is made up of segments represeneted by child views to avoid having to redraw the whole graph with every update.
 */

import UIKit

@IBDesignable
class GraphView: UIScrollView {

    // MARK: Properties

    private var segments = [GraphSegment]()
    private var currentSegment: GraphSegment? { segments.last }
    private var valueRanges = [-4.0...4.0, -4.0...4.0, -4.0...4.0]

    @IBInspectable
    var xColor: UIColor = UIColor.red

    @IBInspectable
    var yColor: UIColor = UIColor.green

    @IBInspectable
    var zColor: UIColor = UIColor.blue

    @IBInspectable
    var gridColor: UIColor = UIColor(white: 0, alpha: 0.1)

    // MARK: Update methods

    func add(_ value: Record) {
        // Move all the segments horizontally.
        for segment in segments {
            segment.center.x += 1
        }

        // Add a new segment there are no segments or if the current segment is full.
        if currentSegment?.isFull ?? true {
            addSegment()
        }

        // Add the values to the current segment.
        currentSegment?.add(value)
    }

    func clear() {
        segments.forEach { $0.removeFromSuperview() }
        segments.removeAll(keepingCapacity: true)
    }

    // MARK: Private convenience methods

    private func addSegment() {
        let segmentWidth = CGFloat(GraphSegment.capacity)

        // Determine the start point for the next segment.
        let startPoint: Record
        if let currentSegment = currentSegment {
            startPoint = currentSegment.dataPoints.last!
        } else {
            startPoint = Record(time: 0, x: 0, y: 0, z: 0)
        }

        // Create and store a new segment.
        let segment = GraphSegment(
            startPoint: startPoint,
            valueRanges: valueRanges,
            lineColors: [xColor, yColor, zColor],
            gridColor: gridColor
        )
        segments.append(segment)

        // Add the segment to the view.
        segment.backgroundColor = backgroundColor
        segment.frame = CGRect(x: -segmentWidth, y: 0, width: segmentWidth, height: frame.size.height)
        contentSize = CGSize(width: segmentWidth * CGFloat(segments.count), height: frame.size.height)
        addSubview(segment)
    }
}
