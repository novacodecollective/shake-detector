//
//  RecoringMatchingTests.swift
//  Tests
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

@testable import Shake_Detector
import XCTest

class RecoringMatchingTests: XCTestCase {
    func testMatchingLosAngeles() {
        // Given
        let url = Bundle(for: RecoringMatchingTests.self).url(forResource: "Los Angeles Test", withExtension: "csv")!
        let recording = Recording(url: url)
        let matcher = RecordingMatcher()

        // When
        let match = matcher.bestMatch(for: recording)

        // Then
        XCTAssertEqual(match?.name, .losAngeles)
    }

    func testMatchingTohoku() {
        // Given
        let url = Bundle(for: RecoringMatchingTests.self).url(forResource: "Tohoku Test", withExtension: "csv")!
        let recording = Recording(url: url)
        let matcher = RecordingMatcher()

        // When
        let match = matcher.bestMatch(for: recording)

        // Then
        XCTAssertEqual(match?.name, .tohoku)
    }
}
