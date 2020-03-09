//
//  RecordingClassifierTests.swift
//  Tests
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

@testable import Shake_Detector
import XCTest

class RecordingClassifierTests: XCTestCase {
    private let classifier = RecordingClassifier()

    func testMatchingScottsMill() {
        let classification: Recording.Classification = .scottsMill

        for url in Recording.preRecordingURLs(for: classification) {
            let recording = Recording(url: url, classification: classification)!
            let match = classifier.bestMatch(for: recording)
            debugPrint("Longest matching subrange: \(match?.hashMatches.count ?? 0)")
            XCTAssertEqual(match?.classification, classification, "\(url.lastPathComponent) should match")
        }
    }

    func testMatchingLosAngeles() {
        let classification: Recording.Classification = .losAngeles

        for url in Recording.preRecordingURLs(for: classification) {
            let recording = Recording(url: url, classification: classification)!
            let match = classifier.bestMatch(for: recording)
            debugPrint("Longest matching subrange: \(match?.hashMatches.count ?? 0)")
            XCTAssertEqual(match?.classification, classification, "\(url.lastPathComponent) should match")
        }
    }

    func testMatchingTohoku() {
        let classification: Recording.Classification = .tohoku

        for url in Recording.preRecordingURLs(for: classification) {
            let recording = Recording(url: url, classification: classification)!
            let match = classifier.bestMatch(for: recording)
            debugPrint("Longest matching subrange: \(match?.hashMatches.count ?? 0)")
            XCTAssertEqual(match?.classification, classification, "\(url.lastPathComponent) should match")
        }
    }
}
