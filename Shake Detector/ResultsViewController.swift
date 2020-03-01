//
//  ResultsViewController.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/15/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {
    var recording: Recording = Recording()

    @IBOutlet weak var magnitudeLabel: UILabel!
    @IBOutlet weak var resultGraphView: GraphView!
    @IBOutlet weak var scottsMillGraphView: GraphView!
    @IBOutlet weak var losAngelesGraphView: GraphView!
    @IBOutlet weak var tohokuGraphView: GraphView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let peakGroundAcceleration = recording.peakAcceleration

        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1

        magnitudeLabel.text = numberFormatter.string(for: peakGroundAcceleration)

        resultGraphView.add(recording.trimmed())
        scottsMillGraphView.add(Recording(name: .scottsMill).trimmed())
        losAngelesGraphView.add(Recording(name: .losAngeles).trimmed())
        tohokuGraphView.add(Recording(name: .tohoku).trimmed())
    }

    @IBAction func saveResults(_ sender: UIBarButtonItem) {
        do {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                .replacingOccurrences(of: "/", with: "-")

            let url = try recording.save(filename: "Recording \(timestamp)")
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityViewController, animated: true, completion: nil)
        } catch {
            print("Failed to save CSV \(error)")
        }
    }
}
