//
//  LocationInfo.swift
//  MyStory
//
//  位置信息模型
//

import Foundation

struct LocationInfo: Codable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let name: String?
    let address: String?
    let city: String?
    let country: String?
    var useFrequency: Int = 0
    
    var displayText: String {
        if let name = name, !name.isEmpty {
            return name
        } else if let city = city, !city.isEmpty {
            return city
        } else if let address = address, !address.isEmpty {
            return address
        } else {
            return "未知位置"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, name, address, city, country, useFrequency
    }
}
