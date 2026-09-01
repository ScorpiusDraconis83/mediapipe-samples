# MediaPipe Language Detector iOS Demo

This sample app demonstrates how to use the MediaPipe Language Detector Task on iOS. It predicts the language of input text along with confidence probabilities.

## Prerequisites

-   A physical iOS device (iPhone or iPad) or iOS Simulator with iOS 15.0 or later.
-   Xcode 14.1 or later.
-   CocoaPods installed.

## Setup

1.  **Download the model:**
    Run the following script to download the language detection model.
    ```bash
    sh RunScripts/download_models.sh
    ```

2.  **Install dependencies:**
    Run the following command in the `ios` directory to install the required CocoaPods.
    ```bash
    pod install
    ```

3.  **Open the project:**
    Open the `LanguageDetector.xcworkspace` file in Xcode.

4.  **Run the app:**
    Select your target device or simulator and run the app.

## How it works

The app uses the `MediaPipeTasksText` library to perform language detection.

### LanguageDetector Options

The `LanguageDetectorOptions` allows you to configure:
-   `baseOptions.modelAssetPath`: Path to the TFLite model.
-   `scoreThreshold`: Prediction confidence threshold to filter results.
-   `maxResults`: Maximum number of top language predictions to return.

### Inference

The app performs language detection synchronously on a background thread:
-   `detect(text:)` returns a `LanguageDetectorResult` containing an array of `LanguagePrediction` objects (`languageCode` and `probability`).
