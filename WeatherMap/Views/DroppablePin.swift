//
//  DroppablePin.swift
//  WeatherMap
//
//  Created by Waleed Saad on 12/13/18.
//  Copyright © 2018 Waleed Saad. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
    
    
}


