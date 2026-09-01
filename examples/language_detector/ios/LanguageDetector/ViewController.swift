// Copyright 2026 The MediaPipe Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import MediaPipeTasksText

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  private let titleLabel = UILabel()
  private let inputTextView = UITextView()
  private let detectButton = UIButton(type: .system)
  private let presetSegmentedControl = UISegmentedControl(items: ["FR", "ES", "DE", "JA", "EN"])
  private let inferenceTimeLabel = UILabel()
  private let resultsTableView = UITableView()
  private let activityIndicator = UIActivityIndicatorView(style: .large)

  private var helper: LanguageDetectorHelper?
  private var predictions: [LanguagePrediction] = []

  private let sampleTexts: [String] = [
    "Bonjour le monde! Comment allez-vous aujourd'hui? MediaPipe permet de créer des applications intelligentes facilement.",
    "¡Hola Mundo! La inteligencia artificial en el dispositivo permite una experiencia rápida y segura.",
    "Guten Tag! Maschinelles Lernen auf dem Endgerät ist schnell und datenschutzfreundlich.",
    "こんにちは世界！デバイス上の機械学習により、高速で安全な体験が可能になります。",
    "Hello world! MediaPipe Solutions makes on-device machine learning accessible to mobile developers."
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupUI()
    initializeHelper()
  }

  private func setupUI() {
    titleLabel.text = "Language Detector"
    titleLabel.font = .boldSystemFont(ofSize: 24)
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(titleLabel)

    let segmentedLabel = UILabel()
    segmentedLabel.text = "Preset Samples:"
    segmentedLabel.font = .systemFont(ofSize: 13, weight: .medium)
    segmentedLabel.textColor = .secondaryLabel
    segmentedLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(segmentedLabel)

    presetSegmentedControl.selectedSegmentIndex = 0
    presetSegmentedControl.addTarget(self, action: #selector(presetChanged), for: .valueChanged)
    presetSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(presetSegmentedControl)

    inputTextView.layer.borderColor = UIColor.separator.cgColor
    inputTextView.layer.borderWidth = 1
    inputTextView.layer.cornerRadius = 8
    inputTextView.font = .systemFont(ofSize: 16)
    inputTextView.text = sampleTexts[0]
    inputTextView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(inputTextView)

    detectButton.setTitle("Detect Language", for: .normal)
    detectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    detectButton.backgroundColor = .systemBlue
    detectButton.setTitleColor(.white, for: .normal)
    detectButton.layer.cornerRadius = 8
    detectButton.addTarget(self, action: #selector(detectClicked), for: .touchUpInside)
    detectButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(detectButton)

    inferenceTimeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    inferenceTimeLabel.textColor = .secondaryLabel
    inferenceTimeLabel.text = "Inference Time: -- ms"
    inferenceTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(inferenceTimeLabel)

    let resultsHeaderLabel = UILabel()
    resultsHeaderLabel.text = "Predictions:"
    resultsHeaderLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    resultsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(resultsHeaderLabel)

    resultsTableView.dataSource = self
    resultsTableView.delegate = self
    resultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
    resultsTableView.layer.borderColor = UIColor.separator.cgColor
    resultsTableView.layer.borderWidth = 1
    resultsTableView.layer.cornerRadius = 8
    resultsTableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(resultsTableView)

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(activityIndicator)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      segmentedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
      segmentedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

      presetSegmentedControl.topAnchor.constraint(equalTo: segmentedLabel.bottomAnchor, constant: 6),
      presetSegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      presetSegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      inputTextView.topAnchor.constraint(equalTo: presetSegmentedControl.bottomAnchor, constant: 12),
      inputTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      inputTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      inputTextView.heightAnchor.constraint(equalToConstant: 110),

      detectButton.topAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: 12),
      detectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      detectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      detectButton.heightAnchor.constraint(equalToConstant: 44),

      inferenceTimeLabel.topAnchor.constraint(equalTo: detectButton.bottomAnchor, constant: 10),
      inferenceTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      inferenceTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      resultsHeaderLabel.topAnchor.constraint(equalTo: inferenceTimeLabel.bottomAnchor, constant: 10),
      resultsHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      resultsHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      resultsTableView.topAnchor.constraint(equalTo: resultsHeaderLabel.bottomAnchor, constant: 6),
      resultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      resultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      resultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }

  private func initializeHelper() {
    guard let modelPath = Bundle.main.path(forResource: "language_detector", ofType: "tflite") else {
      inferenceTimeLabel.text = "Error: language_detector.tflite not found in bundle"
      return
    }
    helper = LanguageDetectorHelper(modelPath: modelPath)
  }

  @objc private func presetChanged() {
    let index = presetSegmentedControl.selectedSegmentIndex
    if index >= 0 && index < sampleTexts.count {
      inputTextView.text = sampleTexts[index]
    }
  }

  @objc private func detectClicked() {
    guard let text = inputTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    inputTextView.resignFirstResponder()
    activityIndicator.startAnimating()

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else { return }
      let bundle = self.helper?.detect(text: text)
      DispatchQueue.main.async {
        self.activityIndicator.stopAnimating()
        if let bundle = bundle {
          self.predictions = bundle.predictions
          self.inferenceTimeLabel.text = String(format: "Inference Time: %.1f ms", bundle.inferenceTime)
        } else {
          self.predictions = []
          self.inferenceTimeLabel.text = "Inference failed"
        }
        self.resultsTableView.reloadData()
      }
    }
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return predictions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: "ResultCell")
    let prediction = predictions[indexPath.row]
    let code = prediction.languageCode
    let name = Locale.current.localizedString(forLanguageCode: code) ?? code
    cell.textLabel?.text = "\(name) (\(code))"
    cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
    cell.detailTextLabel?.text = String(format: "%.1f%%", prediction.probability * 100.0)
    cell.detailTextLabel?.font = .monospacedDigitSystemFont(ofSize: 15, weight: .regular)
    return cell
  }
}
