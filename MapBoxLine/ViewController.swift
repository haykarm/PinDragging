//
//  ViewController.swift
//  MapBoxLine
//
//  Created by Hayk Harutyunyan on 11/1/20.
//  Copyright © 2020 Hayk Harutyunyan. All rights reserved.
//

import UIKit
import Mapbox
import CoreLocation

class ViewController: UIViewController {

    var locationManager = CLLocationManager()
    @IBOutlet weak var mapView: MGLMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupLocationManager()
        addTapGesture()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setupLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func addTapGesture() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
        singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
         
    }
    
    @objc private func handleMapTap(sender: UITapGestureRecognizer) {
        // Convert tap location (CGPoint) to geographic coordinate (CLLocationCoordinate2D).
        let tapPoint: CGPoint = sender.location(in: mapView)
        let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: nil)
        print("You tapped at: \(tapCoordinate.latitude), \(tapCoordinate.longitude)")
        
        // Remove any existing polyline(s) from the map.
//        if mapView.annotations?.count != nil, let existingAnnotations = mapView.annotations {
        //            mapView.removeAnnotations(existingAnnotations)
        //        }
        if let annot = mapView.annotations, annot.count > 2 {
            mapView.annotations?.forEach({ (annotation) in
                mapView.removeAnnotation(annotation)
            })
        }
        
        if mapView.annotations == nil || mapView.annotations!.count < 2 {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = tapCoordinate
            mapView.addAnnotation(annotation)
            annotation.title = "To drag this annotation, first tap and hold."

        }
        
        if let annot = mapView.annotations, annot.count == 2 {
            // Create an array of coordinates for our polyline, starting at the center of the map and ending at the tap coordinate.
            var coordinates: [CLLocationCoordinate2D] = annot.map {$0.coordinate}
            let polyline = MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
            mapView.addAnnotation(polyline)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.setCenter(locationManager.location?.coordinate ?? Constants.initialCoordinates, zoomLevel: Constants.initialZoom, animated: false)
        locationManager.stopUpdatingLocation()
    }
}

extension ViewController: MGLMapViewDelegate {

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
         //This example is only concerned with point annotations.
        guard annotation is MGLPointAnnotation else {
            return nil
        }

        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "draggablePoint") {
            return annotationView
        } else {
            let draggableView = DraggableAnnotationView(reuseIdentifier: "draggablePoint", size: 30)
            draggableView.delegate = self
            return draggableView
        }
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
}

extension ViewController: DraggableAnnotationViewDelegate {
    func draggableAnnotation(view: DraggableAnnotationView, didBecome state: State) {
        
        if state == .start {
            mapView.annotations?.forEach({ (annot) in
                if annot is MGLPolyline {
                    mapView.removeAnnotation(annot)
                }
            })
        }
        
        if state == .ended {
            let tapPoint: CGPoint = CGPoint(x: view.center.x, y: view.center.y)
            let tapCoordinate: CLLocationCoordinate2D = mapView.convert(tapPoint, toCoordinateFrom: nil)
            if let annotation = mapView.annotations?.first(where: {!$0.isEqual(view.annotation) && $0 is MGLPointAnnotation}) {
                let coord = [annotation.coordinate, tapCoordinate]
                let polyline = MGLPolyline(coordinates: coord, count: UInt(coord.count))
                mapView.addAnnotation(polyline)
            }
            print("coordinate 2D Proection \(tapCoordinate)")
        }
    }
}
