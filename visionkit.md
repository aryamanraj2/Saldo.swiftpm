System/Role: You are an expert iOS Engineer specializing in the Vision Framework and SwiftUI. You are helping a student developer implement a high-performance receipt scanner for an existing Finance Tracker app (Swift Student Challenge submission).

The Context: I have an existing SwiftUI application with a "Floating Action Button" (Scan Receipt). I need you to write the code that executes when this button is clicked. The User Flow is:

User taps "Scan Receipt" -> Opens a Camera Sheet.

The Camera UI uses VisionKit (VNDocumentCameraViewController) for high-quality document scanning (auto-shutter, perspective correction).

Once the user saves the scan, the image is passed to a processing service.

The service uses the NEW Vision APIs (detailed below) to extract the Merchant, Date, and Total.

Required Technology Stack (Strict Adherence): You must use the new Vision framework updates (referred to as the "iOS 26" / WWDC25 update style in my context files):

RecognizeDocumentsRequest: The core request to process the image.

DocumentObservation: The result type.

detectedData: Use this property on the observation to extract typed data (Dates and Amounts) without manual Regex.

DetectLensSmudgeRequest: Run this on the captured image to print a quality warning in the console if the lens was dirty.

DetectDocumentSegmentationRequest: Use this if needed to verify the crop, but rely primarily on VisionKit's native cropping.

The Task: Please write two Swift files:

ReceiptScannerView.swift:

A UIViewControllerRepresentable wrapper for VNDocumentCameraViewController.

It should have a Coordinator that handles didFinishWith scan.

Pass the scanned UIImage to the ReceiptProcessor.

ReceiptProcessor.swift:

An actor or class that handles the Vision requests async.

Function signature: func process(image: UIImage) async throws -> ReceiptMetadata.

Logic:

First, run DetectLensSmudgeRequest. If confidence > 0.9, log a "Smudge Warning".

Next, run RecognizeDocumentsRequest.

Iterate through observation.detectedData to find the Date and Total Amount (Currency).

Use observation.title or the first valid text block as the Merchant Name.

Return a clean struct ReceiptMetadata containing these fields.

Constraints:

Assume the user's project is already set up for Swift Concurrency.

Do not use the old VNRecognizeTextRequest unless RecognizeDocumentsRequest fails to return structured data.

Keep the code modular so I can easily call it from my existing "Scan" button action.