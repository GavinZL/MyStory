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
    let horizontalAccuracy: Double  // 水平精度（米）
    let verticalAccuracy: Double    // 垂直精度（米）
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
    
    /// 根据精度返回合适的显示文本
    var displayTextByAccuracy: String {
        if horizontalAccuracy < 0 {
            return city ?? name ?? "未知位置"
        }
        
        // 高精度（< 20m）：显示详细地址
        if horizontalAccuracy < 20 {
            if let name = name, !name.isEmpty {
                return name
            }
            if let address = address, !address.isEmpty {
                return address
            }
        }
        
        // 中等精度（20-100m）：显示城市+区域
        if horizontalAccuracy < 100 {
            if let city = city, !city.isEmpty {
                return city
            }
            if let address = address, !address.isEmpty {
                return address
            }
        }
        
        // 低精度（> 100m）：仅显示城市
        return city ?? "位置信息"
    }
    
    /// 获取次要地址信息（用于副标题显示）
    var secondaryAddressText: String? {
        if horizontalAccuracy < 20, let address = address, !address.isEmpty, let name = name, !name.isEmpty, name != address {
            return address
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, horizontalAccuracy, verticalAccuracy, name, address, city, country, useFrequency
    }
}
