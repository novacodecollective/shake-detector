//
//  ResultsViewController.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/15/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {
    var recording: [Record] = []

    @IBOutlet weak var magnitudeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let peakGroundAcceleration = recording.map { $0.magnitude }.max()

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1

        magnitudeLabel.text = numberFormatter.string(for: peakGroundAcceleration)
    }
}
