//  Sharing.swift
//  VibeSign
//
//  Created by Jacob Lin on 2025/5/16.

import SwiftUI

struct TextFile: Identifiable {
    let id = UUID()
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
    }
}
