//
//  MediaViewController.swift
//  Navigation
//
//  Created by Egor Badaev on 23.04.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import UIKit

class MediaViewController: UIViewController {

    // MARK: - Custom types
    private enum Segment: Int, CaseIterable {
        case audio = 0
        case video
        case recorder

        var title: String {
            switch self {
            case .audio:
                return "Audio"
            case .video:
                return "Video"
            case .recorder:
                return "Recorder"
            }
        }
    }

    // MARK: - Properties
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: Segment.allCases.map({ $0.title }))

        segmentedControl.toAutoLayout()
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)

        return segmentedControl
    }()

    private var containerView: UIStackView = {
        let containerView = UIStackView()
        containerView.toAutoLayout()
        containerView.axis = .horizontal
        containerView.spacing = 0
        return containerView
    }()

    private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()

        scrollView.toAutoLayout()

        return scrollView
    }()

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupChildViewControllers()
        setupUI()
    }

    // MARK: - Container methods
    override func addChild(_ controller: UIViewController) {
        super.addChild(controller)
        controller.view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: view.frame.width, height: view.frame.height)
        controller.view.toAutoLayout()
        containerView.addArrangedSubview(controller.view)
        controller.didMove(toParent: self)
    }

    // MARK: - Actions
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        showChild(index: sender.selectedSegmentIndex)
    }

    // MARK: - Private methods
    private func setupChildViewControllers() {
        [
            PlayerViewController(),
            VideoPlayerViewController(),
            RecorderViewController()
        ].forEach { addChild($0) }

        showChild(index: 0, animated: false)
    }

    private func setupUI() {
        segmentedControl.selectedSegmentIndex = 0

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }

        view.addSubview(segmentedControl)
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)

        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            scrollView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: AppConstants.margin),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])

        children.forEach { vc in
            NSLayoutConstraint.activate([
                vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                vc.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        }
    }

    private func showChild(index: Int, animated: Bool = true) {
        let offset = CGPoint(x: scrollView.frame.width * CGFloat(index), y: 0)
        scrollView.setContentOffset(offset, animated: animated)

        guard index == Segment.video.rawValue,
              let videoVC = children[index] as? VideoPlayerViewController else {
            return
        }

        videoVC.playFirstVideoIfNeeded()
    }

}
