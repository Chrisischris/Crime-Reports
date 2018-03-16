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

// Variables
var startDateValue = "2018-01-01"
var endDateValue = "2099-01-01"
var maxDistance = 1659.345
//Crime Reports Data
var data: [[String: Any]] = []

class FirstViewController: UIViewController, MKMapViewDelegate{
    
    //Location Manager
    let locationManager = CLLocationManager()
    
    //Container View Outlet
    @IBOutlet weak var containerView: UIView!
    //Map View Outlet
    @IBOutlet weak var mapView: MKMapView!
    //View Button Outlet
    @IBOutlet weak var viewButton: UIBarButtonItem!
    //Refresh Button Outlet
    @IBOutlet weak var refreshButton: UIButton!

    
    //SODA Client 3CYKTT42HJUDGalN2tURvsYoi
    let client = SODAClient(domain: "data.buffalony.gov", token: "3CYKTT42HJUDGalN2tURvsYoi")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView?.showsUserLocation = true
        requestLocationAccess()
        
        data.removeAll()
        
        // Auto-refresh
        refresh(self)
        
        // Sets default view
        let span = MKCoordinateSpanMake(0.25, 0.25)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.89, longitude: -78.88), span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
    // Performs the data query then updates the UI
    @objc func refresh (_ sender: Any) {
        data.removeAll()
        // Warn about setting limit too high
        let cngQuery = client.query(dataset: "d6g9-xbgu").filter("incident_datetime >= '" + startDateValue + "T01:00:00.000' AND incident_datetime < '" + endDateValue + "T01:00:00.000'").limit(10000000000000)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        cngQuery.orderDescending("incident_datetime").get { res in
            switch res {
            case .dataset (let adata):
                // Update our data
                data = adata
            case .error (let err):
                let errorMessage = (err as NSError).userInfo.debugDescription
                let alertController = UIAlertController(title: "Error Refreshing", message: errorMessage, preferredStyle:.alert)
                self.present(alertController, animated: true, completion: nil)
            }
            
            // Update the UI
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.drawBlocks(withData: data)
        }
    }
    
    //Annotates Map With Blocks of Color Determined by ammount of reports
    func drawBlocks(withData adata: [[String: Any]]!) {
        // Clear Old Annotations
        if mapView.overlays.count > 0 {
            self.mapView.overlays.forEach {
                if !($0 is MKUserLocation) {
                    self.mapView.remove($0)
                }
            }
        }
        
        data = adata
        
        var tempData: [[Double]] = []
        
        
        var anns : [MKAnnotation] = []
        for item in data {
            
            // item["incident_location"] != nil
            guard let lat = (item["latitude"] as? NSString)?.doubleValue,
                let lon = (item["longitude"] as? NSString)?.doubleValue else { continue }
            
            // Set coordinates to tempData
            tempData.append([lat, lon])
            
            // Not Used Yet
            let a = MKPointAnnotation()
            a.title = item["incident_type_primary"] as? String ?? ""
            a.coordinate = CLLocationCoordinate2D (latitude: lat, longitude: lon)
            a.subtitle = item["incident_datetime"] as? String ?? item["address_1"] as? String ?? ""
            anns.append(a)
        }
        
        var rangeFinder = tempData
        var minPoints = 100000000
        var maxPoints = 0
        while (rangeFinder.count > 1){
            let rangeCoordinate1 = CLLocation(latitude: rangeFinder[0][0], longitude: rangeFinder[0][1])
            rangeFinder.remove(at: 0)
            var currentCount = 0
            var x = 0
            repeat {
                // Removes Empty Fields
                if (rangeFinder[x][0] == 0 || rangeFinder[x][1] == 0){
                    rangeFinder.remove(at: x)
                }else{
                    let rangeCoordinate2 = CLLocation(latitude: rangeFinder[x][0], longitude: rangeFinder[x][1])
                    if (rangeCoordinate2.distance(from: rangeCoordinate1) <= maxDistance){
                        currentCount += 1
                        rangeFinder.remove(at: x)
                    }else{
                        x += 1
                    }
                }
            } while x < rangeFinder.count
            
            if (currentCount > maxPoints){
                maxPoints = currentCount
            }
            if (currentCount < minPoints && currentCount > 5){
                minPoints = currentCount
            }
        }
        
        var colorRanges: [Int] = [0,0,0,0]
        for index in 0...3 {
            colorRanges[index] = minPoints + ((maxPoints - minPoints)/5) * (index + 1)
        }
        print(minPoints, maxPoints, colorRanges)
        
        while (tempData.count > 1){
            // Points to be drawn on map
            var sectorPoints: [CLLocationCoordinate2D] = []
            
            // Filters Points by set max Distance from one another
            let coordinate1 = CLLocation(latitude: tempData[0][0], longitude: tempData[0][1])
            tempData.remove(at: 0)
            var i = 0
            repeat {
                // Removes Empty Fields
                if (tempData[i][0] == 0 || tempData[i][1] == 0){
                    tempData.remove(at: i)
                }else{
                    let coordinate2 = CLLocation(latitude: tempData[i][0], longitude: tempData[i][1])
                    if (coordinate2.distance(from: coordinate1) <= maxDistance){
                        sectorPoints.append(CLLocationCoordinate2D(latitude: tempData[i][0], longitude: tempData[i][1]))
                        tempData.remove(at: i)
                        
                    }else{
                        i += 1
                    }
                }
            } while i < tempData.count
        
            // Finds Outside Coordinates
            var shapeCoordinates: [CLLocationCoordinate2D] = [CLLocationCoordinate2D(latitude: -180, longitude: 0), CLLocationCoordinate2D(latitude: 0, longitude: 0), CLLocationCoordinate2D(latitude: 0, longitude: -180), CLLocationCoordinate2D(latitude: 0, longitude: -180),
                CLLocationCoordinate2D(latitude: 90, longitude: -180), CLLocationCoordinate2D(latitude: 90, longitude: 0),
                CLLocationCoordinate2D(latitude: 90, longitude: 0), CLLocationCoordinate2D(latitude: 0, longitude: 0)]
            for item in sectorPoints {
                // Top Left
                if (item.longitude < shapeCoordinates[0].longitude && item.latitude > shapeCoordinates[0].latitude){
                    shapeCoordinates[0] = item
                }
                // Top Middle
                if (item.latitude > shapeCoordinates[1].latitude){
                    shapeCoordinates[1] = item
                }else if (shapeCoordinates[1].latitude == 0){
                    shapeCoordinates[1] = shapeCoordinates[0]
                }
                // Top Right
                if (item.longitude > shapeCoordinates[2].longitude && item.latitude > shapeCoordinates[2].latitude){
                    shapeCoordinates[2] = item
                }else if (shapeCoordinates[2].latitude == 0){
                    shapeCoordinates[2] = shapeCoordinates[1]
                }
                // Right Middle
                if (item.longitude > shapeCoordinates[3].longitude){
                    shapeCoordinates[3] = item
                }else if (shapeCoordinates[3].latitude == 0){
                    shapeCoordinates[3] = shapeCoordinates[2]
                }
                // Bottom Right
                if (item.longitude > shapeCoordinates[4].longitude && item.latitude < shapeCoordinates[4].latitude){
                    shapeCoordinates[4] = item
                }else if (shapeCoordinates[4].latitude == 90){
                    shapeCoordinates[4] = shapeCoordinates[3]
                }
                // Bottom Middle
                if (item.latitude < shapeCoordinates[5].latitude){
                    shapeCoordinates[5] = item
                }else if (shapeCoordinates[5].latitude == 90){
                    shapeCoordinates[5] = shapeCoordinates[4]
                }
                // Bottom Left
                if (item.longitude < shapeCoordinates[6].longitude && item.latitude < shapeCoordinates[6].latitude){
                    shapeCoordinates[6] = item
                }else if (shapeCoordinates[6].latitude == 90){
                    shapeCoordinates[6] = shapeCoordinates[5]
                }
                // Left Middle
                if (item.longitude < shapeCoordinates[7].longitude){
                    shapeCoordinates[7] = item
                }else  if (shapeCoordinates[7].latitude == 0){
                    shapeCoordinates[7] = shapeCoordinates[6]
                }
            }
            
            if (shapeCoordinates[0].latitude != -180){
                let polygon = MKPolygon(coordinates: shapeCoordinates, count: shapeCoordinates.count)
                
                if (sectorPoints.count < colorRanges[0]){polygon.title = "1"}
                if (sectorPoints.count > colorRanges[0]){polygon.title = "2"}
                if (sectorPoints.count > colorRanges[1]){polygon.title = "3"}
                if (sectorPoints.count > colorRanges[2]){polygon.title = "4"}
                if (sectorPoints.count > colorRanges[3]){polygon.title = "5"}
                
                mapView?.add(polygon)
            }
        }
    }
    
    // mapView Renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolygon {
            let title = overlay.title as? String
            if (title == "1"){
                let renderer1 = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer1.fillColor = #colorLiteral(red: 0.9882352941, green: 0.7254901961, blue: 0.1764705882, alpha: 0.6)
                renderer1.strokeColor = UIColor.black
                renderer1.lineWidth = 0.1
                return renderer1
            }
            if (title == "2"){
                let renderer2 = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer2.fillColor = #colorLiteral(red: 0.8156862745, green: 0.368627451, blue: 0.1450980392, alpha: 0.6)
                renderer2.strokeColor = UIColor.black
                renderer2.lineWidth = 0.1
                return renderer2
            }
            if (title == "3"){
                let renderer3 = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer3.fillColor = #colorLiteral(red: 0.7019607843, green: 0.1254901961, blue: 0.1215686275, alpha: 0.6)
                renderer3.strokeColor = UIColor.black
                renderer3.lineWidth = 0.1
                return renderer3
            }
            if (title == "4"){
                let renderer4 = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer4.fillColor = #colorLiteral(red: 0.4156862745, green: 0.1411764706, blue: 0.262745098, alpha: 0.6)
                renderer4.strokeColor = UIColor.black
                renderer4.lineWidth = 0.1
                return renderer4
            }
            if (title == "5"){
                let renderer5 = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer5.fillColor = #colorLiteral(red: 0.1098039216, green: 0.1647058824, blue: 0.4196078431, alpha: 0.6)
                renderer5.strokeColor = UIColor.black
                renderer5.lineWidth = 0.1
                return renderer5
            }
        }
        return MKOverlayRenderer()
    }
    
    // View Button Clicked
    @IBAction func viewButtonClicked(_ sender: UIButton) {
        // Set Container View Visibilty
        containerView.isHidden = !containerView.isHidden
    }
    
    // Refresh Button Clicked
    @IBAction func refreshButtonClicked(_ sender: Any) {
        print("BUTTON PRESSED")
        print(data.count)
        refresh(self)
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

// Drop Down Class
class dropDownController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var radiusInMiles: UILabel!
    
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func dateChanged(_ sender: UIDatePicker) {
        if (sender == startDatePicker){
            let dateString = String(describing: sender.date)
            startDateValue = String(dateString.prefix(10))
        }
        if (sender == endDatePicker){
            let dateString = String(describing: sender.date)
            endDateValue = String(dateString.prefix(10))
        }
    }

    
    @IBAction func radiusChanged(_ sender: UISlider) {
        maxDistance = Double(sender.value)
        let maxDistanceFeet = Int(maxDistance * 3.2808)
        radiusInMiles.text = "Radius: " + String(maxDistanceFeet) + " ft"
    }
    
}



