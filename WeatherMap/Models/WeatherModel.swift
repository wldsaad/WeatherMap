//
//  WeatherModel.swift
//  WeatherMap
//
//  Created by Waleed Saad on 12/13/18.
//  Copyright © 2018 Waleed Saad. All rights reserved.
//

import Foundation

enum weatherKeys: String {
    case summary, temperature, icon
}

struct WeatherModel {
    private(set) public var temperature: Double?
    private(set) public var summary: String?
    private(set) public var icon: String?
    
    
    
    init(weatherJson: [String:Any]) {
        if let summary = weatherJson[weatherKeys.summary.rawValue] as? String {
            self.summary = summary
        }
        if let icon = weatherJson[weatherKeys.icon.rawValue] as? String {
            self.icon = icon
        }
        if let temperature = weatherJson[weatherKeys.temperature.rawValue] as? Double {
            self.temperature = temperature
        }
    }
}


