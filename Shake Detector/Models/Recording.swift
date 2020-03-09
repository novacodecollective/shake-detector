//
//  Recording.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

class Recording {
    private var records: [Record]
    private let classification: Classification?

    init(records: [Record] = [], classification: Classification? = nil) {
        self.records = records
        self.classification = classification
    }
}

// MARK: - Classifications

extension Recording {
    /// Names of baked-in recordings.
    enum Classification: String, CaseIterable {
        case losAngeles = "Los Angeles"
        case scottsMill = "Scotts Mill"
        case tohoku = "Tohoku"
    }
}

// MARK: - Magnitude

extension Recording {
    var peakAcceleration: Double { map { $0.peakAcceleration }.max() ?? 0 }
    var magnitudes: [Double] { map { $0.magnitude } }

    func trimmed(toThreshold threshold: Double = 0.01) -> Recording {
        let records = self.records
            .drop(while: { $0.magnitude <= threshold }) // Trim start
            .reversed()
            .drop(while: { $0.magnitude <= threshold }) // Trim end
            .reversed()

        return Recording(records: Array(records), classification: classification)
    }
}

// MARK: - CSV Loading

extension Recording {
    /// Loads a recording from a CSV file URL.
    /// - Parameters:
    ///   - url: The CSV file URL to load the recording from.
    ///   - classification: The classification of the recording.
    convenience init?(url: URL, classification: Classification?) {
        guard let string = try? String(contentsOf: url) else {
            assertionFailure("Failed to load data from CSV file: \(url.path)")
            return nil
        }

        let rows = string
            .split(separator: "\n")
            .dropFirst()

        let records: [Record] = rows.compactMap { row in
            let values = row
                .split(separator: ",")
                .compactMap { Double($0) }

            guard values.count == 4 else {
                print("Bad CSV row: \(row)")
                return nil
            }

            return Record(time: values[0], x: values[1], y: values[2], z: values[3])
        }

        self.init(records: records, classification: classification)
    }

    /// Returns the URLs of all the pre-recordings for the specified name.
    /// - Parameters:
    ///   - classification: The classification of the pre-recording URLs.
    ///   - fileManager: The file manager instance to use in generating the URLs. Defaults to `.default`.
    static func preRecordingURLs(for classification: Classification, fileManager: FileManager = .default) -> [URL] {
        guard let directory = Bundle.main.resourceURL?.appendingPathComponent(classification.rawValue, isDirectory: true) else {
            assertionFailure("Failed to find pre-recording directory for \(classification)")
            return []
        }

        do {
            return try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
        } catch {
            assertionFailure("Failed to load pre-recordings for \(classification): \(error)")
            return []
        }
    }

    /// Loads all the pre-recordings for a given name.
    /// - Parameter classification: The classification the recordings to load.
    /// - Returns: All the pre-recordings for the given name.
    static subscript(classification: Classification) -> [Recording] {
        let urls = preRecordingURLs(for: classification)
        return urls.compactMap { url in Recording(url: url, classification: classification) }
    }

    /// Saves this recoding to a CSV file in the device's documents directory.
    /// - Parameter filename: The name of the file to save.
    func save(filename: String) throws -> URL {
        let rows = ["time,x,y,z"] + map { "\($0.time),\($0.x),\($0.y),\($0.z)" }
        let string = rows.joined(separator: "\n")

        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = directory.appendingPathComponent(filename + ".csv", isDirectory: false)
        try string.write(toFile: url.path, atomically: false, encoding: .utf8)

        return url
    }
}

// MARK: - Protocol Conformance

extension Recording: RandomAccessCollection, Equatable {
    typealias Index = Int
    typealias Element = Record
    typealias ArrayLiteralElement = Record

    var startIndex: Index { return records.startIndex }
    var endIndex: Index { return records.endIndex }

    subscript(index: Index) -> Element {
        get { return records[index] }
        set { records[index] = newValue }
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        return lhs.records == rhs.records
    }

    static func += (lhs: Recording, rhs: Record) {
        lhs.records.append(rhs)
    }

    func index(after i: Index) -> Index {
        return records.index(after: i)
    }
}
