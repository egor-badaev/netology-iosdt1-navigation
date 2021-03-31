//
//  PlanetModel.swift
//  Navigation
//
//  Created by Egor Badaev on 30.03.2021.
//  Copyright © 2021 Egor Badaev. All rights reserved.
//

import Foundation

struct Planet: Decodable {
    
    // MARK: - Properties
    let name: String?
    let rotationPeriod: Int?
    let orbitalPeriod: Int?
    let diameter: Int?
    let climate: [ClimateType]
    let gravity: Gravity?
    let terrain: [String]
    let surfaceWater: Int?
    let population: Int?
    let residents: [URL]
    let films: [URL]
    let created: Date
    let edited: Date
    let url: URL
    
    // MARK: - Helpers
    private static let nilKey = "unknown"
    
    enum ClimateType: String {
        case arid, temperate, tropical, frozen, murky, windy, hot, frigid, humid, moist, polluted, superheated, subartic, artic, rocky
        case artificialTemperate = "artificial temperate"
    }
    
    typealias Gravity = Double
    
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case name, diameter, climate, gravity, terrain, population, residents, films, created, edited, url
        case rotationPeriod = "rotation_period"
        case orbitalPeriod = "orbital_period"
        case surfaceWater = "surface_water"
    }
    
    // MARK: - Init
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try Planet.decodeNilOrString(with: container, forKey: .name)
        
        rotationPeriod = try Planet.decodeIntFromString(with: container, forKey: .rotationPeriod)
        orbitalPeriod = try Planet.decodeIntFromString(with: container, forKey: .orbitalPeriod)
        diameter = try Planet.decodeIntFromString(with: container, forKey: .diameter)
        
        let climateString = try container.decode(String.self, forKey: .climate)
        let climateStringArray = climateString.split(separator: ",")
        var climateArray = [ClimateType]()
        climateStringArray.forEach {
            if let climateItem = ClimateType(rawValue: $0.trimmingCharacters(in: .whitespaces)) {
                climateArray.append(climateItem)
            }
        }
        climate = climateArray
        
        let gravityString = try container.decode(String.self, forKey: .gravity)
        gravity = gravityString.toGravity()
        
        var terrainArray = [String]()
        if let terrains = try Planet.decodeNilOrString(with: container, forKey: .terrain) {
            let terrainsArray = terrains.split(separator: ",")
            terrainArray = terrainsArray.map { $0.trimmingCharacters(in: .whitespaces) }
        }
        terrain = terrainArray
        
        surfaceWater = try Planet.decodeIntFromString(with: container, forKey: .surfaceWater)
        population = try Planet.decodeIntFromString(with: container, forKey: .population)
        
        residents = try Planet.decodeUrlStrings(with: container, forKey: .residents)
        films = try Planet.decodeUrlStrings(with: container, forKey: .films)
        
        created = try Planet.decodeDateString(with: container, forKey: .created)
        edited = try Planet.decodeDateString(with: container, forKey: .edited)
        
        let urlString = try container.decode(String.self, forKey: .url)
        url = try urlString.toURL()
    }
    
    // MARK: - Helper methods
    private static func decodeUrlStrings(with container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> [URL] {
        let urlStrings = try container.decode([String].self, forKey: key)
        var urls = [URL]()
        try urlStrings.forEach { urlString in
            let url = try urlString.toURL()
            urls.append(url)
        }
        return urls
    }
    
    private static func decodeDateString(with container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Date {
        let dateString = try container.decode(String.self, forKey: key)
        let date = try dateString.toISO8601Date()
        return date
    }
    
    private static func decodeNilOrString(with container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> String? {
        let string = try container.decode(String.self, forKey: key)
        return string == Planet.nilKey ? nil : string

    }
    
    private static func decodeIntFromString(with container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Int? {
        if let number = try? container.decode(Int.self, forKey: key) {
            return number
        }
        let string = try container.decode(String.self, forKey: key)
        return Int(string)
    }
}

// MARK: - Gravity type extensions

extension Planet.Gravity {
    var humanReadable: String {
        return "\(self) standard"
    }
}

fileprivate extension String {
    func toGravity() -> Planet.Gravity? {
        let components = self.split(separator: " ")
        guard let string = components.first,
              let number = Double(string) else {
            print("Cannot convert string to gravity")
            return nil
        }
        return number
    }
}
