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

class FirstViewController: UIViewController {
    
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
        
        // Sets default view
        let span = MKCoordinateSpanMake(0.5, 0.5)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.89, longitude: -78.88), span: span)
        mapView.setRegion(region, animated: true)
        
        // Draws Polygons
        addPolygon()
        
        // Auto-refresh
        refresh(self)
    }
    
    /// Asynchronous performs the data query then updates the UI
    @objc func refresh (_ sender: Any) {
        // there are about a dozen 1990 records in this particular database that have an incorrectly formatted
        // cad_event_number, so we'll filter them out to get most recent events first.
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
    func drawBlocks() {
        // Max Report Distance From Each Other in meters
        let maxDistance = 1690.0
        // Placeholder for actual data
        var data: [[Double]] = [[1, 2], [3, 5], [5, 4], [4,1]]
        // Points to be drawn on map
        var sectorPoints: [[Double]] = []
        
        let coordinate1 = CLLocation(latitude: data[0][0], longitude: data[0][1])
        sectorPoints.append(data[0])
        data.remove(at: 0)
        
        var i = 0
        repeat {
            let coordinate2 = CLLocation(latitude: data[i][0], longitude: data[i][1])
            if (coordinate2.distance(from: coordinate1) <= maxDistance){
                sectorPoints.append([data[i][0], data[i][1]])
                data.remove(at: i)
            }else{
                i += 1
            }
        } while i < data.count
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
    
    //View Button Clicked
    @IBAction func viewButtonClicked(_ sender: UIButton) {
        print("BUTTON PRESSED")
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

extension FirstViewController: MKMapViewDelegate {
    
}


