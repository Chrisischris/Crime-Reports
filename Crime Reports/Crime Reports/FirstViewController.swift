//
//  FirstViewController.swift
//  Crime Reports
//
//  Created by Chris Haen on 3/7/18.
//  Copyright © 2018 Christopher Haen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class FirstViewController: UIViewController, MKMapViewDelegate{
    
    //Location Manager
    let locationManager = CLLocationManager()
    
    //Map View Outlet
    @IBOutlet weak var mapView: MKMapView!
    //View Button Outlet
    @IBOutlet weak var viewButton: UIBarButtonItem!
    
    //SODA Client 3CYKTT42HJUDGalN2tURvsYoi
    let client = SODAClient(domain: "data.buffalony.gov", token: "3CYKTT42HJUDGalN2tURvsYoi")
    //Crime Reports Data
    var data: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.showsUserLocation = true
        requestLocationAccess()
        
        // Auto-refresh
        refresh(self)
        
        // Sets default view
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.89, longitude: -78.88), span: span)
        mapView.setRegion(region, animated: true)
        
        // Draws Polygons
        //addPolygon()
       
        //update(withData: data, animated: true)
        
    }
    
    /// Asynchronous performs the data query then updates the UI
    @objc func refresh (_ sender: Any) {
        let cngQuery = client.query(dataset: "d6g9-xbgu").filter("incident_datetime > '2017-01-01T01:00:00.000'")
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        cngQuery.orderDescending("incident_datetime").get { res in
            switch res {
            case .dataset (let data):
                // Update our data
                self.data = data
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                let alertController = UIAlertController(title: "Error Refreshing", message: errorMessage, preferredStyle:.alert)
                self.present(alertController, animated: true, completion: nil)
            }
            
            // Update the UI
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    //Annotates Map With Blocks of Color Determined by ammount of reports
    func drawBlocks(withData data: [[String: Any]]!) {
        // Clear Old Annotations
        if mapView.annotations.count > 0 {
            let ex = mapView.annotations
            mapView.removeAnnotations(ex)
        }
        
        // Longitude and latitude limits
        var minLatitude : CLLocationDegrees = 90.0
        var maxLatitude : CLLocationDegrees = -90.0
        var minLongitude : CLLocationDegrees = 180.0
        var maxLongitude : CLLocationDegrees = -180.0
        
        self.data = data
        
        // Max Report Distance From Each Other in meters
        let maxDistance = 1650.0
        // Placeholder for actual data
        var tempData: [[Double]] = []
        // Points to be drawn on map
        var sectorPoints: [CLLocationCoordinate2D] = []

        
        var anns : [MKAnnotation] = []
        for item in data {
            
            // item["incident_location"] != nil
            guard let lat = (item["latitude"] as? NSString)?.doubleValue,
                let lon = (item["longitude"] as? NSString)?.doubleValue else { continue }
            
            // Set coordinates to tempData
            tempData.append([lat, lon])
            
            minLatitude = min(minLatitude, lat)
            maxLatitude = max(maxLatitude, lat)
            minLongitude = min(minLongitude, lon)
            maxLongitude = max(maxLongitude, lon)
            
            let a = MKPointAnnotation()
            a.title = item["incident_type_primary"] as? String ?? ""
            a.coordinate = CLLocationCoordinate2D (latitude: lat, longitude: lon)
            a.subtitle = item["incident_datetime"] as? String ?? item["address_1"] as? String ?? ""
            anns.append(a)
        }
        
        
        let coordinate1 = CLLocation(latitude: tempData[0][0], longitude: tempData[0][1])

        var i = 0
        repeat {
            let coordinate2 = CLLocation(latitude: tempData[i][0], longitude: tempData[i][1])
            if (coordinate2.distance(from: coordinate1) <= maxDistance){
                sectorPoints.append(CLLocationCoordinate2D(latitude: tempData[i][0], longitude: tempData[i][1]))
                tempData.remove(at: i)
                
            }else{
                i += 1
            }
        } while i < tempData.count
        
        let polygon = MKPolygon(coordinates: sectorPoints, count: sectorPoints.count)
        mapView?.add(polygon)
    }
    
    // Draws Polygons
    func addPolygon() {
        var locations = [CLLocationCoordinate2D(latitude:42.8878136848238 , longitude:-78.877777858282 ), CLLocationCoordinate2D(latitude:42.91441 , longitude:-78.83839 ), CLLocationCoordinate2D(latitude:42.94835949967193 , longitude:-78.88673757608235)]
        let polygon = MKPolygon(coordinates: &locations, count: locations.count)
        mapView?.add(polygon)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // Not Going to be used just for reference
    func update(withData data: [[String: Any]]!, animated: Bool) {
        
        // Remember the data because we may not be able to display it yet
        self.data = data
        
        if (!isViewLoaded) {
            return
        }
        
        // Clear old annotations
        if mapView.annotations.count > 0 {
            let ex = mapView.annotations
            mapView.removeAnnotations(ex)
        }
        
        // Longitude and latitude limits
        var minLatitude : CLLocationDegrees = 90.0
        var maxLatitude : CLLocationDegrees = -90.0
        var minLongitude : CLLocationDegrees = 180.0
        var maxLongitude : CLLocationDegrees = -180.0
        
        // Create annotations for the data
        var anns : [MKAnnotation] = []
        for item in data {
            
            // item["incident_location"] != nil
            guard let lat = (item["latitude"] as? NSString)?.doubleValue,
                let lon = (item["longitude"] as? NSString)?.doubleValue else { continue }
            
            minLatitude = min(minLatitude, lat)
            maxLatitude = max(maxLatitude, lat)
            minLongitude = min(minLongitude, lon)
            maxLongitude = max(maxLongitude, lon)
            
            let a = MKPointAnnotation()
            a.title = item["incident_type_primary"] as? String ?? ""
            a.coordinate = CLLocationCoordinate2D (latitude: lat, longitude: lon)
            a.subtitle = item["incident_datetime"] as? String ?? item["address_1"] as? String ?? ""
            anns.append(a)
        }
        
        // Set the annotations and center the map
        if (anns.count > 0) {
            mapView.addAnnotations(anns)
            let span = MKCoordinateSpanMake(maxLatitude - minLatitude, maxLongitude - minLongitude)
            let center = CLLocationCoordinate2D(latitude: (maxLatitude + minLatitude)/2.0, longitude: (maxLongitude + minLongitude)/2.0)
            let region = MKCoordinateRegionMake(center, span)
            //            let r = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2D(latitude: lata*w, longitude: lona*w), 2000, 2000)
            mapView.setRegion(region, animated: animated)
        }
    }
    
    //View Button Clicked
    @IBAction func viewButtonClicked(_ sender: UIButton) {
        print("BUTTON PRESSED")
        //update(withData: data, animated: true)
        drawBlocks(withData: data)
    }
    
    //Request Location Access
    func requestLocationAccess() {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
            
        case .denied, .restricted:
            print("location access denied")
            
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }

}



