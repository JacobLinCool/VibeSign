//  SettingsView.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/16.

import SwiftUI

struct SettingsView: View {
    @AppStorage("applePencilOnly") private var applePencilOnly: Bool = false
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("General")) {
                    Toggle("Apple Pencil Only", isOn: $applePencilOnly)
                    Text(
                        "When enabled, only Apple Pencil input will be accepted for drawing. This helps prevent accidental marks from your hand or fingers while recording."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                }
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(
                            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                                ?? "1.0"
                        )
                        .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
