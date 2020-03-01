//
//  Array+Chunking.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/29/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map { index in
            return Array(self[index ..< Swift.min(index + size, count)])
        }
    }
}
