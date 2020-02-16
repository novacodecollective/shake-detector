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

    var magnitude: Double {
        return max(abs(x), max(abs(y), abs(z)))
    }
}

// MARK: - CSV Loading

extension Record {
    enum Name: String, CaseIterable {
        case losAngeles = "Los Angeles"
        case scottsMill = "Scott's Mill"
        case tohoku = "Tohoku"
    }

    static func recording(for name: Name) -> [Record] {
        guard let url = Bundle.main.url(forResource: name.rawValue, withExtension: "csv") else {
            print("Failed to find CSV file: \(name.rawValue)")
            return []
        }

        guard let string = try? String(contentsOf: url) else {
            print("Failed to load data from CSV file: \(name.rawValue)")
            return []
        }

        let rows = string
            .split(separator: "\n")
            .dropFirst()

        let recordings: [Record] = rows.compactMap { row in
            let values = row
                .split(separator: ",")
                .compactMap { Double($0) }

            guard values.count == 4 else {
                print("Bad CSV row: \(row)")
                return nil
            }

            return Record(time: values[0], x: values[1], y: values[2], z: values[3])
        }

        return recordings
    }
}
