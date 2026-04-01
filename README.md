<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/saldo.png" width="180" alt="Saldo App Icon">
</p>

<h1 align="center">Saldo</h1>
<p align="center">
  <strong>Selected Outstanding Submission • Apple Swift Student Challenge 2026 Winner</strong>
</p>

<p align="center">
  <em>Bridging the gap to financial independence for college students.</em>
</p>

---

## The Vision

The transition from student life to financial autonomy is a critical phase often overlooked by formal education. Saldo was developed to empower college students navigating the challenges of living from allowance to allowance. By providing a clear, intuitive, and secure platform, Saldo helps bridge the gap toward total financial independence through transparency and actionable insights.

## Key Features

Saldo is built entirely with native Apple frameworks, ensuring a premium, high-performance experience with zero external dependencies.

### 1. Visual Savings (Grails)
Users can track up to three primary savings objectives, known as "Grails." Saldo utilizes the **Vision framework** to automatically extract foreground subjects from user-uploaded images, creating elegant, masked previews that keep motivations visible.

### 2. Intelligent Receipt Recognition
Managing expenses is simplified through native **OCR (Optical Character Recognition)**. Using the iOS 26 `RecognizeDocumentsRequest`, Saldo scans physical receipts to extract transaction metadata, employing advanced filtering to distinguish amounts from promotional text.

### 3. Dynamic Balance-Driven Theming
The user interface adapts in real-time to the user's financial health. The app smoothly transitions its theme based on current balance and allowance cycles, providing immediate visual feedback on spending status:
- **Red**: Low balance/critical spending.
- **Yellow**: Moderate/cautious spending.
- **Green**: Healthy/stable balance.

### 4. Subscription & Recurring Expense Management
Saldo provides a consolidated dashboard for tracking all recurring commitments, including streaming services, AI tools, and educational platforms, ensuring users are never surprised by scheduled payments.

### 5. Liquid Glass Interaction Design
Built with modern **SwiftUI** principles, Saldo features a custom "Liquid Glass" design system. This includes high-fidelity glassmorphism, fluid gesture-driven navigation via multi-detent bottom sheets, and custom scroll-synchronized animations.

## Screenshots

| Dashboard | Receipt Scanning | Savings Grails |
| :---: | :---: | :---: |
| ![Dashboard Placeholder](Assets.xcassets/AppIcon.appiconset/saldo.png) | ![Scanner Placeholder](Assets.xcassets/AppIcon.appiconset/saldo.png) | ![Grails Placeholder](Assets.xcassets/AppIcon.appiconset/saldo.png) |
| *Adaptive balance dashboard* | *Vision-powered OCR scanning* | *Masked visual savings goals* |

*(Note: Screenshots are representative of the iOS 26 user interface.)*

## Technical Implementation

- **Platform**: iOS 26.0+ (Swift Playground App Package)
- **Architecture**: Domain-driven design with actor-isolated processing services for Vision and OCR tasks.
- **State Management**: Reactive data flow using Swift 6 `@Observable` and `@AppStorage`.
- **Concurrency**: Full optimization for Swift 6 strict concurrency, ensuring thread safety and responsive performance.
- **Privacy**: All processing is performed strictly on-device. Financial data and assets never leave the user's hardware.
- **Persistence**: Secure file-based persistence in the Application Support directory for image assets and metadata.

## Installation

To build and run the Saldo project:
1. Open the `.swiftpm` package in **Xcode** or **Swift Playgrounds**.
2. Select an iOS device or simulator running **iOS 26.0 or later**.
3. *Recommendation: Use a physical device for features requiring the camera or Vision foreground masking.*

---
Designed and developed by Aryaman Jaiswal. Bridging the gap for the next generation.
