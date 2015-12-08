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

    //UI
    @IBOutlet weak var mapView: MKMapView!
    
    //Manager
    let locationManager = CLLocationManager()

    //Socket
    let socket = SocketIOClient(socketURL: "http://192.196.1.106:3000")//, options: [.Log(true), .ForcePolling(true)])
    var resetAck:SocketAckEmitter?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self

        socket.on("connection") {data, ack in
            print("socket connected")
        }
        self.socket.connect()
        self.socket.onAny {
            print("Got event: \($0.event), with items: \($0.items)")
            //            self.ongoingChat.append(data[0] as! (name: String, time:NSDate, lat:CLLocationDegrees?, lon:CLLocationDegrees?))
            //            self.tableView.reloadData()
        }
    }

    // MARK:- CLLocationManagerDelegate methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
//        if let location = locations.first as CLLocation? {
//            mapView.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 3000, 3000)
//        }
    }

    @IBAction func centerLocationButtonPressed(sender: UIBarButtonItem) {
        self.mapView.fitMapViewToAnnotaionList()
    }
    
    @IBAction func zoomOut(sender: UIBarButtonItem) {
        
//        self.mapView.setZoomByDelta(10, animated: true)
        self.mapView.setRegion((MKCoordinateRegionMakeWithDistance((self.locationManager.location?.coordinate)!, 10000000, 10000000)), animated: true)

    }
    
    func dropAnnotations(){
        
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
    
//    func setZoomByDelta(delta: Double, animated: Bool) {
//        var _region = region;
//        var _span = region.span;
//        _span.latitudeDelta *= delta;
//        _span.longitudeDelta *= delta;
//        
//        if _span.latitudeDelta < 2000000 && _span.longitudeDelta < 2000000 {
//            _region.span = _span;
//        }
//        
//        setRegion(_region, animated: animated)
//    }
    
}
