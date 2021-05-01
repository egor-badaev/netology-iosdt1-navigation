//
//  InfoViewModel.swift
//  Navigation
//
//  Created by Egor Badaev on 01.05.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

class InfoViewModel: InfoViewControllerOutput {

    // MARK: - Properties
    weak var viewInput: InfoViewControllerInput?

    // MARK: Header
    var shouldDisplayUI: Bool {
        return toDoDataTask?.state != .running && planetDataTask?.state != .running
    }

    private(set) var titleLabelText: String?
    private(set) var periodLabelText: String?
    private(set) var planetNameText: String = ""

    private var toDoUrlSting: String
    private var planetUrlString: String
    private var toDoDataTask: URLSessionDataTask?
    private var planetDataTask: URLSessionDataTask?

    // MARK: Residents table
    var numberOfRows: Int {
        return residents.count
    }

    var shouldDisplayTable: Bool {
        return planetDataTask?.state == .completed && activeDataTasks == 0
    }

    private var residents: [Person] = []
    private var activeDataTasks = 0

    // MARK: - Initializer
    init(forPostWithIndex index: Int) {
        toDoUrlSting = FeedModel.shared.posts[index].toDoUrl
        planetUrlString = FeedModel.shared.posts[index].planetUrl
    }

    // MARK: - Methods
    // MARK: Header
    func fetchData() {
        guard let toDoUrl = URL(string: toDoUrlSting),
              let planetUrl = URL(string: planetUrlString) else {
            print("Can't create URL from the string provided")
            viewInput?.closeController(for: NetworkError.invalidURL)
            return
        }

        toDoDataTask = NetworkService.makeDataTask(with: toDoUrl) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("NetworkService failure: \(error.localizedDescription)")
                self.viewInput?.closeController(for: error)
            case .success(let (_, data)):
                if let dictionary = try? data.toObject(),
                   let toDo = ToDo(from: dictionary) {
                    self.titleLabelText = toDo.title
                    self.viewInput?.displayUI()
                } else {
                    print("JSON data has unknown format")
                    self.viewInput?.closeController(for: NetworkError.invalidData)
                }
            }
        }
        toDoDataTask?.resume()

        planetDataTask = NetworkService.makeDataTask(with: planetUrl, completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("NetworkService failure: \(error.localizedDescription)")
                self.viewInput?.closeController(for: error)
            case .success(let (_, data)):
                do {
                    let planet = try JSONDecoder().decode(Planet.self, from: data)

                    var period: String

                    if let planetName = planet.name {
                        self.planetNameText = "планеты \"\(planetName)\""
                    } else {
                        self.planetNameText = "неизвестной планеты"
                    }

                    if let planetPeriod = planet.orbitalPeriod {
                        let days = planetPeriod.pluralForm(of: PluralizableString(one: "день", few: "дня", many: "дней"))
                        period = "составляет \(days)"
                    } else {
                        period = "неизвестен"
                    }

                    self.periodLabelText = "Период обращения \(self.planetNameText) по своей орбите \(period)"
                    self.viewInput?.displayUI()

                    self.fetchResidents(from: planet.residents)

                } catch {
                    print("Decoding failed: \(error)")
                    self.viewInput?.closeController(for: error)
                }
            }
        })
        planetDataTask?.resume()
    }

    // MARK: Residents table
    func textLabelForRow(index: Int) -> String {
        return residents[index].name
    }

    private func fetchResidents(from urls: [URL]) {
        guard !urls.isEmpty else {
            print("No residents on the planet")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.viewInput?.showNoResidentsLabel()
            }
            return
        }

        urls.forEach { url in
            activeDataTasks += 1
            NetworkService.startDataTask(with: url) { [weak self] result in
                guard let self = self else { return }
                self.activeDataTasks -= 1

                switch result {
                case .failure(let error):
                    print("NetworkService failure: \(error.localizedDescription)")
                    self.viewInput?.closeController(for: error)
                case .success(let (_, data)):
                    do {
                        let person = try JSONDecoder().decode(Person.self, from: data)
                        self.residents.append(person)
                        self.viewInput?.showResidentsTableIfReady()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

}
