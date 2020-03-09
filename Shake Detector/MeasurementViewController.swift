//
//  MeasurementViewController.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/15/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import CoreMotion
import UIKit

class MeasurementViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var waveformView: WaveformView!

    private let motionManager = CMMotionManager()
    private var recording = Recording()
    private var isRecording: Bool = false
    private var measurementStartTime: TimeInterval?

    private lazy var simulatorPlaybackRecording = Recording[.tohoku][0]
    private var simulationFrame: Int = 0
    private var timer: Timer?

    // MARK: Life cycle events

    deinit {
        stopMeasuring()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMeasuring()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        graphView.clear()
        stopMeasuring()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let resultViewController = segue.destination as? ResultsViewController {
            resultViewController.recording = recording
        }
    }

    // MARK: User interaction events

    @IBAction func startStopButtonTapped(_ sender: UIBarButtonItem) {
        if isRecording {
            isRecording = false
            navigateToResults(sender: sender)
            sender.title = "Start"
        } else {
            isRecording = true
            recording = Recording()
            startMeasuring()
            sender.title = "Stop"
        }

        UIApplication.shared.isIdleTimerDisabled = isRecording
        sender.isEnabled = true
    }

    // MARK: Private convenience methods

    private func startMeasuring() {
        let updateInterval: TimeInterval = 1 / 60

        guard motionManager.isDeviceMotionAvailable else {
            // Simulate a recording when running on a simulator
            self.timer?.invalidate()
            let timer = Timer(timeInterval: updateInterval, target: self, selector: #selector(simulateRecord), userInfo: nil, repeats: true)
            self.timer = timer
            RunLoop.main.add(timer, forMode: .common)
            return
        }

        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { deviceMotion, error in
            guard let deviceMotion = deviceMotion else {
                print("Failed to retrieve device motion readings: \(String(describing: error))")
                return
            }

            let time: TimeInterval
            if let startTime = self.measurementStartTime {
                time = deviceMotion.timestamp - startTime
            } else {
                time = 0
                self.measurementStartTime = deviceMotion.timestamp
            }

            let record = Record(
                time: time,
                x: deviceMotion.userAcceleration.x,
                y: deviceMotion.userAcceleration.y,
                z: deviceMotion.userAcceleration.z
            )

            self.add(record: record)
        }
    }

    private func stopMeasuring() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        measurementStartTime = nil
    }

    @objc
    private func simulateRecord() {
        let time: TimeInterval
        if let startTime = measurementStartTime {
            time = Date().timeIntervalSinceReferenceDate - startTime
        } else {
            time = 0
            measurementStartTime = Date().timeIntervalSinceReferenceDate
        }

        let simulatedRecord = simulatorPlaybackRecording[simulationFrame]
        add(record: Record(time: time, x: simulatedRecord.x, y: simulatedRecord.y, z: simulatedRecord.z))

        simulationFrame = (simulationFrame + 1) % simulatorPlaybackRecording.count
    }

    private func add(record: Record) {
        if isRecording {
            recording += record
            graphView.add(record)
        }
        waveformView.updateWithLevel(CGFloat(record.magnitude))
    }

    private func navigateToResults(sender: Any?) {
        performSegue(withIdentifier: "Show Results", sender: sender)
    }
}
