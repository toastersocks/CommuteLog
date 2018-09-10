//
//  CommutesViewController.swift
//  CommuteLog
//
//  Created by Ryan Arana on 8/18/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import UIKit

protocol CommutesViewControllerEventHandler: class {
    func commutesViewController(_ vc: CommutesViewController, didSelect commute: Commute)
    func commutesViewController(_ vc: CommutesViewController, didDelete commute: Commute)
}

class CommutesViewController: UIViewController {
    let tableView: UITableView
    weak var eventHandler: CommutesViewControllerEventHandler?

    var commutes: [Commute] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    init(commutes: [Commute] = [], eventHandler: CommutesViewControllerEventHandler? = nil) {
        tableView = UITableView(frame: .zero)
        self.commutes = commutes
        self.eventHandler = eventHandler
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            tableView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor)
        ])

        view.backgroundColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
    }
}

extension CommutesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commutes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let commute = commutes[indexPath.item]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.textLabel?.text = "\(formatter.string(from: commute.start)) - \(String(format: "%0.1f min", commute.duration.duration / 60))"
        cell.detailTextLabel?.text = commute.description
        return cell
    }
}

extension CommutesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        eventHandler?.commutesViewController(self, didSelect: commutes[indexPath.item])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            eventHandler?.commutesViewController(self, didDelete: commutes[indexPath.item])
        default: break
        }
    }
}

