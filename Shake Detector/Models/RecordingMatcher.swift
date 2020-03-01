//
//  RecordingMatcher.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

struct RecordingMatch {
    let name: Recording.Name
    let recording: Recording
    let fingerprint: RecordingFingerprint
}

class RecordingMatcher {
    private lazy var recordingCandidates: [RecordingMatch] = {
        return Recording.Name.allCases.map { name in
            let recording = Recording(name: name)
            let fingerprint = RecordingFingerprint(recording: recording)
            return RecordingMatch(name: name, recording: recording, fingerprint: fingerprint)
        }
    }()

    func bestMatch(for recording: Recording) -> RecordingMatch? {
        let fingerprint = RecordingFingerprint(recording: recording)

        return recordingCandidates.first { candidate in
            candidate.fingerprint.hashes == fingerprint.hashes
        }
    }
}
