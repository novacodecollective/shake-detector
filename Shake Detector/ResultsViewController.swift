//
//  ResultsViewController.swift
//  Shake Detector
//
//  Created by Eric Jensen on 2/15/20.
//  Copyright © 2020 Nova Code Collective. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {

    // MARK: Properties

    private let classifier = RecordingClassifier()
    var recording: Recording = Recording()

    @IBOutlet weak var resultGraphView: GraphView!
    @IBOutlet weak var matchGraphView: GraphView!
    @IBOutlet weak var matchLabel: UILabel!

    // MARK: Life cycle events

    override func viewDidLoad() {
        super.viewDidLoad()

        resultGraphView.add(recording)

        if let bestMatch = classifier.bestMatch(for: recording) {
            matchLabel.text = "Matches: \(bestMatch.classification.rawValue)"
            matchGraphView.add(bestMatch.recording)
        } else {
            matchLabel.text = "No Match"
        }
    }

    // MARK: User interaction events

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
