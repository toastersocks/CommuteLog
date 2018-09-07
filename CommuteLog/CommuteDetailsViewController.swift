//
//  CommuteDetailsViewController.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/4/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit
import MapKit

class CommuteDetailsViewController: UIViewController {
    let mapView = MKMapView(frame: .zero)
    let formatter: DateFormatter = DateFormatter()

    let commute: Commute
    init(commute: Commute) {
        self.commute = commute
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        view.backgroundColor = .white

        let startLabel: UILabel = UILabel(frame: .zero)
        startLabel.text = "Start: \(formatter.string(from: commute.start))"

        let endLabel: UILabel = UILabel(frame: .zero)
        let endText: String
        if let end = commute.end {
            endText = formatter.string(from: end)
        } else {
           endText = "---"
        }
        endLabel.text = "End:   \(endText)"

        let labels = UIStackView(arrangedSubviews: [startLabel, endLabel])
        labels.alignment = .fill
        labels.axis = .vertical
        labels.distribution = .equalSpacing
        labels.spacing = 8
        labels.isLayoutMarginsRelativeArrangement = true
        labels.preservesSuperviewLayoutMargins = true
        view.addSubview(labels)
        labels.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labels.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            labels.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            labels.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        formatter.timeStyle = .long
        formatter.dateStyle = .none

        for location in commute.locations {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            annotation.title = formatter.string(from: location.timestamp)
            mapView.addAnnotation(annotation)
        }
        mapView.preservesSuperviewLayoutMargins = true
        mapView.insetsLayoutMarginsFromSafeArea = true
        mapView.layoutMargins = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
        mapView.showAnnotations(mapView.annotations, animated: true)
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: labels.bottomAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CommuteDetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "commuteLocation")
        pin.animatesDrop = true
        pin.canShowCallout = true
        return pin
    }
}
