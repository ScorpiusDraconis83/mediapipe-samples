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
import MediaPipeTasksAudio

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AudioClassifierHelperDelegate {

  private let titleLabel = UILabel()
  private let statusLabel = UILabel()
  private let toggleRecordButton = UIButton(type: .system)
  private let thresholdLabel = UILabel()
  private let thresholdSlider = UISlider()
  private let maxResultsLabel = UILabel()
  private let maxResultsStepper = UIStepper()
  private let inferenceTimeLabel = UILabel()
  private let resultsTableView = UITableView()

  private var helper: AudioClassifierHelper?
  private var categories: [ResultCategory] = []
  private var isRecording = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupUI()
    initializeHelper()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isRecording {
      toggleRecording()
    }
  }

  private func setupUI() {
    titleLabel.text = "Audio Classifier"
    titleLabel.font = .boldSystemFont(ofSize: 24)
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(titleLabel)

    statusLabel.text = "Tap Start to classify ambient sound"
    statusLabel.font = .systemFont(ofSize: 14)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .center
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)

    toggleRecordButton.setTitle("Start Recording", for: .normal)
    toggleRecordButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    toggleRecordButton.backgroundColor = .systemRed
    toggleRecordButton.setTitleColor(.white, for: .normal)
    toggleRecordButton.layer.cornerRadius = 10
    toggleRecordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    toggleRecordButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toggleRecordButton)

    let settingsCard = UIStackView()
    settingsCard.axis = .vertical
    settingsCard.spacing = 10
    settingsCard.layer.borderColor = UIColor.separator.cgColor
    settingsCard.layer.borderWidth = 1
    settingsCard.layer.cornerRadius = 10
    settingsCard.isLayoutMarginsRelativeArrangement = true
    settingsCard.layoutMargins = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
    settingsCard.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(settingsCard)

    let thresholdStack = UIStackView()
    thresholdStack.axis = .horizontal
    thresholdStack.distribution = .equalSpacing
    thresholdLabel.text = "Threshold: 0.30"
    thresholdLabel.font = .systemFont(ofSize: 14, weight: .medium)
    thresholdStack.addArrangedSubview(thresholdLabel)

    thresholdSlider.minimumValue = 0.0
    thresholdSlider.maximumValue = 0.95
    thresholdSlider.value = 0.30
    thresholdSlider.addTarget(self, action: #selector(thresholdChanged), for: .valueChanged)
    thresholdSlider.widthAnchor.constraint(equalToConstant: 160).isActive = true
    thresholdStack.addArrangedSubview(thresholdSlider)
    settingsCard.addArrangedSubview(thresholdStack)

    let maxResultsStack = UIStackView()
    maxResultsStack.axis = .horizontal
    maxResultsStack.distribution = .equalSpacing
    maxResultsLabel.text = "Max Results: 3"
    maxResultsLabel.font = .systemFont(ofSize: 14, weight: .medium)
    maxResultsStack.addArrangedSubview(maxResultsLabel)

    maxResultsStepper.minimumValue = 1
    maxResultsStepper.maximumValue = 10
    maxResultsStepper.value = 3
    maxResultsStepper.addTarget(self, action: #selector(maxResultsChanged), for: .valueChanged)
    maxResultsStack.addArrangedSubview(maxResultsStepper)
    settingsCard.addArrangedSubview(maxResultsStack)

    inferenceTimeLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    inferenceTimeLabel.textColor = .secondaryLabel
    inferenceTimeLabel.text = "Inference Time: -- ms"
    inferenceTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(inferenceTimeLabel)

    let resultsHeaderLabel = UILabel()
    resultsHeaderLabel.text = "Detected Categories:"
    resultsHeaderLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    resultsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(resultsHeaderLabel)

    resultsTableView.dataSource = self
    resultsTableView.delegate = self
    resultsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "AudioResultCell")
    resultsTableView.layer.borderColor = UIColor.separator.cgColor
    resultsTableView.layer.borderWidth = 1
    resultsTableView.layer.cornerRadius = 8
    resultsTableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(resultsTableView)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      toggleRecordButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
      toggleRecordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      toggleRecordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      toggleRecordButton.heightAnchor.constraint(equalToConstant: 46),

      settingsCard.topAnchor.constraint(equalTo: toggleRecordButton.bottomAnchor, constant: 14),
      settingsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      settingsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      inferenceTimeLabel.topAnchor.constraint(equalTo: settingsCard.bottomAnchor, constant: 12),
      inferenceTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      inferenceTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      resultsHeaderLabel.topAnchor.constraint(equalTo: inferenceTimeLabel.bottomAnchor, constant: 10),
      resultsHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      resultsHeaderLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      resultsTableView.topAnchor.constraint(equalTo: resultsHeaderLabel.bottomAnchor, constant: 6),
      resultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      resultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      resultsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
    ])
  }

  private func initializeHelper() {
    guard let modelPath = Bundle.main.path(forResource: "yamnet", ofType: "tflite") else {
      statusLabel.text = "Error: yamnet.tflite not found in bundle"
      return
    }
    helper = AudioClassifierHelper(
      modelPath: modelPath,
      scoreThreshold: thresholdSlider.value,
      maxResults: Int(maxResultsStepper.value)
    )
    helper?.delegate = self
  }

  @objc private func toggleRecording() {
    if isRecording {
      isRecording = false
      helper?.stopLiveClassification()
      toggleRecordButton.setTitle("Start Recording", for: .normal)
      toggleRecordButton.backgroundColor = .systemRed
      statusLabel.text = "Stopped recording"
    } else {
      isRecording = true
      helper?.scoreThreshold = thresholdSlider.value
      helper?.maxResults = Int(maxResultsStepper.value)
      helper?.startLiveClassification()
      toggleRecordButton.setTitle("Stop Recording", for: .normal)
      toggleRecordButton.backgroundColor = .systemGray
      statusLabel.text = "Listening to ambient audio..."
    }
  }

  @objc private func thresholdChanged() {
    let value = thresholdSlider.value
    thresholdLabel.text = String(format: "Threshold: %.2f", value)
    helper?.scoreThreshold = value
  }

  @objc private func maxResultsChanged() {
    let value = Int(maxResultsStepper.value)
    maxResultsLabel.text = "Max Results: \(value)"
    helper?.maxResults = value
  }

  // MARK: - AudioClassifierHelperDelegate

  func audioClassifierHelper(
    _ helper: AudioClassifierHelper,
    didFinishClassification categories: [ResultCategory],
    inferenceTime: Double
  ) {
    self.categories = categories
    self.inferenceTimeLabel.text = String(format: "Inference Time: %.1f ms", inferenceTime)
    self.resultsTableView.reloadData()
  }

  func audioClassifierHelper(_ helper: AudioClassifierHelper, didFailWithError error: Error) {
    self.statusLabel.text = "Error: \(error.localizedDescription)"
    if isRecording {
      toggleRecording()
    }
  }

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return categories.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .value1, reuseIdentifier: "AudioResultCell")
    let category = categories[indexPath.row]
    let name = category.categoryName ?? "Unknown"
    cell.textLabel?.text = name
    cell.textLabel?.font = .systemFont(ofSize: 15, weight: .medium)
    cell.detailTextLabel?.text = String(format: "%.1f%%", category.score * 100.0)
    cell.detailTextLabel?.font = .monospacedDigitSystemFont(ofSize: 15, weight: .bold)
    return cell
  }
}
