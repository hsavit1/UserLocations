//
//  ViewController.swift
//  UserLocations
//
//  Created by Henry Savit on 12/7/15.
//  Copyright © 2015 HenrySavit. All rights reserved.
//

import UIKit
import Socket_IO_Client_Swift
import CoreLocation
import MapKit
import Foundation


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        return manager
    }()
    
    let socket = SocketIOClient(socketURL: "https://fierce-fortress-2845.herokuapp.com/", options: [.Log(true), .ForcePolling(true)])
    var resetAck:SocketAckEmitter?

    var locations = [MKPointAnnotation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket.on("connection") {data, ack in
            print("socket connected")
        }
        
        socket.on("removeLocation") {data, ack in
            print("removed the location")
        }
        
        socket.on("locationUpdate") {data, ack in
            print("added the location")
        }
        
        self.socket.connect()
        
        self.socket.onAny {
            print("Got event: \($0.event), with items: \($0.items)")
        }
    }

    // MARK:- CLLocationManagerDelegate methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }

    @IBAction func centerLocationButtonPressed(sender: UIBarButtonItem) {
        self.mapView.fitMapViewToAnnotaionList()
    }
    
    @IBAction func zoomOut(sender: UIBarButtonItem) {
        self.mapView.setRegion((MKCoordinateRegionMakeWithDistance((self.locationManager.location?.coordinate)!, 10000000, 10000000)), animated: true)
    }
    
    func dropAnnotations(){
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        //remove the old location from socket
        socket.emit("removeLocation", oldLocation.coordinate as! AnyObject)
        
        //add a new location to socket
        socket.emit("locationUpdate", newLocation.coordinate as! AnyObject)
        
        // Add another annotation to the map.
        let annotation = MKPointAnnotation()
        annotation.coordinate = newLocation.coordinate
        
        // Also add to our map so we can remove old values later
        locations.append(annotation)
        
        // Remove values if the array is too big
        while locations.count > 100 {
            let annotationToRemove = locations.first!
            locations.removeAtIndex(0)
            
            // Also remove from the map
            mapView.removeAnnotation(annotationToRemove)
        }
        
        if UIApplication.sharedApplication().applicationState == .Active {
            mapView.showAnnotations(locations, animated: true)
            mapView.fitMapViewToAnnotaionList()
        } else {
            NSLog("App is currently in the background. New location is at %@", newLocation)
        }
    }

}


extension MKMapView {
    func fitMapViewToAnnotaionList() -> Void {
        let mapEdgePadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        var zoomRect:MKMapRect = MKMapRectNull
        
        for index in 0..<self.annotations.count {
            let annotation = self.annotations[index]
            let aPoint:MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
            let rect:MKMapRect = MKMapRectMake(aPoint.x, aPoint.y, 0.1, 0.1)
            
            if MKMapRectIsNull(zoomRect) {
                zoomRect = rect
            } else {
                zoomRect = MKMapRectUnion(zoomRect, rect)
            }
        }
        self.setVisibleMapRect(zoomRect, edgePadding: mapEdgePadding, animated: true)
    }
}
