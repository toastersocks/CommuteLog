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
    func startCommute(for vc: CommutesViewController)
    func endCommute(for vc: CommutesViewController)
}

class CommutesViewController: UIViewController {
    let tableView: UITableView
    let formatter: DateFormatter
    weak var eventHandler: CommutesViewControllerEventHandler?

    var commutes: [Commute] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateNavButton()
            }
        }
    }

    init(commutes: [Commute] = [], eventHandler: CommutesViewControllerEventHandler? = nil) {
        tableView = UITableView(frame: .zero)
        self.commutes = commutes
        self.eventHandler = eventHandler
        self.formatter = DateFormatter()
        formatter.dateStyle = .medium
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Fuck storyboards.")
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
        updateNavButton()
    }

    private func updateNavButton() {
        if commutes.filter({ $0.isActive }).isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(startCommute))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "End", style: .plain, target: self, action: #selector(endCommute))
        }
    }

    @objc private func startCommute() {
        eventHandler?.startCommute(for: self)
        updateNavButton()
    }

    @objc private func endCommute() {
        eventHandler?.endCommute(for: self)
        updateNavButton()
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
        cell.textLabel?.text = "\(formatter.string(from: commute.start)) - \(String(format: "%0.1f min", commute.duration.duration / 60))"
        cell.detailTextLabel?.text = commute.description
        if commute.isActive {
            cell.backgroundColor = .green
        } else {
            cell.backgroundColor = .white
        }
        return cell
    }
}

extension CommutesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        eventHandler?.commutesViewController(self, didSelect: commutes[indexPath.item])
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !commutes[indexPath.item].isActive
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

