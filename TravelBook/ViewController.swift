//
//  ViewController.swift
//  TravelBook
//
//  Created by Birkan Pusa on 17.12.2021.
//

import UIKit
import MapKit
//konum alabilmek için corelocation
import CoreLocation

//Sınıfları viewcontroller'e tanımlıyoruz
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        // en iyi konumu al dedik
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //izin istedik
        locationManager.requestWhenInUseAuthorization()
        //konumu güncellemeye başladık
        locationManager.startUpdatingLocation()
    }
    
    //konumu mapte göstermek için gerekli fonksiyon
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //koordinatı diziden aldık
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        //zoom seviyesi ayarlama
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        
    }


}

