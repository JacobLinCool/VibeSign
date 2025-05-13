//
//  ContentView.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/14.
//

import SwiftUI
import UIKit

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

// Controller to allow imperative control from SwiftUI
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

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRecording, let event = event else { return }
        for touch in touches {
            let coalesced = event.coalescedTouches(for: touch) ?? [touch]
            for t in coalesced {
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
        // Draw boundary box
        let path = UIBezierPath(rect: bounds.insetBy(dx: 2, dy: 2))
        UIColor.systemBlue.setStroke()
        path.lineWidth = 4
        path.stroke()
        // Draw data points
        UIColor.systemRed.setFill()
        for sample in samples {
            let dotRect = CGRect(
                x: sample.location.x - 2, y: sample.location.y - 2, width: 4, height: 4)
            let dot = UIBezierPath(ovalIn: dotRect)
            dot.fill()
        }
    }
}

struct SignaturePreview: View {
    let samples: [PencilSample]
    var isAnimating: Bool = false

    @State private var animatedSamples: [PencilSample] = []  // Samples to render
    @State private var animationTimer: Timer? = nil
    @State private var currentIndex: Int = 0
    @State private var isPausedForLoop: Bool = false

    var body: some View {
        GeometryReader { geo in
            // Use animatedSamples for drawing
            let points = animatedSamples.map { $0.location }

            if points.isEmpty {
                // Render nothing or a placeholder if there are no points.
                // For an empty list, the GeometryReader will be empty.
            } else {
                let minX = points.map { $0.x }.min() ?? 0
                let minY = points.map { $0.y }.min() ?? 0
                // Ensure maxX/maxY are based on actual points, defaulting to minX/minY if needed
                let maxX = points.map { $0.x }.max() ?? minX
                let maxY = points.map { $0.y }.max() ?? minY

                // Ensure w and h are at least 1 to avoid division by zero and handle single/collinear points
                let w = max(maxX - minX, 1)
                let h = max(maxY - minY, 1)

                let padding: CGFloat = 2.0  // Padding around the signature drawing

                // Calculate the actual drawing area available after considering padding
                // Ensure drawingArea dimensions are at least 1
                let drawingAreaWidth = max(geo.size.width - 2 * padding, 1)
                let drawingAreaHeight = max(geo.size.height - 2 * padding, 1)

                let scale = min(drawingAreaWidth / w, drawingAreaHeight / h)

                // Calculate the size of the content once scaled
                let scaledContentWidth = w * scale
                let scaledContentHeight = h * scale

                // Calculate offsets to center the scaled content within the drawingArea.
                // The base offset starts from `padding`.
                let offsetX = padding + (drawingAreaWidth - scaledContentWidth) / 2
                let offsetY = padding + (drawingAreaHeight - scaledContentHeight) / 2

                Path { path in
                    for pt in points {  // Use the 'points' variable derived from 'pointsToDraw'
                        // Apply scaling and translation from the original coordinate system (minX, minY)
                        let x = (pt.x - minX) * scale + offsetX
                        let y = (pt.y - minY) * scale + offsetY

                        // Define a small circle for each point
                        let dotSize: CGFloat = 1.5  // Diameter of the dot
                        // Create a CGRect for the dot, centered at (x, y)
                        let dotRect = CGRect(
                            x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                        path.addEllipse(in: dotRect)
                    }
                }
                .fill(Color.accentColor)  // Fill the dots with the accent color
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
            animatedSamples = samples  // Show all points if not animating
        }
    }

    private func advanceAnimation() {
        guard isAnimating && !samples.isEmpty else { return }

        if isPausedForLoop {
            // Currently paused, timer fired to end pause
            isPausedForLoop = false
            currentIndex = 0
            animatedSamples = []
            // Fall through to add the first point of the new loop
        }

        if currentIndex < samples.count {
            animatedSamples.append(samples[currentIndex])

            let delay: TimeInterval
            if currentIndex + 1 < samples.count {
                // Time until next point
                delay = samples[currentIndex + 1].timestamp - samples[currentIndex].timestamp
            } else {
                // This is the last point, schedule pause
                isPausedForLoop = true
                delay = 3.0  // Pause for 3 seconds
            }

            // Ensure delay is non-negative and has a minimum value if timestamps are too close or identical.
            let effectiveDelay = max(delay, 0.001)  // Minimum delay of 1ms

            animationTimer = Timer.scheduledTimer(withTimeInterval: effectiveDelay, repeats: false)
            { _ in
                if !self.isPausedForLoop {
                    // If we just scheduled a pause, currentIndex is not incremented here.
                    // It will be reset when the pause ends and advanceAnimation is called again.
                    self.currentIndex += 1
                }
                self.advanceAnimation()  // Continue to next step (either next point or end pause)
            }
        } else if !isPausedForLoop {  // Should loop if all points are drawn and not currently in a pause cycle
            // This case handles the restart after the last point if not going into a pause (e.g., if pause logic was different)
            // Or if manageAnimation is called when animation was already complete.
            currentIndex = 0
            animatedSamples = []
            if isAnimating && !samples.isEmpty {  // Ensure still should be animating
                advanceAnimation()  // Restart animation
            }
        }
        // If isPausedForLoop is true and currentIndex >= samples.count, it means the 3s pause timer is active.
        // When that timer fires, it will call advanceAnimation, which will then reset isPausedForLoop and restart.
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

struct ContentView: View {
    @State private var isRecording = false
    @State private var signatureHistory: [SignatureRecord] = []
    @State private var currentSamples: [PencilSample] = []
    @State private var selectedSignature: UUID? = nil
    @State private var showDeleteConfirm = false
    @State private var showDetailSheet = false
    @StateObject private var trackerController = PencilTrackerController()
    @State private var documentToShare: TextFile? = nil

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedSignature) {
                Section(header: Text("History")) {
                    ForEach(signatureHistory) { record in  // Iterate over SignatureRecord
                        HStack(spacing: 8) {
                            SignaturePreview(samples: record.samples)
                                .frame(width: 36, height: 36)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                            VStack(alignment: .leading, spacing: 2) {
                                // Find index for display name, or use a more stable identifier if available
                                if let idx = signatureHistory.firstIndex(where: {
                                    $0.id == record.id
                                }) {
                                    Text("Signature \(signatureHistory.count - idx)")  // Display in reverse order of creation
                                        .font(.subheadline)
                                }
                                SignatureStats(samples: record.samples, createdAt: record.createdAt)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSignature = record.id
                            showDetailSheet = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                selectedSignature = record.id
                                showDeleteConfirm = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Signatures")
            .toolbar {
                ToolbarItem {
                    Button("Export All") {
                        exportSignatures()
                    }
                    .disabled(signatureHistory.isEmpty)
                }
            }
        } detail: {
            ZStack {
                VStack {
                    ZStack {
                        PencilTracker(isRecording: $isRecording, controller: trackerController) {
                            samples in
                            currentSamples = samples
                        }
                        .frame(width: 600, height: 600)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    .padding()
                    HStack(spacing: 16) {
                        Button(action: {
                            if isRecording {
                                // Currently recording, about to STOP
                                // The isRecording state will be toggled.
                                // Saving to history will be handled by .onChange(of: isRecording)
                                // after currentSamples is updated by PencilTracker's onStop.
                                isRecording.toggle()
                            } else {
                                // Currently stopped, about to START
                                trackerController.clear()  // Clear the visual canvas
                                currentSamples = []  // Clear the data model for current drawing
                                isRecording.toggle()  // This will trigger PencilTracker to start recording
                            }
                        }) {
                            Label(
                                isRecording ? "Stop" : "Start",
                                systemImage: isRecording ? "stop.circle.fill" : "play.circle.fill"
                            )
                            .labelStyle(.titleAndIcon)
                            .frame(minWidth: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isRecording ? .red : .accentColor)
                        Button("Clear") {
                            trackerController.clear()
                            currentSamples = []
                        }
                        .buttonStyle(.bordered)
                        .disabled(isRecording)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Draw")
            .sheet(isPresented: $showDetailSheet) {
                if let selectedId = selectedSignature,
                    let record = signatureHistory.first(where: { $0.id == selectedId })
                {
                    SignatureDetailView(samples: record.samples, createdAt: record.createdAt)
                }
            }
            .alert(
                "Delete Signature?", isPresented: $showDeleteConfirm,
                actions: {
                    Button("Delete", role: .destructive) {
                        if let selectedId = selectedSignature {
                            signatureHistory.removeAll(where: { $0.id == selectedId })
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                },
                message: {
                    Text("This action cannot be undone.")
                })
        }
        .sheet(item: $documentToShare) { textFile in
            ShareSheet(activityItems: [textFile.fileURL])
        }
        .onChange(of: isRecording) { oldValue, newValue in
            if !newValue {
                // Just stopped recording
                // currentSamples should have been updated by PencilTracker's onStop callback by now.
                if !currentSamples.isEmpty {
                    let newRecord = SignatureRecord(samples: currentSamples, createdAt: Date())
                    signatureHistory.insert(newRecord, at: 0)
                    // currentSamples is not cleared here, it holds the last drawn signature.
                    // It will be cleared if "Start" or "Clear" is pressed.
                }
            }
        }
    }

    func exportSignatures() {
        var jsonlString = ""
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        // Define a temporary struct for encoding that includes createdAt
        struct ExportableSignature: Encodable {
            let createdAt: Date
            let samples: [PencilSample]
        }

        for record in signatureHistory.reversed() {  // Export in chronological order
            let exportableRecord = ExportableSignature(
                createdAt: record.createdAt, samples: record.samples)
            do {
                let jsonData = try encoder.encode(exportableRecord)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    jsonlString += jsonString + "\n"
                }
            } catch {
                print("Error encoding signature record: \(error)")
            }
        }

        if jsonlString.isEmpty {
            print("No data to export.")
            return
        }

        // Create a temporary file to share
        let fileName = "signatures.jsonl"
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        do {
            try jsonlString.write(to: fileURL, atomically: true, encoding: .utf8)
            self.documentToShare = TextFile(fileURL: fileURL)
        } catch {
            print("Error writing to file: \(error)")
        }
    }
}

// Helper struct for sharing
struct TextFile: Identifiable {
    let id = UUID()  // Ensure unique ID for each instance
    let fileURL: URL
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
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
            SignaturePreview(samples: samples, isAnimating: true)  // Enable animation here
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

struct PencilTracker: UIViewRepresentable {
    @Binding var isRecording: Bool
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
        controller?.view = view
        return view
    }
    func updateUIView(_ uiView: PencilTrackView, context: Context) {
        uiView.onStop = onStop
        if isRecording && !uiView.isRecording {
            uiView.startRecording()
        } else if !isRecording && uiView.isRecording {
            uiView.stopRecording()
        }
        // No clear logic here; handled by controller
    }
}

#Preview {
    ContentView()
}
