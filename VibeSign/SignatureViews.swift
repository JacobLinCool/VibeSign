//  SignatureViews.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/16.

import SwiftUI

struct SignaturePreview: View {
    let samples: [PencilSample]
    var isAnimating: Bool = false
    @State private var animatedSamples: [PencilSample] = []
    @State private var animationTimer: Timer? = nil
    @State private var currentIndex: Int = 0
    @State private var isPausedForLoop: Bool = false
    var body: some View {
        GeometryReader { geo in
            let points = animatedSamples.map { $0.location }
            if points.isEmpty {
            } else {
                let minX = points.map { $0.x }.min() ?? 0
                let minY = points.map { $0.y }.min() ?? 0
                let maxX = points.map { $0.x }.max() ?? minX
                let maxY = points.map { $0.y }.max() ?? minY
                let w = max(maxX - minX, 1)
                let h = max(maxY - minY, 1)
                let padding: CGFloat = 2.0
                let drawingAreaWidth = max(geo.size.width - 2 * padding, 1)
                let drawingAreaHeight = max(geo.size.height - 2 * padding, 1)
                let scale = min(drawingAreaWidth / w, drawingAreaHeight / h)
                let scaledContentWidth = w * scale
                let scaledContentHeight = h * scale
                let offsetX = padding + (drawingAreaWidth - scaledContentWidth) / 2
                let offsetY = padding + (drawingAreaHeight - scaledContentHeight) / 2
                Path { path in
                    for pt in points {
                        let x = (pt.x - minX) * scale + offsetX
                        let y = (pt.y - minY) * scale + offsetY
                        let dotSize: CGFloat = 1.5
                        let dotRect = CGRect(
                            x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                        path.addEllipse(in: dotRect)
                    }
                }
                .fill(Color.accentColor)
            }
        }
        .onAppear(perform: manageAnimation)
        .onDisappear {
            animationTimer?.invalidate()
            animationTimer = nil
        }
        .onChange(of: samples) { manageAnimation() }
        .onChange(of: isAnimating) { manageAnimation() }
    }
    private func manageAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        animatedSamples = []
        currentIndex = 0
        isPausedForLoop = false
        if isAnimating && !samples.isEmpty {
            advanceAnimation()
        } else {
            animatedSamples = samples
        }
    }
    private func advanceAnimation() {
        guard isAnimating && !samples.isEmpty else { return }
        if isPausedForLoop {
            isPausedForLoop = false
            currentIndex = 0
            animatedSamples = []
        }
        if currentIndex < samples.count {
            animatedSamples.append(samples[currentIndex])
            let delay: TimeInterval
            if currentIndex + 1 < samples.count {
                delay = samples[currentIndex + 1].timestamp - samples[currentIndex].timestamp
            } else {
                isPausedForLoop = true
                delay = 3.0
            }
            let effectiveDelay = max(delay, 0.001)
            animationTimer = Timer.scheduledTimer(withTimeInterval: effectiveDelay, repeats: false)
            { _ in
                if !self.isPausedForLoop {
                    self.currentIndex += 1
                }
                self.advanceAnimation()
            }
        } else if !isPausedForLoop {
            currentIndex = 0
            animatedSamples = []
            if isAnimating && !samples.isEmpty {
                advanceAnimation()
            }
        }
    }
}

struct SignatureStats: View {
    let samples: [PencilSample]
    let createdAt: Date?
    var body: some View {
        let count = samples.count
        let duration = (samples.last?.timestamp ?? 0) - (samples.first?.timestamp ?? 0)
        let avgForce =
            samples.isEmpty ? 0 : samples.map { $0.force }.reduce(0, +) / CGFloat(samples.count)
        VStack(alignment: .leading, spacing: 2) {
            if let createdAt = createdAt {
                Text(createdAt, style: .date) + Text(" ")
                    + Text(createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text("\(count) pts")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "%.2fs", duration))
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(String(format: "F: %.2f", avgForce))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct SignatureDetailView: View {
    let samples: [PencilSample]
    let createdAt: Date
    var body: some View {
        VStack(spacing: 16) {
            Text("Signature Detail")
                .font(.title2)
            HStack {
                Text("Created:")
                Text(createdAt, style: .date)
                Text(createdAt, style: .time)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            SignaturePreview(samples: samples, isAnimating: true)
                .frame(width: 200, height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            SignatureStats(samples: samples, createdAt: nil)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(samples.enumerated()), id: \.offset) { idx, s in
                        Text(
                            "\(idx): (x: \(String(format: "%.1f", s.location.x)), y: \(String(format: "%.1f", s.location.y)), force: \(String(format: "%.2f", s.force)))"
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 400)
    }
}
