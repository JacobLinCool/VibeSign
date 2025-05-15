//  PencilTracker.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/16.

import SwiftUI
import UIKit

class PencilTrackerController: ObservableObject {
    fileprivate var view: PencilTrackView?
    func clear() {
        view?.samples.removeAll()
        view?.setNeedsDisplay()
    }
}

class PencilTrackView: UIView {
    var samples: [PencilSample] = []
    var isRecording: Bool = false
    var onStop: (([PencilSample]) -> Void)?
    var applePencilOnly: Bool = true

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRecording, let event = event else { return }
        for touch in touches {
            if applePencilOnly && touch.type != .pencil { continue }  // Only accept Apple Pencil if enabled
            let coalesced = event.coalescedTouches(for: touch) ?? [touch]
            for t in coalesced {
                if applePencilOnly && t.type != .pencil { continue }
                let sample = PencilSample(
                    timestamp: t.timestamp,
                    location: t.preciseLocation(in: self),
                    force: t.force,
                    altitude: t.altitudeAngle,
                    azimuth: t.azimuthAngle(in: self)
                )
                samples.append(sample)
            }
        }
        setNeedsDisplay()
    }
    func startRecording() {
        samples.removeAll()
        isRecording = true
    }
    func stopRecording() {
        isRecording = false
        onStop?(samples)
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let path = UIBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
        UIColor.systemBlue.setStroke()
        path.lineWidth = 4
        path.stroke()
        UIColor.systemRed.setFill()
        for sample in samples {
            let dotRect = CGRect(
                x: sample.location.x - 2, y: sample.location.y - 2, width: 4, height: 4)
            let dot = UIBezierPath(ovalIn: dotRect)
            dot.fill()
        }
    }
}

struct PencilTracker: UIViewRepresentable {
    @Binding var isRecording: Bool
    var applePencilOnly: Bool = true
    var controller: PencilTrackerController? = nil
    var onStop: ([PencilSample]) -> Void
    class Coordinator {
        var parent: PencilTracker
        init(_ parent: PencilTracker) { self.parent = parent }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> PencilTrackView {
        let view = PencilTrackView()
        view.backgroundColor = .white
        view.onStop = onStop
        view.applePencilOnly = applePencilOnly
        controller?.view = view
        return view
    }
    func updateUIView(_ uiView: PencilTrackView, context: Context) {
        uiView.onStop = onStop
        uiView.applePencilOnly = applePencilOnly
        if isRecording && !uiView.isRecording {
            uiView.startRecording()
        } else if !isRecording && uiView.isRecording {
            uiView.stopRecording()
        }
    }
}
