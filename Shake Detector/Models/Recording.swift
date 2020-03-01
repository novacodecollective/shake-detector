//
//  Recording.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

typealias Recording = [Record]

extension Recording {
    /// Names of baked-in recordings.
    enum Name: String, CaseIterable {
        case losAngeles = "Los Angeles"
        case scottsMill = "Scott's Mill"
        case tohoku = "Tohoku"
    }
}

// MARK: - Magnitude

extension Recording {
    var peakAcceleration: Double { map { $0.peakAcceleration }.max() ?? 0 }
    var magnitudes: [Double] { map { $0.magnitude } }

    func trimmed(toThreshold threshold: Double = 0.1) -> Recording {
        return drop(while: { $0.magnitude <= threshold }) // Trim start
            .reversed()
            .drop(while: { $0.magnitude <= threshold }) // Trim end
            .reversed()
    }
}

// MARK: - CSV Loading

extension Recording {
    /// Initializes a baked-in recording by name.
    /// - Parameter name: The name of the baked-in recording.
    init(name: Name) {
        guard let url = Bundle.main.url(forResource: name.rawValue, withExtension: "csv") else {
            print("Failed to find CSV file: \(name.rawValue)")
            self = []
            return
        }

        self.init(url: url)
    }

    /// Loads a recording from a file URL.
    /// - Parameter url: The file URL to load the recording from.
    init(url: URL) {
        guard let string = try? String(contentsOf: url) else {
            print("Failed to load data from CSV file: \(url.path)")
            self = []
            return
        }

        let rows = string
            .split(separator: "\n")
            .dropFirst()

        self = rows.compactMap { row in
            let values = row
                .split(separator: ",")
                .compactMap { Double($0) }

            guard values.count == 4 else {
                print("Bad CSV row: \(row)")
                return nil
            }

            return Record(time: values[0], x: values[1], y: values[2], z: values[3])
        }
    }

    func save(filename: String) throws -> URL {
        let rows = ["time,x,y,z"] + map { "\($0.time),\($0.x),\($0.y),\($0.z)" }
        let string = rows.joined(separator: "\n")

        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = directory.appendingPathComponent(filename + ".csv", isDirectory: false)
        try string.write(toFile: url.path, atomically: false, encoding: .utf8)

        return url
    }
}
