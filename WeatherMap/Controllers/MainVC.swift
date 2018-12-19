//
//  ViewController.swift
//  WeatherMap
//
//  Created by Waleed Saad on 12/13/18.
//  Copyright © 2018 Waleed Saad. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainVC: UIViewController {
    
    //OUTLETS
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var pullupviewHeightLayout: NSLayoutConstraint!
    
    //CONSTANTS
    private let locationManager = CLLocationManager()
    private let radius: Double = 1000000.0
    private let tapsRequired = 2
    private let infoViewHeight: CGFloat = 250
    
    //VARIABLES
    private var errorAlert: UIAlertController!
    private var infoView: InfoView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        checkLocationServices()
        addDoubleTapToMap()
    }
    
    //Check for location services enabled or not
    private func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled() {
            checkAuth()
        } else {
            showAlertError(withTitle: "Disabled Location Services!", withMessageToShow: "Please enable your location services")
        }
    }
    
    //Check for WhenInUse Auth
    private func checkAuth(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            if Reachability.isConnectedToNetwork(){
                getCurrentLocation()
            } else {
                showAlertError(withTitle: "No Internet Connection", withMessageToShow: "Please check your internet connection")
            }
            
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    //Request location
    private func getCurrentLocation(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        if let coordinates = locationManager.location?.coordinate {
            centerLocationOnMap(coordinates: coordinates)
        }
    }
    
    //Center view on current location
    private func centerLocationOnMap(coordinates: CLLocationCoordinate2D){
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: radius, longitudinalMeters: radius)
        mapView.setRegion(region, animated: true)
    }

    //Reset view to current location
    @IBAction func centerAction(_ sender: Any) {
        if let coordinates = locationManager.location?.coordinate {
            centerLocationOnMap(coordinates: coordinates)
        }
    }
    
    
    //Alert error dialog
    private func showAlertError(withTitle title: String, withMessageToShow message: String){
        errorAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        present(errorAlert, animated: true) {
            // Enabling Interaction for Transperent Full Screen Overlay
            self.errorAlert.view.superview?.subviews.first?.isUserInteractionEnabled = true
            
            // Adding Tap Gesture to Overlay
           self.errorAlert.view.superview?.subviews.first?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.errorAlertBackgroundTapped)))
        }
    }
    
    @objc func errorAlertBackgroundTapped() {
        errorAlert.dismiss(animated: true, completion: nil)
    }
}



//EXTENSIONS
//CoreLocationDelegate Extension
extension MainVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last else {
            return
        }
        centerLocationOnMap(coordinates: lastLocation.coordinate)

    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            if Reachability.isConnectedToNetwork(){
                if let coordinates = locationManager.location?.coordinate {
                    centerLocationOnMap(coordinates: coordinates)
                }
            } else {
                showAlertError(withTitle: "No Internet Connection", withMessageToShow: "Please check your internet connection")
            }
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showAlertError(withTitle: "Location Services Error", withMessageToShow: "Error happened!")
    }
}

//MapViewDelegate Extension
extension MainVC: MKMapViewDelegate {
    
    //Add double tap to the map
    private func addDoubleTapToMap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropMarkOnMap(sender:)))
        doubleTap.numberOfTapsRequired = tapsRequired
        mapView.addGestureRecognizer(doubleTap)
    }
    
    //Add custom pin
    @objc private func dropMarkOnMap(sender:UITapGestureRecognizer){
        if Reachability.isConnectedToNetwork(){
            showInfoView()
            let touchPoint = sender.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = DroppablePin(coordinate: coordinates, identifier: "DroppablePin")
            annotation.coordinate = coordinates
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(annotation)
            centerLocationOnMap(coordinates: coordinates)
            insertInfoView(coordinates: coordinates)
            addCloseDownSwipeOnPullUpView()
        } else {
            showAlertError(withTitle: "No Internet Connection", withMessageToShow: "Please check your internet connection")
        }
        
        
    }
    
    //Animate info view
    private func showInfoView(){
        pullupviewHeightLayout.constant = infoViewHeight
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    //Add swipe to hide info view
    private func addCloseDownSwipeOnPullUpView(){
        let closeSwipe = UISwipeGestureRecognizer(target: self, action: #selector(hideInfoView))
        closeSwipe.direction = .down
        pullUpView.addGestureRecognizer(closeSwipe)
    }
    
    //SwipeDown Infoview
    @objc private func hideInfoView(){
        pullupviewHeightLayout.constant = 0
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
            for view in self.pullUpView.subviews {
                view.removeFromSuperview()
            }
        }
    }
    
    //Insert InfoView inside show info view
    private func insertInfoView(coordinates: CLLocationCoordinate2D){
        infoView = Bundle.main.loadNibNamed("InfoViewNib", owner: self, options: nil)?.first as? InfoView
            infoView?.frame.size = pullUpView.frame.size
        updateInfoViewData(forView: infoView!, withCoordinates: coordinates)
            pullUpView.addSubview(infoView!)
    }
    
    //Update Location data and Weather accoring to this location
    private func updateInfoViewData(forView view: InfoView, withCoordinates coordinates: CLLocationCoordinate2D){
        view.latitudeLabel.text = "Lat: \(String(format: "%.4f", coordinates.latitude))"
        view.longitudeLabel.text = "Long: \(String(format: "%.4f", coordinates.longitude))"
        getWeather(view: view, coodrinates: coordinates)
    }
    
    //Get Weather Data according to location
    private func getWeather(view: InfoView, coodrinates: CLLocationCoordinate2D){
        let weatherObject = GetWeather()
        weatherObject.getWeatherJson(coordinates: coodrinates) { (weatherResponse) in
            if let currentWeather = weatherResponse {
                DispatchQueue.main.async {
                    self.updateWeatherInfo(forView: view, weather: currentWeather)
                }
            }
        }
    }
    
    //Update Weather info
    private func updateWeatherInfo(forView view:InfoView, weather: WeatherModel){
        if let icon = weather.icon {
            view.iconView.image = UIImage(named: icon)
        }
        if let summary = weather.summary {
            view.summaryLabel.text = summary
        }
        
        if let temperature = weather.temperature {
            let celeziusSign: String = "°"
            view.temperatureLabel.text = "\(Int(temperature))\(celeziusSign)"
        }
        view.activityIndicator.stopAnimating()
    }
    
    //Pin tintcolor
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "DroppablePin")
        pinAnnotationView.animatesDrop = true
        pinAnnotationView.pinTintColor = #colorLiteral(red: 0.3236978054, green: 0.1063579395, blue: 0.574860394, alpha: 1)
        return pinAnnotationView
    }
}
