# VibeSign

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

VibeSign is a simple iPadOS application designed for capturing and storing digital signatures using an Apple Pencil. It allows users to draw signatures, view a history of their saved signatures, and export them in JSONL format. This tool is particularly useful for researchers or developers needing detailed stroke data from Apple Pencil input.

## Features

- **Detailed Pencil Input**: Captures timestamp, precise location, force, altitude angle, and azimuth angle for each point in a signature.
- **Signature History**: Displays saved signatures in a list with a preview, creation date, and key statistics (point count, duration, average force).
- **Interactive Drawing Canvas**: A dedicated area for drawing signatures.
- **Detailed View**: Tap a signature in the history to view a larger preview and the raw point data.
- **Signature Replay**: Watch a replay of the signature being drawn in the detailed view.
- **JSONL Export**: Export all signature data in JSON Lines format, ideal for data analysis. Each line is a JSON object representing one signature.
- **Clear Canvas**: Easily clear the current drawing.
- **Delete Signatures**: Remove individual signatures from the history.

<!-- Suggestion: Add a "Screenshots" section here -->
<!--
## Screenshots

(Consider adding a few screenshots or a GIF of the app in action here)
- App interface showing history and drawing area.
- Detailed view of a signature.
- Exported JSONL file structure example.
-->

## Getting Started

### Prerequisites

- iPadOS device compatible with Apple Pencil.
- Xcode (latest version recommended).
- Apple Pencil.

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/JacobLinCool/VibeSign.git
    ```

2. Open the `VibeSign.xcodeproj` file in Xcode.
3. Select your iPad as the build target.
4. Build and run the application on your device.

## How It Works

- The application interface is divided into two main sections: a list displaying the history of saved signatures and a dedicated drawing area.
- To create a new signature, tap "Start" and begin drawing on the canvas with an Apple Pencil. The app captures detailed stroke data.
- Tap "Stop" to finish the current signature. The signature is automatically saved and added to the history.
- The signature history is displayed in reverse chronological order (newest first).
- Individual signatures can be selected from the list to view detailed information, including a replay of the signature being drawn, or be deleted.
- The "Export All" button compiles all stored signatures into a `signatures.jsonl` file and presents a share sheet for saving or sending the file.

## Technical Details

- **Framework**: Built natively with SwiftUI for the user interface.
- **Drawing Input**: Utilizes `UIViewRepresentable` to wrap a custom `UIView` (`PencilTrackView`) for capturing detailed touch data from Apple Pencil. This allows access to properties like `force`, `altitudeAngle`, and `azimuthAngle` from `UITouch`.
- **Data Storage**: Signatures are currently stored in-memory. For persistence across app launches, further development would be needed (e.g., using Core Data, SwiftData, or saving to files).
- **Data Export**: Employs `JSONEncoder` with ISO8601 date formatting for creating the JSONL export file. Each signature record in the export includes the creation date and an array of pencil samples.
- **Signature Replay**: The detailed view allows for an animated replay of the signature, visualizing the drawing process based on the captured timestamps.

## Export Format (JSONL)

Each line in the exported `signatures.jsonl` file is a JSON object representing a single signature. Here's an example structure for one line:

```json
{"createdAt":"2025-05-14T10:30:00Z","samples":[{"timestamp":60537.123,"location":{"x":100.5,"y":150.2},"force":1.5,"altitude":0.785,"azimuth":1.570}]}
// ... more samples ...
```

- `createdAt`: ISO8601 timestamp of when the signature was saved.
- `samples`: An array of `PencilSample` objects.
  - `timestamp`: TimeInterval of the touch event.
  - `location`: CGPoint (x, y) of the touch.
  - `force`: Force of the touch.
  - `altitude`: Altitude angle of the Apple Pencil.
  - `azimuth`: Azimuth angle of the Apple Pencil.

## Open Source & Research Utility

This application is open source under the MIT License. Its capability to capture detailed Apple Pencil input makes it a potentially valuable tool for researchers in fields such as:

- Biometric signature verification
- Handwriting analysis and generation
- Cognitive science studies on motor control
- Human-Computer Interaction (HCI) research requiring precise input data

The JSONL export feature facilitates easy data extraction and integration into various data analysis pipelines and tools.

## Contributing

Contributions are welcome! If you have ideas for improvements, new features, or bug fixes, please feel free to:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/YourFeatureName`).
3. Make your changes.
4. Commit your changes (`git commit -m 'Add some feature'`).
5. Push to the branch (`git push origin feature/YourFeatureName`).
6. Open a Pull Request.

Please ensure your code adheres to the existing style and that any new features are well-documented.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
