//
//  ContentView.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/14.
//

import CoreGraphics
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var isRecording = false
    @State private var signatureHistory: [SignatureRecord] = []
    @State private var currentSamples: [PencilSample] = []
    @State private var selectedSignature: UUID? = nil
    @State private var showDeleteConfirm = false
    @State private var showDetailSheet = false
    @StateObject private var trackerController = PencilTrackerController()
    @State private var documentToShare: TextFile? = nil
    @State private var showDeleteAllConfirm = false
    @State private var showSettings = false
    @AppStorage("applePencilOnly") private var applePencilOnly: Bool = true

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem {
                    Button("Export All") {
                        exportSignatures()
                    }
                    .disabled(signatureHistory.isEmpty)
                }
                ToolbarItem {
                    Button("Delete All") {
                        showDeleteAllConfirm = true
                    }
                    .disabled(signatureHistory.isEmpty)
                    .foregroundColor(.red)
                }
            }
        } detail: {
            ZStack {
                VStack {
                    ZStack {
                        PencilTracker(
                            isRecording: $isRecording, applePencilOnly: applePencilOnly,
                            controller: trackerController
                        ) {
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
        .alert(
            "Delete All Signatures?", isPresented: $showDeleteAllConfirm,
            actions: {
                Button("Delete All", role: .destructive) {
                    signatureHistory.removeAll()
                }
                Button("Cancel", role: .cancel) {}
            },
            message: {
                Text("This action cannot be undone.")
            }
        )
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
        .sheet(isPresented: $showSettings) {
            SettingsView()
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

#Preview {
    ContentView()
}
