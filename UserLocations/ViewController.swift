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

/*
Methods

on(event: String, callback: NormalCallback) -> NSUUID - Adds a handler for an event. Items are passed by an array. ack can be used to send an ack when one is requested. See example. Returns a unique id for the handler.
once(event: String, callback: NormalCallback) -> NSUUID - Adds a handler that will only be executed once. Returns a unique id for the handler.
onAny(callback:((event: String, items: AnyObject?)) -> Void) - Adds a handler for all events. It will be called on any received event.
emit(event: String, _ items: AnyObject...) - Sends a message. Can send multiple items.
emit(event: String, withItems items: [AnyObject]) - emit for Objective-C
emitWithAck(event: String, _ items: AnyObject...) -> (timeoutAfter: UInt64, callback: (NSArray?) -> Void) -> Void - Sends a message that requests an acknowledgement from the server. Returns a function which you can use to add a handler. See example. Note: The message is not sent until you call the returned function.
emitWithAck(event: String, withItems items: [AnyObject]) -> (UInt64, (NSArray?) -> Void) -> Void - emitWithAck for Objective-C. Note: The message is not sent until you call the returned function.
connect() - Establishes a connection to the server. A "connect" event is fired upon successful connection.
connect(timeoutAfter timeoutAfter: Int, withTimeoutHandler handler: (() -> Void)?) - Connect to the server. If it isn't connected after timeoutAfter seconds, the handler is called.
close() - Closes the socket. Once a socket is closed it should not be reopened.
reconnect() - Causes the client to reconnect to the server.
joinNamespace() - Causes the client to join nsp. Shouldn't need to be called unless you change nsp manually.
leaveNamespace() - Causes the client to leave the nsp and go back to /
off(event: String) - Removes all event handlers for event.
off(id id: NSUUID) - Removes the event that corresponds to id.
removeAllHandlers() - Removes all handlers.
Client Events

connect - Emitted when on a successful connection.
disconnect - Emitted when the connection is closed.
error - Emitted on an error.
reconnect - Emitted when the connection is starting to reconnect.
reconnectAttempt - Emitted when attempting to reconnect.

*/


class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    lazy var locationManager: CLLocationManager! = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        return manager
    }()
    
    let socket = SocketIOClient(socketURL: "https://fierce-fortress-2845.herokuapp.com/")//, options: [.Log(true), .ForcePolling(true)])
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
