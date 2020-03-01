//
//  Record.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/17/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

struct Record: Codable {
    let time: TimeInterval
    let x: Double
    let y: Double
    let z: Double

    subscript(index: Int) -> Double {
        switch index {
        case 0: return x
        case 1: return y
        case 2: return z
        default: preconditionFailure("Index out of bounds")
        }
    }

    var peakAcceleration: Double {
        return max(max(abs(x), abs(y)), abs(z))
    }

    var magnitude: Double {
        return abs(x) + abs(y) + abs(z)
    }
}
