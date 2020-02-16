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

    private let motionManager = CMMotionManager()
    @IBOutlet weak var graphView: GraphView!
    private var recording: [Record] = []

    // MARK: Event handlers

    deinit {
        stopMeasuring()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if recording.isEmpty {
            for record in Record.recording(for: .tohoku) {
                add(record: record)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        graphView.clear()
    }

    @IBAction func startStopButtonTapped(_ sender: UIBarButtonItem) {
        if motionManager.isDeviceMotionActive {
            stopMeasuring()
            navigateToResults(sender: sender)
            sender.title = "Start"
        } else {
            startMeasuring()
            sender.title = "Stop"
        }
    }

    // MARK: Private convenience methods

    private func startMeasuring() {
        recording.removeAll()
        var startTime: TimeInterval?

        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = 1 / 60
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { deviceMotion, error in
            guard let deviceMotion = deviceMotion else {
                print("Failed to retrieve device motion readings: \(String(describing: error))")
                return
            }

            let time: TimeInterval
            if let startTime = startTime {
                time = deviceMotion.timestamp - startTime
            } else {
                time = 0
                startTime = deviceMotion.timestamp
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

    private func add(record: Record) {
        self.recording.append(record)
        self.graphView.add(record)
    }

    private func stopMeasuring() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func navigateToResults(sender: Any?) {
        performSegue(withIdentifier: "Show Results", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let resultViewController = segue.destination as? ResultsViewController {
            resultViewController.recording = recording
        }
    }
}
