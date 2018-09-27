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

    private(set) var commute: Commute

    private let startLabel: UILabel
    private let endLabel: UILabel

    init(commute: Commute) {
        self.commute = commute
        self.startLabel = UILabel(frame: .zero)
        self.endLabel = UILabel(frame: .zero)
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

        updateLabels()
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

        [commute.startPoint, commute.endPoint].forEach(addAnnotation(for:))
        commute.locations.forEach(addAnnotation(for:))
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

    func updateCommute(_ newCommute: Commute) {
        newCommute.locations.suffix(from: commute.locations.endIndex).forEach(addAnnotation(for:))
        self.commute = newCommute

        updateLabels()
    }

    private func addAnnotation(for location: Location) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.clCoordinate
        annotation.title = formatter.string(from: location.timestamp)
        mapView.addAnnotation(annotation)
    }

    private func addAnnotation(for endPoint: CommuteEndPoint) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = endPoint.location.clCoordinate
        annotation.title = endPoint.identifier == commute.startPoint.identifier ? "Start" : "End"
        annotation.subtitle = endPoint.identifier
        mapView.addAnnotation(annotation)

        let circle = MKCircle(center: endPoint.location.clCoordinate, radius: endPoint.radius)
        circle.title = annotation.title
        mapView.addOverlay(circle)
    }

    private func updateLabels() {
        startLabel.text = "Start: \(formatter.string(from: commute.start))"

        let endText: String
        if let end = commute.end {
            endText = formatter.string(from: end)
        } else {
            endText = "---"
        }
        endLabel.text = "End:   \(endText)"
    }
}

extension CommuteDetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "commuteLocation")
        pin.animatesDrop = true
        pin.canShowCallout = true
        if annotation.title == "Start" {
            pin.pinTintColor = .green
        } else if annotation.title == "End" {
            pin.pinTintColor = .red
        } else {
            pin.pinTintColor = .gray
        }
        return pin
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            switch overlay.title {
            case "Start":
                circle.strokeColor = .green
            case "End":
                circle.strokeColor = .red
            default: break
            }
            circle.fillColor = circle.strokeColor?.withAlphaComponent(0.1)
            circle.lineWidth = 1
            return circle
        } else {
            return MKPolylineRenderer()
        }
    }
}
