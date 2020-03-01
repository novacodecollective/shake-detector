//
//  RecordingFingerprint.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

struct RecordingFingerprint {
    private static let frequencyRanges: [Int] = [1, 5, 10, 15, 20]

    let frequencies: [[Double]]
    let hashes: [Int]

    init(recording: Recording) {
        let chunkSize: Int = 120
        let frequencyRanges = RecordingFingerprint.frequencyRanges

        frequencies = recording
            .trimmed()
            .magnitudes
            .chunked(into: chunkSize)
            .map { fft($0) }

        var hashes: [Int] = []
        var points: [[Int]] = (0..<frequencies.count).map { _ in [Int](repeating: 0, count: frequencyRanges.count) }
        var highscores: [[Double]] = (0..<frequencies.count).map { _ in [Double](repeating: 0, count: frequencyRanges.count) }

        for (chunkIndex, chunk) in frequencies.enumerated() {
            for frequency in (1...20) {
                guard frequency < chunk.count else {
                    break
                }

                let magnitude = chunk[frequency] * 10
                let index = RecordingFingerprint.frequencyIndex(frequency: frequency)

                if magnitude > highscores[chunkIndex][index] {
                    highscores[chunkIndex][index] = magnitude
                    points[chunkIndex][index] = frequency
                }
            }

            let hash = RecordingFingerprint.hash(points[chunkIndex][0], points[chunkIndex][1], points[chunkIndex][2], points[chunkIndex][3])
            hashes.append(hash)
        }

        self.hashes = hashes
    }

    private static func frequencyIndex(frequency: Int) -> Int {
        frequencyRanges.firstIndex(where: { $0 >= frequency }) ?? (frequencyRanges.count - 1)
    }

    private static func hash(_ p1: Int, _ p2: Int, _ p3: Int, _ p4: Int) -> Int {
        let fuzzFactor = 2

        let h1 = (p1 - (p1 % fuzzFactor)) * 1
        let h2 = (p2 - (p2 % fuzzFactor)) * 100
        let h3 = (p3 - (p3 % fuzzFactor)) * 100000
        let h4 = (p4 - (p4 % fuzzFactor)) * 100000000

        return h1 + h2 + h3 + h4
    }
}
