//
//  RecordingClassifier.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

class RecordingClassifier {
    private typealias SubrangeMatch = (candidate: Candidate, subrange: [HashMatch])

    struct Match {
        let classification: Recording.Classification
        let recording: Recording
        let hashMatches: [HashMatch]
    }

    private struct Candidate: Equatable {
        let classification: Recording.Classification
        let recording: Recording
        let fingerprint: RecordingFingerprint
    }

    struct HashMatch {
        let sourceIndex: Int
        let targetIndex: Int
        let hash: Int

        var distance: Int { targetIndex - sourceIndex }
    }

    private static let candidates: [Candidate] = {
        return Recording.Classification.allCases.flatMap { classification in
            return Recording[classification].map { recording in
                let fingerprint = RecordingFingerprint(recording: recording)
                return Candidate(classification: classification, recording: recording, fingerprint: fingerprint)
            }
        }
    }()

    func bestMatch(for recording: Recording) -> Match? {
        let targetFingerprint = RecordingFingerprint(recording: recording)


        let longestMatchingSubranges: [SubrangeMatch] = RecordingClassifier.candidates
            .filter { $0.recording != recording }
            .map { candidate -> (candidate: Candidate, subrange: [HashMatch]) in
                let matches = hashMatches(source: candidate.fingerprint, target: targetFingerprint)
                return (candidate, matchingSubranges(for: matches).values.max { $0.count < $1.count } ?? [] )
        }

        let groupedMatches = [Recording.Classification: [SubrangeMatch]](grouping: longestMatchingSubranges) { $0.candidate.classification }

        let bestClassification = groupedMatches.max { classification1, classification2 in
            let average1 = Double(classification1.value.reduce(0) { $0 + $1.subrange.count }) / Double(max(classification1.value.count, 1))
            let average2 = Double(classification2.value.reduce(0) { $0 + $1.subrange.count }) / Double(max(classification2.value.count, 1))

            return average1 < average2
        }

        return bestClassification.map { result in
            let bestMatch = result.value.max { $0.subrange.count < $1.subrange.count }
            return Match(classification: result.key, recording: bestMatch!.candidate.recording, hashMatches: bestMatch!.subrange)
        }
    }

    private func matchingSubranges(for matches: [HashMatch]) -> [Int: [HashMatch]] {
        return [Int: [HashMatch]](grouping: matches) { $0.distance }
    }

    private func hashMatches(source: RecordingFingerprint, target: RecordingFingerprint) -> [HashMatch] {
        return source.hashes.enumerated().flatMap { sourceIndex, sourceHash in
            return target.hashes.enumerated().compactMap { targetIndex, targetHash in
                return sourceHash == targetHash ? HashMatch(sourceIndex: sourceIndex, targetIndex: targetIndex, hash: sourceHash) : nil
            }
        }
    }
}
