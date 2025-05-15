//  Models.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/16.

import CoreGraphics
import Foundation

struct PencilSample: Codable, Equatable {
    let timestamp: TimeInterval
    let location: CGPoint
    let force: CGFloat
    let altitude: CGFloat
    let azimuth: CGFloat

    static func == (lhs: PencilSample, rhs: PencilSample) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.location == rhs.location
            && lhs.force == rhs.force && lhs.altitude == rhs.altitude && lhs.azimuth == rhs.azimuth
    }
}

struct SignatureRecord: Identifiable {
    let id = UUID()
    let samples: [PencilSample]
    let createdAt: Date
}
